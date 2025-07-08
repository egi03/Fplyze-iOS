//
//  WhatIfScenariosTab.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 03.07.2025..
//

import SwiftUI

struct WhatIfScenariosTab: View {
    let scenarios: [WhatIfScenario]
    @State private var selectedScenario: WhatIfScenario?
    @State private var filterType: ScenarioFilterType = .all
    @State private var showingInfoSheet = false
    
    enum ScenarioFilterType: String, CaseIterable {
        case all = "All Scenarios"
        case captain = "Captain Choices"
        case chips = "Chip Timing"
        case transfers = "Transfers"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .captain: return "star.circle"
            case .chips: return "wand.and.stars"
            case .transfers: return "arrow.left.arrow.right"
            }
        }
        
        var scenarioType: ScenarioType? {
            switch self {
            case .all: return nil
            case .captain: return .captainChange
            case .chips: return .chipTiming
            case .transfers: return .transferChange
            }
        }
    }
    
    var filteredScenarios: [WhatIfScenario] {
        if let type = filterType.scenarioType {
            return scenarios.filter { $0.type == type }
        }
        return scenarios
    }
    
    var scenarioSummary: WhatIfSummary {
        let biggestGain = scenarios.flatMap { $0.results }.map { $0.pointsChange }.max() ?? 0
        let biggestLoss = scenarios.flatMap { $0.results }.map { $0.pointsChange }.min() ?? 0
        let mostVolatile = findMostVolatileGameweek()
        
        return WhatIfSummary(
            totalScenariosAnalyzed: scenarios.count,
            biggestPotentialGain: biggestGain,
            biggestMissedOpportunity: abs(biggestLoss),
            mostVolatileGameweek: mostVolatile,
            stabilityRating: calculateStabilityRating()
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Demo Banner
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
            
            ScrollView {
                VStack(spacing: 16) {
                    // Header with summary
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("What-If Scenarios")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                
                                Text("Explore alternative timelines")
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
                        
                        // Summary Card
                        WhatIfSummaryCard(summary: scenarioSummary)
                            .padding(.horizontal)
                        
                        // Filter Options
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(ScenarioFilterType.allCases, id: \.self) { type in
                                    FilterChip(
                                        type: type,
                                        isSelected: filterType == type,
                                        count: getScenarioCount(for: type),
                                        action: { filterType = type }
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
                    
                    // Scenario Cards
                    if filteredScenarios.isEmpty {
                        EmptyWhatIfView()
                            .padding(.horizontal)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredScenarios) { scenario in
                                WhatIfScenarioCard(
                                    scenario: scenario,
                                    isExpanded: selectedScenario?.id == scenario.id,
                                    onTap: {
                                        withAnimation(.spring()) {
                                            selectedScenario = selectedScenario?.id == scenario.id ? nil : scenario
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
        }
        .sheet(isPresented: $showingInfoSheet) {
            WhatIfScenariosInfoSheet()
        }
    }
    
    private func getScenarioCount(for filterType: ScenarioFilterType) -> Int {
        if let type = filterType.scenarioType {
            return scenarios.filter { $0.type == type }.count
        }
        return scenarios.count
    }
    
    private func findMostVolatileGameweek() -> Int? {
        let gameweekImpacts = Dictionary(grouping: scenarios) { $0.gameweek }
            .compactMapValues { scenarios in
                scenarios.flatMap { $0.results }.map { abs($0.rankChange) }.reduce(0, +)
            }
        
        return gameweekImpacts.max { $0.value < $1.value }?.key
    }
    
    private func calculateStabilityRating() -> Double {
        let totalRankChanges = scenarios.flatMap { $0.results }.map { abs($0.rankChange) }.reduce(0, +)
        let totalResults = scenarios.flatMap { $0.results }.count
        
        guard totalResults > 0 else { return 100 }
        
        let averageChange = Double(totalRankChanges) / Double(totalResults)
        return max(0, 100 - (averageChange * 10)) // Convert to stability percentage
    }
}

// MARK: - Supporting Views

struct WhatIfSummaryCard: View {
    let summary: WhatIfSummary
    
    var stabilityRating: String {
        switch summary.stabilityRating {
        case 80...100: return "🗿 Rock Solid"
        case 60..<80: return "⚖️ Stable"
        case 40..<60: return "🌊 Moderate"
        case 20..<40: return "🌪️ Volatile"
        default: return "💥 Chaotic"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("League Analysis")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text(stabilityRating)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(getStabilityColor().opacity(0.2))
                    .foregroundColor(getStabilityColor())
                    .cornerRadius(6)
            }
            
            HStack(spacing: 12) {
                WhatIfStatBox(
                    title: "Scenarios",
                    value: "\(summary.totalScenariosAnalyzed)",
                    subtitle: "analyzed",
                    icon: "list.bullet.rectangle",
                    color: .blue
                )
                
                WhatIfStatBox(
                    title: "Biggest Gain",
                    value: "\(summary.biggestPotentialGain)",
                    subtitle: "points",
                    icon: "arrow.up.circle",
                    color: .green
                )
                
                WhatIfStatBox(
                    title: "Biggest Miss",
                    value: "\(summary.biggestMissedOpportunity)",
                    subtitle: "points",
                    icon: "arrow.down.circle",
                    color: .red
                )
            }
            
            if let volatileGW = summary.mostVolatileGameweek {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Most Volatile Gameweek")
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        Text("GW\(volatileGW) had the highest potential for rank changes")
                            .font(.caption2)
                            .foregroundColor(Color("FplTextSecondary"))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
    }
    
    private func getStabilityColor() -> Color {
        switch summary.stabilityRating {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .red
        }
    }
}

struct WhatIfStatBox: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            VStack(spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(Color("FplTextSecondary"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct FilterChip: View {
    let type: WhatIfScenariosTab.ScenarioFilterType
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.caption)
                
                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                if count > 0 {
                    Text("(\(count))")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : Color("FplTextSecondary"))
                }
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

struct WhatIfScenarioCard: View {
    let scenario: WhatIfScenario
    let isExpanded: Bool
    let onTap: () -> Void
    
    var impactSummary: String {
        let affected = scenario.results.filter { $0.significantChange }.count
        let total = scenario.results.count
        
        if affected == 0 {
            return "💤 Minimal impact"
        } else if affected < total / 3 {
            return "📊 Minor changes"
        } else if affected < total * 2 / 3 {
            return "📈 Moderate impact"
        } else {
            return "🌪️ Major shake-up"
        }
    }
    
    var biggestWinner: WhatIfResult? {
        scenario.results.max { $0.rankChange > $1.rankChange }
    }
    
    var biggestLoser: WhatIfResult? {
        scenario.results.max { $0.rankChange < $1.rankChange }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: scenario.type.icon)
                            .foregroundColor(getScenarioTypeColor())
                        
                        Text(scenario.title)
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    
                    Text(scenario.description)
                        .font(.subheadline)
                        .foregroundColor(Color("FplTextSecondary"))
                        .lineLimit(isExpanded ? nil : 2)
                    
                    HStack {
                        if let gw = scenario.gameweek {
                            Label("GW\(gw)", systemImage: "calendar")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        Text(impactSummary)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(getScenarioTypeColor().opacity(0.2))
                            .foregroundColor(getScenarioTypeColor())
                            .cornerRadius(4)
                        
                        Spacer()
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(scenario.results.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(getScenarioTypeColor())
                    
                    Text("managers")
                        .font(.caption2)
                        .foregroundColor(Color("FplTextSecondary"))
                    
                    Text(scenario.impact.impactLevel)
                        .font(.caption2)
                        .multilineTextAlignment(.trailing)
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
                        // Impact Overview
                        ScenarioImpactOverview(impact: scenario.impact)
                        
                        // Top Changes
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Biggest Changes")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            VStack(spacing: 8) {
                                if let winner = biggestWinner, winner.rankChange != 0 {
                                    WhatIfResultRow(result: winner, isPositive: winner.improvement)
                                }
                                
                                if let loser = biggestLoser, loser.rankChange != 0 {
                                    WhatIfResultRow(result: loser, isPositive: loser.improvement)
                                }
                            }
                        }
                        
                        // All Results (top 10)
                        if scenario.results.count > 2 {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("All Changes")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Text("Showing top 10")
                                        .font(.caption)
                                        .foregroundColor(Color("FplTextSecondary"))
                                }
                                
                                LazyVStack(spacing: 6) {
                                    ForEach(scenario.results
                                        .sorted { abs($0.rankChange) > abs($1.rankChange) }
                                        .prefix(10)
                                    ) { result in
                                        CompactResultRow(result: result)
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
    
    private func getScenarioTypeColor() -> Color {
        switch scenario.type {
        case .captainChange: return .orange
        case .transferChange: return .blue
        case .chipTiming: return .purple
        case .teamSelection: return .green
        }
    }
}

struct ScenarioImpactOverview: View {
    let impact: ScenarioImpact
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Impact Analysis")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                ImpactStatBox(
                    title: "Avg Rank Change",
                    value: String(format: "%.1f", abs(impact.averageRankChange)),
                    isPositive: impact.averageRankChange < 0,
                    icon: impact.averageRankChange < 0 ? "arrow.up" : "arrow.down"
                )
                
                ImpactStatBox(
                    title: "Avg Points Change",
                    value: String(format: "%.0f", abs(impact.averagePointsChange)),
                    isPositive: impact.averagePointsChange > 0,
                    icon: impact.averagePointsChange > 0 ? "plus" : "minus"
                )
                
                ImpactStatBox(
                    title: "Managers Affected",
                    value: "\(impact.managersAffected)",
                    isPositive: true,
                    icon: "person.3"
                )
            }
        }
        .padding()
        .background(Color("FplBackground"))
        .cornerRadius(12)
    }
}

struct ImpactStatBox: View {
    let title: String
    let value: String
    let isPositive: Bool
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(isPositive ? .green : .red)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(isPositive ? .green : .red)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(Color("FplTextSecondary"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WhatIfResultRow: View {
    let result: WhatIfResult
    let isPositive: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(result.managerName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Rank: \(result.originalRank) → \(result.newRank)")
                    .font(.caption)
                    .foregroundColor(Color("FplTextSecondary"))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                HStack {
                    Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                        .font(.caption)
                        .foregroundColor(isPositive ? .green : .red)
                    
                    Text("\(abs(result.rankChange))")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(isPositive ? .green : .red)
                }
                
                if result.pointsChange != 0 {
                    Text("\(result.pointsChange > 0 ? "+" : "")\(result.pointsChange) pts")
                        .font(.caption2)
                        .foregroundColor(Color("FplTextSecondary"))
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isPositive ? Color.green.opacity(0.05) : Color.red.opacity(0.05))
        .cornerRadius(8)
    }
}

struct CompactResultRow: View {
    let result: WhatIfResult
    
    var body: some View {
        HStack {
            Text(result.managerName)
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("\(result.originalRank) → \(result.newRank)")
                .font(.caption)
                .foregroundColor(Color("FplTextSecondary"))
            
            HStack(spacing: 2) {
                if result.rankChange != 0 {
                    Image(systemName: result.improvement ? "arrow.up" : "arrow.down")
                        .font(.caption2)
                        .foregroundColor(result.improvement ? .green : .red)
                    
                    Text("\(abs(result.rankChange))")
                        .font(.caption)
                        .foregroundColor(result.improvement ? .green : .red)
                } else {
                    Text("=")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 40, alignment: .trailing)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color("FplBackground"))
        .cornerRadius(6)
    }
}

struct EmptyWhatIfView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No What-If Scenarios")
                .font(.headline)
                .foregroundColor(Color("FplTextSecondary"))
            
            Text("Alternative timeline analysis will appear here")
                .font(.subheadline)
                .foregroundColor(Color("FplTextSecondary"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(60)
    }
}

struct WhatIfScenariosInfoSheet: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Understanding What-If Scenarios")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom)
                    
                    InfoSection(
                        title: "What are What-If Scenarios?",
                        icon: "questionmark.circle",
                        description: """
                        What-if scenarios show how league standings would change if different decisions were made. They help you understand the impact of key choices and identify missed opportunities.
                        """
                    )
                    
                    InfoSection(
                        title: "Captain Scenarios",
                        icon: "star.circle",
                        description: """
                        Shows what would happen if managers made different captain choices. Often reveals how much captain selection affects final rankings.
                        
                        • Optimal captain timing
                        • Impact of captain failures
                        • League volatility analysis
                        """
                    )
                    
                    InfoSection(
                        title: "Chip Timing Scenarios",
                        icon: "wand.and.stars",
                        description: """
                        Analyzes how different chip timing would affect results:
                        
                        • Triple Captain optimal usage
                        • Bench Boost best gameweeks
                        • Free Hit strategic timing
                        • Wildcard opportunity windows
                        """
                    )
                    
                    InfoSection(
                        title: "Impact Levels",
                        icon: "chart.bar",
                        description: """
                        • 💤 Minimal: Few managers affected
                        • 📊 Minor: Small changes to standings
                        • 📈 Moderate: Noticeable rank shifts
                        • 🌪️ Major: Significant league shake-up
                        """
                    )
                    
                    InfoSection(
                        title: "Using These Insights",
                        icon: "lightbulb",
                        description: """
                        • Learn from missed opportunities
                        • Understand decision impact
                        • Plan future strategies
                        • Identify key decision points
                        • Remember: hindsight is 20/20!
                        """
                    )
                }
                .padding()
            }
            .navigationBarTitle("What-If Guide", displayMode: .inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}
