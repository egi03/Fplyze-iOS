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
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "star.fill")
                        .font(.title3)
                        .foregroundColor(.yellow)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right.circle")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(favorite.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color("FplTextPrimary"))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("ID: \(favorite.id)")
                        .font(.caption)
                        .foregroundColor(Color("FplTextSecondary"))
                    
                    Text(favorite.formattedDate)
                        .font(.caption2)
                        .foregroundColor(Color("FplTextSecondary"))
                }
                
                Spacer()
            }
            .padding()
            .frame(width: 200, height: 120)
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(0.98)
        .animation(.easeInOut(duration: 0.1), value: 0.98)
    }
}
