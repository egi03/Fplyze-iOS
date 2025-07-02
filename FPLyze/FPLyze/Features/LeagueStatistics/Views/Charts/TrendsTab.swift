//
//  TrendsTab.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 21.06.2025..
//

import SwiftUI
import Charts

struct TrendsTab: View {
    let members: [LeagueMember]
    @State private var selectedMembers: Set<Int> = []
    @State private var chartType: ChartType = .cumulativePoints
    
    enum ChartType: String, CaseIterable {
        case cumulativePoints = "Total Points"
        case gameweekPoints = "GW Points"
        case rankProgression = "Rank"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Chart Type", selection: $chartType) {
                ForEach(ChartType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(members.prefix(10)) { member in
                        MemberChip(
                            name: member.playerName,
                            isSelected: selectedMembers.contains(member.id),
                            color: colorForMember(member.id),
                            action: {
                                if selectedMembers.contains(member.id) {
                                    selectedMembers.remove(member.id)
                                } else {
                                    selectedMembers.insert(member.id)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            if selectedMembers.isEmpty {
                EmptyChartView()
            } else {
                ChartView(
                    members: members.filter { selectedMembers.contains($0.id) },
                    chartType: chartType
                )
            }
            Spacer()
        }
        .background(Color("FplBackground"))
    }
    
    private func colorForMember(_ id: Int) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .red, .pink]
        return colors[id % colors.count]
    }
    
}
