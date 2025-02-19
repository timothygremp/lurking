import Foundation
import CoreLocation

class RecentSearchManager: ObservableObject {
    @Published private(set) var recentSearches: [RecentSearch] = []
    private let maxSearches = 10
    private let defaults = UserDefaults.standard
    private let storageKey = "recentSearches"
    
    init() {
        loadRecentSearches()
    }
    
    func addSearch(title: String, subtitle: String, state: String, zip: String) {
        print("Adding search: \(title), \(subtitle), \(state), \(zip)")
        let newSearch = RecentSearch(
            mainText: title,
            subText: subtitle,
            state: state,
            zip: zip
        )
        
        // Remove if already exists to avoid duplicates
        recentSearches.removeAll { $0.mainText == title && $0.subText == subtitle }
        
        // Add new search at the beginning
        recentSearches.insert(newSearch, at: 0)
        print("Current searches count: \(recentSearches.count)")
        
        // Keep only the last 10 searches
        if recentSearches.count > maxSearches {
            recentSearches = Array(recentSearches.prefix(maxSearches))
        }
        
        saveRecentSearches()
    }
    
    private func loadRecentSearches() {
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([RecentSearch].self, from: data) {
            recentSearches = decoded
            print("Loaded \(recentSearches.count) recent searches")
        } else {
            print("No recent searches found or failed to decode")
        }
    }
    
    private func saveRecentSearches() {
        if let encoded = try? JSONEncoder().encode(recentSearches) {
            defaults.set(encoded, forKey: storageKey)
            print("Saved \(recentSearches.count) recent searches")
        } else {
            print("Failed to encode recent searches")
        }
    }
} 