import Foundation

/// Service for managing user's favorite/bookmarked MDM keys
actor FavoritesService {
    static let shared = FavoritesService()

    private let fileURL: URL
    private var favorites: Set<String> = []

    private init() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = documentsURL.appendingPathComponent("favorites.json")
        Task {
            await loadFavorites()
        }
    }

    // MARK: - Public API

    func isFavorite(_ keyID: String) async -> Bool {
        favorites.contains(keyID)
    }

    func toggleFavorite(_ keyID: String) async {
        if favorites.contains(keyID) {
            favorites.remove(keyID)
        } else {
            favorites.insert(keyID)
        }
        await saveFavorites()
    }

    func addFavorite(_ keyID: String) async {
        favorites.insert(keyID)
        await saveFavorites()
    }

    func removeFavorite(_ keyID: String) async {
        favorites.remove(keyID)
        await saveFavorites()
    }

    func getAllFavorites() async -> Set<String> {
        favorites
    }

    func clearAll() async {
        favorites.removeAll()
        await saveFavorites()
    }

    // MARK: - Persistence

    private func loadFavorites() async {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            // Try to migrate from UserDefaults if exists
            if let legacyFavorites = UserDefaults.standard.array(forKey: "favoriteKeys") as? [String] {
                favorites = Set(legacyFavorites)
                await saveFavorites()
                UserDefaults.standard.removeObject(forKey: "favoriteKeys")
            }
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([String].self, from: data)
            favorites = Set(decoded)
        } catch {
            logError("Failed to load favorites: \(error)")
            favorites = []
        }
    }

    private func saveFavorites() async {
        do {
            let array = Array(favorites).sorted()
            let data = try JSONEncoder().encode(array)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            logError("Failed to save favorites: \(error)")
        }
    }
}
