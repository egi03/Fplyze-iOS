//
//  LeagueStatisticsData.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 21.06.2025..
//

import Foundation

struct LeagueStatisticsData {
    let leagueId: Int
    let leagueName: String
    let records: [LeagueRecord]
    let managerStatistics: [ManagerStatistics]
    let headToHeadStatistics: [HeadToHeadRecord]
    let members: [LeagueMember]
    let missedPlayerAnalyses: [MissedPlayerAnalysis]
    let underperformerAnalyses: [UnderperformerAnalysis]
    let differentialAnalyses: [DifferentialAnalysis]
    let whatIfScenarios: [WhatIfScenario]
    
    init(
        leagueId: Int,
        leagueName: String,
        records: [LeagueRecord],
        managerStatistics: [ManagerStatistics],
        headToHeadStatistics: [HeadToHeadRecord],
        members: [LeagueMember],
        missedPlayerAnalyses: [MissedPlayerAnalysis] = [],
        underperformerAnalyses: [UnderperformerAnalysis] = [],
        differentialAnalyses: [DifferentialAnalysis] = [],
        whatIfScenarios: [WhatIfScenario] = []
    ) {
        self.leagueId = leagueId
        self.leagueName = leagueName
        self.records = records
        self.managerStatistics = managerStatistics
        self.headToHeadStatistics = headToHeadStatistics
        self.members = members
        self.missedPlayerAnalyses = missedPlayerAnalyses
        self.underperformerAnalyses = underperformerAnalyses
        self.differentialAnalyses = differentialAnalyses
        self.whatIfScenarios = whatIfScenarios
    }
    
    // Convenience computed properties
    var hasAdvancedAnalysis: Bool {
        !differentialAnalyses.isEmpty || !whatIfScenarios.isEmpty
    }
    
    var totalDifferentials: Int {
        differentialAnalyses.map { $0.differentialPicks.count }.reduce(0, +)
    }
    
    var averageDifferentialSuccessRate: Double {
        guard !differentialAnalyses.isEmpty else { return 0 }
        let totalSuccessRate = differentialAnalyses.map { $0.differentialSuccessRate }.reduce(0, +)
        return totalSuccessRate / Double(differentialAnalyses.count)
    }
    
    var mostVolatileScenario: WhatIfScenario? {
        whatIfScenarios.max { $0.impact.averageRankChange < $1.impact.averageRankChange }
    }
}
