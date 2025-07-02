//
//  LeagueStatisticsRepository.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 20.06.2025..

import Foundation
import Combine

@MainActor
class LeagueStatisticsRepository: ObservableObject {
    private let apiService = FPLAPIService.shared
    private let cache = CacheManager.shared
    private let playerAnalysisService = PlayerAnalysisService()
    
    @Published var loadingProgress: Double = 0.0
    @Published var loadingMessage: String = ""
    
    private var currentLeagueInfo: League?
    
    // Settings for performance
    private let batchSize = 10 // Process members in batches
    private let maxConcurrentRequests = 5 // Limit concurrent API calls
    
    func fetchLeagueStatistics(leagueId: Int, forceRefresh: Bool = false) async throws -> LeagueStatisticsData {
        // Check cache first
        if !forceRefresh, let cached = await cache.getCachedLeague(leagueId) {
            return cached
        }
        
        loadingProgress = 0.0
        loadingMessage = "Fetching league members..."
        
        let (members, leagueName) = try await fetchAllMembers(leagueId: leagueId)
        
        loadingMessage = "Loading detailed statistics..."
        let detailedMembers = try await fetchMembersInBatches(members)
        
        loadingMessage = "Calculating statistics..."
        loadingProgress = 0.9
        
        // Perform player analysis
        loadingMessage = "Analyzing player performance..."
        let missedAnalyses: [MissedPlayerAnalysis]
        let underperformerAnalyses: [UnderperformerAnalysis]

        do {
            (missedAnalyses, underperformerAnalyses) = try await playerAnalysisService.analyzeLeague(detailedMembers)
        } catch {
            print("Player analysis failed: \(error)")
            // Continue without player analysis data
            missedAnalyses = []
            underperformerAnalyses = []
        }
        
        let statistics = LeagueStatisticsData(
            leagueId: leagueId,
            leagueName: leagueName,
            records: calculateRecords(from: detailedMembers),
            managerStatistics: calculateManagerStatistics(from: detailedMembers),
            headToHeadStatistics: calculateHeadToHeadRecords(from: detailedMembers),
            members: detailedMembers,
            missedPlayerAnalyses: missedAnalyses,
            underperformerAnalyses: underperformerAnalyses
        )
        
        // Cache the results
        await cache.cacheLeague(leagueId, data: statistics)
        
        loadingProgress = 1.0
        return statistics
    }
    
    private func fetchAllMembers(leagueId: Int) async throws ->  ([LeagueMember], String) {
        var allMembers: [LeagueMember] = []
        var page = 1
        var hasMore = true
        var leagueName = "Unknown"
        
        
        while hasMore {
            let response = try await apiService.getLeagueStandings(
                leagueId: leagueId,
                page: page
            )
            
            if page == 1 {
                leagueName = response.league.name
                currentLeagueInfo = response.league
            }
            
            let members = response.standings.results.map { result in
                LeagueMember(
                    id: result.entry,
                    entry: result.entry,
                    entryName: result.entryName,
                    playerName: result.playerName,
                    eventTotal: result.eventTotal,
                    rank: result.rank,
                    lastRank: result.lastRank,
                    total: result.total
                )
            }
            
            allMembers.append(contentsOf: members)
            hasMore = response.standings.hasNext
            page += 1
            
            // Update progress
            loadingProgress = min(0.3, Double(allMembers.count) / 100.0 * 0.3)
        }
        
        return (allMembers, leagueName)
    }
    
    private func fetchMembersInBatches(_ members: [LeagueMember]) async throws -> [LeagueMember] {
        var detailedMembers: [LeagueMember] = []
        let totalMembers = min(members.count, 50) // Limit to top 50 for performance
        
        for batchStart in stride(from: 0, to: totalMembers, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, totalMembers)
            let batch = Array(members[batchStart..<batchEnd])
            
            let batchResults = try await withThrowingTaskGroup(of: LeagueMember?.self) { group in
                for member in batch {
                    group.addTask {
                        try? await self.fetchMemberDetails(member)
                    }
                }
                
                var results: [LeagueMember] = []
                for try await member in group {
                    if let member = member {
                        results.append(member)
                    }
                }
                return results
            }
            
            detailedMembers.append(contentsOf: batchResults)
            
            // Update progress
            let baseProgress = 0.3
            let detailProgress = 0.6 * (Double(detailedMembers.count) / Double(totalMembers))
            loadingProgress = baseProgress + detailProgress
        }
        
        return detailedMembers
    }
    
    private func fetchMemberDetails(_ member: LeagueMember) async throws -> LeagueMember {
        do {
            let history = try await apiService.getManagerHistory(entryId: member.entry)
            
            var updatedMember = member
            
            updatedMember.gameweekHistory = history.current.map { gw in
                GameweekPerformance(
                    event: gw.event,
                    points: gw.points,
                    totalPoints: gw.totalPoints,
                    rank: gw.rank,
                    overallRank: gw.overallRank,
                    benchPoints: gw.pointsOnBench,
                    transfers: gw.eventTransfers,
                    transfersCost: gw.eventTransfersCost,
                    value: gw.value,
                    activeChip: nil
                )
            }
            
            updatedMember.chips = history.chips.map { chip in
                let chipGameweek = updatedMember.gameweekHistory
                    .first { $0.event == chip.event }
                
                let points = chipGameweek?.points ?? 0
                let benchBoost = chip.name == "bboost" ? chipGameweek?.benchPoints : nil
                
                return ChipUsage(
                    name: chip.name,
                    event: chip.event,
                    points: points,
                    benchBoost: benchBoost,
                    fieldPoints: nil
                )
            }
            
            return updatedMember
        } catch {
            print("Failed to fetch details for member \(member.playerName): \(error)")
            return member
        }
    }
    
    private func calculateRecords(from members: [LeagueMember]) -> [LeagueRecord] {
        var records: [LeagueRecord] = []
        
        // Best GW - with improved algorithm
        let allGameweeks = members.flatMap { member in
            member.gameweekHistory.map { gw in
                (member: member, gameweek: gw.event, points: gw.points)
            }
        }
        
        if let best = allGameweeks.max(by: { $0.points < $1.points }) {
            records.append(LeagueRecord(
                type: .bestGameweek,
                value: best.points,
                managerId: best.member.entry,
                managerName: best.member.playerName,
                entryName: best.member.entryName,
                gameweek: best.gameweek,
                additionalInfo: nil
            ))
        }
        
        // Worst GW (excluding zeros)
        if let worst = allGameweeks
            .filter({ $0.points > 0 })
            .min(by: { $0.points < $1.points }) {
            records.append(LeagueRecord(
                type: .worstGameweek,
                value: worst.points,
                managerId: worst.member.entry,
                managerName: worst.member.playerName,
                entryName: worst.member.entryName,
                gameweek: worst.gameweek,
                additionalInfo: nil
            ))
        }
        
        // Most consistent manager
        let consistencyScores = members.map { member in
            let points = member.gameweekHistory.map { Double($0.points) }
            let average = points.isEmpty ? 0 : points.reduce(0, +) / Double(points.count)
            let variance = points.isEmpty ? 0 : points
                .map { pow($0 - average, 2) }
                .reduce(0, +) / Double(points.count)
            let stdDev = sqrt(variance)
            return (member: member, consistency: stdDev, average: average)
        }
        
        if let mostConsistent = consistencyScores
            .filter({ $0.average > 0 })
            .min(by: { $0.consistency < $1.consistency }) {
            records.append(LeagueRecord(
                type: .mostConsistent,
                value: Int(mostConsistent.average),
                managerId: mostConsistent.member.entry,
                managerName: mostConsistent.member.playerName,
                entryName: mostConsistent.member.entryName,
                gameweek: nil,
                additionalInfo: "σ = \(String(format: "%.1f", mostConsistent.consistency))"
            ))
        }
        
        // Best chips with improved logic
        processChipRecords(&records, from: members)
        
        // Biggest rise/fall
        processMomentumRecords(&records, from: members)
        
        return records
    }
    
    private func processChipRecords(_ records: inout [LeagueRecord], from members: [LeagueMember]) {
        let chipTypes: [(ChipType, RecordType)] = [
            (.benchBoost, .bestBenchBoost),
            (.tripleCaptain, .bestTripleCaptain),
            (.freeHit, .bestFreeHit),
            (.wildcard, .bestWildcard)
        ]
        
        for (chipType, recordType) in chipTypes {
            let chipUsages = members.flatMap { member in
                member.chips
                    .filter { $0.name == chipType.rawValue }
                    .map { (member: member, chip: $0) }
            }
            
            if let bestChip = chipUsages.max(by: { $0.chip.points < $1.chip.points }) {
                records.append(LeagueRecord(
                    type: recordType,
                    value: bestChip.chip.points,
                    managerId: bestChip.member.entry,
                    managerName: bestChip.member.playerName,
                    entryName: bestChip.member.entryName,
                    gameweek: bestChip.chip.event,
                    additionalInfo: chipType.displayName
                ))
            }
        }
    }
    
    private func processMomentumRecords(_ records: inout [LeagueRecord], from members: [LeagueMember]) {
        // Calculate biggest weekly rank improvements
        for member in members {
            let history = member.gameweekHistory
            guard history.count > 1 else { continue }
            
            for i in 1..<history.count {
                let rankChange = history[i-1].rank - history[i].rank
                
                // Check for biggest rise
                if let currentBiggestRise = records.first(where: { $0.type == .biggestRise }) {
                    if rankChange > currentBiggestRise.value {
                        records.removeAll { $0.type == .biggestRise }
                        records.append(LeagueRecord(
                            type: .biggestRise,
                            value: rankChange,
                            managerId: member.entry,
                            managerName: member.playerName,
                            entryName: member.entryName,
                            gameweek: history[i].event,
                            additionalInfo: "+\(rankChange) places"
                        ))
                    }
                } else if rankChange > 0 {
                    records.append(LeagueRecord(
                        type: .biggestRise,
                        value: rankChange,
                        managerId: member.entry,
                        managerName: member.playerName,
                        entryName: member.entryName,
                        gameweek: history[i].event,
                        additionalInfo: "+\(rankChange) places"
                    ))
                }
            }
        }
    }
    
    private func calculateManagerStatistics(from members: [LeagueMember]) -> [ManagerStatistics] {
        members.map { member in
            let points = member.gameweekHistory.map { Double($0.points) }
            let average = points.isEmpty ? 0 : points.reduce(0, +) / Double(points.count)
            
            let variance = points.isEmpty ? 0 : points
                .map { pow($0 - average, 2) }
                .reduce(0, +) / Double(points.count)
            let stdDev = sqrt(variance)
            
            let streak = calculateStreak(for: member.gameweekHistory)
            let captainSuccess = calculateCaptainSuccess(for: member)
            
            return ManagerStatistics(
                id: member.id,
                managerId: member.entry,
                managerName: member.playerName,
                entryName: member.entryName,
                averagePoints: average,
                standardDeviation: stdDev,
                bestWeek: member.gameweekHistory.map { $0.points }.max() ?? 0,
                worstWeek: member.gameweekHistory.filter { $0.points > 0 }.map { $0.points }.min() ?? 0,
                currentStreak: streak,
                captainSuccess: captainSuccess,
                benchWaste: Double(member.gameweekHistory.map { $0.benchPoints }.reduce(0, +)) / Double(max(member.gameweekHistory.count, 1)),
                chipsUsed: member.chips.count,
                totalTransfers: member.gameweekHistory.map { $0.transfers }.reduce(0, +)
            )
        }
    }
    
    private func calculateCaptainSuccess(for member: LeagueMember) -> Double {
        // Estimate captain success based on points distribution
        let gameweeks = member.gameweekHistory
        guard !gameweeks.isEmpty else { return 0 }
        
        let averagePoints = Double(gameweeks.map { $0.points }.reduce(0, +)) / Double(gameweeks.count)
        let highScoringWeeks = gameweeks.filter { Double($0.points) > averagePoints * 1.2 }.count
        
        return Double(highScoringWeeks) / Double(gameweeks.count) * 100
    }
    
    private func calculateStreak(for history: [GameweekPerformance]) -> StreakInfo {
        guard history.count > 1 else {
            return StreakInfo(type: .greenArrows, count: 0, startWeek: 0)
        }
        
        var greenArrows = 0
        var redArrows = 0
        let recentGames = Array(history.suffix(5))
        
        for i in 1..<recentGames.count {
            if recentGames[i].rank < recentGames[i-1].rank {
                greenArrows += 1
                redArrows = 0
            } else if recentGames[i].rank > recentGames[i-1].rank {
                redArrows += 1
                greenArrows = 0
            }
        }
        
        if greenArrows > redArrows {
            return StreakInfo(
                type: .greenArrows,
                count: greenArrows,
                startWeek: recentGames.last?.event ?? 0
            )
        } else {
            return StreakInfo(
                type: .redArrows,
                count: redArrows,
                startWeek: recentGames.last?.event ?? 0
            )
        }
    }
    
    private func calculateHeadToHeadRecords(from members: [LeagueMember]) -> [HeadToHeadRecord] {
        var records: [HeadToHeadRecord] = []
        
        // Only calculate for a reasonable number of comparisons
        let membersToCompare = Array(members.prefix(20))
        
        for i in 0..<membersToCompare.count {
            for j in (i+1)..<membersToCompare.count {
                let member1 = membersToCompare[i]
                let member2 = membersToCompare[j]
                
                var wins = 0, draws = 0, losses = 0
                var totalFor = 0, totalAgainst = 0
                var biggestWin: GameweekComparison?
                var biggestLoss: GameweekComparison?
                
                let minGameweeks = min(
                    member1.gameweekHistory.count,
                    member2.gameweekHistory.count
                )
                
                for gw in 0..<minGameweeks {
                    let m1Points = member1.gameweekHistory[gw].points
                    let m2Points = member2.gameweekHistory[gw].points
                    
                    totalFor += m1Points
                    totalAgainst += m2Points
                    
                    if m1Points > m2Points {
                        wins += 1
                        let diff = m1Points - m2Points
                        if biggestWin == nil || diff > biggestWin!.difference {
                            biggestWin = GameweekComparison(
                                gameweek: gw + 1,
                                manager1Points: m1Points,
                                manager2Points: m2Points,
                                difference: diff
                            )
                        }
                    } else if m1Points < m2Points {
                        losses += 1
                        let diff = m2Points - m1Points
                        if biggestLoss == nil || diff > biggestLoss!.difference {
                            biggestLoss = GameweekComparison(
                                gameweek: gw + 1,
                                manager1Points: m1Points,
                                manager2Points: m2Points,
                                difference: diff
                            )
                        }
                    } else {
                        draws += 1
                    }
                }
                
                records.append(HeadToHeadRecord(
                    manager1Id: member1.entry,
                    manager1Name: member1.playerName,
                    manager2Id: member2.entry,
                    manager2Name: member2.playerName,
                    wins: wins,
                    draws: draws,
                    losses: losses,
                    totalPointsFor: totalFor,
                    totalPointsAgainst: totalAgainst,
                    biggestWin: biggestWin,
                    biggestLoss: biggestLoss
                ))
            }
        }
        
        return records
    }
}
