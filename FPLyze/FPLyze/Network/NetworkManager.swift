//
//  NetworkManager.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 20.06.2025..
//

import Foundation
import Combine

enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(Int)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode api response"
        case .serverError(let code):
            return "Server error: \(code)"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

class FPLAPIService {
    static let shared = FPLAPIService()
    private let baseURL = "https://fantasy.premierleague.com/api"
    private let session = URLSession.shared
    
    private init() {}
    
    // Generic function that can decode any Codeable type
    private func request<T: Codable>(_ endpoint: String, type: T.Type) async throws -> T {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                guard(200...299).contains(httpResponse.statusCode) else {
                    throw NetworkError.serverError(httpResponse.statusCode)
                }
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
            
        } catch let error as DecodingError {
            print("Decoding error: \(error)")
            throw NetworkError.decodingError
        } catch {
            throw NetworkError.unknown(error)
        }
    }
    
    func getLeagueStandings(leagueId: Int, page: Int = 1) async throws -> LeagueStandingsResponse{
        try await request(
            "leagues-classic/\(leagueId)/standings/?page_standings=\(page)",
            type: LeagueStandingsResponse.self
        )
    }
    
    func getManagerHistory(entryId: Int) async throws -> ManagerHistoryResponse {
        try await request(
            "entry/\(entryId)/history",
            type: ManagerHistoryResponse.self
        )
    }
    
    func getGameweekPicks(entryId: Int, event: Int) async throws -> GameweekPicksResponse {
        try await request(
            "entry/\(entryId)/event/\(event)/picks/",
            type: GameweekPicksResponse.self
        )
    }
}
