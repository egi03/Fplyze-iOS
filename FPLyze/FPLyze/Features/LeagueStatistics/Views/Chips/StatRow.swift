//
//  StatRow.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 21.06.2025..
//

import SwiftUI


struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(Color("FplTextSecondary"))
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .padding()
        .background(Color("FplSurface"))
        .cornerRadius(10)
    }
}
