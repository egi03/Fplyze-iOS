//
//  LeagueStatisticsViewModel.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 21.06.2025..
//

import Foundation
import SwiftUI


@MainActor
class LeagueStatisticsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    @Published var statistics: LeagueStatisticsData?
    @Published var selectedTab: StatisticsTab = .records
    @Published var selectedManagerId: Int?
    
    private let repository = LeagueStatisticsRepository()
    
    func loadStatistics(for leagueId: Int) async {
        isLoading = true
        error = nil
        
        do {
            let stats = try await repository.fetchLeagueStatistics(leagueId: leagueId)
            self.statistics = stats
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func selectTab(_ tab: StatisticsTab) {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedTab = tab
        }
    }
    
    func selectManager(_ managerId: Int) {
        selectedManagerId = managerId
    }
}


