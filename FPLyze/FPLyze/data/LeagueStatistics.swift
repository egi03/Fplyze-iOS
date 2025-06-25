//
//  LeagueStatistics.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 15.06.2025..
//

import Foundation
import SwiftUI

struct LeagueMember: Identifiable, Codable {
    let id: Int
    let entry: Int
    let entryName: String
    let playerName: String
    let eventTotal: Int
    let rank: Int
    let lastRank: Int
    let total: Int
    var gameweekHistory: [GameweekPerformance] = []
    var chips: [ChipUsage] = []
    var captainHistory: [CaptainPick] = []
    
    var rankChange: Int {
        lastRank - rank
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case entry
        case entryName = "entry_name"
        case playerName = "player_name"
        case eventTotal = "event_total"
        case rank
        case lastRank = "last_rank"
        case total
    }
}

struct GameweekPerformance: Identifiable, Codable {
    let id = UUID()
    let event: Int
    let points: Int
    let totalPoints: Int
    let rank: Int
    let overallRank: Int
    let benchPoints: Int
    let transfers: Int
    let transfersCost: Int
    let value: Int
    let activeChip: String?
    
    enum CodingKeys: String, CodingKey {
        case event, points, rank, value, transfers
        case totalPoints = "total_points"
        case overallRank = "overall_rank"
        case benchPoints = "points_on_bench"
        case transfersCost = "event_transfers_cost"
        case activeChip = "active_chip"
    }
}

struct CaptainPick: Identifiable {
    let id = UUID()
    let event: Int
    let captainId: Int
    let captainName: String
    let captainPoints: Int
    let effectivePoints: Int
    let multiplier: Int
    let viceCaptainId: Int
    let viceCaptainName: String
}

struct ChipUsage: Identifiable, Codable {
    var id = UUID()
    let name: String
    let event: Int
    let points: Int
    let benchBoost: Int?
    let fieldPoints: Int?
    
    var chipType: ChipType? {
        ChipType(rawValue: name)
    }
}

enum ChipType: String, CaseIterable {
    case benchBoost = "bboost"
    case tripleCaptain = "3xc"
    case freeHit = "freehit"
    case wildcard = "wildcard"
    
    var displayName: String {
        switch self {
        case .benchBoost: return "Bench Boost"
        case .tripleCaptain: return "Triple Captain"
        case .freeHit: return "Free Hit"
        case .wildcard: return "Wildcard"
        }
    }
    
    var icon: String {
        switch self {
        case .benchBoost: return "person.3.fill"
        case .tripleCaptain: return "star.circle.fill"
        case .freeHit: return "arrow.clockwise.circle.fill"
        case .wildcard: return "wand.and.stars"
        }
    }
    
    var color: Color {
        switch self {
        case .benchBoost: return .blue
        case .tripleCaptain: return .orange
        case .freeHit: return .green
        case .wildcard: return .purple
        }
    }
}

struct LeagueRecord: Identifiable {
    let id = UUID()
    let type: RecordType
    let value: Int
    let managerId: Int
    let managerName: String
    let entryName: String
    let gameweek: Int?
    let additionalInfo: String?
}

enum RecordType: String, CaseIterable {
    case bestGameweek = "Best Gameweek"
    case worstGameweek = "Worst Gameweek"
    case bestCaptain = "Best Captain"
    case worstCaptain = "Worst Captain"
    case bestBenchBoost = "Best Bench Boost"
    case bestTripleCaptain = "Best Triple Captain"
    case bestFreeHit = "Best Free Hit"
    case bestWildcard = "Best Wildcard"
    case biggestRise = "Biggest Rise"
    case biggestFall = "Biggest Fall"
    case mostPointsOnBench = "Most Points on Bench"
    case mostConsistent = "Most Consistent"
    
    var icon: String {
        switch self {
        case .bestGameweek: return "trophy.fill"
        case .worstGameweek: return "hand.thumbsdown.fill"
        case .bestCaptain: return "star.fill"
        case .worstCaptain: return "star"
        case .bestBenchBoost: return "person.3.fill"
        case .bestTripleCaptain: return "star.circle.fill"
        case .bestFreeHit: return "arrow.clockwise"
        case .bestWildcard: return "wand.and.stars"
        case .biggestRise: return "arrow.up.circle.fill"
        case .biggestFall: return "arrow.down.circle.fill"
        case .mostPointsOnBench: return "chair.fill"
        case .mostConsistent: return "chart.line.uptrend.xyaxis"
        }
    }
    
    var color: Color {
        switch self {
        case .bestGameweek, .bestCaptain, .bestBenchBoost,
             .bestTripleCaptain, .bestFreeHit, .bestWildcard:
            return .green
        case .worstGameweek, .worstCaptain, .biggestFall:
            return .red
        case .biggestRise:
            return .blue
        case .mostPointsOnBench:
            return .orange
        case .mostConsistent:
            return .purple
        }
    }
}


struct ManagerStatistics: Identifiable {
    let id: Int
    let managerId: Int
    let managerName: String
    let entryName: String
    let averagePoints: Double
    let standardDeviation: Double
    let bestWeek: Int
    let worstWeek: Int
    let currentStreak: StreakInfo
    let captainSuccess: Double
    let benchWaste: Double
    let chipsUsed: Int
    let totalTransfers: Int
}

struct StreakInfo {
    let type: StreakType
    let count: Int
    let startWeek: Int
}

enum StreakType: String {
    case greenArrows = "Green Arrows"
    case redArrows = "Red Arrows"
    case top10k = "Top 10K"
    case aboveAverage = "Above Average"
}

struct HeadToHeadRecord: Identifiable {
    let id = UUID()
    let manager1Id: Int
    let manager1Name: String
    let manager2Id: Int
    let manager2Name: String
    let wins: Int
    let draws: Int
    let losses: Int
    let totalPointsFor: Int
    let totalPointsAgainst: Int
    let biggestWin: GameweekComparison?
    let biggestLoss: GameweekComparison?
}

struct GameweekComparison {
    let gameweek: Int
    let manager1Points: Int
    let manager2Points: Int
    let difference: Int
}
