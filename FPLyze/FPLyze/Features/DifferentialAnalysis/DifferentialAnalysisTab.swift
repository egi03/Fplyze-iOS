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
                // Demo Banner
                DemoBanner()
                    .padding(.horizontal)
                
                // Header with league summary
                VStack(spacing: 16) {
                    DifferentialHeaderCard(
                        summary: leagueSummary,
                        onInfoClick: { showingInfoSheet = true }
                    )
                    
                    // Sort Options
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
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
                
                // Manager Analysis Cards
                if analyses.isEmpty {
                    EmptyDifferentialView()
                        .padding(.horizontal)
                } else {
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
