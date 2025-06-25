//
//  RankingCard.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 21.06.2025..
//

import SwiftUI

struct RankingCard: View {
let rank: Int
let statistics: ManagerStatistics
let sortType: RankingSortType
let isSelected: Bool
let onTap: () -> Void

var rankColor: Color {
    switch rank {
    case 1: return .yellow
    case 2: return Color(white: 0.75)
    case 3: return .orange
    default: return .clear
    }
}

var statValue: String {
    switch sortType {
    case .averagePoints:
        return String(format: "%.1f", statistics.averagePoints)
    case .consistency:
        return String(format: "%.1f", statistics.standardDeviation)
    case .bestWeek:
        return "\(statistics.bestWeek)"
    case .captainSuccess:
        return String(format: "%.1f", statistics.captainSuccess)
    case .benchWaste:
        return String(format: "%.1f", statistics.benchWaste)
    case .transfers:
        return "\(statistics.totalTransfers)"
    }
}

var body: some View {
    HStack {
        // Rank Badge
        ZStack {
            Circle()
                .fill(rankColor)
                .frame(width: 40, height: 40)
            
            Text("\(rank)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(rank <= 3 ? .white : .primary)
        }
        
        // Manager Info
        VStack(alignment: .leading, spacing: 4) {
            Text(statistics.entryName)
                .font(.headline)
            Text(statistics.managerName)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        
        Spacer()
        
        // Stat Value
        VStack(alignment: .trailing) {
            Text(statValue)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color("FplPrimary"))
            Text(sortType.unit)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    .padding()
    .background(
        RoundedRectangle(cornerRadius: 15)
            .fill(Color.white)
            .shadow(color: isSelected ? Color("FplAccent") : .clear, radius: 5)
    )
    .overlay(
        RoundedRectangle(cornerRadius: 15)
            .stroke(isSelected ? Color("FplAccent") : .clear, lineWidth: 2)
    )
    .onTapGesture(perform: onTap)
}
}
