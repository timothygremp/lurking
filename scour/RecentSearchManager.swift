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
    
    func addSearch(title: String, subtitle: String) {
        print("Adding search: \(title), \(subtitle)")
        let newSearch = RecentSearch(mainText: title, subText: subtitle)
        
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
        } else 