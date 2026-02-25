import Foundation

/// Strips CMS/PKCS#7 signatures from signed Apple .mobileconfig files.
///
/// Signed mobileconfigs are DER-encoded CMS SignedData envelopes. The actual
/// plist payload is embedded inside — we extract it without verifying the signature,
/// which is intentional: we want to *read* the policy regardless of signing state.
///
/// Strategy: walk the DER ASN.1 tree to find the encapContentInfo eContent octet string,
/// which contains the raw plist bytes. Falls back to magic-byte search if parsing fails.
struct SignatureStripper {

    enum StrippingError: LocalizedError {
        case notSigned
        case extractionFailed(String)

        var errorDescription: String? {
            switch self {
            case .notSigned: return "File is not a signed mobileconfig"
            case .extractionFailed(let r): return "Could not extract payload: \(r)"
            }
        }
    }

    /// Returns `(strippedPlistData, wasActuallySigned)`.
    static func strip(data: Data) throws -> (Data, Bool) {
        // Fast path: already XML or binary plist — nothing to do
        if looksLikePlist(data) {
            return (data, false)
        }

        // Must start with DER SEQUENCE (0x30) to be CMS
        guard data.first == 0x30 else {
            throw StrippingError.notSigned
        }

        // Try structured ASN.1 extraction first (precise)
        if let extracted = extractViaDER(data) {
            return (extracted, true)
        }

        // Fallback: search for plist magic bytes within the binary envelope
        if let extracted = extractViaMagicSearch(data) {
            return (extracted, true)
        }

        throw StrippingError.extractionFailed("No plist content found inside CMS envelope")
    }

    /// Convenience: strip from a file URL, return text content
    static func stripToString(url: URL) throws -> (String, Bool) {
        let data = try Data(contentsOf: url)
        let (stripped, wasSigned) = try strip(data: data)
        guard let text = String(data: stripped, encoding: .utf8) else {
            throw StrippingError.extractionFailed("Stripped plist is not valid UTF-8")
        }
        return (text, wasSigned)
    }

    // MARK: - Detection

    static func looksLikeSigned(_ data: Data) -> Bool {
        guard data.first == 0x30, !looksLikePlist(data) else { return false }
        // CMS OID prefix: 1.2.840.113549.1.7.2 → hex 2a 86 48 86 f7 0d 01 07 02
        let oidBytes: [UInt8] = [0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x07, 0x02]
        return data.range(of: Data(oidBytes), in: 0..<min(64, data.count)) != nil
    }

    private static func looksLikePlist(_ data: Data) -> Bool {
        if data.starts(with: Data("<?xml".utf8)) { return true }
        if data.starts(with: Data("bplist".utf8)) { return true }
        if data.starts(with: Data("<!DOCTYPE".utf8)) { return true }
        return false
    }

    // MARK: - ASN.1 DER Walker

    /// Navigate CMS SignedData → encapContentInfo → eContent OCTET STRING.
    ///
    /// CMS structure (RFC 5652):
    ///   SEQUENCE {
    ///     OID (signedData)
    ///     [0] EXPLICIT {
    ///       SEQUENCE { -- SignedData
    ///         INTEGER  -- version
    ///         SET      -- digestAlgorithms
    ///         SEQUENCE { -- encapContentInfo
    ///           OID (data)
    ///           [0] EXPLICIT {
    ///             OCTET STRING -- ← the plist lives here
    ///           }
    ///         }
    ///         ...
    ///       }
    ///     }
    ///   }
    private static func extractViaDER(_ data: Data) -> Data? {
        var offset = 0
        let bytes = Array(data)

        // Outer SEQUENCE
        guard readTag(bytes, offset: &offset, expected: 0x30) != nil else { return nil }
        offset = 0 // reset — re-enter from the start of the outer sequence contents
        guard skipTag(bytes, offset: &offset, expected: 0x30) else { return nil }

        // OID — skip it
        guard skipTag(bytes, offset: &offset, expected: 0x06) else { return nil }

        // [0] EXPLICIT CONTEXT
        guard skipTagIfPresent(bytes, offset: &offset, tag: 0xA0) else { return nil }

        // Inner SEQUENCE (SignedData)
        guard skipTag(bytes, offset: &offset, expected: 0x30) else { return nil }

        // version INTEGER
        guard skipTag(bytes, offset: &offset, expected: 0x02) else { return nil }

        // digestAlgorithms SET
        guard skipTag(bytes, offset: &offset, expected: 0x31) else { return nil }

        // encapContentInfo SEQUENCE
        guard skipTag(bytes, offset: &offset, expected: 0x30) else { return nil }

        // eContentType OID
        guard skipTag(bytes, offset: &offset, expected: 0x06) else { return nil }

        // [0] EXPLICIT wrapping the content
        guard skipTagIfPresent(bytes, offset: &offset, tag: 0xA0) else { return nil }

        // OCTET STRING — the actual payload
        if let contentBytes = readTag(bytes, offset: &offset, expected: 0x04) {
            return Data(contentBytes)
        }

        // Some implementations use a constructed OCTET STRING — try that
        // (tag 0x24 = CONSTRUCTED OCTET STRING)
        if let contentBytes = readTag(bytes, offset: &offset, expected: 0x24) {
            // Concatenate inner octet strings
            let inner = contentBytes
            var innerOffset = 0
            var result = Data()
            while innerOffset < inner.count {
                if let chunk = readTag(inner, offset: &innerOffset, expected: 0x04) {
                    result.append(contentsOf: chunk)
                } else {
                    break
                }
            }
            return result.isEmpty ? nil : result
        }

        return nil
    }

    // MARK: - ASN.1 Helpers

    @discardableResult
    private static func readTag(_ bytes: [UInt8], offset: inout Int, expected: UInt8) -> [UInt8]? {
        guard offset < bytes.count, bytes[offset] == expected else { return nil }
        offset += 1
        guard let len = readLength(bytes, offset: &offset) else { return nil }
        guard offset + len <= bytes.count else { return nil }
        let content = Array(bytes[offset..<offset + len])
        offset += len
        return content
    }

    @discardableResult
    private static func readTag(_ data: Data, offset: inout Int, expected: UInt8) -> [UInt8]? {
        let bytes = Array(data)
        return readTag(bytes, offset: &offset, expected: expected)
    }

    private static func skipTag(_ bytes: [UInt8], offset: inout Int, expected: UInt8) -> Bool {
        return readTag(bytes, offset: &offset, expected: expected) != nil
    }

    private static func skipTagIfPresent(_ bytes: [UInt8], offset: inout Int, tag: UInt8) -> Bool {
        guard offset < bytes.count else { return false }
        if bytes[offset] == tag {
            return skipTag(bytes, offset: &offset, expected: tag)
        }
        return true // not present is fine
    }

    private static func readLength(_ bytes: [UInt8], offset: inout Int) -> Int? {
        guard offset < bytes.count else { return nil }
        let first = bytes[offset]
        offset += 1

        if first & 0x80 == 0 {
            return Int(first) // short form
        }

        let numBytes = Int(first & 0x7F)
        guard numBytes > 0, numBytes <= 4, offset + numBytes <= bytes.count else { return nil }

        var length = 0
        for i in 0..<numBytes {
            length = (length << 8) | Int(bytes[offset + i])
        }
        offset += numBytes
        return length
    }

    // MARK: - Magic Byte Fallback

    /// Scan for `<?xml` or `bplist00` inside the binary envelope.
    /// This is the blunt instrument that works when the ASN.1 walk fails.
    private static func extractViaMagicSearch(_ data: Data) -> Data? {
        // Try XML plist
        if let xmlStart = data.range(of: Data("<?xml".utf8)) {
            var candidate = data[xmlStart.lowerBound...]
            // Find closing </plist> to trim any trailing CMS bytes
            if let plistEnd = candidate.range(of: Data("</plist>".utf8)) {
                candidate = candidate[..<plistEnd.upperBound]
            }
            return Data(candidate)
        }

        // Try binary plist
        if let bplistStart = data.range(of: Data("bplist".utf8)) {
            return Data(data[bplistStart.lowerBound...])
        }

        return nil
    }
}
