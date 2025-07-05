//
//  DifferentialAnalysisService.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 03.07.2025..
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
        
        // For demo purposes, we'll simulate differential analysis
        // In a real implementation, you'd need to fetch actual team ownership data
        
        var differentialPicks: [DifferentialPick] = []
        var missedOpportunities: [MissedDifferential] = []
        
        // Simulate finding differential picks
        let topPlayers = allPlayers.prefix(50)
        let simulatedDifferentials = generateSimulatedDifferentials(
            member: member,
            topPlayers: Array(topPlayers),
            leagueSize: leagueMembers.count
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
    
    private func generateSimulatedDifferentials(
        member: LeagueMember,
        topPlayers: [PlayerData],
        leagueSize: Int
    ) -> (picks: [DifferentialPick], missed: [MissedDifferential]) {
        
        var picks: [DifferentialPick] = []
        var missed: [MissedDifferential] = []
        
        // Simulate 3-7 differential picks per member
        let numDifferentials = 3 + (member.entry % 5)
        
        for i in 0..<numDifferentials {
            let playerIndex = (member.entry * 3 + i) % topPlayers.count
            let player = topPlayers[playerIndex]
            
            // Simulate ownership percentages
            let globalOwnership = player.ownership
            let leagueOwnership = max(5.0, globalOwnership - Double(10 + (member.entry % 20)))
            
            // Only consider as differential if league ownership < 30%
            if leagueOwnership < 30 {
                let gameweeks = simulateGameweeksOwned(member: member, playerIndex: i)
                let points = simulatePlayerPoints(player: player, gameweeks: gameweeks)
                
                let impact = getDifferentialImpact(points: points, ownership: leagueOwnership)
                let outcome = getDifferentialOutcome(points: points, gameweeks: gameweeks.count, ownership: leagueOwnership)
                
                let differential = DifferentialPick(
                    player: player,
                    gameweeksPicked: gameweeks,
                    pointsScored: points,
                    leagueOwnership: leagueOwnership,
                    globalOwnership: globalOwnership,
                    impact: impact,
                    outcome: outcome
                )
                
                picks.append(differential)
            }
        }
        
        // Simulate missed opportunities
        for i in 0..<3 {
            let playerIndex = (member.entry * 7 + i + 100) % topPlayers.count
            let player = topPlayers[playerIndex]
            
            if player.ownership < 25 { // Low ownership differential
                let gameweeks = [1, 2, 3, 4] // Simulate missed gameweeks
                let points = simulatePlayerPoints(player: player, gameweeks: gameweeks)
                
                if points > 30 { // Only show significant missed opportunities
                    let ownedBy = simulateOtherOwners(leagueSize: leagueSize)
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
    
    // MARK: - What-If Scenarios Implementation
    
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
    
    // MARK: - Helper Functions
    
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
    
    private func getDifferentialOutcome(points: Int, gameweeks: Int, ownership: Double) -> DifferentialOutcome {
        let pointsPerGameweek = Double(points) / Double(gameweeks)
        let ownershipFactor = (100 - ownership) / 100
        let score = pointsPerGameweek * ownershipFactor
        
        if score > 15 {
            return .masterStroke
        } else if score > 8 {
            return .goodPick
        } else if score > 4 {
            return .neutral
        } else if score > 2 {
            return .poorChoice
        } else {
            return .disaster
        }
    }
    
    private func simulateGameweeksOwned(member: LeagueMember, playerIndex: Int) -> [Int] {
        let startGW = 1 + (playerIndex * 3) % 20
        let duration = 3 + (member.entry % 4)
        return Array(startGW..<min(startGW + duration, 39))
    }
    
    private func simulatePlayerPoints(player: PlayerData, gameweeks: [Int]) -> Int {
        let avgPointsPerGame = Double(player.totalPoints) / 38.0
        let variationFactor = 0.8 + Double(gameweeks.count % 5) * 0.1
        return Int(avgPointsPerGame * Double(gameweeks.count) * variationFactor)
    }
    
    private func simulateOtherOwners(leagueSize: Int) -> [String] {
        let names = ["Alex", "Jordan", "Sam", "Riley", "Casey"]
        let count = min(2 + (leagueSize % 3), names.count)
        return Array(names.prefix(count))
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
