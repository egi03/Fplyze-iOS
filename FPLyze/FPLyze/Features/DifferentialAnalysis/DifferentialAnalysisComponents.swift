//
//  DifferentialAnalysisComponents.swift
//  FPL.stats
//
//  Created by Eugen Sedlar on 08.07.2025..
//

import SwiftUI

// MARK: - Demo Banner

struct DemoBanner: View {
    var body: some View {
        HStack {
            Image(systemName: "hammer.fill")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("DEMO")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                
                Text("This feature is work in progress")
                    .font(.caption2)
                    .foregroundColor(Color("FplTextSecondary"))
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.orange.opacity(0.3)),
            alignment: .bottom
        )
    }
}

// MARK: - Header Card

struct DifferentialHeaderCard: View {
    let summary: LeagueDifferentialSummary
    let onInfoClick: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DIFFERENTIAL ANALYSIS")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("FplAccentLight"))
                        .tracking(1.5)
                    
                    Text("Unique picks that made the difference")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color("FplTextPrimary"))
                }
                
                Spacer()
                
                Button(action: onInfoClick) {
                    Image(systemName: "info.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 40, height: 40)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            // Summary Stats
            HStack(spacing: 16) {
                SummaryStatBox(
                    title: "Total",
                    value: "\(summary.totalDifferentials)",
                    subtitle: "differentials",
                    color: .blue
                )
                
                SummaryStatBox(
                    title: "Success Rate",
                    value: "\(Int(summary.successRate))%",
                    subtitle: "paid off",
                    color: summary.successRate > 50 ? .green : .orange
                )
                
                if let topDiff = summary.topDifferential {
                    SummaryStatBox(
                        title: "Best Pick",
                        value: topDiff.player.webName,
                        subtitle: "\(topDiff.pointsScored) pts",
                        color: Color("FplPurple")
                    )
                } else {
                    SummaryStatBox(
                        title: "Best Pick",
                        value: "-",
                        subtitle: "No data",
                        color: Color("FplPurple")
                    )
                }
            }
        }
        .padding()
        .background(Color("FplSurface"))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 5)
    }
}


// MARK: - Sort Chip

struct DifferentialSortChip: View {
    let type: DifferentialAnalysisTab.DifferentialSortType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.caption)
                
                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ? Color("FplPrimary") : Color("FplSurface")
            )
            .foregroundColor(isSelected ? .white : Color("FplTextPrimary"))
            .cornerRadius(20)
        }
    }
}

// MARK: - Analysis Card

struct DifferentialAnalysisCard: View {
    let analysis: DifferentialAnalysis
    let rank: Int
    let isExpanded: Bool
    let onTap: () -> Void
    
    var topDifferential: DifferentialPick? {
        analysis.differentialPicks.max { first, second in
            first.differentialScore < second.differentialScore
        }
    }
    
    var rankColor: Color {
        switch rank {
        case 1: return Color("FplPurple")
        case 2: return .blue
        case 3: return .green
        default: return .gray
        }
    }
    
    var successRateColor: Color {
        switch analysis.differentialSuccessRate {
        case 70...: return .green
        case 50..<70: return .blue
        case 30..<50: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                // Rank Badge
                ZStack {
                    Circle()
                        .fill(rankColor)
                        .frame(width: 35, height: 35)
                    
                    Text("#\(rank)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(analysis.managerName)
                        .font(.headline)
                        .foregroundColor(Color("FplTextPrimary"))
                    
                    HStack(spacing: 8) {
                        RiskLevelBadge(level: analysis.riskRating)
                        
                        Text("\(analysis.differentialPicks.count) differentials")
                            .font(.caption)
                            .foregroundColor(Color("FplTextSecondary"))
                    }
                    
                    if let top = topDifferential {
                        Text("Best: \(top.player.displayName) (\(top.pointsScored) pts)")
                            .font(.caption2)
                            .foregroundColor(Color("FplPurple"))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(alignment: .bottom, spacing: 2) {
                        Text(String(format: "%.0f", analysis.differentialSuccessRate))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(successRateColor)
                        
                        Text("%")
                            .font(.caption)
                            .foregroundColor(Color("FplTextSecondary"))
                            .padding(.bottom, 2)
                    }
                    
                    Text("success rate")
                        .font(.caption2)
                        .foregroundColor(Color("FplTextSecondary"))
                    
                    Text("\(analysis.totalDifferentialPoints) pts")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(Color("FplTextSecondary"))
                    .font(.caption)
            }
            .padding()
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
            
            // Expanded Content
            if isExpanded {
                VStack(spacing: 0) {
                    Divider()
                    
                    VStack(spacing: 16) {
                        // Differential Picks Section Only
                        if !analysis.differentialPicks.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Differential Picks")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Text("Best \(min(10, analysis.differentialPicks.count)) picks")
                                        .font(.caption)
                                        .foregroundColor(Color("FplTextSecondary"))
                                }
                                
                                VStack(spacing: 8) {
                                    let sortedPicks = analysis.differentialPicks
                                        .sorted { $0.differentialScore > $1.differentialScore }
                                        .prefix(10)
                                    
                                    ForEach(Array(sortedPicks.enumerated()), id: \.element.id) { index, pick in
                                        DifferentialPickRow(pick: pick, rank: index + 1)
                                    }
                                }
                                
                                if analysis.differentialPicks.count > 10 {
                                    Text("+ \(analysis.differentialPicks.count - 10) more differentials")
                                        .font(.caption)
                                        .foregroundColor(Color("FplTextSecondary"))
                                        .padding(.top, 4)
                                }
                            }
                        }
                        
                        // REMOVED: Missed Opportunities Section
                    }
                    .padding()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color("FplSurface"))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
}

// MARK: - Risk Level Badge

struct RiskLevelBadge: View {
    let level: RiskLevel
    
    var body: some View {
        Text(level.label)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(level.color).opacity(0.2))
            .foregroundColor(Color(level.color))
            .cornerRadius(4)
    }
}

// MARK: - Differential Pick Row

struct DifferentialPickRow: View {
    let pick: DifferentialPick
    let rank: Int?
    
    var body: some View {
        HStack {
            // Rank badge if provided
            if let rank = rank {
                ZStack {
                    Circle()
                        .fill(rankColor(for: rank))
                        .frame(width: 24, height: 24)
                    
                    Text("#\(rank)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            // Position Badge
            PositionBadge(position: pick.player.elementType)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(pick.player.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    Text("\(pick.gameweeksPicked.count) GWs")
                        .font(.caption2)
                    
                    Text("\(String(format: "%.1f", pick.leagueOwnership))% owned")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    
                    Text("Score: \(String(format: "%.1f", pick.differentialScore))")
                        .font(.caption2)
                        .foregroundColor(Color("FplPurple"))
                }
                .foregroundColor(Color("FplTextSecondary"))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text(pick.outcome.emoji)
                        .font(.caption)
                    
                    Text("\(pick.pointsScored)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(pick.outcome.color))
                }
                
                Text(pick.outcome.label)
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color(pick.outcome.color).opacity(0.2))
                    .foregroundColor(Color(pick.outcome.color))
                    .cornerRadius(3)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color("FplBackground"))
        .cornerRadius(8)
    }
    
    private func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1: return .green
        case 2: return .blue
        case 3: return .orange
        default: return .gray
        }
    }
}

// MARK: - Missed Opportunity Row

struct MissedOpportunityRow: View {
    let missed: MissedDifferential
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(missed.player.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Owned by: \(missed.ownedByManagers.prefix(3).joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundColor(Color("FplTextSecondary"))
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(missed.pointsMissed)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
                Text("pts missed")
                    .font(.caption2)
                    .foregroundColor(Color("FplTextSecondary"))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(8)
    }
}


// MARK: - Empty State

struct EmptyDifferentialView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No Differential Data")
                .font(.headline)
                .foregroundColor(Color("FplTextSecondary"))
            
            Text("Differential analysis will appear here once ownership data is available")
                .font(.subheadline)
                .foregroundColor(Color("FplTextSecondary"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(60)
    }
}

// MARK: - Info Sheet

struct DifferentialAnalysisInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Understanding Differentials")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom)
                    
                    InfoSection(
                        title: "What are Differentials?",
                        icon: "star",
                        description: """
                        Differential picks are players owned by few managers in your league compared to the general FPL population. They're risky but can provide huge advantages when they pay off.
                        
                        • Low ownership = higher differential potential
                        • Success depends on timing and player selection
                        • Can dramatically change league standings
                        """
                    )
                    
                    InfoSection(
                        title: "Risk Levels",
                        icon: "exclamationmark.triangle",
                        description: """
                        • Conservative: Sticks to popular template players
                        • Balanced: Good mix of template and differentials  
                        • Aggressive: Bold differential choices
                        • Reckless: High-risk, high-reward strategy
                        """
                    )
                    
                    InfoSection(
                        title: "Outcomes",
                        icon: "chart.bar",
                        description: """
                        • Master Stroke 🧠: Exceptional differential that paid off big
                        • Good Pick ✅: Solid differential choice
                        • Neutral 📊: Average performance
                        • Poor Choice 😬: Differential that didn't work out
                        • Disaster 💥: Major differential failure
                        """
                    )
                    
                    InfoSection(
                        title: "Strategy Tips",
                        icon: "lightbulb",
                        description: """
                        • Time differentials around good fixtures
                        • Consider form and team news
                        • Don't go too differential in defense
                        • Balance risk across your team
                        • Sometimes template is template for a reason!
                        """
                    )
                }
                .padding()
            }
            .navigationBarTitle("Differential Guide", displayMode: .inline)
            .navigationBarItems(
                trailing: Button("Done") { dismiss() }
            )
        }
    }
}
