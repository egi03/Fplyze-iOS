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
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color("FplPrimary").opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color("FplPrimary"))
                        .font(.system(size: 16, weight: .medium))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("League ID: \(search.leagueId)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color("FplTextPrimary"))
                    
                    if let name = search.leagueName {
                        Text(name)
                            .font(.caption)
                            .foregroundColor(Color("FplTextSecondary"))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Color("FplTextSecondary"))
                    .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color("FplCardBackground"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("FplDivider"), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
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
    VStack(spacing: 12) {
        RecentSearchRow(
            search: UserPreferences.RecentSearch(
                leagueId: 12345,
                searchDate: Date(),
                leagueName: "My Test League"
            ),
            action: {}
        )
        
        RecentSearchRow(
            search: UserPreferences.RecentSearch(
                leagueId: 67890,
                searchDate: Date(),
                leagueName: nil
            ),
            action: {}
        )
    }
    .padding()
    .background(Color("FplBackground"))
}
