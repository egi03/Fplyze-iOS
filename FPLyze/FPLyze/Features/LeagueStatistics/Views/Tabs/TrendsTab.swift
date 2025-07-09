//
//  TrendsTab.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 21.06.2025..
//

import SwiftUI
import Charts

struct TrendsTab: View {
    let members: [LeagueMember]
    @State private var selectedMembers: Set<Int> = []
    @State private var chartType: ChartType = .cumulativePoints
    
    enum ChartType: String, CaseIterable {
        case cumulativePoints = "Total Points"
        case leagueRank = "League Rank"
        case gameweekPoints = "GW Points"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed header section
            VStack(spacing: 0) {
                Picker("Chart Type", selection: $chartType) {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(members.prefix(10)) { member in
                            MemberChip(
                                name: member.playerName,
                                isSelected: selectedMembers.contains(member.id),
                                color: colorForMember(member.id),
                                action: {
                                    if selectedMembers.contains(member.id) {
                                        selectedMembers.remove(member.id)
                                    } else {
                                        selectedMembers.insert(member.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
            }
            .background(Color("FplBackground"))
            
            // Scrollable content section
            if selectedMembers.isEmpty {
                EmptyChartView()
            } else {
                ScrollView {
                    EnhancedChartView(
                        members: members.filter { selectedMembers.contains($0.id) },
                        chartType: chartType
                    )
                    .padding(.bottom, 20) // Extra bottom padding
                }
            }
        }
        .background(Color("FplBackground"))
    }
    
    private func colorForMember(_ id: Int) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .red, .pink]
        return colors[id % colors.count]
    }
}

struct EnhancedChartView: View {
    let members: [LeagueMember]
    let chartType: TrendsTab.ChartType
    
    var body: some View {
        VStack(spacing: 16) {
            // Chart Title and Info
            VStack(spacing: 8) {
                Text(chartTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(chartDescription)
                    .font(.caption)
                    .foregroundColor(Color("FplTextSecondary"))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            // Main Chart
            Chart {
                ForEach(members) { member in
                    ForEach(Array(member.gameweekHistory.enumerated()), id: \.element.id) { index, gw in
                        LineMark(
                            x: .value("Gameweek", gw.event),
                            y: .value(yAxisLabel, yValue(for: gw)),
                            series: .value("Manager", member.playerName)
                        )
                        .foregroundStyle(by: .value("Manager", member.playerName))
                        .symbol(by: .value("Manager", member.playerName))
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                    }
                }
            }
            .chartXAxisLabel("Gameweek")
            .chartYAxisLabel(yAxisLabel)
            .chartYScale(domain: yAxisDomain)
            .frame(height: 300)
            .padding()
            .background(Color("FplSurface"))
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.1), radius: 5)
            
            // Chart Legend and Stats
            chartLegendAndStats
        }
        .padding()
    }
    
    private var chartTitle: String {
        switch chartType {
        case .cumulativePoints:
            return "Cumulative Points Progress"
        case .leagueRank:
            return "League Rank Progression"
        case .gameweekPoints:
            return "Gameweek Points Progression"
        }
    }
    
    private var chartDescription: String {
        switch chartType {
        case .cumulativePoints:
            return "Track total points accumulated over the season"
        case .leagueRank:
            return "Monitor position changes within your league (lower is better)"
        case .gameweekPoints:
            return "Individual gameweek scoring patterns throughout the season"
        }
    }
    
    private var yAxisLabel: String {
        switch chartType {
        case .cumulativePoints:
            return "Total Points"
        case .leagueRank:
            return "League Position"
        case .gameweekPoints:
            return "Points"
        }
    }
    
    private var yAxisDomain: ClosedRange<Double> {
        switch chartType {
        case .cumulativePoints:
            let maxPoints = members.flatMap { $0.gameweekHistory }.map { $0.totalPoints }.max() ?? 1000
            return 0...Double(maxPoints + 100)
        case .leagueRank:
            // For league rank, we want to show from 1 to the max league size
            let maxRank = members.flatMap { $0.gameweekHistory }.map { $0.rank }.max() ?? 20
            return 1...Double(maxRank)
        case .gameweekPoints:
            // For gameweek points, show reasonable range
            let maxGWPoints = members.flatMap { $0.gameweekHistory }.map { $0.points }.max() ?? 100
            return 0...Double(maxGWPoints + 20)
        }
    }
    
    private func yValue(for gw: GameweekPerformance) -> Double {
        switch chartType {
        case .cumulativePoints:
            return Double(gw.totalPoints)
        case .leagueRank:
            return Double(gw.rank)
        case .gameweekPoints:
            return Double(gw.points)
        }
    }
    
    private var chartLegendAndStats: some View {
        VStack(spacing: 12) {
            // Performance Summary
            HStack {
                Text("Performance Summary")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(members) { member in
                    MemberPerformanceCard(member: member, chartType: chartType)
                }
            }
        }
        .padding()
        .background(Color("FplSurface"))
        .cornerRadius(12)
    }
}

struct MemberPerformanceCard: View {
    let member: LeagueMember
    let chartType: TrendsTab.ChartType
    
    var performanceStats: (current: String, trend: String, trendColor: Color) {
        let history = member.gameweekHistory
        guard !history.isEmpty else { return ("N/A", "No data", .gray) }
        
        let latest = history.last!
        
        switch chartType {
        case .cumulativePoints:
            let totalPoints = latest.totalPoints
            let avgPerGW = Double(totalPoints) / Double(history.count)
            return (
                "\(totalPoints) pts",
                String(format: "%.1f pts/GW", avgPerGW),
                avgPerGW > 50 ? .green : avgPerGW > 40 ? .orange : .red
            )
            
        case .leagueRank:
            let currentRank = latest.rank
            let trend = calculateRankTrend(history: history, useLeagueRank: true)
            return (
                "Position \(currentRank)",
                trend.description,
                trend.color
            )
            
        case .gameweekPoints:
            let recentPoints = latest.points
            let avgPoints = calculateAverageGameweekPoints(history: history)
            let trend = calculatePointsTrend(history: history)
            return (
                "\(recentPoints) pts",
                String(format: "Avg: %.1f", avgPoints),
                trend.color
            )
        }
    }
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Circle()
                    .fill(colorForMember(member.id))
                    .frame(width: 12, height: 12)
                
                Text(member.playerName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(performanceStats.current)
                    .font(.caption)
                    .fontWeight(.bold)
                
                Text(performanceStats.trend)
                    .font(.caption2)
                    .foregroundColor(performanceStats.trendColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color("FplCardBackground"))
        .cornerRadius(8)
    }
    
    private func colorForMember(_ id: Int) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .red, .pink]
        return colors[id % colors.count]
    }
    
    private func calculateRankTrend(history: [GameweekPerformance], useLeagueRank: Bool) -> (description: String, color: Color) {
        guard history.count >= 2 else { return ("No trend data", .gray) }
        
        let recentGames = Array(history.suffix(5)) // Look at last 5 gameweeks
        let rankValues = recentGames.map { useLeagueRank ? $0.rank : $0.overallRank }
        
        let firstRank = rankValues.first!
        let lastRank = rankValues.last!
        let rankChange = firstRank - lastRank // Positive = improvement (rank went down)
        
        if rankChange > 0 {
            return ("📈 Rising (\(rankChange))", .green)
        } else if rankChange < 0 {
            return ("📉 Falling (\(abs(rankChange)))", .red)
        } else {
            return ("➡️ Stable", .blue)
        }
    }
    
    private func calculateAverageGameweekPoints(history: [GameweekPerformance]) -> Double {
        guard !history.isEmpty else { return 0 }
        let totalPoints = history.map { $0.points }.reduce(0, +)
        return Double(totalPoints) / Double(history.count)
    }
    
    private func calculatePointsTrend(history: [GameweekPerformance]) -> (description: String, color: Color) {
        guard history.count >= 3 else { return ("No trend data", .gray) }
        
        let recentGames = Array(history.suffix(3))
        let points = recentGames.map { $0.points }
        
        let firstHalf = Array(points.prefix(points.count / 2))
        let secondHalf = Array(points.suffix(points.count - points.count / 2))
        
        let firstAvg = Double(firstHalf.reduce(0, +)) / Double(firstHalf.count)
        let secondAvg = Double(secondHalf.reduce(0, +)) / Double(secondHalf.count)
        
        let difference = secondAvg - firstAvg
        
        if difference > 5 {
            return ("📈 Improving form", .green)
        } else if difference < -5 {
            return ("📉 Declining form", .red)
        } else {
            return ("➡️ Steady form", .blue)
        }
    }
}

// Update the EmptyChartView to be more informative
struct EmptyChartView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("Select Managers to View Trends")
                    .font(.headline)
                    .foregroundColor(Color("FplTextSecondary"))
                
                Text("Choose managers from the list above to compare their performance trends throughout the season")
                    .font(.subheadline)
                    .foregroundColor(Color("FplTextSecondary"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 6) {
                HStack(spacing: 12) {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.blue)
                    Text("Track points accumulation")
                        .font(.caption)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundColor(.green)
                    Text("Monitor rank changes")
                        .font(.caption)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.orange)
                    Text("Compare performance")
                        .font(.caption)
                }
            }
            .foregroundColor(Color("FplTextSecondary"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}
