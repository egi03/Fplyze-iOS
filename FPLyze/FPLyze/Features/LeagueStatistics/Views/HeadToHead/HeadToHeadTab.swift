//
//  HeadToHeadTab.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 21.06.2025..
//

import SwiftUI

struct HeadToHeadTab: View {
    let records: [HeadToHeadRecord]
    @State private var selectedManagerId: Int?
    @State private var selectedRecord: HeadToHeadRecord?
    @State private var showingManagerStats = false
    
    // Get all unique managers from records
    var allManagers: [ManagerInfo] {
        var managers: [ManagerInfo] = []
        var seenIds: Set<Int> = []
        
        for record in records {
            if !seenIds.contains(record.manager1Id) {
                managers.append(ManagerInfo(id: record.manager1Id, name: record.manager1Name))
                seenIds.insert(record.manager1Id)
            }
            if !seenIds.contains(record.manager2Id) {
                managers.append(ManagerInfo(id: record.manager2Id, name: record.manager2Name))
                seenIds.insert(record.manager2Id)
            }
        }
        
        return managers.sorted { $0.name < $1.name }
    }
    
    // Get records for selected manager
    var selectedManagerRecords: [DisplayRecord] {
        guard let selectedId = selectedManagerId else { return [] }
        
        return records.compactMap { record in
            if record.manager1Id == selectedId {
                return DisplayRecord(
                    originalRecord: record,
                    isFlipped: false,
                    opponentId: record.manager2Id,
                    opponentName: record.manager2Name,
                    wins: record.wins,
                    draws: record.draws,
                    losses: record.losses,
                    pointsFor: record.totalPointsFor,
                    pointsAgainst: record.totalPointsAgainst
                )
            } else if record.manager2Id == selectedId {
                return DisplayRecord(
                    originalRecord: record,
                    isFlipped: true,
                    opponentId: record.manager1Id,
                    opponentName: record.manager1Name,
                    wins: record.losses, // Flipped
                    draws: record.draws,
                    losses: record.wins, // Flipped
                    pointsFor: record.totalPointsAgainst, // Flipped
                    pointsAgainst: record.totalPointsFor // Flipped
                )
            }
            return nil
        }.sorted { $0.winPercentage > $1.winPercentage }
    }
    
    var selectedManagerStats: ManagerH2HStats? {
        guard selectedManagerId != nil else { return nil }
        
        let records = selectedManagerRecords
        let totalGames = records.map { $0.totalGames }.reduce(0, +)
        let totalWins = records.map { $0.wins }.reduce(0, +)
        let totalDraws = records.map { $0.draws }.reduce(0, +)
        let totalLosses = records.map { $0.losses }.reduce(0, +)
        let totalPointsFor = records.map { $0.pointsFor }.reduce(0, +)
        let totalPointsAgainst = records.map { $0.pointsAgainst }.reduce(0, +)
        
        let winPercentage = totalGames > 0 ? Double(totalWins) / Double(totalGames) * 100 : 0
        let avgPointsFor = totalGames > 0 ? Double(totalPointsFor) / Double(totalGames) : 0
        let avgPointsAgainst = totalGames > 0 ? Double(totalPointsAgainst) / Double(totalGames) : 0
        
        let bestOpponent = records.max { $0.winPercentage < $1.winPercentage }
        let worstOpponent = records.min { $0.winPercentage < $1.winPercentage }
        
        return ManagerH2HStats(
            totalGames: totalGames,
            totalWins: totalWins,
            totalDraws: totalDraws,
            totalLosses: totalLosses,
            winPercentage: winPercentage,
            totalPointsFor: totalPointsFor,
            totalPointsAgainst: totalPointsAgainst,
            avgPointsFor: avgPointsFor,
            avgPointsAgainst: avgPointsAgainst,
            bestMatchup: bestOpponent?.opponentName,
            worstMatchup: worstOpponent?.opponentName,
            dominantWins: records.filter { $0.winPercentage > 70 }.count,
            strugglingAgainst: records.filter { $0.winPercentage < 30 }.count
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with title and info
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Head-to-Head Analysis")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Compare manager performance")
                            .font(.subheadline)
                            .foregroundColor(Color("FplTextSecondary"))
                    }
                    
                    Spacer()
                    
                    if selectedManagerId != nil {
                        Button(action: { showingManagerStats.toggle() }) {
                            Image(systemName: "chart.bar.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Manager Selector
                ManagerSelectorView(
                    managers: allManagers,
                    selectedManagerId: $selectedManagerId
                )
            }
            .background(Color("FplSurface"))
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.05), radius: 5, y: 5)
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Main Content
            if let selectedId = selectedManagerId {
                ScrollView {
                    VStack(spacing: 16) {
                        // Manager Stats Overview
                        if let stats = selectedManagerStats {
                            ManagerStatsOverview(
                                managerName: allManagers.first { $0.id == selectedId }?.name ?? "Unknown",
                                stats: stats
                            )
                            .padding(.horizontal)
                        }
                        
                        // Head-to-Head Records
                        LazyVStack(spacing: 12) {
                            ForEach(selectedManagerRecords, id: \.originalRecord.id) { displayRecord in
                                EnhancedH2HCard(
                                    displayRecord: displayRecord,
                                    selectedManagerName: allManagers.first { $0.id == selectedId }?.name ?? "Unknown",
                                    isExpanded: selectedRecord?.id == displayRecord.originalRecord.id,
                                    onTap: {
                                        withAnimation(.spring()) {
                                            selectedRecord = selectedRecord?.id == displayRecord.originalRecord.id ? nil : displayRecord.originalRecord
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 20)
                    }
                }
            } else {
                // Empty State
                EmptyH2HState()
            }
        }
        .background(Color("FplBackground"))
        .sheet(isPresented: $showingManagerStats) {
            if let stats = selectedManagerStats,
               let selectedManager = allManagers.first(where: { $0.id == selectedManagerId }) {
                ManagerH2HDetailSheet(
                    managerName: selectedManager.name,
                    stats: stats,
                    records: selectedManagerRecords
                )
            }
        }
    }
}

// MARK: - Supporting Models

struct ManagerInfo: Identifiable {
    let id: Int
    let name: String
}

struct DisplayRecord {
    let originalRecord: HeadToHeadRecord
    let isFlipped: Bool
    let opponentId: Int
    let opponentName: String
    let wins: Int
    let draws: Int
    let losses: Int
    let pointsFor: Int
    let pointsAgainst: Int
    
    var totalGames: Int { wins + draws + losses }
    var winPercentage: Double {
        guard totalGames > 0 else { return 0 }
        return Double(wins) / Double(totalGames) * 100
    }
    
    var pointsDifference: Int { pointsFor - pointsAgainst }
    
    var dominance: Dominance {
        if winPercentage >= 80 { return .dominant }
        else if winPercentage >= 60 { return .strong }
        else if winPercentage >= 40 { return .competitive }
        else { return .struggling }
    }
    
    enum Dominance {
        case dominant, strong, competitive, struggling
        
        var color: Color {
            switch self {
            case .dominant: return .purple
            case .strong: return .green
            case .competitive: return .blue
            case .struggling: return .red
            }
        }
        
        var label: String {
            switch self {
            case .dominant: return "Dominant"
            case .strong: return "Strong"
            case .competitive: return "Competitive"
            case .struggling: return "Struggling"
            }
        }
        
        var emoji: String {
            switch self {
            case .dominant: return "👑"
            case .strong: return "💪"
            case .competitive: return "⚔️"
            case .struggling: return "😅"
            }
        }
    }
}

struct ManagerH2HStats {
    let totalGames: Int
    let totalWins: Int
    let totalDraws: Int
    let totalLosses: Int
    let winPercentage: Double
    let totalPointsFor: Int
    let totalPointsAgainst: Int
    let avgPointsFor: Double
    let avgPointsAgainst: Double
    let bestMatchup: String?
    let worstMatchup: String?
    let dominantWins: Int
    let strugglingAgainst: Int
    
    var overallDominance: DisplayRecord.Dominance {
        if winPercentage >= 80 { return .dominant }
        else if winPercentage >= 60 { return .strong }
        else if winPercentage >= 40 { return .competitive }
        else { return .struggling }
    }
}

// MARK: - Supporting Views

struct ManagerSelectorView: View {
    let managers: [ManagerInfo]
    @Binding var selectedManagerId: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(Color("FplPrimary"))
                
                Text("Select Manager")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if selectedManagerId != nil {
                    Button("Clear") {
                        withAnimation {
                            selectedManagerId = nil
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(managers) { manager in
                        ManagerSelectorCard(
                            manager: manager,
                            isSelected: selectedManagerId == manager.id,
                            action: {
                                withAnimation(.spring()) {
                                    selectedManagerId = manager.id
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom)
    }
}

struct ManagerSelectorCard: View {
    let manager: ManagerInfo
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isSelected ? [Color("FplPrimary"), Color("FplAccent")] : [Color("FplSurface"), Color("FplBackground")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Text(String(manager.name.prefix(2)).uppercased())
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .white : Color("FplTextPrimary"))
                }
                
                Text(manager.name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? Color("FplPrimary") : Color("FplTextSecondary"))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 70)
            }
            .padding(.vertical, 8)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ManagerStatsOverview: View {
    let managerName: String
    let stats: ManagerH2HStats
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(managerName)'s Record")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text(stats.overallDominance.emoji)
                        Text(stats.overallDominance.label)
                            .font(.subheadline)
                            .foregroundColor(stats.overallDominance.color)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(alignment: .bottom, spacing: 2) {
                        Text(String(format: "%.0f", stats.winPercentage))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(stats.overallDominance.color)
                        
                        Text("%")
                            .font(.caption)
                            .foregroundColor(Color("FplTextSecondary"))
                            .padding(.bottom, 2)
                    }
                    
                    Text("win rate")
                        .font(.caption)
                        .foregroundColor(Color("FplTextSecondary"))
                }
            }
            
            // Win/Draw/Loss breakdown
            HStack(spacing: 16) {
                H2HStatBox(
                    title: "Wins",
                    value: "\(stats.totalWins)",
                    subtitle: "victories",
                    color: .green,
                    icon: "checkmark.circle.fill"
                )
                
                H2HStatBox(
                    title: "Draws",
                    value: "\(stats.totalDraws)",
                    subtitle: "draws",
                    color: .orange,
                    icon: "equal.circle.fill"
                )
                
                H2HStatBox(
                    title: "Losses",
                    value: "\(stats.totalLosses)",
                    subtitle: "defeats",
                    color: .red,
                    icon: "xmark.circle.fill"
                )
            }
            
            // Performance metrics
            VStack(spacing: 8) {
                HStack {
                    H2HMetricRow(
                        title: "Avg Points For",
                        value: String(format: "%.1f", stats.avgPointsFor),
                        icon: "plus.circle",
                        color: .blue
                    )
                    
                    H2HMetricRow(
                        title: "Avg Points Against",
                        value: String(format: "%.1f", stats.avgPointsAgainst),
                        icon: "minus.circle",
                        color: .red
                    )
                }
                
                if let best = stats.bestMatchup {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        
                        Text("Best vs: \(best)")
                            .font(.caption)
                        
                        Spacer()
                    }
                }
                
                if let worst = stats.worstMatchup {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        
                        Text("Struggles vs: \(worst)")
                            .font(.caption)
                        
                        Spacer()
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color("FplSurface"))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
}

struct H2HStatBox: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
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
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct H2HMetricRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(Color("FplTextSecondary"))
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

struct EnhancedH2HCard: View {
    let displayRecord: DisplayRecord
    let selectedManagerName: String
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Card Content
            HStack {
                // Opponent Info
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("vs")
                            .font(.caption)
                            .foregroundColor(Color("FplTextSecondary"))
                        
                        Text(displayRecord.opponentName)
                            .font(.headline)
                            .fontWeight(.bold)
                            .lineLimit(1)
                    }
                    
                    HStack {
                        Text(displayRecord.dominance.emoji)
                        Text(displayRecord.dominance.label)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(displayRecord.dominance.color.opacity(0.2))
                            .foregroundColor(displayRecord.dominance.color)
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                // W-D-L Record
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        RecordBadge(value: displayRecord.wins, label: "W", color: .green)
                        RecordBadge(value: displayRecord.draws, label: "D", color: .orange)
                        RecordBadge(value: displayRecord.losses, label: "L", color: .red)
                    }
                    
                    Text("\(String(format: "%.0f", displayRecord.winPercentage))% Win Rate")
                        .font(.caption2)
                        .foregroundColor(Color("FplTextSecondary"))
                }
                
                // Expand Arrow
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
                        // Points Comparison
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Points For")
                                    .font(.caption)
                                    .foregroundColor(Color("FplTextSecondary"))
                                
                                Text("\(displayRecord.pointsFor)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            
                            VStack(spacing: 4) {
                                Text("Difference")
                                    .font(.caption)
                                    .foregroundColor(Color("FplTextSecondary"))
                                
                                HStack {
                                    Image(systemName: displayRecord.pointsDifference >= 0 ? "arrow.up" : "arrow.down")
                                        .font(.caption)
                                    
                                    Text("\(abs(displayRecord.pointsDifference))")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(displayRecord.pointsDifference >= 0 ? .green : .red)
                            }
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Points Against")
                                    .font(.caption)
                                    .foregroundColor(Color("FplTextSecondary"))
                                
                                Text("\(displayRecord.pointsAgainst)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Biggest Results (if available)
                        if let biggestWin = displayRecord.originalRecord.biggestWin {
                            BigResultCard(
                                title: displayRecord.isFlipped ? "Biggest Loss" : "Biggest Win",
                                comparison: biggestWin,
                                isFlipped: displayRecord.isFlipped,
                                color: displayRecord.isFlipped ? .red : .green
                            )
                        }
                        
                        if let biggestLoss = displayRecord.originalRecord.biggestLoss {
                            BigResultCard(
                                title: displayRecord.isFlipped ? "Biggest Win" : "Biggest Loss",
                                comparison: biggestLoss,
                                isFlipped: displayRecord.isFlipped,
                                color: displayRecord.isFlipped ? .green : .red
                            )
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
}

struct RecordBadge: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(Color("FplTextSecondary"))
        }
        .frame(width: 30)
    }
}

struct BigResultCard: View {
    let title: String
    let comparison: GameweekComparison
    let isFlipped: Bool
    let color: Color
    
    var displayScore: String {
        if isFlipped {
            return "\(comparison.manager2Points) - \(comparison.manager1Points)"
        } else {
            return "\(comparison.manager1Points) - \(comparison.manager2Points)"
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Text("GW \(comparison.gameweek)")
                    .font(.caption2)
                    .foregroundColor(Color("FplTextSecondary"))
            }
            
            Spacer()
            
            Text(displayScore)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text("(+\(comparison.difference))")
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color.opacity(0.2))
                .foregroundColor(color)
                .cornerRadius(4)
        }
        .padding()
        .background(color.opacity(0.05))
        .cornerRadius(12)
    }
}

struct EmptyH2HState: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.2.circle")
                .font(.system(size: 80))
                .foregroundColor(Color("FplPrimary").opacity(0.3))
            
            VStack(spacing: 12) {
                Text("Select a Manager")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Choose a manager from the list above to see their head-to-head record against all other managers in the league")
                    .font(.subheadline)
                    .foregroundColor(Color("FplTextSecondary"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 8) {
                HStack(spacing: 16) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.green)
                    Text("Win/Loss records")
                        .font(.caption)
                }
                
                HStack(spacing: 16) {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.blue)
                    Text("Points comparisons")
                        .font(.caption)
                }
                
                HStack(spacing: 16) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                    Text("Best and worst performances")
                        .font(.caption)
                }
            }
            .foregroundColor(Color("FplTextSecondary"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

struct ManagerH2HDetailSheet: View {
    let managerName: String
    let stats: ManagerH2HStats
    let records: [DisplayRecord]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Detailed Stats
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Detailed Statistics")
                            .font(.headline)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            DetailStatCard(title: "Total Games", value: "\(stats.totalGames)", icon: "gamecontroller")
                            DetailStatCard(title: "Win Percentage", value: "\(String(format: "%.1f", stats.winPercentage))%", icon: "percent")
                            DetailStatCard(title: "Total Points", value: "\(stats.totalPointsFor)", icon: "sum")
                            DetailStatCard(title: "Points Difference", value: "\(stats.totalPointsFor - stats.totalPointsAgainst)", icon: "plus.minus")
                        }
                    }
                    
                    // Performance Breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Performance Breakdown")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            if stats.dominantWins > 0 {
                                HStack {
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.purple)
                                    Text("Dominant matchups: \(stats.dominantWins)")
                                        .font(.subheadline)
                                    Spacer()
                                }
                            }
                            
                            if stats.strugglingAgainst > 0 {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text("Struggling against: \(stats.strugglingAgainst)")
                                        .font(.subheadline)
                                    Spacer()
                                }
                            }
                        }
                    }
                    
                    // All Matchups
                    VStack(alignment: .leading, spacing: 12) {
                        Text("All Matchups")
                            .font(.headline)
                        
                        ForEach(records, id: \.originalRecord.id) { record in
                            CompactH2HRow(record: record)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("\(managerName) Stats")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct DetailStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color("FplPrimary"))
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(Color("FplTextSecondary"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color("FplSurface"))
        .cornerRadius(12)
    }
}

struct CompactH2HRow: View {
    let record: DisplayRecord
    
    var body: some View {
        HStack {
            Text(record.opponentName)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("\(record.wins)-\(record.draws)-\(record.losses)")
                .font(.caption)
                .foregroundColor(Color("FplTextSecondary"))
            
            Text("\(String(format: "%.0f", record.winPercentage))%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(record.dominance.color)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color("FplBackground"))
        .cornerRadius(8)
    }
}
