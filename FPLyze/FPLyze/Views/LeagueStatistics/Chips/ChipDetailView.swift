//
//  ChipDetailView.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 21.06.2025..
//

import SwiftUI

struct ChipDetailView: View {
    let member: LeagueMember
    let usage: ChipUsage
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Spacer()
                        Button(action: {
                            onDismiss()
                        }) {
                            Text("Done")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 8)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(member.entryName)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(member.playerName)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        if let chipType = usage.chipType {
                            Label(chipType.displayName, systemImage: chipType.icon)
                                .font(.headline)
                                .foregroundColor(chipType.color)
                        }
                        
                        Spacer()
                        
                        Text("Gameweek \(usage.event)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 12) {
                        Text("\(usage.points)")
                            .font(.system(size: 60))
                            .fontWeight(.bold)
                            .foregroundColor(Color("FplPrimary"))
                        
                        Text("Points Scored")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("FplAccent").opacity(0.1))
                    .cornerRadius(20)
                    
                    if let benchBoost = usage.benchBoost {
                        StatRow(title: "Bench Points", value: "\(benchBoost)")
                    }
                    
                    if let fieldPoints = usage.fieldPoints {
                        StatRow(title: "Field Points", value: "\(fieldPoints)")
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            .navigationTitle("Chip Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
