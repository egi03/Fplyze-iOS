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
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "star.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("FplAccent"), Color.yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right.circle")
                        .font(.caption)
                        .foregroundColor(Color("FplTextSecondary"))
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
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color("FplCardBackground"))
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        LinearGradient(
                            colors: [Color("FplAccent").opacity(0.3), Color("FplPrimary").opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
    }
}

#Preview {
    FavoriteLeagueCard(
        favorite: UserPreferences.FavoriteLeague(
            id: 123456,
            name: "My Test League",
            addedDate: Date()
        ),
        action: {}
    )
    .padding()
    .background(Color("FplBackground"))
}
