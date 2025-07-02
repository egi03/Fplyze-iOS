//
//  ManagerHistoryResponse.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 20.06.2025..
//

struct ManagerHistoryResponse: Codable {
    let current: [GameweekHistory]
    let past: [PastSeason]
    let chips: [ChipPlay]
}

struct GameweekHistory: Codable {
    let event: Int
    let points: Int
    let totalPoints: Int
    let rank: Int
    let rankSort: Int
    let overallRank: Int
    let bank: Int
    let value: Int
    let eventTransfers: Int
    let eventTransfersCost: Int
    let pointsOnBench: Int
    
    enum CodingKeys: String, CodingKey {
        case event, points, rank, bank, value
        case totalPoints = "total_points"
        case rankSort = "rank_sort"
        case overallRank = "overall_rank"
        case eventTransfers = "event_transfers"
        case eventTransfersCost = "event_transfers_cost"
        case pointsOnBench = "points_on_bench"
    }
}

struct ChipPlay: Codable {
    let name: String
    let time: String
    let event: Int
}

struct PastSeason: Codable {
    let seasonName: String
    let rank: Int
    let totalPoints: Int
    
    enum CodingKeys: String, CodingKey {
        case rank
        case seasonName = "season_name"
        case totalPoints = "total_points"
    }
}
