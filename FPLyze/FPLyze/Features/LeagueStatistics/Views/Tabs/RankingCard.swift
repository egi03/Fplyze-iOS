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
    
    var enhancedDescription: String? {
        switch sortType {
        case .consistency:
            return statistics.consistencyDescription
        case .averagePoints:
            if statistics.averagePoints > 60 {
                return "🔥 Elite performance"
            } else if statistics.averagePoints > 50 {
                return "✅ Strong manager"
            } else if statistics.averagePoints > 40 {
                return "📊 Average performance"
            } else {
                return "📉 Needs improvement"
            }
        case .captainSuccess:
            if statistics.captainSuccess > 70 {
                return "🎯 Excellent captaincy"
            } else if statistics.captainSuccess > 50 {
                return "👍 Good captain picks"
            } else {
                return "🤔 Room for improvement"
            }
        case .benchWaste:
            if statistics.benchWaste < 2 {
                return "💪 Minimal waste"
            } else if statistics.benchWaste < 4 {
                return "👌 Good team selection"
            } else {
                return "😰 Too many bench points"
            }
        default:
            return nil
        }
    }

    var body: some View {
        VStack(spacing: 12) {
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
                        .foregroundColor(Color("FplTextSecondary"))
                    
                    if let description = enhancedDescription {
                        Text(description)
                            .font(.caption2)
                            .foregroundColor(getSortTypeColor())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(getSortTypeColor().opacity(0.15))
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                // Stat Value with enhanced info
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(alignment: .bottom, spacing: 4) {
                        Text(statValue)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color("FplPrimary"))
                        
                        Text(sortType.unit)
                            .font(.caption)
                            .foregroundColor(Color("FplTextSecondary"))
                            .padding(.bottom, 2)
                    }
                    
                    if sortType == .consistency {
                        Text(statistics.consistencyRating)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(getConsistencyColor(statistics.standardDeviation))
                    }
                }
            }
            
            // Expanded details when selected
            if isSelected {
                Divider()
                
                VStack(spacing: 8) {
                    if sortType == .consistency {
                        ConsistencyDetails(statistics: statistics)
                    } else {
                        StatisticsBreakdown(statistics: statistics)
                    }
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding()
        .background(Color("FplSurface"))
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(isSelected ? Color("FplAccent") : .clear, lineWidth: 2)
        )
        .cornerRadius(15)
        .shadow(color: .black.opacity(isSelected ? 0.15 : 0.08), radius: isSelected ? 8 : 5)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
        .onTapGesture(perform: onTap)
    }
    
    private func getSortTypeColor() -> Color {
        switch sortType {
        case .consistency: return .purple
        case .averagePoints: return .green
        case .captainSuccess: return .orange
        case .benchWaste: return .red
        case .bestWeek: return .blue
        case .transfers: return .gray
        }
    }
    
    private func getConsistencyColor(_ stdDev: Double) -> Color {
        switch stdDev {
        case 0..<8: return .green
        case 8..<12: return .blue
        case 12..<18: return .orange
        default: return .red
        }
    }
}

struct ConsistencyDetails: View {
    let statistics: ManagerStatistics
    
    var consistencyRanking: String {
        switch statistics.standardDeviation {
        case 0..<5: return "Top tier consistency"
        case 5..<8: return "Very reliable"
        case 8..<12: return "Moderately consistent"
        case 12..<18: return "Inconsistent"
        default: return "Highly unpredictable"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Consistency Analysis")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(consistencyRanking)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.2))
                    .cornerRadius(6)
            }
            
            Text("Standard deviation measures how much your scores vary from your \(String(format: "%.1f", statistics.averagePoints)) average.")
                .font(.caption)
                .foregroundColor(Color("FplTextSecondary"))
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Best Week")
                        .font(.caption2)
                        .foregroundColor(Color("FplTextSecondary"))
                    Text("\(statistics.bestWeek) pts")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 2) {
                    Text("Range")
                        .font(.caption2)
                        .foregroundColor(Color("FplTextSecondary"))
                    Text("\(statistics.worstWeek)-\(statistics.bestWeek)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Worst Week")
                        .font(.caption2)
                        .foregroundColor(Color("FplTextSecondary"))
                    Text("\(statistics.worstWeek) pts")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .padding(.vertical, 4)
        }
        .padding()
        .background(Color.purple.opacity(0.05))
        .cornerRadius(8)
    }
}

struct StatisticsBreakdown: View {
    let statistics: ManagerStatistics
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                StatQuickView(
                    title: "Average",
                    value: String(format: "%.1f", statistics.averagePoints),
                    color: .green
                )
                
                StatQuickView(
                    title: "Consistency",
                    value: String(format: "%.1f", statistics.standardDeviation),
                    color: .purple
                )
                
                StatQuickView(
                    title: "Best",
                    value: "\(statistics.bestWeek)",
                    color: .blue
                )
            }
            
            HStack {
                StatQuickView(
                    title: "Transfers",
                    value: "\(statistics.totalTransfers)",
                    color: .gray
                )
                
                StatQuickView(
                    title: "Chips Used",
                    value: "\(statistics.chipsUsed)/4",
                    color: .orange
                )
                
                StatQuickView(
                    title: "Bench Waste",
                    value: String(format: "%.1f", statistics.benchWaste),
                    color: .red
                )
            }
        }
    }
}

struct StatQuickView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(Color("FplTextSecondary"))
        }
        .frame(maxWidth: .infinity)
    }
}
