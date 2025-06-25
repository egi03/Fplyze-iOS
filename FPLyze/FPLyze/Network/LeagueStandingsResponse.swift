//
//  ResponseModels.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 20.06.2025..
//

struct LeagueStandingsResponse: Codable {
    let league: League
    let standings: Standings
}

struct League: Codable {
    let id: Int
    let name: String
    let created: String
    let closed: Bool
    let maxEntries: Int?
    let leagueType: String
    let scoring: String
}

struct Standings : Codable {
    let hasNext: Bool
    let page: Int
    let results: [StandingResult]
}

struct StandingResult: Codable {
    let id: Int
    let eventTotal: Int
    let playerName: String
    let rank: Int
    let lastRank: Int
    let rankSort: Int
    let total: Int
    let entry: Int
    let entryName: String
}
