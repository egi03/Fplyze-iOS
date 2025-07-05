//
//  SortChip.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 21.06.2025..
//

import SwiftUI

struct SortChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color("FplBackground"))
                .foregroundColor(isSelected ?  Color("FplPrimary") : Color("FplSecondary"))
        }
    }
}
