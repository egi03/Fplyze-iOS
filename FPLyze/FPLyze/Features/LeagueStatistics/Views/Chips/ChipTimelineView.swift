//
//  ChipTimelineView.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 21.06.2025..
//

import SwiftUI


struct ChipTimelineView: View {
    let chipUsage: [(LeagueMember, ChipUsage)]
    let chipType: ChipType
    
    // Group by gameweek
    var usageByGameweek: [Int: Int] {
        var grouped: [Int: Int] = [:]
        for (_, usage) in chipUsage {
            grouped[usage.event, default: 0] += 1
        }
        return grouped
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Usage Timeline")
                .font(.headline)
            
            // Simple bar chart
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(1...38, id: \.self) { gw in
                    VStack {
                        if let count = usageByGameweek[gw], count > 0 {
                            Rectangle()
                                .fill(chipType.color)
                                .frame(width: 6, height: CGFloat(count * 20))
                            
                            if count > 2 {
                                Text("\(count)")
                                    .font(.system(size: 8))
                                    .foregroundColor(Color("FplTextSecondary"))
                            }
                        } else {
                            Color.clear
                                .frame(width: 6, height: 1)
                        }
                    }
                }
            }
            .frame(height: 100)
            .padding(.horizontal)
            
            HStack {
                Text("GW1")
                    .font(.caption2)
                    .foregroundColor(Color("FplTextSecondary"))
                
                Spacer()
                
                Text("GW38")
                    .font(.caption2)
                    .foregroundColor(Color("FplTextSecondary"))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
    }
}
