//
//  DifferentialAnalysis.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 03.07.2025..
//

import Foundation
import SwiftUI

// MARK: - Differential Analysis Models

struct DifferentialAnalysis: Identifiable {
    let id = UUID()
    let managerId: Int
    let managerName: String
    let entryName: String
    let differentialPicks: [DifferentialPick]
    let missedOpportunities: [MissedDifferential]
    let totalDifferentialPoints: Int
    let differentialSuccessRate: Double
    let riskRating: RiskLevel
}

struct DifferentialPick: Identifiable {
    let id = UUID()
    let player: PlayerData
    let gameweeksPicked: [Int]
    let pointsScored: Int
    let leagueOwnership: Double // % of league that owned this player
    let globalOwnership: Double // % of all FPL that owned this player
    let impact: DifferentialImpact
    let outcome: DifferentialOutcome
    
    var differentialScore: Double {
        // Higher score = better differential
        let ownershipFactor = max(0.1, (100 - leagueOwnership) / 100)
        let pointsFactor = Double(pointsScored) / Double(gameweeksPicked.count)
        return pointsFactor * ownershipFactor
    }
}

struct MissedDifferential: Identifiable {
    let id = UUID()
    let player: PlayerData
    let ownedByManagers: [String] // Names of managers who had this differential
    let pointsMissed: Int
    let gameweeksMissed: [Int]
    let impact: DifferentialImpact
}

enum DifferentialImpact {
    case gameChanging, significant, moderate, minimal
    
    var label: String {
        switch self {
        case .gameChanging: return "Game Changing"
        case .significant: return "Significant"
        case .moderate: return "Moderate"
        case .minimal: return "Minimal"
        }
    }
    
    var color: Color {
        switch self {
        case .gameChanging: return .purple
        case .significant: return .blue
        case .moderate: return .orange
        case .minimal: return .gray
        }
    }
}

enum DifferentialOutcome {
    case masterStroke, goodPick, neutral, poorChoice, disaster
    
    var label: String {
        switch self {
        case .masterStroke: return "Master Stroke"
        case .goodPick: return "Good Pick"
        case .neutral: return "Neutral"
        case .poorChoice: return "Poor Choice"
        case .disaster: return "Disaster"
        }
    }
    
    var emoji: String {
        switch self {
        case .masterStroke: return "🧠"
        case .goodPick: return "✅"
        case .neutral: return "📊"
        case .poorChoice: return "😬"
        case .disaster: return "💥"
        }
    }
    
    var color: Color {
        switch self {
        case .masterStroke: return .purple
        case .goodPick: return .green
        case .neutral: return .blue
        case .poorChoice: return .orange
        case .disaster: return .red
        }
    }
}

enum RiskLevel {
    case conservative, balanced, aggressive, reckless
    
    var label: String {
        switch self {
        case .conservative: return "Conservative"
        case .balanced: return "Balanced"
        case .aggressive: return "Aggressive"
        case .reckless: return "Reckless"
        }
    }
    
    var description: String {
        switch self {
        case .conservative: return "Plays it safe with popular picks"
        case .balanced: return "Good mix of template and differentials"
        case .aggressive: return "Bold differential choices"
        case .reckless: return "High-risk, high-reward strategy"
        }
    }
    
    var color: Color {
        switch self {
        case .conservative: return .green
        case .balanced: return .blue
        case .aggressive: return .orange
        case .reckless: return .red
        }
    }
}

// MARK: - What If Scenario Models

struct WhatIfScenario: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let type: ScenarioType
    let gameweek: Int?
    let results: [WhatIfResult]
    let impact: ScenarioImpact
}

enum ScenarioType {
    case captainChange, transferChange, chipTiming, teamSelection
    
    var icon: String {
        switch self {
        case .captainChange: return "star.circle"
        case .transferChange: return "arrow.left.arrow.right"
        case .chipTiming: return "wand.and.stars"
        case .teamSelection: return "person.3"
        }
    }
}

struct WhatIfResult: Identifiable {
    let id = UUID()
    let managerId: Int
    let managerName: String
    let originalRank: Int
    let newRank: Int
    let originalPoints: Int
    let newPoints: Int
    let rankChange: Int
    let pointsChange: Int
    
    var improvement: Bool {
        rankChange < 0 // Lower rank number is better
    }
    
    var significantChange: Bool {
        abs(rankChange) >= 3 || abs(pointsChange) >= 20
    }
}

struct ScenarioImpact {
    let managersAffected: Int
    let averageRankChange: Double
    let averagePointsChange: Double
    let biggestWinner: String?
    let biggestLoser: String?
    let leagueShakeUp: Bool
    
    var impactLevel: String {
        if leagueShakeUp {
            return "🌪️ Major Shake-up"
        } else if abs(averageRankChange) > 2 {
            return "📈 Significant Impact"
        } else if abs(averageRankChange) > 1 {
            return "📊 Moderate Impact"
        } else {
            return "🤷 Minor Impact"
        }
    }
}

// MARK: - Analysis Summaries

struct LeagueDifferentialSummary {
    let totalDifferentials: Int
    let successfulDifferentials: Int
    let failedDifferentials: Int
    let successRate: Double
    let topDifferential: DifferentialPick?
    let worstDifferential: DifferentialPick?
    let mostConservativeManager: String?
    let mostAggressiveManager: String?
    let averageRiskLevel: RiskLevel
}

struct WhatIfSummary {
    let totalScenariosAnalyzed: Int
    let biggestPotentialGain: Int
    let biggestMissedOpportunity: Int
    let mostVolatileGameweek: Int?
    let stabilityRating: Double // How much league standings would change
}
