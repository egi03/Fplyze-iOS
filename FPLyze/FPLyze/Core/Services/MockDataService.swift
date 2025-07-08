//
//  MockDataService.swift
//  FPLyze
//
//  Demo data service for showcasing app features
//

import Foundation

class MockDataService {
    static let shared = MockDataService()
    
    private init() {}
    
    func generateDemoLeagueData() -> LeagueStatisticsData {
        let members = generateDemoMembers()
        let records = generateDemoRecords(from: members)
        let managerStats = generateDemoManagerStatistics(from: members)
        let headToHeadStats = generateDemoHeadToHeadStatistics(from: members)
        let missedAnalyses = generateDemoMissedAnalyses(from: members)
        let underperformerAnalyses = generateDemoUnderperformerAnalyses(from: members)
        let differentialAnalyses = generateDemoDifferentialAnalyses(from: members)
        let whatIfScenarios = generateDemoWhatIfScenarios(from: members)
        
        return LeagueStatisticsData(
            leagueId: 999999,
            leagueName: "FPL Demo League",
            records: records,
            managerStatistics: managerStats,
            headToHeadStatistics: headToHeadStats,
            members: members,
            missedPlayerAnalyses: missedAnalyses,
            underperformerAnalyses: underperformerAnalyses,
            differentialAnalyses: differentialAnalyses,
            whatIfScenarios: whatIfScenarios
        )
    }
    
    // MARK: - Demo Members Generation
    
    private func generateDemoMembers() -> [LeagueMember] {
        let demoNames = [
            ("Alex Thompson", "The Gunners"),
            ("Sarah Williams", "City Slickers"),
            ("Mike Johnson", "Red Devils United"),
            ("Emma Davis", "Liverpool Legends"),
            ("Chris Brown", "Spurs Forever"),
            ("Lisa Wilson", "Chelsea FC"),
            ("Tom Anderson", "Hammers United"),
            ("Kate Miller", "Arsenal Army"),
            ("James Taylor", "Blue Moon"),
            ("Amy Clarke", "Villa Park"),
            ("Ryan Moore", "Crystal Eagles"),
            ("Sophie Lee", "Wolves Pack"),
            ("Daniel White", "Saints Marching"),
            ("Olivia Green", "Bees United"),
            ("Jack Harris", "Foxes Den")
        ]
        
        return demoNames.enumerated().map { index, nameData in
            let entryId = 1000000 + index
            let member = LeagueMember(
                id: entryId,
                entry: entryId,
                entryName: nameData.1,
                playerName: nameData.0,
                eventTotal: generateRandomEventTotal(),
                rank: index + 1,
                lastRank: generateLastRank(currentRank: index + 1),
                total: generateTotalPoints(rank: index + 1),
                gameweekHistory: generateDemoGameweekHistory(),
                chips: generateDemoChips(),
                captainHistory: []
            )
            return member
        }
    }
    
    private func generateRandomEventTotal() -> Int {
        return Int.random(in: 35...95)
    }
    
    private func generateLastRank(currentRank: Int) -> Int {
        let change = Int.random(in: -3...3)
        return max(1, min(15, currentRank + change))
    }
    
    private func generateTotalPoints(rank: Int) -> Int {
        // Better ranks have higher points
        let basePoints = 2400 - (rank * 50)
        return basePoints + Int.random(in: -100...100)
    }
    
    private func generateDemoGameweekHistory() -> [GameweekPerformance] {
        return (1...20).map { gameweek in
            let points = Int.random(in: 25...95)
            return GameweekPerformance(
                event: gameweek,
                points: points,
                totalPoints: gameweek * 65 + Int.random(in: -50...50),
                rank: Int.random(in: 1...15),
                overallRank: Int.random(in: 500000...3000000),
                benchPoints: Int.random(in: 0...25),
                transfers: Int.random(in: 0...2),
                transfersCost: Int.random(in: 0...8),
                value: Int.random(in: 980...1030),
                activeChip: gameweek % 8 == 0 ? ["bboost", "3xc", "freehit"].randomElement() : nil
            )
        }
    }
    
    private func generateDemoChips() -> [ChipUsage] {
        var chips: [ChipUsage] = []
        let chipTypes = ["bboost", "3xc", "freehit", "wildcard"]
        
        // Randomly assign 2-4 chips per manager
        let numChips = Int.random(in: 2...4)
        let selectedChips = Array(chipTypes.shuffled().prefix(numChips))
        
        for (index, chipType) in selectedChips.enumerated() {
            let gameweek = (index + 1) * 4 + Int.random(in: 0...3)
            let points = Int.random(in: 45...120)
            
            var chip = ChipUsage(
                name: chipType,
                event: gameweek,
                points: points
            )
            
            if chipType == "bboost" {
                chip = ChipUsage(
                    name: chipType,
                    event: gameweek,
                    points: points,
                    benchBoost: Int.random(in: 8...35)
                )
            } else if chipType == "3xc" {
                let captainPoints = Int.random(in: 4...20)
                chip = ChipUsage(
                    name: chipType,
                    event: gameweek,
                    points: points,
                    captainName: ["Salah", "Haaland", "Kane", "Son", "De Bruyne"].randomElement(),
                    captainPoints: captainPoints,
                    captainEffectivePoints: captainPoints * 3
                )
            }
            
            chips.append(chip)
        }
        
        return chips
    }
    
    // MARK: - Demo Records Generation
    
    private func generateDemoRecords(from members: [LeagueMember]) -> [LeagueRecord] {
        var records: [LeagueRecord] = []
        
        // Best Gameweek
        let bestMember = members.randomElement()!
        records.append(LeagueRecord(
            type: .bestGameweek,
            value: 127,
            managerId: bestMember.entry,
            managerName: bestMember.playerName,
            entryName: bestMember.entryName,
            gameweek: 15,
            additionalInfo: nil,
            captainName: nil,
            captainActualPoints: nil
        ))
        
        // Best Triple Captain
        let tcMember = members.randomElement()!
        records.append(LeagueRecord(
            type: .bestTripleCaptain,
            value: 102,
            managerId: tcMember.entry,
            managerName: tcMember.playerName,
            entryName: tcMember.entryName,
            gameweek: 8,
            additionalInfo: "Captain: Haaland (17 pts × 3 = 51 pts)",
            captainName: "Haaland",
            captainActualPoints: 17
        ))
        
        // Best Bench Boost
        let bbMember = members.randomElement()!
        records.append(LeagueRecord(
            type: .bestBenchBoost,
            value: 89,
            managerId: bbMember.entry,
            managerName: bbMember.playerName,
            entryName: bbMember.entryName,
            gameweek: 12,
            additionalInfo: "Bench contributed 28 pts",
            captainName: nil,
            captainActualPoints: nil
        ))
        
        // Most Consistent
        let consistentMember = members.randomElement()!
        records.append(LeagueRecord(
            type: .mostConsistent,
            value: 64,
            managerId: consistentMember.entry,
            managerName: consistentMember.playerName,
            entryName: consistentMember.entryName,
            gameweek: nil,
            additionalInfo: "Std Dev: 8.2 - Very consistent scores",
            captainName: nil,
            captainActualPoints: nil
        ))
        
        // Worst Gameweek
        let worstMember = members.randomElement()!
        records.append(LeagueRecord(
            type: .worstGameweek,
            value: 18,
            managerId: worstMember.entry,
            managerName: worstMember.playerName,
            entryName: worstMember.entryName,
            gameweek: 7,
            additionalInfo: nil,
            captainName: nil,
            captainActualPoints: nil
        ))
        
        return records
    }
    
    // MARK: - Demo Manager Statistics
    
    private func generateDemoManagerStatistics(from members: [LeagueMember]) -> [ManagerStatistics] {
        return members.map { member in
            let avgPoints = Double.random(in: 45...75)
            let stdDev = Double.random(in: 6...18)
            
            return ManagerStatistics(
                id: member.id,
                managerId: member.entry,
                managerName: member.playerName,
                entryName: member.entryName,
                averagePoints: avgPoints,
                standardDeviation: stdDev,
                bestWeek: Int.random(in: 80...127),
                worstWeek: Int.random(in: 18...35),
                currentStreak: StreakInfo(
                    type: [.greenArrows, .redArrows].randomElement()!,
                    count: Int.random(in: 1...4),
                    startWeek: Int.random(in: 15...20)
                ),
                captainSuccess: Double.random(in: 40...80),
                benchWaste: Double.random(in: 1...8),
                chipsUsed: Int.random(in: 2...4),
                totalTransfers: Int.random(in: 15...45)
            )
        }
    }
    
    // MARK: - Demo Head-to-Head Statistics
    
    private func generateDemoHeadToHeadStatistics(from members: [LeagueMember]) -> [HeadToHeadRecord] {
        var records: [HeadToHeadRecord] = []
        
        // Generate H2H for first 10 members to keep it manageable
        let topMembers = Array(members.prefix(10))
        
        for i in 0..<topMembers.count {
            for j in (i+1)..<topMembers.count {
                let member1 = topMembers[i]
                let member2 = topMembers[j]
                
                let gameweeks = 20
                let wins = Int.random(in: 4...12)
                let losses = Int.random(in: 4...12)
                let draws = gameweeks - wins - losses
                
                let record = HeadToHeadRecord(
                    manager1Id: member1.entry,
                    manager1Name: member1.playerName,
                    manager2Id: member2.entry,
                    manager2Name: member2.playerName,
                    wins: wins,
                    draws: draws,
                    losses: losses,
                    totalPointsFor: Int.random(in: 1200...1500),
                    totalPointsAgainst: Int.random(in: 1200...1500),
                    biggestWin: GameweekComparison(
                        gameweek: Int.random(in: 1...20),
                        manager1Points: Int.random(in: 70...95),
                        manager2Points: Int.random(in: 25...45),
                        difference: Int.random(in: 20...45)
                    ),
                    biggestLoss: GameweekComparison(
                        gameweek: Int.random(in: 1...20),
                        manager1Points: Int.random(in: 25...45),
                        manager2Points: Int.random(in: 70...95),
                        difference: Int.random(in: 20...45)
                    )
                )
                
                records.append(record)
            }
        }
        
        return records
    }
    
    // MARK: - Demo Player Analyses
    
    private func generateDemoMissedAnalyses(from members: [LeagueMember]) -> [MissedPlayerAnalysis] {
        return members.map { member in
            let missedPlayers = generateDemoMissedPlayers()
            return MissedPlayerAnalysis(
                managerId: member.entry,
                managerName: member.playerName,
                missedPlayers: missedPlayers,
                totalMissedPoints: missedPlayers.map { $0.missedPoints }.reduce(0, +),
                biggestMiss: missedPlayers.max { $0.missedPoints < $1.missedPoints }
            )
        }
    }
    
    private func generateDemoMissedPlayers() -> [MissedPlayer] {
        let playerNames = ["Haaland", "Salah", "De Bruyne", "Kane", "Son", "Rashford", "Martinelli", "Saka"]
        let count = Int.random(in: 3...8)
        
        return (0..<count).map { index in
            let playerName = playerNames.randomElement()!
            let missedPoints = Int.random(in: 15...85)
            let gameweeks = (1...Int.random(in: 3...8)).map { _ in Int.random(in: 1...20) }
            
            return MissedPlayer(
                player: generateDemoPlayer(name: playerName),
                missedPoints: missedPoints,
                missedGameweeks: gameweeks,
                avgPointsPerMiss: Double(missedPoints) / Double(gameweeks.count)
            )
        }
    }
    
    private func generateDemoUnderperformerAnalyses(from members: [LeagueMember]) -> [UnderperformerAnalysis] {
        return members.map { member in
            let underperformers = generateDemoUnderperformers()
            return UnderperformerAnalysis(
                managerId: member.entry,
                managerName: member.playerName,
                underperformers: underperformers,
                worstPerformer: underperformers.min { $0.avgPointsPerGame < $1.avgPointsPerGame }
            )
        }
    }
    
    private func generateDemoUnderperformers() -> [UnderperformingPlayer] {
        let playerNames = ["Sterling", "Grealish", "Mount", "Havertz", "Nunez", "Antony", "Sancho"]
        let count = Int.random(in: 2...6)
        
        return (0..<count).map { _ in
            let playerName = playerNames.randomElement()!
            let gamesOwned = Int.random(in: 5...15)
            let avgPoints = Double.random(in: 1.5...4.5)
            
            return UnderperformingPlayer(
                player: generateDemoPlayer(name: playerName),
                gamesOwned: gamesOwned,
                pointsWhileOwned: Int(avgPoints * Double(gamesOwned)),
                avgPointsPerGame: avgPoints,
                benchedGames: Int.random(in: 0...3)
            )
        }
    }
    
    private func generateDemoPlayer(name: String) -> PlayerData {
        let positions = [1, 2, 3, 4] // GKP, DEF, MID, FWD
        let position = positions.randomElement()!
        
        return PlayerData(
            id: Int.random(in: 1...600),
            webName: name,
            teamCode: Int.random(in: 1...20),
            elementType: position,
            nowCost: Int.random(in: 45...135),
            totalPoints: Int.random(in: 50...250),
            minutes: Int.random(in: 500...3000),
            goalsScored: Int.random(in: 0...25),
            assists: Int.random(in: 0...15),
            cleanSheets: Int.random(in: 0...18),
            selectedByPercent: "\(Double.random(in: 1...45))",
            form: "\(Double.random(in: 2...8))",
            pointsPerGame: "\(Double.random(in: 2...8))",
            ictIndex: "\(Double.random(in: 50...200))",
            status: "a",
            news: ""
        )
    }
    
    // MARK: - Demo Differential Analyses
    
    private func generateDemoDifferentialAnalyses(from members: [LeagueMember]) -> [DifferentialAnalysis] {
        return members.map { member in
            let differentialPicks = generateDemoDifferentialPicks()
            let missedOpportunities = generateDemoMissedDifferentials()
            
            let successfulPicks = differentialPicks.filter { $0.outcome == .masterStroke || $0.outcome == .goodPick }
            let successRate = differentialPicks.isEmpty ? 0 : Double(successfulPicks.count) / Double(differentialPicks.count) * 100
            
            return DifferentialAnalysis(
                managerId: member.entry,
                managerName: member.playerName,
                entryName: member.entryName,
                differentialPicks: differentialPicks,
                missedOpportunities: missedOpportunities,
                totalDifferentialPoints: differentialPicks.map { $0.pointsScored }.reduce(0, +),
                differentialSuccessRate: successRate,
                riskRating: [.conservative, .balanced, .aggressive, .reckless].randomElement()!
            )
        }
    }
    
    private func generateDemoDifferentialPicks() -> [DifferentialPick] {
        let count = Int.random(in: 2...6)
        let playerNames = ["Isak", "Bowen", "Trossard", "Watkins", "Maddison", "Odegaard", "Foden"]
        
        return (0..<count).map { _ in
            let playerName = playerNames.randomElement()!
            let gameweeks = (1...Int.random(in: 3...8)).map { _ in Int.random(in: 1...20) }
            let points = Int.random(in: 15...75)
            let ownership = Double.random(in: 5...35)
            
            return DifferentialPick(
                player: generateDemoPlayer(name: playerName),
                gameweeksPicked: gameweeks,
                pointsScored: points,
                leagueOwnership: ownership,
                globalOwnership: ownership + Double.random(in: -5...15),
                impact: [.gameChanging, .significant, .moderate, .minimal].randomElement()!,
                outcome: [.masterStroke, .goodPick, .neutral, .poorChoice, .disaster].randomElement()!
            )
        }
    }
    
    private func generateDemoMissedDifferentials() -> [MissedDifferential] {
        let count = Int.random(in: 1...4)
        let playerNames = ["Almiron", "Zaha", "Gross", "Ward-Prowse", "McNeil"]
        let managerNames = ["Alex M.", "Sarah K.", "Mike J."]
        
        return (0..<count).map { _ in
            let playerName = playerNames.randomElement()!
            let gameweeks = (1...Int.random(in: 2...5)).map { _ in Int.random(in: 1...20) }
            let numOwners = Int.random(in: 1...3)
            let shuffledNames = managerNames.shuffled()
            let ownedByManagers = Array(shuffledNames.prefix(numOwners))
            
            return MissedDifferential(
                player: generateDemoPlayer(name: playerName),
                ownedByManagers: ownedByManagers,
                pointsMissed: Int.random(in: 20...60),
                gameweeksMissed: gameweeks,
                impact: [.significant, .moderate, .minimal].randomElement()!
            )
        }
    }
    
    // MARK: - Demo What-If Scenarios
    
    private func generateDemoWhatIfScenarios(from members: [LeagueMember]) -> [WhatIfScenario] {
        var scenarios: [WhatIfScenario] = []
        
        // Captain scenario
        let captainResults = members.map { member in
            WhatIfResult(
                managerId: member.entry,
                managerName: member.playerName,
                originalRank: member.rank,
                newRank: member.rank + Int.random(in: -3...3),
                originalPoints: Int.random(in: 45...85),
                newPoints: Int.random(in: 55...95),
                rankChange: Int.random(in: -3...3),
                pointsChange: Int.random(in: -10...25)
            )
        }
        
        scenarios.append(WhatIfScenario(
            title: "Optimal Captain GW15",
            description: "What if everyone captained Haaland in his hat-trick gameweek?",
            type: .captainChange,
            gameweek: 15,
            results: captainResults,
            impact: ScenarioImpact(
                managersAffected: captainResults.count,
                averageRankChange: -1.2,
                averagePointsChange: 8.5,
                biggestWinner: "Alex Thompson",
                biggestLoser: "Mike Johnson",
                leagueShakeUp: true
            )
        ))
        
        // Triple Captain scenario
        let tcResults = members.filter { $0.chips.contains { $0.name == "3xc" } }.map { member in
            WhatIfResult(
                managerId: member.entry,
                managerName: member.playerName,
                originalRank: member.rank,
                newRank: member.rank + Int.random(in: -2...2),
                originalPoints: Int.random(in: 35...75),
                newPoints: Int.random(in: 45...85),
                rankChange: Int.random(in: -2...2),
                pointsChange: Int.random(in: 5...20)
            )
        }
        
        scenarios.append(WhatIfScenario(
            title: "Optimal Triple Captain Timing",
            description: "What if everyone used Triple Captain in GW12 (double gameweek)?",
            type: .chipTiming,
            gameweek: 12,
            results: tcResults,
            impact: ScenarioImpact(
                managersAffected: tcResults.count,
                averageRankChange: -0.8,
                averagePointsChange: 12.3,
                biggestWinner: "Sarah Williams",
                biggestLoser: nil,
                leagueShakeUp: false
            )
        ))
        
        return scenarios
    }
}
