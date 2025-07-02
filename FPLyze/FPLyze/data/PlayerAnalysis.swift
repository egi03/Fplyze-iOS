//
//  PlayerAnalysis.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 01.07.2025..
//

import Foundation

// MARK: - Player Data Models
struct PlayerData: Codable {
    let id: Int
    let webName: String
    let teamCode: Int?
    let elementType: Int
    let nowCost: Int
    let totalPoints: Int
    let minutes: Int
    let goalsScored: Int
    let assists: Int
    let cleanSheets: Int
    let selectedByPercent: String
    let form: String?
    let pointsPerGame: String
    let ictIndex: String?
    let status: String?
    let news: String?
    
    enum CodingKeys: String, CodingKey {
        case id, minutes, assists, form, status, news
        case webName = "web_name"
        case teamCode = "team_code"
        case elementType = "element_type"
        case nowCost = "now_cost"
        case totalPoints = "total_points"
        case goalsScored = "goals_scored"
        case cleanSheets = "clean_sheets"
        case selectedByPercent = "selected_by_percent"
        case pointsPerGame = "points_per_game"
        case ictIndex = "ict_index"
    }
    
    var displayName: String {
        webName
    }
    
    var position: String {
        switch elementType {
        case 1: return "GKP"
        case 2: return "DEF"
        case 3: return "MID"
        case 4: return "FWD"
        default: return "Unknown"
        }
    }
    
    var ownership: Double {
        Double(selectedByPercent.replacingOccurrences(of: "%", with: "")) ?? 0
    }
    
    var pointsPerMinute: Double {
        guard minutes > 0 else { return 0 }
        return Double(totalPoints) / Double(minutes) * 90
    }
}
// MARK: - Analysis Results
struct MissedPlayerAnalysis: Identifiable {
    let id = UUID()
    let managerId: Int
    let managerName: String
    let missedPlayers: [MissedPlayer]
    let totalMissedPoints: Int
    let biggestMiss: MissedPlayer?
}

struct MissedPlayer: Identifiable {
    let id = UUID()
    let player: PlayerData
    let missedPoints: Int
    let missedGameweeks: [Int]
    let avgPointsPerMiss: Double
    
    var impact: PlayerImpact {
        switch missedPoints {
        case 100...: return .critical
        case 50..<100: return .high
        case 25..<50: return .medium
        default: return .low
        }
    }
}

struct UnderperformerAnalysis: Identifiable {
    let id = UUID()
    let managerId: Int
    let managerName: String
    let underperformers: [UnderperformingPlayer]
    let worstPerformer: UnderperformingPlayer?
}

struct UnderperformingPlayer: Identifiable {
    let id = UUID()
    let player: PlayerData
    let gamesOwned: Int
    let pointsWhileOwned: Int
    let avgPointsPerGame: Double
    let benchedGames: Int
    
    var performanceRating: PerformanceRating {
        switch avgPointsPerGame {
        case ..<2.0: return .terrible
        case 2.0..<3.0: return .poor
        case 3.0..<4.0: return .belowAverage
        default: return .average
        }
    }
}

// MARK: - Enums
enum PlayerImpact {
    case critical, high, medium, low
    
    var color: String {
        switch self {
        case .critical: return "red"
        case .high: return "orange"
        case .medium: return "yellow"
        case .low: return "gray"
        }
    }
    
    var label: String {
        switch self {
        case .critical: return "Critical Miss"
        case .high: return "High Impact"
        case .medium: return "Medium Impact"
        case .low: return "Low Impact"
        }
    }
}

enum PerformanceRating {
    case terrible, poor, belowAverage, average
    
    var color: String {
        switch self {
        case .terrible: return "red"
        case .poor: return "orange"
        case .belowAverage: return "yellow"
        case .average: return "green"
        }
    }
    
    var label: String {
        switch self {
        case .terrible: return "Terrible"
        case .poor: return "Poor"
        case .belowAverage: return "Below Average"
        case .average: return "Average"
        }
    }
}

// MARK: - Transfer History
struct TransferHistory: Codable {
    let element: Int // Player ID
    let elementIn: Int
    let elementOut: Int
    let entryId: Int
    let event: Int // Gameweek
    let time: String
    
    enum CodingKeys: String, CodingKey {
        case element
        case elementIn = "element_in"
        case elementOut = "element_out"
        case entryId = "entry"
        case event
        case time
    }
}
