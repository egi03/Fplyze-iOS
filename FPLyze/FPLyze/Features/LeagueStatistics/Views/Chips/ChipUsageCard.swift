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
        switch chipType {
        case .tripleCaptain:
            // For triple captain, evaluate based on captain points, not total
            if let captainPoints = usage.captainPoints {
                switch captainPoints {
                case 15...: return .excellent
                case 10..<15: return .good
                case 6..<10: return .average
                default: return .poor
                }
            } else {
                // Fallback to total points evaluation
                switch usage.points {
                case 100...: return .excellent
                case 80..<100: return .good
                case 60..<80: return .average
                default: return .poor
                }
            }
        case .benchBoost:
            if let benchPoints = usage.benchBoost {
                switch benchPoints {
                case 25...: return .excellent
                case 18..<25: return .good
                case 12..<18: return .average
                default: return .poor
                }
            } else {
                return .average
            }
        default:
            switch usage.points {
            case 100...: return .excellent
            case 80..<100: return .good
            case 60..<80: return .average
            default: return .poor
            }
        }
    }
    
    var displayInfo: (mainValue: String, subtitle: String, description: String) {
        switch chipType {
        case .tripleCaptain:
            if let captainName = usage.captainName,
               let captainPoints = usage.captainPoints {
                return (
                    mainValue: "\(captainPoints)",
                    subtitle: "captain pts (×3)",
                    description: "\(captainName) scored \(captainPoints) pts"
                )
            } else {
                return (
                    mainValue: "\(usage.points)",
                    subtitle: "total pts",
                    description: "Triple captain played"
                )
            }
        case .benchBoost:
            if let benchPoints = usage.benchBoost {
                return (
                    mainValue: "\(benchPoints)",
                    subtitle: "bench pts",
                    description: "Bench contributed \(benchPoints) pts"
                )
            } else {
                return (
                    mainValue: "\(usage.points)",
                    subtitle: "total pts",
                    description: "Bench boost played"
                )
            }
        default:
            return (
                mainValue: "\(usage.points)",
                subtitle: "total pts",
                description: "\(chipType.displayName) played"
            )
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                HStack {
                    // Manager Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(member.entryName)
                            .font(.headline)
                            .foregroundColor(Color("FplTextPrimary"))
                        
                        Text(member.playerName)
                            .font(.caption)
                            .foregroundColor(Color("FplTextSecondary"))
                        
                        Label("GW \(usage.event)", systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(Color("FplTextSecondary"))
                    }
                    
                    Spacer()
                    
                    // Enhanced Points & Effectiveness Display
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(alignment: .bottom, spacing: 4) {
                            Text(displayInfo.mainValue)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(effectiveness.color)
                            
                            Text(displayInfo.subtitle)
                                .font(.caption)
                                .foregroundColor(Color("FplTextSecondary"))
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
                
                // Enhanced description with chip-specific details
                HStack {
                    if chipType == .tripleCaptain {
                        Image(systemName: "star.circle.fill")
                            .foregroundColor(.orange)
                    } else if chipType == .benchBoost {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.blue)
                    } else {
                        Image(systemName: chipType.icon)
                            .foregroundColor(chipType.color)
                    }
                    
                    Text(displayInfo.description)
                        .font(.caption)
                        .foregroundColor(Color("FplTextSecondary"))
                    
                    Spacer()
                    
                    // Show total gameweek points for context if different from main value
                    if chipType == .tripleCaptain || chipType == .benchBoost {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(usage.points) pts")
                                .font(.caption2)
                                .foregroundColor(Color("FplTextSecondary"))
                            Text("total GW")
                                .font(.caption2)
                                .foregroundColor(Color("FplTextSecondary"))
                        }
                    }
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
