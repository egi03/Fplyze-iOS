//
//  ChipSelector.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 21.06.2025..
//

import SwiftUI


struct ChipSelector: View {
    @Binding var selectedChip: ChipType
    let chipUsage: [ChipType: [(LeagueMember, ChipUsage)]]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ChipType.allCases, id: \.self) { chip in
                    ChipButton(
                        chip: chip,
                        isSelected: selectedChip == chip,
                        count: chipUsage[chip]?.count ?? 0,
                        action: { selectedChip = chip }
                    )
                }
            }
            .padding()
        }
        .background(Color.white)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 5)
    }
}
