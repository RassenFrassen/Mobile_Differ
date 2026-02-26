import Foundation
import SwiftUI

/// Service for handling deep links into the app
/// Supports URLs like: differ://key/{keyID} or differ://payload/{payloadType}
@MainActor
class DeepLinkService: ObservableObject {
    static let shared = DeepLinkService()

    @Published var pendingDeepLink: DeepLink?

    enum DeepLink: Equatable {
        case key(id: String)
        case payload(type: String)
        case search(query: String)
        case favorites
        case history
        case settings
    }

    private init() {}

    /// Parse and handle a URL
    func handle(_ url: URL) -> Bool {
        guard url.scheme == "differ" else { return false }

        let host = url.host ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        switch host {
        case "key":
            if let keyID = pathComponents.first {
                pendingDeepLink = .key(id: keyID)
                return true
            }

        case "payload":
            if let payloadType = pathComponents.first {
                pendingDeepLink = .payload(type: payloadType)
                return true
            }

        case "search":
            if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
               let query = queryItems.first(where: { $0.name == "q" })?.value {
                pendingDeepLink = .search(query: query)
                return true
            }

        case "favorites":
            pendingDeepLink = .favorites
            return true

        case "history":
            pendingDeepLink = .history
            return true

        case "settings":
            pendingDeepLink = .settings
            return true

        default:
            break
        }

        return false
    }

    /// Clear the pending deep link
    func clearPendingDeepLink() {
        pendingDeepLink = nil
    }

    /// Generate a shareable deep link for a key
    static func keyURL(for keyID: String) -> URL? {
        URL(string: "differ://key/\(keyID)")
    }

    /// Generate a shareable deep link for a payload
    static func payloadURL(for payloadType: String) -> URL? {
        let encoded = payloadType.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? payloadType
        return URL(string: "differ://payload/\(encoded)")
    }

    /// Generate a search deep link
    static func searchURL(query: String) -> URL? {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: "differ://search?q=\(encoded)")
    }
}
