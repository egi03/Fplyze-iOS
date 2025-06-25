//
//  LeagueStatisticsData.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 21.06.2025..
//

struct LeagueStatisticsData {
    let leagueId: Int
    let records: [LeagueRecord]
    let managerStatistics: [ManagerStatistics]
    let headToHeadStatistics: [HeadToHeadRecord]
    let members: [LeagueMember]
}
