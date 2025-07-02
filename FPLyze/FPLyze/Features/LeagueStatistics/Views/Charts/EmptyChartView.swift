//
//  EmptyChartView.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 21.06.2025..
//
import SwiftUI

struct EmptyChartView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Select members to view trends")
                .foregroundColor(Color("FplTextSecondary"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
