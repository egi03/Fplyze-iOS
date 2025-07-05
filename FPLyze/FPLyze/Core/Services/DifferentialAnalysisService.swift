//
//  DifferentialAnalysisService.swift
//  FPLyze
//

import Foundation

@MainActor
class DifferentialAnalysisService {
    private let apiService = FPLAPIService.shared
    
    // MARK: - Main Analysis Functions
    
    func analyzeDifferentials(for members: [LeagueMember]) async throws -> [DifferentialAnalysis] {
        // Get player data for ownership percentages
        let playerData = try await apiService.getPlayerData()
        let allPlayers = playerData.elements
        
        var analyses: [DifferentialAnalysis] = []
        
        for member in members {
            let analysis = await analyzeMemberDifferentials(
                member: member,
                allPlayers: allPlayers,
                leagueMembers: members
            )
            analyses.append(analysis)
        }
        
        return analyses
    }
    
    func generateWhatIfScenarios(for members: [LeagueMember]) async throws -> [WhatIfScenario] {
        var scenarios: [WhatIfScenario] = []
        
        // Captain What-If Scenarios
        let captainScenarios = await generateCaptainScenarios(members: members)
        scenarios.append(contentsOf: captainScenarios)
        
        // Chip Timing Scenarios
        let chipScenarios = await generateChipTimingScenarios(members: members)
        scenarios.append(contentsOf: chipScenarios)
        
        return scenarios
    }
    
    // MARK: - Differential Analysis Implementation
    
    private func analyzeMemberDifferentials(
        member: LeagueMember,
        allPlayers: [PlayerData],
        leagueMembers: [LeagueMember]
    ) async -> DifferentialAnalysis {
        
        var differentialPicks: [DifferentialPick] = []
        var missedOpportunities: [MissedDifferential] = []
        
        // Create deterministic but varied differentials based on member ID
        let memberSeed = member.entry
        let topPlayers = allPlayers.filter { $0.totalPoints > 50 }.sorted { $0.totalPoints > $1.totalPoints }.prefix(100)
        let simulatedDifferentials = generateImprovedDifferentials(
            member: member,
            topPlayers: Array(topPlayers),
            leagueSize: leagueMembers.count,
            seed: memberSeed
        )
        
        differentialPicks = simulatedDifferentials.picks
        missedOpportunities = simulatedDifferentials.missed
        
        let totalPoints = differentialPicks.map { $0.pointsScored }.reduce(0, +)
        let successfulPicks = differentialPicks.filter { $0.outcome == .masterStroke || $0.outcome == .goodPick }.count
        let successRate = differentialPicks.isEmpty ? 0 : Double(successfulPicks) / Double(differentialPicks.count) * 100
        
        let riskLevel = calculateRiskLevel(
            differentialCount: differentialPicks.count,
            leagueSize: leagueMembers.count,
            successRate: successRate
        )
        
        return DifferentialAnalysis(
            managerId: member.entry,
            managerName: member.playerName,
            entryName: member.entryName,
            differentialPicks: differentialPicks,
            missedOpportunities: missedOpportunities,
            totalDifferentialPoints: totalPoints,
            differentialSuccessRate: successRate,
            riskRating: riskLevel
        )
    }
    
    private func generateImprovedDifferentials(
        member: LeagueMember,
        topPlayers: [PlayerData],
        leagueSize: Int,
        seed: Int
    ) -> (picks: [DifferentialPick], missed: [MissedDifferential]) {
        
        var picks: [DifferentialPick] = []
        var missed: [MissedDifferential] = []
        
        // Create a more varied number of differentials (2-8 per member)
        let numDifferentials = 2 + (seed % 7)
        
        // Create deterministic but varied selection
        for i in 0..<numDifferentials {
            let playerIndex = (seed * 7 + i * 11) % topPlayers.count
            let player = topPlayers[playerIndex]
            
            // Create more realistic ownership percentages
            let baseOwnership = player.ownership
            let ownershipVariation = Double((seed + i) % 40) - 20.0 // -20 to +20
            let leagueOwnership = max(5.0, min(60.0, baseOwnership + ownershipVariation))
            
            // Only consider as differential if league ownership < 40%
            if leagueOwnership < 40 {
                let gameweeks = simulateGameweeksOwned(memberSeed: seed, playerIndex: i)
                let points = simulateImprovedPlayerPoints(player: player, gameweeks: gameweeks, seed: seed + i)
                
                let impact = getDifferentialImpact(points: points, ownership: leagueOwnership)
                let outcome = getImprovedDifferentialOutcome(points: points, gameweeks: gameweeks.count, ownership: leagueOwnership)
                
                let differential = DifferentialPick(
                    player: player,
                    gameweeksPicked: gameweeks,
                    pointsScored: points,
                    leagueOwnership: leagueOwnership,
                    globalOwnership: baseOwnership,
                    impact: impact,
                    outcome: outcome
                )
                
                picks.append(differential)
            }
        }
        
        // Simulate missed opportunities (1-3 per member)
        let numMissed = 1 + (seed % 3)
        for i in 0..<numMissed {
            let playerIndex = (seed * 13 + i * 17 + 50) % topPlayers.count
            let player = topPlayers[playerIndex]
            
            // Focus on players with lower ownership for missed opportunities
            if player.ownership < 30 {
                let gameweeks = Array(1 + (i * 3)...min(4 + (i * 3), 10))
                let points = simulateImprovedPlayerPoints(player: player, gameweeks: gameweeks, seed: seed + i + 100)
                
                // Only show significant missed opportunities
                if points > 25 {
                    let ownedBy = simulateOtherOwners(leagueSize: leagueSize, seed: seed + i)
                    let impact = getDifferentialImpact(points: points, ownership: player.ownership)
                    
                    let missed_diff = MissedDifferential(
                        player: player,
                        ownedByManagers: ownedBy,
                        pointsMissed: points,
                        gameweeksMissed: gameweeks,
                        impact: impact
                    )
                    
                    missed.append(missed_diff)
                }
            }
        }
        
        return (picks, missed)
    }
    
    // MARK: - Improved Simulation Functions
    
    private func simulateImprovedPlayerPoints(player: PlayerData, gameweeks: [Int], seed: Int) -> Int {
        let avgPointsPerGame = Double(player.totalPoints) / 38.0
        
        // Create more realistic variation (0.5x to 2.5x)
        let randomFactor = Double((seed % 200) + 50) / 100.0 // 0.5 to 2.5
        
        // Better players have more consistent high returns
        let playerQualityBonus = player.totalPoints > 150 ? 1.2 : (player.totalPoints > 100 ? 1.1 : 1.0)
        
        // Some gameweeks are just better (simulate double gameweeks, good fixtures)
        let gameweekBonus = gameweeks.contains { $0 % 7 == 0 } ? 1.3 : 1.0
        
        let finalPoints = Int(avgPointsPerGame * Double(gameweeks.count) * randomFactor * playerQualityBonus * gameweekBonus)
        
        // Ensure minimum reasonable points
        return max(gameweeks.count * 2, finalPoints)
    }
    
    private func getImprovedDifferentialOutcome(points: Int, gameweeks: Int, ownership: Double) -> DifferentialOutcome {
        let pointsPerGameweek = Double(points) / Double(gameweeks)
        let ownershipBonus = (50 - ownership) / 50.0 // Higher bonus for lower ownership
        let adjustedScore = pointsPerGameweek * (1.0 + ownershipBonus)
        
        // More generous thresholds for better outcomes
        if adjustedScore > 12 {
            return .masterStroke
        } else if adjustedScore > 7 {
            return .goodPick
        } else if adjustedScore > 4 {
            return .neutral
        } else if adjustedScore > 2 {
            return .poorChoice
        } else {
            return .disaster
        }
    }
    
    private func simulateGameweeksOwned(memberSeed: Int, playerIndex: Int) -> [Int] {
        let startGW = 1 + ((memberSeed + playerIndex * 3) % 15)
        let duration = 3 + ((memberSeed + playerIndex) % 8)
        return Array(startGW..<min(startGW + duration, 39))
    }
    
    private func simulateOtherOwners(leagueSize: Int, seed: Int) -> [String] {
        let names = ["Alex M.", "Jordan S.", "Sam K.", "Riley P.", "Casey L.", "Taylor B.", "Morgan F.", "Drew C."]
        let count = min(1 + (seed % 3), min(names.count, leagueSize / 3))
        let startIndex = seed % (names.count - count + 1)
        return Array(names[startIndex..<startIndex + count])
    }
    
    // MARK: - What-If Scenarios Implementation (unchanged)
    
    private func generateCaptainScenarios(members: [LeagueMember]) async -> [WhatIfScenario] {
        var scenarios: [WhatIfScenario] = []
        
        // Find gameweeks with high captain variation potential
        let targetGameweeks = findHighVariationGameweeks(members: members)
        
        for gameweek in targetGameweeks.prefix(3) {
            let scenario = await generateCaptainScenario(
                gameweek: gameweek,
                members: members
            )
            scenarios.append(scenario)
        }
        
        return scenarios
    }
    
    private func generateCaptainScenario(
        gameweek: Int,
        members: [LeagueMember]
    ) async -> WhatIfScenario {
        
        var results: [WhatIfResult] = []
        
        // Simulate what would happen if everyone captained the highest-scoring player
        let bestCaptainPoints = simulateBestCaptainChoice(gameweek: gameweek)
        
        for member in members {
            let originalGW = member.gameweekHistory.first { $0.event == gameweek }
            guard let original = originalGW else { continue }
            
            // Estimate current captain contribution (rough calculation)
            let estimatedCaptainPoints = Int(Double(original.points) * 0.25) // Assume 25% from captain
            let currentCaptainActual = estimatedCaptainPoints / 2 // Reverse the doubling
            
            // Calculate new points with best captain
            let pointsDifference = (bestCaptainPoints * 2) - (currentCaptainActual * 2)
            let newPoints = original.points + pointsDifference
            
            // Simulate new ranking (simplified)
            let newRank = simulateNewRanking(
                member: member,
                originalRank: original.rank,
                pointsChange: pointsDifference,
                gameweek: gameweek
            )
            
            let result = WhatIfResult(
                managerId: member.entry,
                managerName: member.playerName,
                originalRank: original.rank,
                newRank: newRank,
                originalPoints: original.points,
                newPoints: newPoints,
                rankChange: newRank - original.rank,
                pointsChange: pointsDifference
            )
            
            results.append(result)
        }
        
        let impact = calculateScenarioImpact(results: results)
        
        return WhatIfScenario(
            title: "Optimal Captain GW\(gameweek)",
            description: "What if everyone had captained the highest-scoring player in GW\(gameweek)?",
            type: .captainChange,
            gameweek: gameweek,
            results: results,
            impact: impact
        )
    }
    
    private func generateChipTimingScenarios(members: [LeagueMember]) async -> [WhatIfScenario] {
        var scenarios: [WhatIfScenario] = []
        
        // Analyze Triple Captain timing
        let tcScenario = generateTripleCaptainTimingScenario(members: members)
        scenarios.append(tcScenario)
        
        // Analyze Bench Boost timing
        let bbScenario = generateBenchBoostTimingScenario(members: members)
        scenarios.append(bbScenario)
        
        return scenarios
    }
    
    private func generateTripleCaptainTimingScenario(members: [LeagueMember]) -> WhatIfScenario {
        var results: [WhatIfResult] = []
        
        // Find the gameweek with the highest-scoring captain overall
        let optimalGameweek = findOptimalTripleCaptainGameweek()
        let optimalCaptainPoints = 18 // Simulated best captain score
        
        for member in members {
            let tcChip = member.chips.first { $0.name == "3xc" }
            
            if let chip = tcChip {
                // Calculate current vs optimal timing
                let currentPoints = chip.captainPoints ?? 8
                let currentEffective = currentPoints * 3
                let optimalEffective = optimalCaptainPoints * 3
                
                let pointsChange = optimalEffective - currentEffective
                
                let result = WhatIfResult(
                    managerId: member.entry,
                    managerName: member.playerName,
                    originalRank: member.rank,
                    newRank: member.rank - (pointsChange / 10), // Rough rank change
                    originalPoints: currentEffective,
                    newPoints: optimalEffective,
                    rankChange: -(pointsChange / 10),
                    pointsChange: pointsChange
                )
                
                results.append(result)
            }
        }
        
        let impact = calculateScenarioImpact(results: results)
        
        return WhatIfScenario(
            title: "Optimal Triple Captain Timing",
            description: "What if everyone used Triple Captain in the optimal gameweek?",
            type: .chipTiming,
            gameweek: optimalGameweek,
            results: results,
            impact: impact
        )
    }
    
    private func generateBenchBoostTimingScenario(members: [LeagueMember]) -> WhatIfScenario {
        var results: [WhatIfResult] = []
        
        let optimalGameweek = findOptimalBenchBoostGameweek()
        let optimalBenchPoints = 25 // Simulated best bench score
        
        for member in members {
            let bbChip = member.chips.first { $0.name == "bboost" }
            
            if let chip = bbChip {
                let currentBenchPoints = chip.benchBoost ?? 12
                let pointsChange = optimalBenchPoints - currentBenchPoints
                
                let result = WhatIfResult(
                    managerId: member.entry,
                    managerName: member.playerName,
                    originalRank: member.rank,
                    newRank: member.rank - (pointsChange / 8),
                    originalPoints: currentBenchPoints,
                    newPoints: optimalBenchPoints,
                    rankChange: -(pointsChange / 8),
                    pointsChange: pointsChange
                )
                
                results.append(result)
            }
        }
        
        let impact = calculateScenarioImpact(results: results)
        
        return WhatIfScenario(
            title: "Optimal Bench Boost Timing",
            description: "What if everyone used Bench Boost in the optimal gameweek?",
            type: .chipTiming,
            gameweek: optimalGameweek,
            results: results,
            impact: impact
        )
    }
    
    // MARK: - Helper Functions (mostly unchanged)
    
    private func calculateRiskLevel(
        differentialCount: Int,
        leagueSize: Int,
        successRate: Double
    ) -> RiskLevel {
        let riskScore = Double(differentialCount) / Double(leagueSize) * 100
        
        if riskScore > 80 && successRate < 40 {
            return .reckless
        } else if riskScore > 60 {
            return .aggressive
        } else if riskScore > 30 {
            return .balanced
        } else {
            return .conservative
        }
    }
    
    private func getDifferentialImpact(points: Int, ownership: Double) -> DifferentialImpact {
        let impactScore = Double(points) * (100 - ownership) / 100
        
        if impactScore > 60 {
            return .gameChanging
        } else if impactScore > 30 {
            return .significant
        } else if impactScore > 15 {
            return .moderate
        } else {
            return .minimal
        }
    }
    
    private func findHighVariationGameweeks(members: [LeagueMember]) -> [Int] {
        // Find gameweeks with highest point variations
        var gameweekVariations: [Int: Double] = [:]
        
        for gw in 1...38 {
            let points = members.compactMap { member in
                member.gameweekHistory.first { $0.event == gw }?.points
            }
            
            if !points.isEmpty {
                let avg = Double(points.reduce(0, +)) / Double(points.count)
                let variance = points.map { pow(Double($0) - avg, 2) }.reduce(0, +) / Double(points.count)
                gameweekVariations[gw] = variance
            }
        }
        
        return gameweekVariations
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
    }
    
    private func simulateBestCaptainChoice(gameweek: Int) -> Int {
        // Simulate the best possible captain for this gameweek
        let baseScore = 8 + (gameweek % 10)
        return baseScore + (gameweek % 3 == 0 ? 5 : 0) // Some gameweeks are better
    }
    
    private func simulateNewRanking(member: LeagueMember, originalRank: Int, pointsChange: Int, gameweek: Int) -> Int {
        let rankChange = pointsChange / 5 // Rough approximation
        return max(1, originalRank - rankChange)
    }
    
    private func calculateScenarioImpact(results: [WhatIfResult]) -> ScenarioImpact {
        let rankChanges = results.map { Double($0.rankChange) }
        let pointsChanges = results.map { Double($0.pointsChange) }
        
        let avgRankChange = rankChanges.isEmpty ? 0 : rankChanges.reduce(0, +) / Double(rankChanges.count)
        let avgPointsChange = pointsChanges.isEmpty ? 0 : pointsChanges.reduce(0, +) / Double(pointsChanges.count)
        
        let biggestWinner = results.max { $0.rankChange > $1.rankChange }?.managerName
        let biggestLoser = results.max { $0.rankChange < $1.rankChange }?.managerName
        
        let significantChanges = results.filter { $0.significantChange }.count
        let leagueShakeUp = significantChanges > results.count / 3
        
        return ScenarioImpact(
            managersAffected: results.count,
            averageRankChange: avgRankChange,
            averagePointsChange: avgPointsChange,
            biggestWinner: biggestWinner,
            biggestLoser: biggestLoser,
            leagueShakeUp: leagueShakeUp
        )
    }
    
    private func findOptimalTripleCaptainGameweek() -> Int {
        // Simulate finding the best gameweek for triple captain
        return 15 // Double gameweek example
    }
    
    private func findOptimalBenchBoostGameweek() -> Int {
        // Simulate finding the best gameweek for bench boost
        return 19 // Another double gameweek example
    }
}
