//
//  NetworkManager.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 20.06.2025..
//

//
//  NetworkManager.swift
//  FPLyze
//
//  Improved network manager with better error handling and retry logic
//

import Foundation
import Combine

enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(String)
    case serverError(Int)
    case networkUnavailable
    case timeout
    case leagueNotFound
    case rateLimited
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let detail):
            return "Failed to process data: \(detail)"
        case .serverError(let code):
            switch code {
            case 404:
                return "League not found. Please check the ID."
            case 429:
                return "Too many requests. Please try again later."
            case 500...599:
                return "FPL server error. Please try again later."
            default:
                return "Server error: \(code)"
            }
        case .networkUnavailable:
            return "No internet connection"
        case .timeout:
            return "Request timed out. Please try again."
        case .leagueNotFound:
            return "League not found. Please check the ID."
        case .rateLimited:
            return "Too many requests. Please wait a moment."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .timeout:
            return true
        case .serverError(let code):
            return code >= 500
        default:
            return false
        }
    }
}

class FPLAPIService {
    static let shared = FPLAPIService()
    private let baseURL = "https://fantasy.premierleague.com/api"
    private let session: URLSession
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 2.0
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }
    
    private func request<T: Codable>(_ endpoint: String, type: T.Type, retryCount: Int = 0) async throws -> T {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    break // Success
                case 404:
                    throw NetworkError.leagueNotFound
                case 429:
                    throw NetworkError.rateLimited
                default:
                    throw NetworkError.serverError(httpResponse.statusCode)
                }
            }
            
            guard !data.isEmpty else {
                throw NetworkError.noData
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            do {
                return try decoder.decode(T.self, from: data)
            } catch let decodingError {
                // Try to provide more context about the decoding error
                if let jsonObject = try? JSONSerialization.jsonObject(with: data),
                   let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("Failed to decode response: \(jsonString)")
                }
                throw NetworkError.decodingError(decodingError.localizedDescription)
            }
            
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw NetworkError.networkUnavailable
            case .timedOut:
                throw NetworkError.timeout
            default:
                if retryCount < maxRetries && isRetryableError(error) {
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * Double(NSEC_PER_SEC)))
                    return try await request(endpoint, type: type, retryCount: retryCount + 1)
                }
                throw NetworkError.unknown(error)
            }
        } catch let error as NetworkError {
            if error.isRetryable && retryCount < maxRetries {
                try await Task.sleep(nanoseconds: UInt64(retryDelay * Double(NSEC_PER_SEC)))
                return try await request(endpoint, type: type, retryCount: retryCount + 1)
            }
            throw error
        } catch {
            throw NetworkError.unknown(error)
        }
    }
    
    private func isRetryableError(_ error: Error) -> Bool {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .networkConnectionLost, .notConnectedToInternet:
                return true
            default:
                return false
            }
        }
        return false
    }
    
    // Public API methods
    func getLeagueStandings(leagueId: Int, page: Int = 1) async throws -> LeagueStandingsResponse {
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
    
    // Health check method
    func checkConnectivity() async -> Bool {
        do {
            _ = try await session.data(from: URL(string: "\(baseURL)/bootstrap-static/")!)
            return true
        } catch {
            return false
        }
    }
    
    // Get all player data
    func getPlayerData() async throws -> BootstrapData {
        try await request(
            "bootstrap-static/",
            type: BootstrapData.self
        )
    }
    
    // Get manager's transfer history
    func getTransferHistory(entryId: Int) async throws -> [TransferHistory] {
        try await request(
            "entry/\(entryId)/transfers",
            type: [TransferHistory].self
        )
    }
}

// MARK: - Bootstrap Data Model
struct BootstrapData: Codable {
    let elements: [PlayerData]
    let events: [GameweekData]
    
    var topPlayers: [PlayerData] {
        elements
            .sorted { $0.totalPoints > $1.totalPoints }
            .prefix(40)
            .map { $0 }
    }
}

struct GameweekData: Codable {
    let id: Int
    let name: String
    let finished: Bool
    let isCurrent: Bool
    let isPrevious: Bool
    let isNext: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, finished
        case isCurrent = "is_current"
        case isPrevious = "is_previous"
        case isNext = "is_next"
    }
}
