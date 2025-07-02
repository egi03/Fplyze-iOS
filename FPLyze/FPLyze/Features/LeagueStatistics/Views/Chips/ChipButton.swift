//
//  ChipButton.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 21.06.2025..
//

import SwiftUI

struct ChipButton: View {
    let chip: ChipType
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? chip.color : chip.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: chip.icon)
                        .foregroundColor(isSelected ? .white : chip.color)
                        .font(.title2)
                }
                
                Text(chip.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
                
                if count > 0 {
                    Text("(\(count))")
                        .font(.caption2)
                        .foregroundColor(Color("FplTextSecondary"))
                }
            }
            .foregroundColor(isSelected ? chip.color : .primary)
        }
    }
}
