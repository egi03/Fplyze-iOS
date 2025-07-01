//
//  LeagueStatisticsData.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 21.06.2025..
//


import Foundation

struct LeagueStatisticsData {
    let leagueId: Int
    let records: [LeagueRecord]
    let managerStatistics: [ManagerStatistics]
    let headToHeadStatistics: [HeadToHeadRecord]
    let members: [LeagueMember]
    let missedPlayerAnalyses: [MissedPlayerAnalysis]
    let underperformerAnalyses: [UnderperformerAnalysis]
    
    init(
        leagueId: Int,
        records: [LeagueRecord],
        managerStatistics: [ManagerStatistics],
        headToHeadStatistics: [HeadToHeadRecord],
        members: [LeagueMember],
        missedPlayerAnalyses: [MissedPlayerAnalysis] = [],
        underperformerAnalyses: [UnderperformerAnalysis] = []
    ) {
        self.leagueId = leagueId
        self.records = records
        self.managerStatistics = managerStatistics
        self.headToHeadStatistics = headToHeadStatistics
        self.members = members
        self.missedPlayerAnalyses = missedPlayerAnalyses
        self.underperformerAnalyses = underperformerAnalyses
    }
}
