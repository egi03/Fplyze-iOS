//
//  LeagueStatisticsViewModel.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 21.06.2025..
//

import Foundation
import SwiftUI
import Combine

@MainActor
class LeagueStatisticsViewModel: ObservableObject {
    @Published var state: ViewState = .idle
    @Published var statistics: LeagueStatisticsData?
    @Published var selectedTab: StatisticsTab = .records
    @Published var selectedManagerId: Int?
    @Published var refreshing = false
    
    private let repository = LeagueStatisticsRepository()
    private let preferences = UserPreferences.shared
    private var cancellables = Set<AnyCancellable>()
    
    enum ViewState: Equatable {
        case idle
        case loading(progress: Double, message: String)
        case loaded
        case error(Error)
        
        static func == (lhs: ViewState, rhs: ViewState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loaded, .loaded):
                return true
            case let (.loading(p1, m1), .loading(p2, m2)):
                return p1 == p2 && m1 == m2
            case let (.error(e1), .error(e2)):
                return e1.localizedDescription == e2.localizedDescription
            default:
                return false
            }
        }
    }
    
    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }
    
    var error: String? {
        if case .error(let error) = state {
            return error.localizedDescription
        }
        return nil
    }
    
    var loadingProgress: Double {
        if case .loading(let progress, _) = state {
            return progress
        }
        return 0
    }
    
    var loadingMessage: String {
        if case .loading(_, let message) = state {
            return message
        }
        return ""
    }
    
    var leagueName: String? {
        statistics?.members.first?.entryName
    }
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        repository.$loadingProgress
            .combineLatest(repository.$loadingMessage)
            .sink { [weak self] progress, message in
                guard let self = self else { return }
                if self.isLoading {
                    self.state = .loading(progress: progress, message: message)
                }
            }
            .store(in: &cancellables)
    }
    
    func loadStatistics(for leagueId: Int, forceRefresh: Bool = false) async {
        guard !isLoading || forceRefresh else { return }
        
        state = .loading(progress: 0.0, message: "Initializing...")
        
        do {
            let stats = try await repository.fetchLeagueStatistics(
                leagueId: leagueId,
                forceRefresh: forceRefresh
            )
            
            self.statistics = stats
            self.state = .loaded
            
            // Update recent search with league name if available
            if let firstMember = stats.members.first {
                preferences.addRecentSearch(
                    leagueId: leagueId,
                    name: "League of \(firstMember.playerName)"
                )
            }
            
        } catch {
            self.state = .error(error)
        }
        
        refreshing = false
    }
    
    func refresh(leagueId: Int) async {
        refreshing = true
        await loadStatistics(for: leagueId, forceRefresh: true)
    }
    
    func selectTab(_ tab: StatisticsTab) {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedTab = tab
        }
    }
    
    func selectManager(_ managerId: Int) {
        selectedManagerId = managerId
    }
    
    func toggleFavorite(leagueId: Int) {
        guard let stats = statistics else { return }
        
        let leagueName = stats.members.first.map { "League of \($0.playerName)" } ?? "League \(leagueId)"
        preferences.toggleFavorite(leagueId: leagueId, name: leagueName)
    }
    
    func isFavorite(leagueId: Int) -> Bool {
        preferences.isFavorite(leagueId)
    }
}
