//
//  ChipsTab.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 21.06.2025..
//
import SwiftUI

import SwiftUI

struct ChipsTab: View {
    let members: [LeagueMember]
    @State private var selectedChip: ChipType = .benchBoost
    @State private var showingDetail = false
    @State private var selectedUsage: ChipUsage?
    @State private var showingInfoSheet = false
    
    @Environment(\.presentationMode) var presentationMode
    
    var chipUsageByType: [ChipType: [(LeagueMember, ChipUsage)]] {
        var grouped: [ChipType: [(LeagueMember, ChipUsage)]] = [:]
        
        for member in members {
            for chip in member.chips {
                if let chipType = ChipType(rawValue: chip.name) {
                    if grouped[chipType] == nil {
                        grouped[chipType] = []
                    }
                    grouped[chipType]?.append((member, chip))
                }
            }
        }
        
        for (key, value) in grouped {
            grouped[key] = value.sorted { $0.1.points > $1.1.points }
        }
        
        return grouped
    }
    
    var selectedChipUsage: [(LeagueMember, ChipUsage)] {
        chipUsageByType[selectedChip] ?? []
    }
    
    var chipStats: ChipStatistics {
        let usage = selectedChipUsage
        let totalUses = usage.count
        let totalPoints = usage.map { $0.1.points }.reduce(0, +)
        let averagePoints = totalUses > 0 ? Double(totalPoints) / Double(totalUses) : 0
        let bestScore = usage.map { $0.1.points }.max() ?? 0
        
        return ChipStatistics(
            totalUses: totalUses,
            averagePoints: averagePoints,
            bestScore: bestScore
        )
    }
    
    var unusedChipsCount: Int {
        let totalPossibleChips = members.count * 4 // 4 chips per manager
        let usedChips = members.map { $0.chips.count }.reduce(0, +)
        return totalPossibleChips - usedChips
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header Section (now scrollable)
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Chip Analysis")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Special power usage and effectiveness")
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
                    
                    // Chip Selector with enhanced visuals
                    EnhancedChipSelector(
                        selectedChip: $selectedChip,
                        chipUsage: chipUsageByType,
                        totalMembers: members.count
                    )
                    
                    // League Overview Card
                    ChipLeagueOverview(
                        totalMembers: members.count,
                        chipUsage: chipUsageByType,
                        unusedChips: unusedChipsCount
                    )
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
                .background(Color.white)
                .cornerRadius(15)
                .shadow(color: .black.opacity(0.05), radius: 5, y: 5)
                .padding(.horizontal)
                
                // Main Content
                VStack(spacing: 16) {
                    // Enhanced Overview Card
                    EnhancedChipOverviewCard(
                        chipType: selectedChip,
                        stats: chipStats,
                        totalMembers: members.count
                    )
                    .padding(.horizontal)
                    
                    // Usage Timeline with context
                    if !selectedChipUsage.isEmpty {
                        EnhancedChipTimelineView(
                            chipUsage: selectedChipUsage,
                            chipType: selectedChip
                        )
                        .padding(.horizontal)
                    }
                    
                    // Usage Quality Distribution
                    if !selectedChipUsage.isEmpty {
                        ChipQualityDistribution(
                            chipUsage: selectedChipUsage,
                            chipType: selectedChip
                        )
                    }
                    
                    // Individual Usage List
                    if selectedChipUsage.isEmpty {
                        EmptyChipView(chipType: selectedChip)
                            .padding(.horizontal)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Individual Usage")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(selectedChipUsage, id: \.1.id) { member, usage in
                                EnhancedChipUsageCard(
                                    member: member,
                                    usage: usage,
                                    chipType: selectedChip,
                                    averageScore: chipStats.averagePoints,
                                    onTap: {
                                        selectedUsage = usage
                                        showingDetail = true
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
        .sheet(isPresented: $showingInfoSheet) {
            ChipsInfoSheet()
        }
    }
}

struct EnhancedChipSelector: View {
    @Binding var selectedChip: ChipType
    let chipUsage: [ChipType: [(LeagueMember, ChipUsage)]]
    let totalMembers: Int
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(ChipType.allCases, id: \.self) { chip in
                    EnhancedChipButton(
                        chip: chip,
                        isSelected: selectedChip == chip,
                        count: chipUsage[chip]?.count ?? 0,
                        totalPossible: totalMembers,
                        action: { selectedChip = chip }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

struct EnhancedChipButton: View {
    let chip: ChipType
    let isSelected: Bool
    let count: Int
    let totalPossible: Int
    let action: () -> Void
    
    var usagePercentage: Double {
        guard totalPossible > 0 else { return 0 }
        return Double(count) / Double(totalPossible) * 100
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isSelected ? [chip.color, chip.color.opacity(0.7)] : [chip.color.opacity(0.2), chip.color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: chip.icon)
                        .foregroundColor(isSelected ? .white : chip.color)
                        .font(.title2)
                }
                
                VStack(spacing: 4) {
                    Text(chip.displayName)
                        .font(.caption)
                        .fontWeight(isSelected ? .bold : .regular)
                    
                    if count > 0 {
                        Text("\(count)/\(totalPossible)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("\(Int(usagePercentage))% used")
                            .font(.caption2)
                            .foregroundColor(chip.color)
                    } else {
                        Text("Not used")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .foregroundColor(isSelected ? chip.color : .primary)
        }
    }
}

struct ChipLeagueOverview: View {
    let totalMembers: Int
    let chipUsage: [ChipType: [(LeagueMember, ChipUsage)]]
    let unusedChips: Int
    
    var totalChipsUsed: Int {
        chipUsage.values.map { $0.count }.reduce(0, +)
    }
    
    var body: some View {
        HStack(spacing: 20) {
            OverviewStat(
                title: "Total Used",
                value: "\(totalChipsUsed)",
                subtitle: "across all types",
                icon: "star.circle.fill",
                color: .blue
            )
            
            OverviewStat(
                title: "Unused",
                value: "\(unusedChips)",
                subtitle: "chips remaining",
                icon: "hourglass",
                color: .orange
            )
            
            OverviewStat(
                title: "Managers",
                value: "\(totalMembers)",
                subtitle: "in league",
                icon: "person.3.fill",
                color: .green
            )
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct OverviewStat: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct EnhancedChipOverviewCard: View {
    let chipType: ChipType
    let stats: ChipStatistics
    let totalMembers: Int
    
    var chipStrategy: String {
        switch chipType {
        case .benchBoost:
            return "Play when your bench has high-scoring players"
        case .tripleCaptain:
            return "Use on premium players with favorable fixtures"
        case .freeHit:
            return "Perfect for blank or double gameweeks"
        case .wildcard:
            return "Rebuild your team when needed"
        }
    }
    
    var effectivenessRating: String {
        guard stats.totalUses > 0 else { return "No data" }
        
        switch chipType {
        case .benchBoost:
            if stats.averagePoints > 20 { return "🔥 Excellent timing" }
            else if stats.averagePoints > 15 { return "✅ Good usage" }
            else { return "📊 Average results" }
        case .tripleCaptain:
            if stats.averagePoints > 80 { return "🎯 Perfect picks" }
            else if stats.averagePoints > 60 { return "👍 Solid choices" }
            else { return "🤔 Mixed results" }
        default:
            if stats.averagePoints > 70 { return "⭐ Great performance" }
            else if stats.averagePoints > 50 { return "✓ Decent returns" }
            else { return "📈 Room to improve" }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with description
            HStack {
                Image(systemName: chipType.icon)
                    .font(.largeTitle)
                    .foregroundColor(chipType.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(chipType.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(chipStrategy)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }
            
            // Stats Grid with context
            HStack(spacing: 16) {
                EnhancedStatBox(
                    title: "Usage Rate",
                    value: "\(Int(Double(stats.totalUses) / Double(totalMembers) * 100))%",
                    subtitle: "\(stats.totalUses)/\(totalMembers) managers",
                    color: chipType.color
                )
                
                EnhancedStatBox(
                    title: "Average Return",
                    value: String(format: "%.1f pts", stats.averagePoints),
                    subtitle: effectivenessRating,
                    color: chipType.color
                )
                
                EnhancedStatBox(
                    title: "Best Usage",
                    value: "\(stats.bestScore) pts",
                    subtitle: stats.bestScore > 100 ? "🏆 League best!" : "Peak score",
                    color: chipType.color
                )
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [chipType.color.opacity(0.15), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
    }
}

struct EnhancedStatBox: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: color.opacity(0.2), radius: 5)
    }
}

struct ChipQualityDistribution: View {
    let chipUsage: [(LeagueMember, ChipUsage)]
    let chipType: ChipType
    
    var distribution: [String: Int] {
        var dist = ["Excellent": 0, "Good": 0, "Average": 0, "Poor": 0]
        
        for (_, usage) in chipUsage {
            switch chipType {
            case .benchBoost:
                if usage.points > 25 { dist["Excellent"]! += 1 }
                else if usage.points > 18 { dist["Good"]! += 1 }
                else if usage.points > 12 { dist["Average"]! += 1 }
                else { dist["Poor"]! += 1 }
            case .tripleCaptain:
                if usage.points > 90 { dist["Excellent"]! += 1 }
                else if usage.points > 60 { dist["Good"]! += 1 }
                else if usage.points > 40 { dist["Average"]! += 1 }
                else { dist["Poor"]! += 1 }
            default:
                if usage.points > 80 { dist["Excellent"]! += 1 }
                else if usage.points > 60 { dist["Good"]! += 1 }
                else if usage.points > 45 { dist["Average"]! += 1 }
                else { dist["Poor"]! += 1 }
            }
        }
        
        return dist
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Usage Quality Distribution")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                QualityBar(label: "🔥 Excellent", count: distribution["Excellent"] ?? 0, total: chipUsage.count, color: .green)
                QualityBar(label: "✅ Good", count: distribution["Good"] ?? 0, total: chipUsage.count, color: .blue)
                QualityBar(label: "📊 Average", count: distribution["Average"] ?? 0, total: chipUsage.count, color: .orange)
                QualityBar(label: "😔 Poor", count: distribution["Poor"] ?? 0, total: chipUsage.count, color: .red)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .padding(.horizontal)
        }
    }
}

struct QualityBar: View {
    let label: String
    let count: Int
    let total: Int
    let color: Color
    
    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total)
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .frame(width: 80, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 20)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 20)
                        .animation(.spring(), value: percentage)
                }
                .overlay(
                    Text("\(count)")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8),
                    alignment: .leading
                )
            }
            .frame(height: 20)
        }
    }
}

struct EnhancedChipTimelineView: View {
    let chipUsage: [(LeagueMember, ChipUsage)]
    let chipType: ChipType
    
    var usageByGameweek: [Int: Int] {
        var grouped: [Int: Int] = [:]
        for (_, usage) in chipUsage {
            grouped[usage.event, default: 0] += 1
        }
        return grouped
    }
    
    var popularGameweeks: [(gw: Int, count: Int)] {
        usageByGameweek
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { ($0.key, $0.value) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Usage Timeline")
                    .font(.headline)
                
                Spacer()
                
                if !popularGameweeks.isEmpty {
                    Text("Popular: GW\(popularGameweeks.map { String($0.gw) }.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(spacing: 8) {
                // Timeline visualization
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(1...38, id: \.self) { gw in
                        VStack {
                            if let count = usageByGameweek[gw], count > 0 {
                                Rectangle()
                                    .fill(chipType.color)
                                    .frame(width: 6, height: CGFloat(count * 15))
                                    .cornerRadius(3)
                                
                                if count > 2 {
                                    Text("\(count)")
                                        .font(.system(size: 8))
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Color.clear
                                    .frame(width: 6, height: 1)
                            }
                        }
                    }
                }
                .frame(height: 100)
                
                HStack {
                    Text("GW1")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("GW19")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("GW38")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
    }
}

struct EnhancedChipUsageCard: View {
    let member: LeagueMember
    let usage: ChipUsage
    let chipType: ChipType
    let averageScore: Double
    let onTap: () -> Void
    
    var effectiveness: ChipEffectiveness {
        let ratio = Double(usage.points) / averageScore
        
        if ratio > 1.3 { return .excellent }
        else if ratio > 1.0 { return .good }
        else if ratio > 0.7 { return .average }
        else { return .poor }
    }
    
    var performanceMessage: String {
        switch effectiveness {
        case .excellent:
            return "🔥 Way above average!"
        case .good:
            return "✅ Above average"
        case .average:
            return "📊 Around average"
        case .poor:
            return "😔 Below average"
        }
    }
    
    var timingQuality: String {
        // This would be better with actual gameweek average data
        switch chipType {
        case .benchBoost:
            if usage.benchBoost ?? 0 > 20 { return "Perfect timing!" }
            else if usage.benchBoost ?? 0 > 15 { return "Good timing" }
            else { return "Could be better" }
        default:
            if usage.points > 80 { return "Excellent week!" }
            else if usage.points > 60 { return "Good choice" }
            else { return "Tough week" }
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Rank indicator
                VStack {
                    Text("#\(chipUsage.firstIndex(where: { $0.1.id == usage.id }) ?? 0 + 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(effectiveness.color)
                }
                .frame(width: 30)
                
                // Manager Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(member.entryName)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Label(member.playerName, systemImage: "person.fill")
                            .font(.caption)
                        
                        Label("GW \(usage.event)", systemImage: "calendar")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    Text(timingQuality)
                        .font(.caption2)
                        .foregroundColor(chipType.color)
                }
                
                Spacer()
                
                // Points & Performance
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("\(usage.points)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(effectiveness.color)
                        
                        Text("pts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)
                    }
                    
                    Text(performanceMessage)
                        .font(.caption)
                        .foregroundColor(effectiveness.color)
                    
                    // Effectiveness Badge
                    Text(effectiveness.label)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(effectiveness.color.opacity(0.2))
                        .foregroundColor(effectiveness.color)
                        .cornerRadius(6)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                    .shadow(color: effectiveness.color.opacity(0.15), radius: 5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var chipUsage: [(LeagueMember, ChipUsage)] {
        // This is a workaround - in real implementation, pass this from parent
        []
    }
}

struct EmptyChipView: View {
    let chipType: ChipType
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: chipType.icon)
                .font(.system(size: 60))
                .foregroundColor(chipType.color.opacity(0.5))
            
            Text("No \(chipType.displayName) used yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("This chip hasn't been played by any manager in the league")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(60)
    }
}

struct ChipsInfoSheet: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Understanding Chips")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom)
                    
                    ForEach(ChipType.allCases, id: \.self) { chip in
                        ChipExplanation(chipType: chip)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Timing Tips")
                            .font(.headline)
                        
                        Text("""
                        • Bench Boost: Use during Double Gameweeks when all players play twice
                        • Triple Captain: Save for premium players with great fixtures
                        • Free Hit: Perfect for Blank Gameweeks or when many players are unavailable
                        • Wildcard: Use when your team needs major surgery
                        """)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationBarTitle("Chip Strategy", displayMode: .inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct ChipExplanation: View {
    let chipType: ChipType
    
    var scoreRanges: String {
        switch chipType {
        case .benchBoost:
            return "25+ excellent, 15-25 good, <15 average"
        case .tripleCaptain:
            return "90+ excellent, 60-90 good, <60 average"
        case .freeHit:
            return "80+ excellent, 60-80 good, <60 average"
        case .wildcard:
            return "70+ excellent, 50-70 good, <50 average"
        }
    }
    
    var strategy: String {
        switch chipType {
        case .benchBoost:
            return "All 15 players' points count. Best used when your bench has favorable fixtures."
        case .tripleCaptain:
            return "Captain scores triple points instead of double. Save for premium players in great form."
        case .freeHit:
            return "Make unlimited transfers for one week only. Team reverts next gameweek."
        case .wildcard:
            return "Make unlimited transfers without point hits. Changes are permanent."
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: chipType.icon)
                .font(.title2)
                .foregroundColor(chipType.color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(chipType.displayName)
                    .font(.headline)
                
                Text(strategy)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Label(scoreRanges, systemImage: "chart.bar.fill")
                    .font(.caption)
                    .foregroundColor(chipType.color)
            }
        }
        .padding(.vertical, 8)
    }
}
