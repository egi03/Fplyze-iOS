//
//  DifferentialAnalysisTab.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 03.07.2025..
//

import SwiftUI

struct DifferentialAnalysisTab: View {
    let analyses: [DifferentialAnalysis]
    @State private var selectedManager: Int?
    @State private var sortBy: DifferentialSortType = .successRate
    @State private var showingInfoSheet = false
    
    enum DifferentialSortType: String, CaseIterable {
        case successRate = "Success Rate"
        case totalPoints = "Total Points"
        case riskLevel = "Risk Level"
        case differentialCount = "Differential Count"
        
        var icon: String {
            switch self {
            case .successRate: return "percent"
            case .totalPoints: return "sum"
            case .riskLevel: return "exclamationmark.triangle"
            case .differentialCount: return "number"
            }
        }
    }
    
    var sortedAnalyses: [DifferentialAnalysis] {
        switch sortBy {
        case .successRate:
            return analyses.sorted(by: { $0.differentialSuccessRate > $1.differentialSuccessRate })
        case .totalPoints:
            return analyses.sorted(by: { $0.totalDifferentialPoints > $1.totalDifferentialPoints })
        case .riskLevel:
            return analyses.sorted(by: { getRiskValue($0.riskRating) > getRiskValue($1.riskRating) })
        case .differentialCount:
            return analyses.sorted(by: { $0.differentialPicks.count > $1.differentialPicks.count })
        }
    }
    
    var leagueSummary: LeagueDifferentialSummary {
        let allDifferentials = analyses.flatMap { $0.differentialPicks }
        let totalDifferentials = allDifferentials.count
        
        let successfulPicks = allDifferentials.filter { pick in
            pick.outcome == .masterStroke || pick.outcome == .goodPick
        }
        let successfulCount = successfulPicks.count
        
        let topDifferential = allDifferentials.max { first, second in
            first.differentialScore < second.differentialScore
        }
        
        let worstDifferential = allDifferentials.min { first, second in
            first.differentialScore < second.differentialScore
        }
        
        let mostConservative = analyses.min { first, second in
            first.differentialPicks.count < second.differentialPicks.count
        }?.managerName
        
        let mostAggressive = analyses.max { first, second in
            first.differentialPicks.count < second.differentialPicks.count
        }?.managerName
        
        let successRate = totalDifferentials > 0 ? Double(successfulCount) / Double(totalDifferentials) * 100 : 0
        
        return LeagueDifferentialSummary(
            totalDifferentials: totalDifferentials,
            successfulDifferentials: successfulCount,
            failedDifferentials: totalDifferentials - successfulCount,
            successRate: successRate,
            topDifferential: topDifferential,
            worstDifferential: worstDifferential,
            mostConservativeManager: mostConservative,
            mostAggressiveManager: mostAggressive,
            averageRiskLevel: .balanced
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header with league summary
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Differential Analysis")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Unique picks that made the difference")
                                .font(.subheadline)
                                .foregroundColor(Color("FplTextSecondary"))
                        }
                        
                        Spacer()
                        
                        Button(action: { showingInfoSheet = true }) {
                            Image(systemName: "info.circle")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // League Summary Card
                    DifferentialLeagueSummaryCard(summary: leagueSummary)
                        .padding(.horizontal)
                    
                    // Sort Options
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(DifferentialSortType.allCases, id: \.self) { type in
                                DifferentialSortChip(
                                    type: type,
                                    isSelected: sortBy == type,
                                    action: { sortBy = type }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .background(Color("FplSurface"))
                .cornerRadius(15)
                .shadow(color: .black.opacity(0.05), radius: 5, y: 5)
                .padding(.horizontal)
                
                // Manager Analysis Cards
                if analyses.isEmpty {
                    EmptyDifferentialView()
                        .padding(.horizontal)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(sortedAnalyses.enumerated()), id: \.element.id) { index, analysis in
                            DifferentialAnalysisCard(
                                analysis: analysis,
                                rank: index + 1,
                                isExpanded: selectedManager == analysis.managerId,
                                onTap: {
                                    withAnimation(.spring()) {
                                        selectedManager = selectedManager == analysis.managerId ? nil : analysis.managerId
                                    }
                                }
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                
                Spacer(minLength: 20)
            }
        }
        .background(Color("FplBackground"))
        .sheet(isPresented: $showingInfoSheet) {
            DifferentialAnalysisInfoSheet()
        }
    }
    
    private func getRiskValue(_ risk: RiskLevel) -> Int {
        switch risk {
        case .conservative: return 1
        case .balanced: return 2
        case .aggressive: return 3
        case .reckless: return 4
        }
    }
}

// MARK: - Supporting Views

struct DifferentialLeagueSummaryCard: View {
    let summary: LeagueDifferentialSummary
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("League Overview")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(Int(summary.successRate))% Success Rate")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(getSuccessRateColor().opacity(0.2))
                    .foregroundColor(getSuccessRateColor())
                    .cornerRadius(6)
            }
            
            HStack(spacing: 16) {
                SummaryStatBox(
                    title: "Total Differentials",
                    value: "\(summary.totalDifferentials)",
                    subtitle: "unique picks",
                    color: .blue
                )
                
                SummaryStatBox(
                    title: "Successful",
                    value: "\(summary.successfulDifferentials)",
                    subtitle: "paid off",
                    color: .green
                )
                
                SummaryStatBox(
                    title: "Failed",
                    value: "\(summary.failedDifferentials)",
                    subtitle: "backfired",
                    color: .red
                )
            }
            
            if let topDiff = summary.topDifferential {
                VStack(alignment: .leading, spacing: 8) {
                    Text("🏆 Best Differential")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Text(topDiff.player.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(topDiff.pointsScored) pts • \(String(format: "%.1f", topDiff.leagueOwnership))% owned")
                            .font(.caption)
                            .foregroundColor(Color("FplTextSecondary"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
    }
    
    private func getSuccessRateColor() -> Color {
        if summary.successRate > 70 { return .green }
        else if summary.successRate > 50 { return .blue }
        else if summary.successRate > 30 { return .orange }
        else { return .red }
    }
}

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
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                // Rank Badge
                ZStack {
                    Circle()
                        .fill(getRankColor())
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
                            .foregroundColor(.purple)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(alignment: .bottom, spacing: 2) {
                        Text(String(format: "%.0f", analysis.differentialSuccessRate))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(getSuccessRateColor(analysis.differentialSuccessRate))
                        
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
                        // Differential Picks Section
                        if !analysis.differentialPicks.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Differential Picks")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Text("\(analysis.differentialPicks.count) picks")
                                        .font(.caption)
                                        .foregroundColor(Color("FplTextSecondary"))
                                }
                                
                                LazyVStack(spacing: 8) {
                                    let sortedPicks = analysis.differentialPicks.sorted { first, second in
                                        first.differentialScore > second.differentialScore
                                    }
                                    
                                    ForEach(sortedPicks.prefix(5)) { pick in
                                        DifferentialPickRow(pick: pick)
                                    }
                                }
                                
                                if analysis.differentialPicks.count > 5 {
                                    Text("+ \(analysis.differentialPicks.count - 5) more differentials")
                                        .font(.caption)
                                        .foregroundColor(Color("FplTextSecondary"))
                                        .padding(.top, 4)
                                }
                            }
                        }
                        
                        // Missed Opportunities Section
                        if !analysis.missedOpportunities.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Missed Opportunities")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Text("\(analysis.missedOpportunities.count) missed")
                                        .font(.caption)
                                        .foregroundColor(Color("FplTextSecondary"))
                                }
                                
                                LazyVStack(spacing: 8) {
                                    ForEach(analysis.missedOpportunities.prefix(3)) { missed in
                                        MissedOpportunityRow(missed: missed)
                                    }
                                }
                            }
                        }
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
    
    private func getRankColor() -> Color {
        switch rank {
        case 1: return .purple
        case 2: return .blue
        case 3: return .green
        default: return .gray
        }
    }
    
    private func getSuccessRateColor(_ rate: Double) -> Color {
        if rate > 70 { return .green }
        else if rate > 50 { return .blue }
        else if rate > 30 { return .orange }
        else { return .red }
    }
}

struct RiskLevelBadge: View {
    let level: RiskLevel
    
    var body: some View {
        Text(level.label)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(level.color.opacity(0.2))
            .foregroundColor(level.color)
            .cornerRadius(4)
    }
}

struct DifferentialPickRow: View {
    let pick: DifferentialPick
    
    var body: some View {
        HStack {
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
                        .foregroundColor(pick.outcome.color)
                }
                
                Text(pick.outcome.label)
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(pick.outcome.color.opacity(0.2))
                    .foregroundColor(pick.outcome.color)
                    .cornerRadius(3)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color("FplBackground"))
        .cornerRadius(8)
    }
}

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
                
                Text("Owned by: \(missed.ownedByManagers.joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundColor(Color("FplTextSecondary"))
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

struct DifferentialAnalysisInfoSheet: View {
    @Environment(\.presentationMode) var presentationMode
    
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
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}
