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
    
    var icon: String {
        switch self {
        case .records: return "trophy.fill"
        case .rankings: return "list.number"
        case .headToHead: return "person.2.fill"
        case .chips: return "star.circle.fill"
        case .trends: return "chart.line.uptrend.xyaxis"
        }
    }
}