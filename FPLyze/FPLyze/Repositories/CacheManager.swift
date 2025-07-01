//
//  CacheManager.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 01.07.2025..
//

import Foundation

actor CacheManager {
    static let shared = CacheManager()
    
    private var leagueCache: [Int: CachedLeagueData] = [:]
    private let cacheExpiration: TimeInterval = 300 // 5 minutes
    private let maxCacheSize = 10 // Maximum number of leagues to cache
    
    private init() {}
    
    struct CachedLeagueData {
        let data: LeagueStatisticsData
        let timestamp: Date
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > CacheManager.shared.cacheExpiration
        }
    }
    
    func getCachedLeague(_ leagueId: Int) -> LeagueStatisticsData? {
        guard let cached = leagueCache[leagueId],
              !cached.isExpired else {
            return nil
        }
        return cached.data
    }
    
    func cacheLeague(_ leagueId: Int, data: LeagueStatisticsData) {
        // Remove oldest cache if we're at capacity
        if leagueCache.count >= maxCacheSize {
            let oldestKey = leagueCache
                .min(by: { $0.value.timestamp < $1.value.timestamp })?
                .key
            if let oldestKey = oldestKey {
                leagueCache.removeValue(forKey: oldestKey)
            }
        }
        
        leagueCache[leagueId] = CachedLeagueData(
            data: data,
            timestamp: Date()
        )
    }
    
    func clearCache() {
        leagueCache.removeAll()
    }
    
    func removeCachedLeague(_ leagueId: Int) {
        leagueCache.removeValue(forKey: leagueId)
    }
}
    