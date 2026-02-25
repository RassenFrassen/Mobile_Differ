import Foundation

enum GitHubError: LocalizedError {
    case unauthorized
    case notFound
    case rateLimited(resetAt: Date?)
    case clientRateLimited(resetAt: Date)
    case networkError(String)
    case decodingError(String)

    private static let resetFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "GitHub token is invalid or missing"
        case .notFound:
            return "Repository or file not found"
        case .rateLimited(let resetAt):
            if let resetAt {
                return "GitHub API rate limit exceeded. Retry after \(GitHubError.resetFormatter.string(from: resetAt))."
            }
            return "GitHub API rate limit exceeded"
        case .clientRateLimited(let resetAt):
            return "Differ request budget reached. Retry after \(GitHubError.resetFormatter.string(from: resetAt))."
        case .networkError(let m):
            return "Network error: \(m)"
        case .decodingError(let m):
            return "Failed to decode response: \(m)"
        }
    }
}

actor GitHubService {
    static let shared = GitHubService()

    private let baseURL = "https://api.github.com"
    private let unauthenticatedRequestsPerHour = 60
    private let authenticatedRequestsPerHour = 5000

    private var cachedFiles: [String: [GitHubFile]] = [:]
    private var cachedContent: [String: String] = [:]

    private var localWindowStartedAt = Date()
    private var localRequestCount: [Bool: Int] = [false: 0, true: 0]
    private var remoteRateRemaining: Int?
    private var remoteRateResetAt: Date?

    func listFiles(owner: String, repo: String, path: String = "", token: String? = nil) async throws -> [GitHubFile] {
        let cacheKey = "\(owner)/\(repo)/\(path)"
        if let cached = cachedFiles[cacheKey] { return cached }

        let urlString = "\(baseURL)/repos/\(owner)/\(repo)/contents/\(path)"
        let data = try await fetch(urlString: urlString, token: token)

        do {
            let files = try JSONDecoder().decode([GitHubFile].self, from: data)
            cachedFiles[cacheKey] = files
            return files
        } catch {
            throw GitHubError.decodingError(error.localizedDescription)
        }
    }

    func fetchContent(url: String, token: String? = nil) async throws -> String {
        if let cached = cachedContent[url] { return cached }

        let data = try await fetch(urlString: url, token: token)
        guard let content = String(data: data, encoding: .utf8) else {
            throw GitHubError.decodingError("Cannot decode file as UTF-8")
        }
        cachedContent[url] = content
        return content
    }

    func fetchData(url: String, token: String? = nil) async throws -> Data {
        try await fetch(urlString: url, token: token)
    }

    func fetchRepo(owner: String, repo: String, token: String? = nil) async throws -> GitHubRepo {
        let urlString = "\(baseURL)/repos/\(owner)/\(repo)"
        let data = try await fetch(urlString: urlString, token: token)
        do {
            return try JSONDecoder().decode(GitHubRepo.self, from: data)
        } catch {
            throw GitHubError.decodingError(error.localizedDescription)
        }
    }

    func searchProfiles(owner: String, repo: String, query: String, token: String? = nil) async throws -> [GitHubFile] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(baseURL)/search/code?q=\(encoded)+repo:\(owner)/\(repo)"
        let data = try await fetch(urlString: urlString, token: token)

        struct SearchResult: Decodable {
            let items: [GitHubFile]
        }

        do {
            let result = try JSONDecoder().decode(SearchResult.self, from: data)
            return result.items
        } catch {
            throw GitHubError.decodingError(error.localizedDescription)
        }
    }

    func invalidateCache() {
        cachedFiles.removeAll()
        cachedContent.removeAll()
    }

    // MARK: - Private

    private func fetch(urlString: String, token: String?) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw GitHubError.networkError("Invalid URL: \(urlString)")
        }

        let isAuthenticated = !(token?.isEmpty ?? true)
        try enforceLocalRateBudget(isAuthenticated: isAuthenticated)

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("MDMKeys/1.0", forHTTPHeaderField: "User-Agent")
        if let token = token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw GitHubError.networkError(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw GitHubError.networkError("Invalid response")
        }

        updateRemoteRateState(from: http)

        switch http.statusCode {
        case 200...299:
            return data
        case 401:
            throw GitHubError.unauthorized
        case 403, 429:
            if remoteRateRemaining == 0 {
                throw GitHubError.rateLimited(resetAt: remoteRateResetAt)
            }
            throw GitHubError.networkError("HTTP \(http.statusCode): access denied")
        case 404:
            throw GitHubError.notFound
        default:
            throw GitHubError.networkError("HTTP \(http.statusCode)")
        }
    }

    private func enforceLocalRateBudget(isAuthenticated: Bool) throws {
        let now = Date()

        if let resetAt = remoteRateResetAt,
           let remaining = remoteRateRemaining,
           remaining <= 0,
           now < resetAt {
            throw GitHubError.rateLimited(resetAt: resetAt)
        }

        if now.timeIntervalSince(localWindowStartedAt) >= 3600 {
            localWindowStartedAt = now
            localRequestCount = [false: 0, true: 0]
        }

        let limit = isAuthenticated ? authenticatedRequestsPerHour : unauthenticatedRequestsPerHour
        let count = localRequestCount[isAuthenticated, default: 0]
        guard count < limit else {
            throw GitHubError.clientRateLimited(resetAt: localWindowStartedAt.addingTimeInterval(3600))
        }

        localRequestCount[isAuthenticated] = count + 1
    }

    private func updateRemoteRateState(from response: HTTPURLResponse) {
        if let remaining = headerInt("X-RateLimit-Remaining", response: response) {
            remoteRateRemaining = remaining
        }
        if let resetEpoch = headerInt("X-RateLimit-Reset", response: response) {
            remoteRateResetAt = Date(timeIntervalSince1970: TimeInterval(resetEpoch))
        }
    }

    private func headerInt(_ name: String, response: HTTPURLResponse) -> Int? {
        response.value(forHTTPHeaderField: name).flatMap(Int.init)
    }
}

// MARK: - Supporting Types

struct GitHubFile: Codable, Identifiable {
    let name: String
    let path: String
    let type: String
    let downloadURL: String?
    let url: String?
    var id: String { path }
    var isDirectory: Bool { type == "dir" }

    enum CodingKeys: String, CodingKey {
        case name, path, type, url
        case downloadURL = "download_url"
    }
}

struct GitHubRepo: Codable {
    let name: String
    let fullName: String
    let description: String?
    let updatedAt: String?
    let pushedAt: String?
    let defaultBranch: String?

    enum CodingKeys: String, CodingKey {
        case name
        case fullName = "full_name"
        case description
        case updatedAt = "updated_at"
        case pushedAt = "pushed_at"
        case defaultBranch = "default_branch"
    }
}

// MARK: - GitMirrorService (iOS stub — falls through to embedded bundle / GitHub API)

struct GitMirrorSyncResult {
    let owner: String
    let repo: String
    let localURL: URL
    let previousRevision: String?
    let currentRevision: String
    let didChange: Bool
    let didClone: Bool
    let checkedAt: Date
}

actor GitMirrorService {
    static let shared = GitMirrorService()

    /// On iOS, git-based local mirroring is unavailable.
    /// Callers should catch this and fall back to embedded bundles or the GitHub API.
    func syncDaily(owner: String, repo: String) async throws -> GitMirrorSyncResult {
        throw GitHubError.networkError("Local git mirroring is not available on iOS — using embedded bundle or live API")
    }

    func syncNow(owner: String, repo: String) async throws -> GitMirrorSyncResult {
        throw GitHubError.networkError("Local git mirroring is not available on iOS — using embedded bundle or live API")
    }

    func localRepoURL(owner: String, repo: String) -> URL? { nil }
}
