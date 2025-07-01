//
//  FavoriteLeagueCard.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 01.07.2025..
//

import SwiftUI

struct FavoriteLeagueCard: View {
    let favorite: UserPreferences.FavoriteLeague
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    
                    Text(favorite.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color("FplTextPrimary"))
                        .lineLimit(1)
                }
                
                Text("ID: \(favorite.id)")
                    .font(.caption)
                    .foregroundColor(Color("FplTextSecondary"))
                
                Text(favorite.formattedDate)
                    .font(.caption2)
                    .foregroundColor(Color("FplTextSecondary"))
            }
            .padding()
            .frame(width: 180)
            .background(Color("FplCardBackground"))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 5)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(0.98)
        .animation(.easeInOut(duration: 0.1), value: 0.98)
    }
}
