//
//  LeagueStatisticsRepository.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 20.06.2025..
//

import Foundation

@MainActor
class LeagueStatisticsRepository: ObservableObject {
    private let apiService = FPLAPIService.shared
    
    
    
    func fetchLeagueStatistics(leagueId: Int) async throws -> LeagueStatisticsData {
        let members = try await fetchAllMembers(leagueId: leagueId)
        
        
        let detailedMembers = try await withThrowingTaskGroup(of: LeagueMember?.self)
        { group in
            for member in members.prefix(50) {
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
        
        
        let records = calculateRecords(from: detailedMembers)
        let managerStats = calculateManagerStatistics(from: detailedMembers)
        let h2hRecords = calculateHeadToHeadRecords(from: detailedMembers)
        
        return LeagueStatisticsData(
            leagueId: leagueId,
            records: records,
            managerStatistics: managerStats,
            headToHeadStatistics: h2hRecords,
            members: detailedMembers
        )
    }
    
    private func fetchAllMembers(leagueId: Int) async throws -> [LeagueMember] {
        var allMembers: [LeagueMember] = []
        var page = 1
        var hasMore = true
        
        while hasMore {
            let response = try await apiService.getLeagueStandings(
                leagueId: leagueId,
                page: page
            )
            
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
        }
        
        return allMembers
    }
    
    private func fetchMemberDetails(_ member: LeagueMember) async throws -> LeagueMember {
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
            let points = updatedMember.gameweekHistory
                .first { $0.event == chip.event }?.points ?? 0
            
            return ChipUsage(
                name: chip.name,
                event: chip.event,
                points: points,
                benchBoost: nil,
                fieldPoints: nil
            )
        }
        
        return updatedMember
    }
    
    private func calculateRecords(from members: [LeagueMember]) -> [LeagueRecord] {
        var records: [LeagueRecord] = []
        
        // Best GW
        if let best = members.flatMap({ member in
            member.gameweekHistory.map { gw in
                (member, gw.event, gw.points)
            }
        }).max(by: { $0.2 < $1.2}) {
            records.append(LeagueRecord(
                type: .bestGameweek,
                value: best.2,
                managerId: best.0.entry,
                managerName: best.0.playerName,
                entryName: best.0.entryName,
                gameweek: best.1,
                additionalInfo: nil
            ))
        }
        
        // Worst GW
        if let worst = members.flatMap({ member in
            member.gameweekHistory
                .filter { $0.points > 0 }
                .map { gw in (member, gw.event, gw.points)}
        }).min(by: { $0.2 < $1.2}) {
            records.append(LeagueRecord(
                type: .worstGameweek,
                value: worst.2,
                managerId: worst.0.entry,
                managerName: worst.0.playerName,
                entryName: worst.0.entryName,
                gameweek: worst.1,
                additionalInfo: nil
            ))
        }
        
        // Best chips
        let chipTypes: [(ChipType, RecordType)] = [
            (.benchBoost, .bestBenchBoost),
            (.tripleCaptain, .bestTripleCaptain),
            (.freeHit, .bestFreeHit),
            (.wildcard, .bestWildcard)
        ]
        
        for (chipType, recordTyoe) in chipTypes {
            if let bestChip = members.flatMap({ member in
                member.chips
                    .filter { $0.name == chipType.rawValue }
                    .map { chip in (member, chip) }
            }).max(by: { $0.1.points < $1.1.points }) {
                records.append(LeagueRecord(
                    type: recordTyoe,
                    value: bestChip.1.points,
                    managerId: bestChip.0.entry,
                    managerName: bestChip.0.playerName,
                    entryName: bestChip.0.entryName,
                    gameweek: bestChip.1.event,
                    additionalInfo: chipType.displayName
                ))
            }
        }
        return records
    }
    
    private func calculateManagerStatistics(from members: [LeagueMember]) -> [ManagerStatistics] {
        members.map { member in
            let points = member.gameweekHistory.map { Double($0.points) }
            let average = points.isEmpty ? 0 : points.reduce(0, +) / Double(points.count)
            
            let variance = points.isEmpty ? 0 : points
                .map { pow($0 - average, 2)}.reduce(0,+) / Double(points.count)
            let stdDev = sqrt(variance)
            
            let streak = calculateStreak(for: member.gameweekHistory)
            
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
                captainSuccess: 0,
                benchWaste: Double(member.gameweekHistory.map { $0.benchPoints }.reduce(0, +)) / Double(max(member.gameweekHistory.count, 1)),
                chipsUsed: member.chips.count,
                totalTransfers: member.gameweekHistory.map { $0.transfers }.reduce(0, +)
            )
        }
    }
    
    private func calculateStreak(for history: [GameweekPerformance]) -> StreakInfo {
        guard history.count > 1 else {
            return StreakInfo(type: .greenArrows, count: 0, startWeek: 0)
        }
        
        var greenArrows = 0
        let recentGames = Array(history.suffix(5))
        
        for i in 1..<recentGames.count {
            if recentGames[i].rank < recentGames[i-1].rank {
                greenArrows += 1
            }
        }
        return StreakInfo(
            type: greenArrows > 2 ? .greenArrows : .redArrows,
            count: greenArrows,
            startWeek: recentGames.last?.event ?? 0
        )
    }
    
    private func calculateHeadToHeadRecords(from members: [LeagueMember]) -> [HeadToHeadRecord] {
        var records: [HeadToHeadRecord] = []
            
        for i in 0..<members.count {
            for j in (i+1)..<members.count {
                let member1 = members[i]
                let member2 = members[j]
                
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
