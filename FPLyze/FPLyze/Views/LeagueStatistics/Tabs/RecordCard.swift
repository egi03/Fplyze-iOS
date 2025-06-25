//
//  RecordCard.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 21.06.2025..
//
 import SwiftUI

struct RecordCard: View {
    let record: LeagueRecord
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack{
                    Circle()
                        .fill(record.type.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: record.type.icon)
                        .foregroundColor(record.type.color)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                        Text(record.type.rawValue)
                            .font(.headline)
                        
                    Text(record.managerName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    
                    if let gameweek = record.gameweek {
                        Text("Gameweek \(gameweek)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(record.value)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(record.type.color)
                    
                    Text("points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if isExpanded {
                Divider()
                
                HStack {
                    Label("Team: \(record.entryName)", systemImage: "person.fill")
                        .font(.caption)
                    
                    Spacer()
                    
                    if let info = record.additionalInfo {
                        Label(info, systemImage: "info.circle.fill")
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5)
        .onTapGesture(perform: onTap)
    }
}
