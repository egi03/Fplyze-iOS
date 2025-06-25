//
//  ChipsTab.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 21.06.2025..
//

import SwiftUI

struct ChipsTab: View {
    let members: [LeagueMember]
    @State private var selectedChip: ChipType = .benchBoost
    @State private var showingDetail = false
    @State private var selectedUsage: ChipUsage?
    
    @Environment(\.presentationMode) var presentationMode

    
    var chipUsageByType: [ChipType: [(LeagueMember, ChipUsage)]] {
        var grouped: [ChipType: [(LeagueMember, ChipUsage)]] = [:]
        
        for member in members {
            for chip in member.chips {
                if let chipType = ChipType(rawValue: chip.name) {
                    if grouped[chipType] == nil {
                        grouped[chipType] = []
                    }
                    grouped[chipType]?.append((member, chip))
                }
            }
        }
        
        for (key, value) in grouped {
            grouped[key] = value.sorted { $0.1.points > $1.1.points }
        }
        
        return grouped
    }
    
    var selectedChipUsage: [(LeagueMember, ChipUsage)] {
        chipUsageByType[selectedChip] ?? []
    }
    
    var chipStats: ChipStatistics {
        let usage = selectedChipUsage
        let totalUses = usage.count
        let totalPoints = usage.map { $0.1.points }.reduce(0, +)
        let averagePoints = totalUses > 0 ? Double(totalPoints) / Double(totalUses) : 0
        let bestScore = usage.map { $0.1.points }.max() ?? 0
        
        return ChipStatistics(
            totalUses: totalUses,
            averagePoints: averagePoints,
            bestScore: bestScore
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Chip Selector
            ChipSelector(
                selectedChip: $selectedChip,
                chipUsage: chipUsageByType
            )
            
            ScrollView {
                VStack(spacing: 16) {
                    // Overview Card
                    ChipOverviewCard(
                        chipType: selectedChip,
                        stats: chipStats
                    )
                    
                    // Usage Timeline
                    if !selectedChipUsage.isEmpty {
                        ChipTimelineView(
                            chipUsage: selectedChipUsage,
                            chipType: selectedChip
                        )
                    }
                    
                    // Individual Usage List
                    ForEach(selectedChipUsage, id: \.1.id) { member, usage in
                        ChipUsageCard(
                            member: member,
                            usage: usage,
                            chipType: selectedChip,
                            onTap: {
                                selectedUsage = usage
                                showingDetail = true
                            }
                        )
                    }
                }
                .padding()
            }
        }
        .background(Color("FplBackground"))
        .sheet(isPresented: $showingDetail) {
            if let usage = selectedUsage,
               let member = selectedChipUsage.first(where: { $0.1.id == usage.id })?.0 {
                ChipDetailView(
                    member: member,
                    usage: usage,
                    onDismiss: {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
}





