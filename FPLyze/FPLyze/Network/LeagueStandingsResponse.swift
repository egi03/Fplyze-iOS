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
    
    enum CodingKeys: String, CodingKey {
        case id, name, created, closed, scoring
        case maxEntries = "max_entries"
        case leagueType = "league_type"
    }
}

struct Standings: Codable {
    let hasNext: Bool
    let page: Int
    let results: [StandingResult]
    
    enum CodingKeys: String, CodingKey {
        case page, results
        case hasNext = "has_next"
    }
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
    
    enum CodingKeys: String, CodingKey {
        case id, rank, total, entry
        case eventTotal = "event_total"
        case playerName = "player_name"
        case lastRank = "last_rank"
        case rankSort = "rank_sort"
        case entryName = "entry_name"
    }
}
