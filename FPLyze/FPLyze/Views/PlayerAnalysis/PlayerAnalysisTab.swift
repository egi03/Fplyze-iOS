//
//  PlayerAnalysisTab.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 01.07.2025..
//

import SwiftUI

struct PlayerAnalysisTab: View {
    let missedAnalyses: [MissedPlayerAnalysis]
    let underperformerAnalyses: [UnderperformerAnalysis]
    @State private var selectedAnalysisType = AnalysisType.missed
    @State private var selectedManager: Int?
    @State private var showingPlayerDetail = false
    @State private var selectedPlayer: PlayerData?
    @State private var showingInfoSheet = false
    
    enum AnalysisType: String, CaseIterable {
        case missed = "Missed Stars"
        case underperformers = "Underperformers"
        
        var icon: String {
            switch self {
            case .missed: return "star.slash.fill"
            case .underperformers: return "chart.line.downtrend.xyaxis"
            }
        }
        
        var description: String {
            switch self {
            case .missed: return "Top players you didn't own when they scored big"
            case .underperformers: return "Players who disappointed while in your team"
            }
        }
        
        var detailedDescription: String {
            switch self {
            case .missed:
                return "These are the players who had great performances but weren't in your squad. Don't worry - everyone misses some!"
            case .underperformers:
                return "Players who didn't deliver the points you expected while in your team. We've all been there!"
            }
        }
    }
    
    var totalMissedPoints: Int {
        missedAnalyses.map { $0.totalMissedPoints }.reduce(0, +)
    }
    
    var averageMissedPerManager: Double {
        guard !missedAnalyses.isEmpty else { return 0 }
        return Double(totalMissedPoints) / Double(missedAnalyses.count)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header Section (now scrollable)
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Player Analysis")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("What could have been...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
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
                    
                    // Analysis Type Selector with stats
                    VStack(spacing: 12) {
                        Picker("Analysis Type", selection: $selectedAnalysisType) {
                            ForEach(AnalysisType.allCases, id: \.self) { type in
                                Label(type.rawValue, systemImage: type.icon)
                                    .tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        
                        // Context Description
                        Text(selectedAnalysisType.detailedDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Quick Stats
                        AnalysisQuickStats(
                            analysisType: selectedAnalysisType,
                            missedAnalyses: missedAnalyses,
                            underperformerAnalyses: underperformerAnalyses
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 8)
                .background(Color.white)
                .cornerRadius(15)
                .shadow(color: .black.opacity(0.05), radius: 5, y: 5)
                .padding(.horizontal)
                
                // Main Content
                LazyVStack(spacing: 16) {
                    switch selectedAnalysisType {
                    case .missed:
                        if missedAnalyses.isEmpty {
                            EmptyAnalysisView(type: .missed)
                                .padding(.horizontal)
                        } else {
                            ForEach(missedAnalyses) { analysis in
                                EnhancedMissedPlayerCard(
                                    analysis: analysis,
                                    averageLeagueMissed: averageMissedPerManager,
                                    isExpanded: selectedManager == analysis.managerId,
                                    onTap: {
                                        withAnimation(.spring()) {
                                            selectedManager = selectedManager == analysis.managerId ? nil : analysis.managerId
                                        }
                                    },
                                    onPlayerTap: { player in
                                        selectedPlayer = player
                                        showingPlayerDetail = true
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                        
                    case .underperformers:
                        if underperformerAnalyses.isEmpty {
                            EmptyAnalysisView(type: .underperformers)
                                .padding(.horizontal)
                        } else {
                            ForEach(underperformerAnalyses) { analysis in
                                EnhancedUnderperformerCard(
                                    analysis: analysis,
                                    isExpanded: selectedManager == analysis.managerId,
                                    onTap: {
                                        withAnimation(.spring()) {
                                            selectedManager = selectedManager == analysis.managerId ? nil : analysis.managerId
                                        }
                                    },
                                    onPlayerTap: { player in
                                        selectedPlayer = player
                                        showingPlayerDetail = true
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .background(Color("FplBackground"))
        .sheet(isPresented: $showingPlayerDetail) {
            if let player = selectedPlayer {
                EnhancedPlayerDetailSheet(player: player)
            }
        }
        .sheet(isPresented: $showingInfoSheet) {
            PlayerAnalysisInfoSheet()
        }
    }
}

struct AnalysisQuickStats: View {
    let analysisType: PlayerAnalysisTab.AnalysisType
    let missedAnalyses: [MissedPlayerAnalysis]
    let underperformerAnalyses: [UnderperformerAnalysis]
    
    var stats: (total: String, average: String, worst: String) {
        switch analysisType {
        case .missed:
            let total = missedAnalyses.map { $0.totalMissedPoints }.reduce(0, +)
            let average = missedAnalyses.isEmpty ? 0 : total / missedAnalyses.count
            let worst = missedAnalyses.map { $0.totalMissedPoints }.max() ?? 0
            return (
                "\(total) pts",
                "\(average) pts/manager",
                "\(worst) pts"
            )
        case .underperformers:
            let total = underperformerAnalyses.map { $0.underperformers.count }.reduce(0, +)
            let average = underperformerAnalyses.isEmpty ? 0 : total / underperformerAnalyses.count
            let worst = underperformerAnalyses.map { $0.underperformers.count }.max() ?? 0
            return (
                "\(total) players",
                "\(average) per manager",
                "\(worst) players"
            )
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            QuickStatBox(
                title: "Total",
                value: stats.total,
                icon: "sum",
                color: .blue
            )
            
            QuickStatBox(
                title: "Average",
                value: stats.average,
                icon: "divide",
                color: .green
            )
            
            QuickStatBox(
                title: "Most",
                value: stats.worst,
                icon: "exclamationmark.triangle",
                color: .orange
            )
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct QuickStatBox: View {
    let title: String
    let value: String
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
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct EnhancedMissedPlayerCard: View {
    let analysis: MissedPlayerAnalysis
    let averageLeagueMissed: Double
    let isExpanded: Bool
    let onTap: () -> Void
    let onPlayerTap: (PlayerData) -> Void
    
    var performanceRating: String {
        let ratio = Double(analysis.totalMissedPoints) / averageLeagueMissed
        if ratio < 0.7 { return "😎 Better than most!" }
        else if ratio < 1.0 { return "👍 Not bad" }
        else if ratio < 1.3 { return "😅 About average" }
        else { return "😱 Ouch!" }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(analysis.managerName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let biggestMiss = analysis.biggestMiss {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            
                            Text("Biggest miss: \(biggestMiss.player.displayName)")
                                .font(.caption)
                                .foregroundColor(Color("FplTextSecondary"))
                            
                            Text("(\(biggestMiss.missedPoints) pts)")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Text(performanceRating)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(alignment: .bottom, spacing: 2) {
                        Text("\(analysis.totalMissedPoints)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        
                        Text("pts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)
                    }
                    
                    Text("missed total")
                        .font(.caption)
                        .foregroundColor(Color("FplTextSecondary"))
                    
                    // Comparison to average
                    let diff = analysis.totalMissedPoints - Int(averageLeagueMissed)
                    if diff != 0 {
                        Text(diff > 0 ? "+\(diff) vs avg" : "\(diff) vs avg")
                            .font(.caption2)
                            .foregroundColor(diff > 0 ? .red : .green)
                    }
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
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("Top Missed Players")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Text("\(analysis.missedPlayers.count) total")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ForEach(analysis.missedPlayers.prefix(5)) { missed in
                            EnhancedMissedPlayerRow(
                                missed: missed,
                                onTap: { onPlayerTap(missed.player) }
                            )
                        }
                        
                        if analysis.missedPlayers.count > 5 {
                            Text("+ \(analysis.missedPlayers.count - 5) more players")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                    }
                    .padding()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color("FplCardBackground"))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
}

struct EnhancedMissedPlayerRow: View {
    let missed: MissedPlayer
    let onTap: () -> Void
    
    var impactDescription: String {
        switch missed.impact {
        case .critical: return "Season-changing miss"
        case .high: return "Significant points lost"
        case .medium: return "Notable miss"
        case .low: return "Minor impact"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Position Badge
                PositionBadge(position: missed.player.elementType)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(missed.player.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Label("\(missed.missedGameweeks.count) GWs", systemImage: "calendar")
                            .font(.caption2)
                        
                        Label(String(format: "%.1f pts/GW", missed.avgPointsPerMiss), systemImage: "chart.bar")
                            .font(.caption2)
                    }
                    .foregroundColor(Color("FplTextSecondary"))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(alignment: .bottom, spacing: 2) {
                        Text("\(missed.missedPoints)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        
                        Text("pts")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(missed.impact.label)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(missed.impact.color).opacity(0.2))
                        .foregroundColor(Color(missed.impact.color))
                        .cornerRadius(4)
                    
                    Text(impactDescription)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color("FplSurface"))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PositionBadge: View {
    let position: Int
    
    var positionText: String {
        switch position {
        case 1: return "GKP"
        case 2: return "DEF"
        case 3: return "MID"
        case 4: return "FWD"
        default: return "???"
        }
    }
    
    var positionColor: Color {
        switch position {
        case 1: return .orange
        case 2: return .green
        case 3: return .blue
        case 4: return .purple
        default: return .gray
        }
    }
    
    var body: some View {
        Text(positionText)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(width: 35)
            .padding(.vertical, 4)
            .background(positionColor)
            .cornerRadius(6)
    }
}

struct EmptyAnalysisView: View {
    let type: PlayerAnalysisTab.AnalysisType
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: type.icon)
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.5))
            
            Text("No Data Available")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Player analysis data will appear here once available")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(60)
    }
}

struct EnhancedPlayerDetailSheet: View {
    let player: PlayerData
    @Environment(\.presentationMode) var presentationMode
    
    var ownershipContext: String {
        let ownership = player.ownership
        if ownership > 50 { return "Highly owned - template player" }
        else if ownership > 30 { return "Popular pick" }
        else if ownership > 15 { return "Differential option" }
        else if ownership > 5 { return "Under the radar" }
        else { return "Hidden gem" }
    }
    
    var formContext: String {
        guard let form = player.form, let formValue = Double(form) else { return "No recent form data" }
        if formValue > 7 { return "🔥 On fire!" }
        else if formValue > 5 { return "📈 Good form" }
        else if formValue > 3 { return "📊 Average form" }
        else { return "📉 Poor form" }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Enhanced Player Header
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(player.displayName)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                
                                HStack(spacing: 12) {
                                    PositionBadge(position: player.elementType)
                                    
                                    Label("£\(Double(player.nowCost) / 10.0, specifier: "%.1f")m", systemImage: "sterlingsign.circle")
                                        .font(.subheadline)
                                        .foregroundColor(Color("FplTextSecondary"))
                                }
                                
                                Text(ownershipContext)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(player.totalPoints)")
                                    .font(.system(size: 44))
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("FplPrimary"))
                                
                                Text("Total Points")
                                    .font(.caption)
                                    .foregroundColor(Color("FplTextSecondary"))
                                
                                Text(formContext)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(6)
                            }
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color("FplPrimary").opacity(0.1), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(15)
                    }
                    
                    // Key Performance Indicators
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Key Statistics")
                            .font(.headline)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            EnhancedStatCard(
                                title: "Goals",
                                value: "\(player.goalsScored)",
                                icon: "soccerball",
                                description: goalContext(player.goalsScored, position: player.elementType)
                            )
                            
                            EnhancedStatCard(
                                title: "Assists",
                                value: "\(player.assists)",
                                icon: "person.2.fill",
                                description: assistContext(player.assists, position: player.elementType)
                            )
                            
                            EnhancedStatCard(
                                title: "Clean Sheets",
                                value: "\(player.cleanSheets)",
                                icon: "shield.fill",
                                description: cleanSheetContext(player.cleanSheets, position: player.elementType)
                            )
                            
                            EnhancedStatCard(
                                title: "Minutes",
                                value: "\(player.minutes)",
                                icon: "clock.fill",
                                description: minutesContext(player.minutes)
                            )
                            
                            EnhancedStatCard(
                                title: "Ownership",
                                value: "\(player.selectedByPercent)",
                                icon: "person.3.fill",
                                description: ownershipContext
                            )
                            
                            EnhancedStatCard(
                                title: "Form",
                                value: player.form ?? "N/A",
                                icon: "chart.line.uptrend.xyaxis",
                                description: formContext
                            )
                        }
                    }
                    
                    // Performance Metrics with context
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Performance Analysis")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            EnhancedPerformanceBar(
                                title: "Points per Game",
                                value: Double(player.pointsPerGame) ?? 0,
                                maxValue: 10,
                                color: .green,
                                benchmark: 5.0,
                                description: "Elite: 7+, Good: 5-7, Average: 3-5"
                            )
                            
                            EnhancedPerformanceBar(
                                title: "Points per 90 min",
                                value: player.pointsPerMinute,
                                maxValue: 10,
                                color: .blue,
                                benchmark: 5.0,
                                description: "Efficiency when on the pitch"
                            )
                            
                            if let ictIndex = player.ictIndex {
                                EnhancedPerformanceBar(
                                    title: "ICT Index",
                                    value: (Double(ictIndex) ?? 0) / 10,
                                    maxValue: 50,
                                    color: .purple,
                                    benchmark: 25,
                                    description: "Influence, Creativity, Threat combined"
                                )
                            }
                        }
                        .padding()
                        .background(Color("FplSurface"))
                        .cornerRadius(15)
                    }
                    
                    // Status and News
                    if let news = player.news, !news.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Latest News", systemImage: "newspaper")
                                .font(.headline)
                            
                            Text(news)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Player Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    func goalContext(_ goals: Int, position: Int) -> String {
        switch position {
        case 4: // FWD
            if goals > 15 { return "Elite striker" }
            else if goals > 10 { return "Reliable scorer" }
            else if goals > 5 { return "Decent return" }
            else { return "Needs improvement" }
        case 3: // MID
            if goals > 10 { return "Goal machine!" }
            else if goals > 5 { return "Good output" }
            else { return "Standard for position" }
        default:
            if goals > 3 { return "Bonus goals!" }
            else { return "Defensive focus" }
        }
    }
    
    func assistContext(_ assists: Int, position: Int) -> String {
        switch position {
        case 3, 4: // MID, FWD
            if assists > 10 { return "Creative genius" }
            else if assists > 5 { return "Good playmaker" }
            else { return "Room to improve" }
        default:
            if assists > 3 { return "Attacking threat" }
            else { return "Occasional contributor" }
        }
    }
    
    func cleanSheetContext(_ cs: Int, position: Int) -> String {
        switch position {
        case 1, 2: // GKP, DEF
            if cs > 15 { return "Rock solid" }
            else if cs > 10 { return "Reliable defense" }
            else if cs > 5 { return "Decent returns" }
            else { return "Leaky defense" }
        default:
            return "Defensive bonus"
        }
    }
    
    func minutesContext(_ minutes: Int) -> String {
        let gamesPlayed = Double(minutes) / 90.0
        if gamesPlayed > 35 { return "Ever-present" }
        else if gamesPlayed > 30 { return "Key player" }
        else if gamesPlayed > 20 { return "Regular starter" }
        else if gamesPlayed > 10 { return "Rotation risk" }
        else { return "Limited minutes" }
    }
}

struct EnhancedStatCard: View {
    let title: String
    let value: String
    let icon: String
    let description: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(Color("FplPrimary"))
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(Color("FplTextSecondary"))
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct EnhancedPerformanceBar: View {
    let title: String
    let value: Double
    let maxValue: Double
    let color: Color
    let benchmark: Double
    let description: String
    
    var percentage: Double {
        min(value / maxValue, 1.0)
    }
    
    var benchmarkPercentage: Double {
        benchmark / maxValue
    }
    
    var performanceLabel: String {
        if value > benchmark * 1.2 { return "Excellent" }
        else if value > benchmark { return "Above average" }
        else if value > benchmark * 0.8 { return "Average" }
        else { return "Below average" }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f", value))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    
                    Text(performanceLabel)
                        .font(.caption2)
                        .foregroundColor(color)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    // Value bar
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 8)
                        .cornerRadius(4)
                        .animation(.spring(), value: percentage)
                    
                    // Benchmark line
                    Rectangle()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 2, height: 12)
                        .offset(x: geometry.size.width * benchmarkPercentage - 1)
                }
            }
            .frame(height: 12)
            
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct PlayerAnalysisInfoSheet: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Understanding Player Analysis")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom)
                    
                    InfoSection(
                        title: "Missed Stars",
                        icon: "star.slash.fill",
                        description: """
                        Shows players who scored well but weren't in your team. Don't beat yourself up - even the best managers miss some hauls!
                        
                        • Critical: 100+ points missed
                        • High: 50-100 points
                        • Medium: 25-50 points
                        • Low: Under 25 points
                        """
                    )
                    
                    InfoSection(
                        title: "Underperformers",
                        icon: "chart.line.downtrend.xyaxis",
                        description: """
                        Players who didn't deliver while in your squad. We've all been there!
                        
                        • Terrible: <2 pts/game
                        • Poor: 2-3 pts/game
                        • Below Average: 3-4 pts/game
                        • Average: 4+ pts/game
                        """
                    )
                    
                    InfoSection(
                        title: "How to Use This",
                        icon: "lightbulb",
                        description: """
                        • Learn from patterns in missed players
                        • Identify when you're too patient with underperformers
                        • Compare your misses with league average
                        • Remember: hindsight is 20/20!
                        """
                    )
                }
                .padding()
            }
            .navigationBarTitle("Player Analysis Help", displayMode: .inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}
