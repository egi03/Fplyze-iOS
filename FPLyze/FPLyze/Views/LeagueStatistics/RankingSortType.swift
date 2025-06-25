//
//  RankingSortType.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 21.06.2025..
//


enum RankingSortType: String, CaseIterable {
    case averagePoints = "Average"
    case consistency = "Consistency"
    case bestWeek = "Best Week"
    case captainSuccess = "Captain"
    case benchWaste = "Bench Waste"
    case transfers = "Transfers"
    
    var unit: String {
        switch self {
        case .averagePoints: return "pts/gw"
        case .consistency: return "std dev"
        case .bestWeek: return "points"
        case .captainSuccess: return "pts/cap"
        case .benchWaste: return "pts/gw"
        case .transfers: return "total"
        }
    }
}
