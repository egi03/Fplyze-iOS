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
                    .foregroundColor(Color("FplTextSecondary"))
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("League ID: \(search.leagueId)")
                        .font(.subheadline)
                        .foregroundColor(Color("FplTextPrimary"))
                    
                    if let name = search.leagueName {
                        Text(name)
                            .font(.caption)
                            .foregroundColor(Color("FplTextSecondary"))
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Color("FplTextSecondary"))
                    .font(.caption)
            }
            .padding()
            .background(Color("FplCardBackground"))
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.05), radius: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
