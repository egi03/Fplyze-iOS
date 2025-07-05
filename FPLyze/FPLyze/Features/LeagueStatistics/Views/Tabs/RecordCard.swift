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
                        .foregroundColor(Color("FplTextSecondary"))
                    
                    if let gameweek = record.gameweek {
                        Text("Gameweek \(gameweek)")
                            .font(.caption)
                            .foregroundColor(Color("FplTextSecondary"))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if record.type == .bestTripleCaptain {
                        // Enhanced triple captain display
                        if let captainName = record.captainName,
                           let captainPoints = record.captainActualPoints {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(captainPoints)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(record.type.color)
                                
                                Text("captain pts")
                                    .font(.caption2)
                                    .foregroundColor(Color("FplTextSecondary"))
                                
                                Text("(\(captainPoints * 3) total)")
                                    .font(.caption)
                                    .foregroundColor(record.type.color)
                            }
                        } else {
                            // Fallback to total points
                            Text("\(record.value)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(record.type.color)
                            
                            Text("points")
                                .font(.caption)
                                .foregroundColor(Color("FplTextSecondary"))
                        }
                    } else {
                        // Standard display for other records
                        Text("\(record.value)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(record.type.color)
                        
                        Text(getValueLabel(for: record.type))
                            .font(.caption)
                            .foregroundColor(Color("FplTextSecondary"))
                    }
                }
            }
            
            if isExpanded {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Team: \(record.entryName)", systemImage: "person.fill")
                            .font(.caption)
                        
                        Spacer()
                    }
                    .foregroundColor(Color("FplTextSecondary"))
                    
                    if let info = record.additionalInfo {
                        HStack {
                            if record.type == .bestTripleCaptain {
                                Image(systemName: "star.circle.fill")
                                    .foregroundColor(.orange)
                            } else if record.type == .mostConsistent {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .foregroundColor(.purple)
                            } else {
                                Image(systemName: "info.circle.fill")
                            }
                            
                            Text(info)
                                .font(.caption)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .foregroundColor(Color("FplTextSecondary"))
                    }
                    
                    // Additional context for specific record types
                    if record.type == .bestTripleCaptain,
                       let captainName = record.captainName {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .foregroundColor(.green)
                            
                            Text("Captain: \(captainName)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                    }
                    
                    if record.type == .mostConsistent {
                        ConsistencyExplanation()
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color("FplBackground"))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5)
        .onTapGesture(perform: onTap)
    }
    
    private func getValueLabel(for recordType: RecordType) -> String {
        switch recordType {
        case .biggestRise, .biggestFall:
            return "places"
        case .mostConsistent:
            return "avg pts"
        default:
            return "points"
        }
    }
}

struct ConsistencyExplanation: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("What is consistency?")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color("FplTextPrimary"))
            
            Text("Standard deviation measures how much your scores vary from your average. Lower = more consistent.")
                .font(.caption2)
                .foregroundColor(Color("FplTextSecondary"))
                .fixedSize(horizontal: false, vertical: true)
            
            HStack(spacing: 16) {
                ConsistencyLevel(range: "0-5", description: "Very consistent", color: .green)
                ConsistencyLevel(range: "5-8", description: "Steady", color: .blue)
                ConsistencyLevel(range: "8-12", description: "Variable", color: .orange)
                ConsistencyLevel(range: "12+", description: "Volatile", color: .red)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ConsistencyLevel: View {
    let range: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(range)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(description)
                .font(.caption2)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}
