//
//  PlayerAnalysisService.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 01.07.2025..
//

import Foundation

@MainActor
class PlayerAnalysisService {
    private let apiService = FPLAPIService.shared
    
    // Cache for player data
    private var cachedPlayerData: BootstrapData?
    private var lastPlayerDataFetch: Date?
    private let cacheExpiration: TimeInterval = 3600 // 1 hour
    
    // Analyze missed players and underperformers for all league members
    func analyzeLeague(_ members: [LeagueMember]) async throws -> (missed: [MissedPlayerAnalysis], underperformers: [UnderperformerAnalysis]) {
        // Get player data
        let playerData = try await getPlayerData()
        let topPlayers = playerData.topPlayers
        
        var missedAnalyses: [MissedPlayerAnalysis] = []
        var underperformerAnalyses: [UnderperformerAnalysis] = []
        
        // Analyze each member (limit to top 20 for performance)
        for member in members.prefix(20) {
            // For demonstration, we'll create simplified analyses
            // In a real implementation, you'd fetch actual ownership data
            
            // Create missed player analysis
            let missedAnalysis = createMissedPlayerAnalysis(
                for: member,
                topPlayers: topPlayers
            )
            missedAnalyses.append(missedAnalysis)
            
            // Create underperformer analysis
            let underperformerAnalysis = createUnderperformerAnalysis(
                for: member,
                allPlayers: playerData.elements
            )
            underperformerAnalyses.append(underperformerAnalysis)
        }
        
        return (missedAnalyses, underperformerAnalyses)
    }
    
    // Get player data with caching
    private func getPlayerData() async throws -> BootstrapData {
        if let cached = cachedPlayerData,
           let lastFetch = lastPlayerDataFetch,
           Date().timeIntervalSince(lastFetch) < cacheExpiration {
            return cached
        }
        
        let data = try await apiService.getPlayerData()
        cachedPlayerData = data
        lastPlayerDataFetch = Date()
        return data
    }
    
    // Create simplified missed player analysis
    private func createMissedPlayerAnalysis(
        for member: LeagueMember,
        topPlayers: [PlayerData]
    ) -> MissedPlayerAnalysis {
        var missedPlayers: [MissedPlayer] = []
        
        // Simulate analysis - in reality, would check actual ownership
        for (index, player) in topPlayers.enumerated() {
            // Skip some players to simulate ownership
            if index % 3 == member.entry % 3 { continue }
            
            // Calculate simulated missed points based on ownership percentage
            let ownershipFactor = 1.0 - (player.ownership / 100.0)
            let missedGameweeks = Int(Double(member.gameweekHistory.count) * ownershipFactor * 0.7)
            let missedPoints = Int(Double(player.totalPoints) * ownershipFactor * 0.5)
            
            if missedPoints > 20 {
                let missed = MissedPlayer(
                    player: player,
                    missedPoints: missedPoints,
                    missedGameweeks: Array(1...missedGameweeks),
                    avgPointsPerMiss: Double(missedPoints) / Double(max(missedGameweeks, 1))
                )
                missedPlayers.append(missed)
            }
        }
        
        // Sort by missed points and take top 10
        missedPlayers.sort { $0.missedPoints > $1.missedPoints }
        let topMissed = Array(missedPlayers.prefix(10))
        
        return MissedPlayerAnalysis(
            managerId: member.entry,
            managerName: member.playerName,
            missedPlayers: topMissed,
            totalMissedPoints: topMissed.reduce(0) { $0 + $1.missedPoints },
            biggestMiss: topMissed.first
        )
    }
    
    // Create simplified underperformer analysis
    private func createUnderperformerAnalysis(
        for member: LeagueMember,
        allPlayers: [PlayerData]
    ) -> UnderperformerAnalysis {
        var underperformers: [UnderperformingPlayer] = []
        
        // Select random players as "owned" for demonstration
        let ownedCount = 15 + (member.entry % 10)
        let shuffledPlayers = allPlayers.shuffled()
        
        for player in shuffledPlayers.prefix(ownedCount) {
            // Skip high-performing players
            if player.totalPoints > 150 { continue }
            
            // Calculate simulated performance
            let gamesOwned = 10 + (member.entry % 20)
            let avgPointsPerGame = Double(player.totalPoints) / 38.0
            let performanceFactor = Double(100 - player.totalPoints) / 100.0
            
            if avgPointsPerGame < 4.5 && player.minutes > 500 {
                let underperformer = UnderperformingPlayer(
                    player: player,
                    gamesOwned: gamesOwned,
                    pointsWhileOwned: Int(avgPointsPerGame * Double(gamesOwned)),
                    avgPointsPerGame: avgPointsPerGame,
                    benchedGames: Int(Double(gamesOwned) * performanceFactor * 0.3)
                )
                underperformers.append(underperformer)
            }
        }
        
        // Sort by average points (worst first) and take top 10
        underperformers.sort { $0.avgPointsPerGame < $1.avgPointsPerGame }
        let topUnderperformers = Array(underperformers.prefix(10))
        
        return UnderperformerAnalysis(
            managerId: member.entry,
            managerName: member.playerName,
            underperformers: topUnderperformers,
            worstPerformer: topUnderperformers.first
        )
    }
}
