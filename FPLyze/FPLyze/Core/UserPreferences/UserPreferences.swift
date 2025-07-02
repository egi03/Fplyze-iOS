//
//  UserPreferences.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 01.07.2025..
//

import Foundation
import SwiftUI

class UserPreferences: ObservableObject {
    static let shared = UserPreferences()
    
    @AppStorage("favoriteLeagues") private var favoriteLeaguesData: Data = Data()
    @AppStorage("recentSearches") private var recentSearchesData: Data = Data()
    
    @Published var favoriteLeagues: [FavoriteLeague] = []
    @Published var recentSearches: [RecentSearch] = []
    
    private let maxRecentSearches = 10
    private let maxFavorites = 20
    
    struct FavoriteLeague: Codable, Identifiable {
        let id: Int
        let name: String
        let addedDate: Date
        
        var formattedDate: String {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return formatter.localizedString(for: addedDate, relativeTo: Date())
        }
    }
    
    struct RecentSearch: Codable, Identifiable {
        var id = UUID()
        let leagueId: Int
        let searchDate: Date
        var leagueName: String?
    }
    
    init() {
        loadFavorites()
        loadRecentSearches()
    }
    
    // MARK: - Favorites Management
    
    func addFavorite(leagueId: Int, name: String) {
        guard !isFavorite(leagueId) else { return }
        
        let favorite = FavoriteLeague(
            id: leagueId,
            name: name,
            addedDate: Date()
        )
        
        favoriteLeagues.insert(favorite, at: 0)
        
        // Keep only max favorites
        if favoriteLeagues.count > maxFavorites {
            favoriteLeagues = Array(favoriteLeagues.prefix(maxFavorites))
        }
        
        saveFavorites()
    }
    
    func removeFavorite(leagueId: Int) {
        favoriteLeagues.removeAll { $0.id == leagueId }
        saveFavorites()
    }
    
    func isFavorite(_ leagueId: Int) -> Bool {
        favoriteLeagues.contains { $0.id == leagueId }
    }
    
    func toggleFavorite(leagueId: Int, name: String) {
        if isFavorite(leagueId) {
            removeFavorite(leagueId: leagueId)
        } else {
            addFavorite(leagueId: leagueId, name: name)
        }
    }
    
    // MARK: - Recent Searches Management
    
    func addRecentSearch(leagueId: Int, name: String? = nil) {
        // Remove existing entry if present
        recentSearches.removeAll { $0.leagueId == leagueId }
        
        let search = RecentSearch(
            leagueId: leagueId,
            searchDate: Date(),
            leagueName: name
        )
        
        recentSearches.insert(search, at: 0)
        
        // Keep only max recent searches
        if recentSearches.count > maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(maxRecentSearches))
        }
        
        saveRecentSearches()
    }
    
    func clearRecentSearches() {
        recentSearches.removeAll()
        saveRecentSearches()
    }
    
    // MARK: - Persistence
    
    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favoriteLeagues) {
            favoriteLeaguesData = encoded
        }
    }
    
    private func loadFavorites() {
        if let decoded = try? JSONDecoder().decode([FavoriteLeague].self, from: favoriteLeaguesData) {
            favoriteLeagues = decoded
        }
    }
    
    private func saveRecentSearches() {
        if let encoded = try? JSONEncoder().encode(recentSearches) {
            recentSearchesData = encoded
        }
    }
    
    private func loadRecentSearches() {
        if let decoded = try? JSONDecoder().decode([RecentSearch].self, from: recentSearchesData) {
            recentSearches = decoded
        }
    }
}
