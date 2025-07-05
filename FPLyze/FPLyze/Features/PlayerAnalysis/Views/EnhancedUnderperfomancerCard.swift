//
//  EnhancedUnderperformerCard.swift
//  FPLyze
//
//  Enhanced underperformer analysis card with comprehensive comments
//  Shows players who disappointed while owned by the manager
//

import SwiftUI

/// Enhanced card displaying underperforming players analysis for a specific manager
/// Includes performance summaries, expandable details, and player interaction capabilities
struct EnhancedUnderperformerCard: View {
    // MARK: - Properties
    
    /// The underperformer analysis data for this manager
    let analysis: UnderperformerAnalysis
    
    /// Whether this card is currently expanded to show details
    let isExpanded: Bool
    
    /// Callback when the card is tapped (for expansion toggle)
    let onTap: () -> Void
    
    /// Callback when a specific player is tapped (for detail view)
    let onPlayerTap: (PlayerData) -> Void
    
    // MARK: - Computed Properties
    
    /// Overall performance summary based on underperformer count
    var performanceSummary: String {
        let count = analysis.underperformers.count
        if count == 0 { return "🎯 Great picks!" }
        else if count <= 2 { return "👍 Mostly good choices" }
        else if count <= 5 { return "😐 Some disappointments" }
        else if count <= 8 { return "😰 Several letdowns" }
        else { return "😱 Tough season" }
    }
    
    /// Average points per game across all underperforming players
    var averagePointsPerGame: Double {
        guard !analysis.underperformers.isEmpty else { return 0 }
        let totalAvg = analysis.underperformers.map { $0.avgPointsPerGame }.reduce(0, +)
        return totalAvg / Double(analysis.underperformers.count)
    }
    
    /// Estimated total points lost compared to expected performance
    var totalPointsLost: Int {
        // Estimate points lost compared to expected performance (5 pts/game for attackers, 4 for others)
        analysis.underperformers.map { player in
            let expected = player.player.elementType >= 3 ? 5.0 : 4.0
            let lost = (expected - player.avgPointsPerGame) * Double(player.gamesOwned)
            return max(0, Int(lost))
        }.reduce(0, +)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Card Header Section
            cardHeader
            
            // MARK: - Expanded Content Section
            if isExpanded {
                expandedContent
            }
        }
        .background(Color("FplSurface"))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    // MARK: - Card Header
    
    /// Header section with manager info, summary, and key metrics
    private var cardHeader: some View {
        HStack {
            // MARK: - Manager Information Section
            VStack(alignment: .leading, spacing: 6) {
                // Manager name
                Text(analysis.managerName)
                    .font(.headline)
                    .foregroundColor(Color("FplTextPrimary"))
                
                // Worst performer highlight (if available)
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
                
                // Performance summary badge
                Text(performanceSummary)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
            }
            
            Spacer()
            
            // MARK: - Metrics Summary Section
            VStack(alignment: .trailing, spacing: 4) {
                // Primary metric - number of underperformers
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
                
                // Secondary metric - estimated points lost
                if totalPointsLost > 0 {
                    Text("~\(totalPointsLost) pts lost")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            
            // MARK: - Expansion Indicator
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .foregroundColor(Color("FplTextSecondary"))
                .font(.caption)
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
    
    // MARK: - Expanded Content
    
    /// Detailed content shown when card is expanded
    private var expandedContent: some View {
        VStack(spacing: 0) {
            Divider()
            
            VStack(spacing: 16) {
                // MARK: - Summary Statistics Row
                summaryStatsRow
                
                // MARK: - Underperforming Players List
                underperformingPlayersList
            }
            .padding()
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // MARK: - Summary Stats Row
    
    /// Row of summary statistics boxes
    private var summaryStatsRow: some View {
        HStack(spacing: 16) {
            // Average points per game
            SummaryStatBox(
                title: "Avg Points",
                value: String(format: "%.1f", averagePointsPerGame),
                subtitle: "per game",
                color: .orange
            )
            
            // Total games owned across all underperformers
            SummaryStatBox(
                title: "Games Owned",
                value: "\(analysis.underperformers.map { $0.gamesOwned }.reduce(0, +))",
                subtitle: "total",
                color: .blue
            )
            
            // Total games benched
            SummaryStatBox(
                title: "Benched",
                value: "\(analysis.underperformers.map { $0.benchedGames }.reduce(0, +))",
                subtitle: "games",
                color: .purple
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - Underperforming Players List
    
    /// List of underperforming players with details
    private var underperformingPlayersList: some View {
        VStack(spacing: 12) {
            // Section header
            HStack {
                Text("Underperforming Players")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("Sorted by avg pts/game")
                    .font(.caption2)
                    .foregroundColor(Color("FplTextSecondary"))
            }
            
            // Display top 5 underperformers (sorted by worst performance first)
            ForEach(analysis.underperformers.sorted { $0.avgPointsPerGame < $1.avgPointsPerGame }.prefix(5)) { underperformer in
                EnhancedUnderperformerRow(
                    underperformer: underperformer,
                    onTap: { onPlayerTap(underperformer.player) }
                )
            }
            
            // "Show more" indicator if there are additional underperformers
            if analysis.underperformers.count > 5 {
                Text("+ \(analysis.underperformers.count - 5) more underperformers")
                    .font(.caption)
                    .foregroundColor(Color("FplTextSecondary"))
                    .padding(.top, 8)
            }
        }
    }
}

// MARK: - Summary Stat Box Component

/// Individual summary statistic display box
struct SummaryStatBox: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            // Title
            Text(title)
                .font(.caption2)
                .foregroundColor(Color("FplTextSecondary"))
            
            // Value
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            // Subtitle
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

// MARK: - Enhanced Underperformer Row

/// Individual row displaying an underperforming player with detailed metrics
struct EnhancedUnderperformerRow: View {
    // MARK: - Properties
    
    /// The underperforming player data
    let underperformer: UnderperformingPlayer
    
    /// Callback when the row is tapped
    let onTap: () -> Void
    
    // MARK: - Computed Properties
    
    /// Percentage of games this player was benched
    var benchPercentage: Double {
        guard underperformer.gamesOwned > 0 else { return 0 }
        return Double(underperformer.benchedGames) / Double(underperformer.gamesOwned) * 100
    }
    
    /// Expected points per game based on player position
    var expectedPoints: Double {
        // Expected points based on position
        switch underperformer.player.elementType {
        case 1: return 3.5 // GKP - Goalkeepers
        case 2: return 4.0 // DEF - Defenders
        case 3: return 5.0 // MID - Midfielders
        case 4: return 5.5 // FWD - Forwards
        default: return 4.0
        }
    }
    
    /// Contextual description of performance relative to expectations
    var performanceContext: String {
        let ratio = underperformer.avgPointsPerGame / expectedPoints
        if ratio < 0.3 { return "Disaster pick 😱" }
        else if ratio < 0.5 { return "Major disappointment 😔" }
        else if ratio < 0.7 { return "Below expectations 📉" }
        else if ratio < 0.9 { return "Slightly underperformed 😐" }
        else { return "Not too bad 🤷" }
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // MARK: - Main Player Information Row
                playerInfoRow
                
                // MARK: - Performance Context Bar
                performanceContextBar
                
                // MARK: - Additional Context Information
                additionalContextInfo
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(Color("FplSurface"))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Player Info Row
    
    /// Main row with player details and performance metrics
    private var playerInfoRow: some View {
        HStack {
            // Position badge
            PositionBadgeUnderPerfroming(position: underperformer.player.elementType)
            
            // Player details
            VStack(alignment: .leading, spacing: 4) {
                Text(underperformer.player.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color("FplTextPrimary"))
                
                // Ownership and bench stats
                HStack(spacing: 8) {
                    Label("\(underperformer.gamesOwned) games", systemImage: "gamecontroller")
                        .font(.caption2)
                    
                    // Show bench info if player was benched significantly
                    if underperformer.benchedGames > 0 {
                        Label("\(underperformer.benchedGames) benched", systemImage: "chair")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                .foregroundColor(Color("FplTextSecondary"))
            }
            
            Spacer()
            
            // Performance metrics
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
                
                // Performance rating badge
                Text(underperformer.performanceRating.label)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(underperformer.performanceRating.color).opacity(0.2))
                    .foregroundColor(Color(underperformer.performanceRating.color))
                    .cornerRadius(4)
            }
        }
    }
    
    // MARK: - Performance Context Bar
    
    /// Visual bar showing performance relative to expectations
    private var performanceContextBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Context labels
            HStack {
                Text(performanceContext)
                    .font(.caption2)
                    .foregroundColor(Color("FplTextSecondary"))
                
                Spacer()
                
                Text("Expected: \(String(format: "%.1f", expectedPoints)) pts/gw")
                    .font(.caption2)
                    .foregroundColor(Color("FplTextSecondary"))
            }
            
            // Visual performance bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(Color("FplSurface"))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    // Actual performance fill
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: geometry.size.width * min(underperformer.avgPointsPerGame / expectedPoints, 1.0), height: 4)
                        .cornerRadius(2)
                    
                    // Expected performance line
                    Rectangle()
                        .fill(Color.green.opacity(0.5))
                        .frame(width: 2, height: 8)
                        .offset(x: geometry.size.width - 1)
                }
            }
            .frame(height: 8)
        }
    }
    
    // MARK: - Additional Context Info
    
    /// Additional contextual information about the player's ownership
    private var additionalContextInfo: some View {
        Group {
            if underperformer.pointsWhileOwned > 0 {
                HStack {
                    // Total points scored while owned
                    Label("\(underperformer.pointsWhileOwned) total points", systemImage: "sum")
                        .font(.caption2)
                        .foregroundColor(Color("FplTextSecondary"))
                    
                    Spacer()
                    
                    // Bench warning if heavily benched
                    if benchPercentage > 20 {
                        Label("\(Int(benchPercentage))% benched", systemImage: "exclamationmark.triangle")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
    }
}

// MARK: - Position Badge Component (if not already defined)

/// Displays player position with color coding
struct PositionBadgeUnderPerfroming: View {
    let position: Int
    
    /// Position abbreviation text
    var positionText: String {
        switch position {
        case 1: return "GKP"  // Goalkeeper
        case 2: return "DEF"  // Defender
        case 3: return "MID"  // Midfielder
        case 4: return "FWD"  // Forward
        default: return "???"
        }
    }
    
    /// Color coding for each position
    var positionColor: Color {
        switch position {
        case 1: return .orange  // Goalkeeper
        case 2: return .green   // Defender
        case 3: return .blue    // Midfielder
        case 4: return .purple  // Forward
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

// MARK: - Color Helper Function

/// Converts string color names to SwiftUI Color objects
/// Used for performance rating colors
func colorForString(_ colorString: String) -> Color {
    switch(colorString){
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "gray": return .gray
        default: return .gray
    }
}
