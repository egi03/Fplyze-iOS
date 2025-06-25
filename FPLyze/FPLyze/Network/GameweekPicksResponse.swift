//
//  ResponseModels.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 20.06.2025..
//

import Foundation

struct GameweekPicksResponse: Codable {
    let picks: [PlayerPick]
    let activeChip: String?
    let automaticSubs: [AutomaticSubstitution]
    let entryHistory: EntryHistory
}


struct PlayerPick: Codable, Identifiable {
    let id = UUID()
    let element: Int // Player ID
    let position: Int
    let multiplier: Int
    let isCaptain: Bool
    let isViceCaptain: Bool
    
    enum CodingKeys: String, CodingKey {
        case element
        case position
        case multiplier
        case isCaptain = "is_captain"
        case isViceCaptain = "is_vice_captain"
    }
}


struct AutomaticSubstitution: Codable, Identifiable {
    let id = UUID()
    let elementIn: Int
    let elementOut: Int
    let entry: Int
    let event: Int
    
    enum CodingKeys: String, CodingKey {
        case elementIn = "element_in"
        case elementOut = "element_out"
        case entry
        case event
    }
}


struct EntryHistory: Codable {
    let event: Int // Gameweek number
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
        case event
        case points
        case totalPoints = "total_points"
        case rank
        case rankSort = "rank_sort"
        case overallRank = "overall_rank"
        case bank
        case value
        case eventTransfers = "event_transfers"
        case eventTransfersCost = "event_transfers_cost"
        case pointsOnBench = "points_on_bench"
    }
}
