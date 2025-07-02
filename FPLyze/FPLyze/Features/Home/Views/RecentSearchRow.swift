//
//  RecentSearchRow.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 01.07.2025..
//

import SwiftUI

struct RecentSearchRow: View {
    let search: UserPreferences.RecentSearch
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("League ID: \(search.leagueId)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    if let name = search.leagueName {
                        Text(name)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.caption)
            }
            .padding()
            .background(Color.white.opacity(0.15))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
