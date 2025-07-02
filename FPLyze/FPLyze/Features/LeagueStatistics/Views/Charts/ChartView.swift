//
//  ChartView.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 21.06.2025..
//

import SwiftUI
import Charts

struct ChartView: View {
    let members: [LeagueMember]
    let chartType: TrendsTab.ChartType
    
    var body: some View {
        Chart {
            ForEach(members) { member in
                ForEach(Array(member.gameweekHistory.enumerated()), id: \.element.id) {
                    index, gw in
                    LineMark(
                        x: .value("Gameweek", gw.event),
                        y: .value(yAxisLabel, yValue(for: gw)),
                        series: .value("Manager", member.playerName)
                    )
                    .foregroundStyle(by: .value("Manager", member.playerName))
                    .symbol(by: .value("Manager", member.playerName))
                }
            }
        }
        .chartXAxisLabel("Gameweek")
        .chartYAxisLabel(yAxisLabel)
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding()
    }
    
    private var yAxisLabel: String {
        switch chartType {
        case .cumulativePoints:
            return "Total points"
        case .gameweekPoints:
            return "Points"
        case .rankProgression:
            return "Rank"
        }
    }
    
    private func yValue(for gw: GameweekPerformance) -> Int {
        switch chartType {
            case .cumulativePoints: return gw.totalPoints
            case .gameweekPoints: return gw.points
            case .rankProgression: return -gw.rank
        }
    }
}
