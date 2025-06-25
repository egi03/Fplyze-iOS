//
//  ChipUsageCard.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 21.06.2025..
//
import SwiftUI

struct ChipUsageCard: View {
    let member: LeagueMember
    let usage: ChipUsage
    let chipType: ChipType
    let onTap: () -> Void
    
    var effectiveness: ChipEffectiveness {
        switch usage.points {
        case 100...:
            return .excellent
        case 80..<100:
            return .good
        case 60..<80:
            return .average
        default:
            return .poor
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Manager Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(member.entryName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(member.playerName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("GW \(usage.event)", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Points & Effectiveness
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("\(usage.points)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(effectiveness.color)
                        
                        Text("pts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)
                    }
                    
                    // Effectiveness Badge
                    Text(effectiveness.label)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(effectiveness.color.opacity(0.2))
                        .foregroundColor(effectiveness.color)
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                    .shadow(color: effectiveness.color.opacity(0.2), radius: 5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
