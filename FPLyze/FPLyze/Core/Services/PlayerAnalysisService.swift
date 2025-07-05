//
//  PlayerAnalysisService.swift
//  FPLyze
//
//  Fixed player analysis with consistent ownership simulation
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
            // Create missed player analysis
            let missedAnalysis = createImprovedMissedPlayerAnalysis(
                for: member,
                topPlayers: topPlayers
            )
            missedAnalyses.append(missedAnalysis)
            
            // Create underperformer analysis
            let underperformerAnalysis = createImprovedUnderperformerAnalysis(
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
    
    // MARK: - Improved Analysis Methods
    
    private func createImprovedMissedPlayerAnalysis(
        for member: LeagueMember,
        topPlayers: [PlayerData]
    ) -> MissedPlayerAnalysis {
        var missedPlayers: [MissedPlayer] = []
        
        // Create deterministic selection based on member ID
        let memberSeed = member.entry
        
        // Focus on high-performing players for missed analysis
        let eligiblePlayers = topPlayers.filter { $0.totalPoints > 80 }
        
        // Simulate 8-15 potential misses per manager
        let numMisses = 8 + (memberSeed % 8)
        
        for i in 0..<numMisses {
            // Use deterministic selection
            let playerIndex = (memberSeed * 7 + i * 13) % eligiblePlayers.count
            let player = eligiblePlayers[playerIndex]
            
            // Simulate ownership pattern - some players were more likely to be missed
            let ownershipFactor = simulateOwnershipPattern(player: player, memberSeed: memberSeed, iteration: i)
            
            // Only include if this manager "didn't own" this player during good periods
            if ownershipFactor < 0.6 { // 60% threshold for "missing"
                let missedGameweeks = simulateMissedGameweeks(player: player, memberSeed: memberSeed, iteration: i)
                let missedPoints = simulateMissedPoints(player: player, gameweeks: missedGameweeks, memberSeed: memberSeed + i)
                
                if missedPoints > 15 { // Only show significant misses
                    let missed = MissedPlayer(
                        player: player,
                        missedPoints: missedPoints,
                        missedGameweeks: missedGameweeks,
                        avgPointsPerMiss: Double(missedPoints) / Double(max(missedGameweeks.count, 1))
                    )
                    missedPlayers.append(missed)
                }
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
    
    private func createImprovedUnderperformerAnalysis(
        for member: LeagueMember,
        allPlayers: [PlayerData]
    ) -> UnderperformerAnalysis {
        var underperformers: [UnderperformingPlayer] = []
        
        // Create consistent "owned" players for this manager
        let ownedPlayers = simulateOwnedPlayers(for: member, from: allPlayers)
        
        for (player, ownershipData) in ownedPlayers {
            let avgPointsPerGame = Double(player.totalPoints) / 38.0
            
            // Only consider players who underperformed expectations
            let expectedPointsPerGame = getExpectedPointsPerGame(for: player)
            
            if avgPointsPerGame < expectedPointsPerGame && ownershipData.gamesOwned > 5 {
                let underperformer = UnderperformingPlayer(
                    player: player,
                    gamesOwned: ownershipData.gamesOwned,
                    pointsWhileOwned: ownershipData.pointsWhileOwned,
                    avgPointsPerGame: Double(ownershipData.pointsWhileOwned) / Double(ownershipData.gamesOwned),
                    benchedGames: ownershipData.benchedGames
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
    
    // MARK: - Simulation Helper Functions
    
    private func simulateOwnershipPattern(player: PlayerData, memberSeed: Int, iteration: Int) -> Double {
        // Create deterministic but varied ownership patterns
        let playerSeed = player.id + memberSeed + iteration * 7
        return Double(playerSeed % 100) / 100.0
    }
    
    private func simulateMissedGameweeks(player: PlayerData, memberSeed: Int, iteration: Int) -> [Int] {
        // Simulate periods when the manager didn't own this player but should have
        let seed = memberSeed + player.id + iteration * 11
        let startGW = 1 + (seed % 25)
        let duration = 3 + (seed % 8)
        
        return Array(startGW..<min(startGW + duration, 39))
    }
    
    private func simulateMissedPoints(player: PlayerData, gameweeks: [Int], memberSeed: Int) -> Int {
        // Simulate how many points were missed during these gameweeks
        let avgPointsPerGame = Double(player.totalPoints) / 38.0
        let randomFactor = Double((memberSeed % 100) + 50) / 100.0 // 0.5 to 1.5
        
        // Some periods are better than others for different players
        let periodBonus = gameweeks.contains { $0 % 5 == 0 } ? 1.3 : 1.0
        
        let estimatedPoints = Int(avgPointsPerGame * Double(gameweeks.count) * randomFactor * periodBonus)
        return max(gameweeks.count * 2, estimatedPoints) // Minimum 2 points per gameweek
    }
    
    private func simulateOwnedPlayers(for member: LeagueMember, from allPlayers: [PlayerData]) -> [(PlayerData, OwnershipData)] {
        var ownedPlayers: [(PlayerData, OwnershipData)] = []
        
        // Create deterministic but varied squad for each manager
        let memberSeed = member.entry
        let squadSize = 20 + (memberSeed % 15) // 20-35 players owned throughout season
        
        // Filter to realistic player pool (players who actually played)
        let eligiblePlayers = allPlayers.filter { $0.minutes > 200 && $0.totalPoints < 200 }
        
        for i in 0..<squadSize {
            let playerIndex = (memberSeed * 17 + i * 23) % eligiblePlayers.count
            let player = eligiblePlayers[playerIndex]
            
            // Simulate ownership period
            let ownershipData = simulateOwnershipData(player: player, memberSeed: memberSeed, iteration: i)
            
            // Only include players who had disappointing spells
            if ownershipData.avgPointsPerGame < getExpectedPointsPerGame(for: player) {
                ownedPlayers.append((player, ownershipData))
            }
        }
        
        return ownedPlayers
    }
    
    private func simulateOwnershipData(player: PlayerData, memberSeed: Int, iteration: Int) -> OwnershipData {
        let seed = memberSeed + player.id + iteration * 19
        
        let gamesOwned = 5 + (seed % 20) // 5-25 games owned
        let actualAvgPoints = Double(player.totalPoints) / 38.0
        
        // Simulate worse performance while owned (0.6x to 1.0x their season average)
        let performanceFactor = Double((seed % 40) + 60) / 100.0 // 0.6 to 1.0
        let pointsWhileOwned = Int(actualAvgPoints * Double(gamesOwned) * performanceFactor)
        
        let benchedGames = (seed % 5) + 1 // 1-5 games benched
        
        return OwnershipData(
            gamesOwned: gamesOwned,
            pointsWhileOwned: max(pointsWhileOwned, gamesOwned), // Minimum 1 point per game
            avgPointsPerGame: Double(pointsWhileOwned) / Double(gamesOwned),
            benchedGames: min(benchedGames, gamesOwned / 3) // Max 1/3 of games benched
        )
    }
    
    private func getExpectedPointsPerGame(for player: PlayerData) -> Double {
        // Expected points based on position and price
        let positionExpectation: Double
        switch player.elementType {
        case 1: positionExpectation = 3.0 // GKP
        case 2: positionExpectation = 3.5 // DEF
        case 3: positionExpectation = 4.5 // MID
        case 4: positionExpectation = 5.0 // FWD
        default: positionExpectation = 4.0
        }
        
        // Higher priced players should score more
        let priceBonus = Double(player.nowCost) / 100.0 // Price in millions
        
        return positionExpectation + (priceBonus * 0.3)
    }
}

// MARK: - Helper Data Structure

private struct OwnershipData {
    let gamesOwned: Int
    let pointsWhileOwned: Int
    let avgPointsPerGame: Double
    let benchedGames: Int
}
