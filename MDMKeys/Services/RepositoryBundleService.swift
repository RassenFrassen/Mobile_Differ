import Foundation
import ZIPFoundation

/// Service for managing embedded repository bundles used for offline data access.
actor RepositoryBundleService {
    static let shared = RepositoryBundleService()

    private let fileManager = FileManager.default

    struct BundleDownloadResult {
        let source: MDMSource
        let localPath: URL
        let revision: String?
        let downloadedAt: Date
    }

    /// Downloads a repository as a zip bundle and extracts it using ZIPFoundation.
    func downloadAndExtractBundle(
        owner: String,
        repo: String,
        branch: String = "main",
        source: MDMSource,
        token: String?
    ) async throws -> BundleDownloadResult {
        let branchesToTry = [branch, "master", "release"]
        var lastError: Error?

        for branchName in branchesToTry {
            do {
                return try await attemptDownload(
                    owner: owner,
                    repo: repo,
                    branch: branchName,
                    source: source,
                    token: token
                )
            } catch {
                lastError = error
                continue
            }
        }

        throw lastError ?? GitHubError.networkError("Failed to download bundle")
    }

    private func attemptDownload(
        owner: String,
        repo: String,
        branch: String,
        source: MDMSource,
        token: String?
    ) async throws -> BundleDownloadResult {
        guard let zipURL = URL(string: "https://github.com/\(owner)/\(repo)/archive/refs/heads/\(branch).zip") else {
            throw GitHubError.networkError("Invalid zip URL")
        }

        var request = URLRequest(url: zipURL)
        request.setValue("MDMKeys/1.0", forHTTPHeaderField: "User-Agent")
        if let token {
            request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        }

        let (tempZipURL, response) = try await URLSession.shared.download(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw GitHubError.networkError("Failed to download zip")
        }

        let bundlesDir = try getBundlesDirectory()
        let sourceDir = bundlesDir.appendingPathComponent("\(owner)-\(repo)", isDirectory: true)

        if fileManager.fileExists(atPath: sourceDir.path) {
            try fileManager.removeItem(at: sourceDir)
        }
        try fileManager.createDirectory(at: sourceDir, withIntermediateDirectories: true)

        // Use ZIPFoundation for cross-platform extraction
        try fileManager.unzipItem(at: tempZipURL, to: sourceDir)

        let revision = httpResponse.value(forHTTPHeaderField: "Last-Modified")
            ?? ISO8601DateFormatter().string(from: Date())

        return BundleDownloadResult(
            source: source,
            localPath: sourceDir,
            revision: revision,
            downloadedAt: Date()
        )
    }

    /// Gets the bundles directory for storing extracted repositories
    func getBundlesDirectory() throws -> URL {
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let bundlesDir = appSupport
            .appendingPathComponent("MDMKeys", isDirectory: true)
            .appendingPathComponent("Bundles", isDirectory: true)

        if !fileManager.fileExists(atPath: bundlesDir.path) {
            try fileManager.createDirectory(at: bundlesDir, withIntermediateDirectories: true)
        }

        return bundlesDir
    }

    /// Gets the path to an embedded bundle resource bundled inside the app.
    /// If the bundle is a ZIP file, extracts it to the bundles directory first.
    func getEmbeddedBundlePath(for source: MDMSource) async throws -> URL? {
        guard let bundleName = embeddedBundleName(for: source) else { return nil }
        
        // First check if we already have an extracted copy in the bundles directory
        if let extracted = try? await getExtractedEmbeddedBundlePath(for: source),
           fileManager.fileExists(atPath: extracted.path) {
            return extracted
        }
        
        // Check for embedded ZIP file
        if let zipURL = Bundle.main.url(forResource: bundleName, withExtension: "zip") {
            // Extract the ZIP to bundles directory
            return try await extractEmbeddedZip(zipURL: zipURL, for: source)
        }
        
        // Fallback to looking for unzipped embedded bundle (for backwards compatibility)
        return Bundle.main.url(
            forResource: bundleName,
            withExtension: nil,
            subdirectory: "EmbeddedBundles"
        )
    }
    
    /// Extracts an embedded ZIP bundle to the bundles directory
    private func extractEmbeddedZip(zipURL: URL, for source: MDMSource) async throws -> URL {
        let bundlesDir = try getBundlesDirectory()
        guard let bundleName = embeddedBundleName(for: source) else {
            throw GitHubError.networkError("Invalid source")
        }
        
        let extractedDir = bundlesDir.appendingPathComponent(bundleName, isDirectory: true)
        
        // If already extracted, return it
        if fileManager.fileExists(atPath: extractedDir.path) {
            return extractedDir
        }
        
        // Extract the ZIP
        try fileManager.createDirectory(at: extractedDir, withIntermediateDirectories: true)
        try fileManager.unzipItem(at: zipURL, to: extractedDir)
        
        return extractedDir
    }
    
    /// Gets the path to an already-extracted embedded bundle in the bundles directory
    private func getExtractedEmbeddedBundlePath(for source: MDMSource) async throws -> URL? {
        let bundlesDir = try getBundlesDirectory()
        guard let bundleName = embeddedBundleName(for: source) else { return nil }
        
        let extractedPath = bundlesDir.appendingPathComponent(bundleName, isDirectory: true)
        return fileManager.fileExists(atPath: extractedPath.path) ? extractedPath : nil
    }

    private func embeddedBundleName(for source: MDMSource) -> String? {
        switch source {
        case .appleDeviceManagement:
            return "apple-device-management"
        case .profileCreator:
            return "ProfileManifests-ProfileManifests"
        case .rtroutonProfiles:
            return "rtrouton-profiles"
        case .appleDeveloperDocumentation:
            return nil
        case .microsoft:
            return nil
        }
    }

    func hasOfflineBundle(for source: MDMSource) async -> Bool {
        if let downloaded = try? getDownloadedBundlePath(for: source),
           fileManager.fileExists(atPath: downloaded.path) {
            return true
        }
        if let embedded = try? await getEmbeddedBundlePath(for: source),
           fileManager.fileExists(atPath: embedded.path) {
            return true
        }
        return false
    }

    func getDownloadedBundlePath(for source: MDMSource) throws -> URL? {
        let bundlesDir = try getBundlesDirectory()
        let dirName: String
        switch source {
        case .appleDeviceManagement: dirName = "apple-device-management"
        case .profileCreator: dirName = "ProfileManifests-ProfileManifests"
        case .rtroutonProfiles: dirName = "rtrouton-profiles"
        case .appleDeveloperDocumentation: return nil
        case .microsoft: return nil
        }
        let path = bundlesDir.appendingPathComponent(dirName, isDirectory: true)
        return fileManager.fileExists(atPath: path.path) ? path : nil
    }

    func getBundlePath(for source: MDMSource) async throws -> URL? {
        if let downloaded = try getDownloadedBundlePath(for: source) {
            return downloaded
        }
        return try await getEmbeddedBundlePath(for: source)
    }

    /// Lists all files in a bundle with given extensions
    func listFiles(
        in bundleURL: URL,
        withExtensions extensions: [String],
        subdirectory: String? = nil
    ) -> [URL] {
        var searchURL = bundleURL

        if let contents = try? fileManager.contentsOfDirectory(
            at: bundleURL,
            includingPropertiesForKeys: nil
        ) {
            if let rootDir = contents.first(where: { $0.hasDirectoryPath }) {
                searchURL = rootDir
            }
        }

        if let subdirectory {
            searchURL = searchURL.appendingPathComponent(subdirectory, isDirectory: true)
        }

        guard let enumerator = fileManager.enumerator(
            at: searchURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var files: [URL] = []
        for case let fileURL as URL in enumerator {
            guard let isRegularFile = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile,
                  isRegularFile else { continue }
            if extensions.contains(fileURL.pathExtension.lowercased()) {
                files.append(fileURL)
            }
        }

        return files
    }
}
