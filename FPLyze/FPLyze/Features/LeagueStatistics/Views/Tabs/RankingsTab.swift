//
//  RankingsTab.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 21.06.2025..
//

import SwiftUI

struct RankingsTab : View {
    let statistics: [ManagerStatistics]
    @State private var sortBy: RankingSortType = .averagePoints
    @State private var selectedManager: ManagerStatistics?
    
    var sortedStatistics: [ManagerStatistics] {
        switch sortBy {
        case .averagePoints:
            return statistics.sorted { $0.averagePoints > $1.averagePoints }
        case .consistency:
            return statistics.sorted { $0.standardDeviation < $1.standardDeviation }
        case .bestWeek:
            return statistics.sorted { $0.bestWeek > $1.bestWeek }
        case .captainSuccess:
            return statistics.sorted { $0.captainSuccess > $1.captainSuccess }
        case .benchWaste:
            return statistics.sorted { $0.benchWaste < $1.benchWaste }
        case .transfers:
            return statistics.sorted { $0.totalTransfers > $1.totalTransfers }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(RankingSortType.allCases, id: \.self) { type in
                        SortChip(
                            title: type.rawValue,
                            isSelected: sortBy == type,
                            action: { sortBy = type }
                        )
                    }
                }
                .padding()
            }
            background(Color("FplBackground"))
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(sortedStatistics.enumerated()), id: \.element.id) { index, stat in
                        RankingCard(
                            rank: index + 1,
                            statistics: stat,
                            sortType: sortBy,
                            isSelected: selectedManager?.id == stat.id,
                            onTap: {
                                withAnimation {
                                    selectedManager = selectedManager?.id == stat.id ? nil : stat
                                }
                            }
                        )
                    }
                }
                .padding()
            }
        }
        .background(Color("FplBackground"))
    }
}

