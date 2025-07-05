//
//  StatisticsTab.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 21.06.2025..
//

enum StatisticsTab: String, CaseIterable {
    case records = "Records"
    case rankings = "Rankings"
    case headToHead = "Head-to-Head"
    case chips = "Chips"
    case trends = "Trends"
    case playerAnalysis = "Analysis"
    case differentials = "Differentials"
    case whatIf = "What-If"
    
    var icon: String {
        switch self {
        case .records: return "trophy.fill"
        case .rankings: return "list.number"
        case .headToHead: return "person.2.fill"
        case .chips: return "star.circle.fill"
        case .trends: return "chart.line.uptrend.xyaxis"
        case .playerAnalysis: return "magnifyingglass.circle.fill"
        case .differentials: return "star.slash.fill"
        case .whatIf: return "questionmark.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .records: return "League records and achievements"
        case .rankings: return "Manager performance rankings"
        case .headToHead: return "Manager vs manager comparisons"
        case .chips: return "Chip usage and effectiveness"
        case .trends: return "Performance trends over time"
        case .playerAnalysis: return "Player performance analysis"
        case .differentials: return "Unique picks analysis"
        case .whatIf: return "Alternative scenario analysis"
        }
    }
}
