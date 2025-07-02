//
//  ChipOverviewCard.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 21.06.2025..
//

import SwiftUI


struct ChipOverviewCard: View {
    let chipType: ChipType
    let stats: ChipStatistics
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: chipType.icon)
                    .font(.largeTitle)
                    .foregroundColor(chipType.color)
                
                VStack(alignment: .leading) {
                    Text(chipType.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(chipDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Stats Grid
            HStack(spacing: 20) {
                StatBox(
                    title: "Total Uses",
                    value: "\(stats.totalUses)",
                    color: chipType.color
                )
                
                StatBox(
                    title: "Average",
                    value: String(format: "%.1f pts", stats.averagePoints),
                    color: chipType.color
                )
                
                StatBox(
                    title: "Best",
                    value: "\(stats.bestScore) pts",
                    color: chipType.color
                )
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [chipType.color.opacity(0.1), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
    }
    
    private var chipDescription: String {
        switch chipType {
        case .benchBoost:
            return "Points from bench players count"
        case .tripleCaptain:
            return "Captain points are tripled"
        case .freeHit:
            return "Unlimited transfers for one week"
        case .wildcard:
            return "Unlimited transfers without hits"
        }
    }
}
