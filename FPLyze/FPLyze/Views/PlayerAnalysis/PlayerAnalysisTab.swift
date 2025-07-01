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
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Analysis Type Selector
            Picker("Analysis Type", selection: $selectedAnalysisType) {
                ForEach(AnalysisType.allCases, id: \.self) { type in
                    Label(type.rawValue, systemImage: type.icon)
                        .tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .background(Color("FplCardBackground"))
            
            // Description
            Text(selectedAnalysisType.description)
                .font(.caption)
                .foregroundColor(Color("FplTextSecondary"))
                .padding(.horizontal)
                .padding(.bottom, 10)
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    switch selectedAnalysisType {
                    case .missed:
                        ForEach(missedAnalyses) { analysis in
                            MissedPlayerCard(
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
                        }
                        
                    case .underperformers:
                        ForEach(underperformerAnalyses) { analysis in
                            UnderperformerCard(
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
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color("FplBackground"))
        .sheet(isPresented: $showingPlayerDetail) {
            if let player = selectedPlayer {
                PlayerDetailSheet(player: player)
            }
        }
    }
}

// MARK: - Missed Player Card
struct MissedPlayerCard: View {
    let analysis: MissedPlayerAnalysis
    let isExpanded: Bool
    let onTap: () -> Void
    let onPlayerTap: (PlayerData) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
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
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(analysis.totalMissedPoints)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text("points missed")
                        .font(.caption)
                        .foregroundColor(Color("FplTextSecondary"))
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
                Divider()
                
                VStack(spacing: 12) {
                    ForEach(analysis.missedPlayers.prefix(5)) { missed in
                        MissedPlayerRow(
                            missed: missed,
                            onTap: { onPlayerTap(missed.player) }
                        )
                    }
                }
                .padding()
            }
        }
        .background(Color("FplCardBackground"))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
}

// MARK: - Missed Player Row
struct MissedPlayerRow: View {
    let missed: MissedPlayer
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Position Badge
                Text(missed.player.position)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 35)
                    .padding(.vertical, 4)
                    .background(positionColor(missed.player.elementType))
                    .cornerRadius(6)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(missed.player.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("\(missed.missedGameweeks.count) GWs missed")
                        .font(.caption2)
                        .foregroundColor(Color("FplTextSecondary"))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(missed.missedPoints) pts")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text(missed.impact.label)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(missed.impact.color).opacity(0.2))
                        .foregroundColor(Color(missed.impact.color))
                        .cornerRadius(4)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color("FplSurface"))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func positionColor(_ position: Int) -> Color {
        switch position {
        case 1: return .orange // GKP
        case 2: return .green // DEF
        case 3: return .blue // MID
        case 4: return .purple // FWD
        default: return .gray
        }
    }
}

// MARK: - Underperformer Card
struct UnderperformerCard: View {
    let analysis: UnderperformerAnalysis
    let isExpanded: Bool
    let onTap: () -> Void
    let onPlayerTap: (PlayerData) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(analysis.managerName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let worst = analysis.worstPerformer {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.thumbsdown.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                            
                            Text("Worst: \(worst.player.displayName)")
                                .font(.caption)
                                .foregroundColor(Color("FplTextSecondary"))
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(analysis.underperformers.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text("underperformers")
                        .font(.caption)
                        .foregroundColor(Color("FplTextSecondary"))
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
                Divider()
                
                VStack(spacing: 12) {
                    ForEach(analysis.underperformers.prefix(5)) { underperformer in
                        UnderperformerRow(
                            underperformer: underperformer,
                            onTap: { onPlayerTap(underperformer.player) }
                        )
                    }
                }
                .padding()
            }
        }
        .background(Color("FplCardBackground"))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
}

// MARK: - Underperformer Row
struct UnderperformerRow: View {
    let underperformer: UnderperformingPlayer
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Position Badge
                Text(underperformer.player.position)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 35)
                    .padding(.vertical, 4)
                    .background(positionColor(underperformer.player.elementType))
                    .cornerRadius(6)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(underperformer.player.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("\(underperformer.gamesOwned) games owned")
                        .font(.caption2)
                        .foregroundColor(Color("FplTextSecondary"))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f pts/game", underperformer.avgPointsPerGame))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text(underperformer.performanceRating.label)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(underperformer.performanceRating.color).opacity(0.2))
                        .foregroundColor(Color(underperformer.performanceRating.color))
                        .cornerRadius(4)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color("FplSurface"))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func positionColor(_ position: Int) -> Color {
        switch position {
        case 1: return .orange // GKP
        case 2: return .green // DEF
        case 3: return .blue // MID
        case 4: return .purple // FWD
        default: return .gray
        }
    }
}

// MARK: - Player Detail Sheet
struct PlayerDetailSheet: View {
    let player: PlayerData
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Player Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(player.displayName)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            HStack {
                                Text(player.position)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(positionColor(player.elementType))
                                    .cornerRadius(6)
                                
                                Text("£\(Double(player.nowCost) / 10.0, specifier: "%.1f")m")
                                    .font(.subheadline)
                                    .foregroundColor(Color("FplTextSecondary"))
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("\(player.totalPoints)")
                                .font(.system(size: 36))
                                .fontWeight(.bold)
                                .foregroundColor(Color("FplPrimary"))
                            
                            Text("Total Points")
                                .font(.caption)
                                .foregroundColor(Color("FplTextSecondary"))
                        }
                    }
                    .padding()
                    .background(Color("FplSurface"))
                    .cornerRadius(15)
                    
                    // Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(title: "Goals", value: "\(player.goalsScored)", icon: "soccerball")
                        StatCard(title: "Assists", value: "\(player.assists)", icon: "person.2.fill")
                        StatCard(title: "Clean Sheets", value: "\(player.cleanSheets)", icon: "shield.fill")
                        StatCard(title: "Minutes", value: "\(player.minutes)", icon: "clock.fill")
                        StatCard(title: "Ownership", value: "\(player.selectedByPercent)", icon: "person.3.fill")
                        StatCard(title: "Form", value: player.form, icon: "chart.line.uptrend.xyaxis")
                    }
                    
                    // Performance Metrics
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Performance Metrics")
                            .font(.headline)
                        
                        PerformanceBar(
                            title: "Points per Game",
                            value: Double(player.pointsPerGame) ?? 0,
                            maxValue: 10,
                            color: .green
                        )
                        
                        PerformanceBar(
                            title: "Points per 90 min",
                            value: player.pointsPerMinute,
                            maxValue: 10,
                            color: .blue
                        )
                        
                        PerformanceBar(
                            title: "ICT Index",
                            value: (Double(player.ictIndex) ?? 0) / 10,
                            maxValue: 50,
                            color: .purple
                        )
                    }
                    .padding()
                    .background(Color("FplSurface"))
                    .cornerRadius(15)
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
    
    private func positionColor(_ position: Int) -> Color {
        switch position {
        case 1: return .orange
        case 2: return .green
        case 3: return .blue
        case 4: return .purple
        default: return .gray
        }
    }
}

// MARK: - Support Views
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color("FplPrimary"))
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(Color("FplTextSecondary"))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color("FplCardBackground"))
        .cornerRadius(10)
    }
}

struct PerformanceBar: View {
    let title: String
    let value: Double
    let maxValue: Double
    let color: Color
    
    var percentage: Double {
        min(value / maxValue, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(Color("FplTextSecondary"))
                
                Spacer()
                
                Text(String(format: "%.1f", value))
                    .font(.caption)
                    .fontWeight(.bold)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 8)
                        .cornerRadius(4)
                        .animation(.spring(), value: percentage)
                }
            }
            .frame(height: 8)
        }
    }
}
