import SwiftUI

struct EnhancedUnderperformerCard: View {
    let analysis: UnderperformerAnalysis
    let isExpanded: Bool
    let onTap: () -> Void
    let onPlayerTap: (PlayerData) -> Void
    
    var performanceSummary: String {
        let count = analysis.underperformers.count
        if count == 0 { return "🎯 Great picks!" }
        else if count <= 2 { return "👍 Mostly good choices" }
        else if count <= 5 { return "😐 Some disappointments" }
        else if count <= 8 { return "😰 Several letdowns" }
        else { return "😱 Tough season" }
    }
    
    var averagePointsPerGame: Double {
        guard !analysis.underperformers.isEmpty else { return 0 }
        let totalAvg = analysis.underperformers.map { $0.avgPointsPerGame }.reduce(0, +)
        return totalAvg / Double(analysis.underperformers.count)
    }
    
    var totalPointsLost: Int {
        // Estimate points lost compared to expected performance (5 pts/game for attackers, 4 for others)
        analysis.underperformers.map { player in
            let expected = player.player.elementType >= 3 ? 5.0 : 4.0
            let lost = (expected - player.avgPointsPerGame) * Double(player.gamesOwned)
            return max(0, Int(lost))
        }.reduce(0, +)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(analysis.managerName)
                        .font(.headline)
                        .foregroundColor(Color("FplTextPrimary"))
                    
                    if let worst = analysis.worstPerformer {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.thumbsdown.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                            
                            Text("Worst: \(worst.player.displayName)")
                                .font(.caption)
                                .foregroundColor(Color("FplTextSecondary"))
                            
                            Text("(\(String(format: "%.1f", worst.avgPointsPerGame)) pts/gw)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    Text(performanceSummary)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(alignment: .bottom, spacing: 2) {
                        Text("\(analysis.underperformers.count)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        Text("players")
                            .font(.caption)
                            .foregroundColor(Color("FplTextSecondary"))
                            .padding(.bottom, 4)
                    }
                    
                    Text("underperformed")
                        .font(.caption)
                        .foregroundColor(Color("FplTextSecondary"))
                    
                    if totalPointsLost > 0 {
                        Text("~\(totalPointsLost) pts lost")
                            .font(.caption2)
                            .foregroundColor(.red)
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
                    
                    VStack(spacing: 16) {
                        // Summary Stats
                        HStack(spacing: 16) {
                            SummaryStatBox(
                                title: "Avg Points",
                                value: String(format: "%.1f", averagePointsPerGame),
                                subtitle: "per game",
                                color: .orange
                            )
                            
                            SummaryStatBox(
                                title: "Games Owned",
                                value: "\(analysis.underperformers.map { $0.gamesOwned }.reduce(0, +))",
                                subtitle: "total",
                                color: .blue
                            )
                            
                            SummaryStatBox(
                                title: "Benched",
                                value: "\(analysis.underperformers.map { $0.benchedGames }.reduce(0, +))",
                                subtitle: "games",
                                color: .purple
                            )
                        }
                        .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Underperforming Players")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Text("Sorted by avg pts/game")
                                    .font(.caption2)
                                    .foregroundColor(Color("FplTextSecondary"))
                            }
                            
                            ForEach(analysis.underperformers.sorted { $0.avgPointsPerGame < $1.avgPointsPerGame }.prefix(5)) { underperformer in
                                EnhancedUnderperformerRow(
                                    underperformer: underperformer,
                                    onTap: { onPlayerTap(underperformer.player) }
                                )
                            }
                            
                            if analysis.underperformers.count > 5 {
                                Text("+ \(analysis.underperformers.count - 5) more underperformers")
                                    .font(.caption)
                                    .foregroundColor(Color("FplTextSecondary"))
                                    .padding(.top, 8)
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
}

struct SummaryStatBox: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(Color("FplTextSecondary"))
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(Color("FplTextSecondary"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct EnhancedUnderperformerRow: View {
    let underperformer: UnderperformingPlayer
    let onTap: () -> Void
    
    var benchPercentage: Double {
        guard underperformer.gamesOwned > 0 else { return 0 }
        return Double(underperformer.benchedGames) / Double(underperformer.gamesOwned) * 100
    }
    
    var expectedPoints: Double {
        // Expected points based on position
        switch underperformer.player.elementType {
        case 1: return 3.5 // GKP
        case 2: return 4.0 // DEF
        case 3: return 5.0 // MID
        case 4: return 5.5 // FWD
        default: return 4.0
        }
    }
    
    var performanceContext: String {
        let ratio = underperformer.avgPointsPerGame / expectedPoints
        if ratio < 0.3 { return "Disaster pick 😱" }
        else if ratio < 0.5 { return "Major disappointment 😔" }
        else if ratio < 0.7 { return "Below expectations 📉" }
        else if ratio < 0.9 { return "Slightly underperformed 😐" }
        else { return "Not too bad 🤷" }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                HStack {
                    // Position Badge
                    PositionBadge(position: underperformer.player.elementType)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(underperformer.player.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color("FplTextPrimary"))
                        
                        HStack(spacing: 8) {
                            Label("\(underperformer.gamesOwned) games", systemImage: "gamecontroller")
                                .font(.caption2)
                            
                            if underperformer.benchedGames > 0 {
                                Label("\(underperformer.benchedGames) benched", systemImage: "chair")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                        .foregroundColor(Color("FplTextSecondary"))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(alignment: .bottom, spacing: 2) {
                            Text(String(format: "%.1f", underperformer.avgPointsPerGame))
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            
                            Text("pts/gw")
                                .font(.caption2)
                                .foregroundColor(Color("FplTextSecondary"))
                        }
                        
                        Text(underperformer.performanceRating.label)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(underperformer.performanceRating.color).opacity(0.2))
                            .foregroundColor(Color(underperformer.performanceRating.color))
                            .cornerRadius(4)
                    }
                }
                
                // Performance Context Bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(performanceContext)
                            .font(.caption2)
                            .foregroundColor(Color("FplTextSecondary"))
                        
                        Spacer()
                        
                        Text("Expected: \(String(format: "%.1f", expectedPoints)) pts/gw")
                            .font(.caption2)
                            .foregroundColor(Color("FplTextSecondary"))
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            Rectangle()
                                .fill(Color("FplSurface"))
                                .frame(height: 4)
                                .cornerRadius(2)
                            
                            // Actual performance
                            Rectangle()
                                .fill(Color.orange)
                                .frame(width: geometry.size.width * min(underperformer.avgPointsPerGame / expectedPoints, 1.0), height: 4)
                                .cornerRadius(2)
                            
                            // Expected line
                            Rectangle()
                                .fill(Color.green.opacity(0.5))
                                .frame(width: 2, height: 8)
                                .offset(x: geometry.size.width - 1)
                        }
                    }
                    .frame(height: 8)
                }
                
                // Additional Context
                if underperformer.pointsWhileOwned > 0 {
                    HStack {
                        Label("\(underperformer.pointsWhileOwned) total points", systemImage: "sum")
                            .font(.caption2)
                            .foregroundColor(Color("FplTextSecondary"))
                        
                        Spacer()
                        
                        if benchPercentage > 20 {
                            Label("\(Int(benchPercentage))% benched", systemImage: "exclamationmark.triangle")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(Color("FplSurface"))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}


// Color Extension for Impact/Rating colors
extension Color {
    init(_ colorString: String) {
        switch colorString {
        case "red":
            self = .red
        case "orange":
            self = .orange
        case "yellow":
            self = .yellow
        case "green":
            self = .green
        case "blue":
            self = .blue
        case "purple":
            self = .purple
        case "gray":
            self = .gray
        default:
            self = .gray
        }
    }
}
