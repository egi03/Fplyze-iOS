//
//  ThemeSelectionView.swift
//  FPL.stats
//
//  Created by Eugen Sedlar on 09.07.2025..
//

import SwiftUI

// MARK: - Theme Selection Sheet
struct ThemeSelectionSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "paintbrush.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color("FplPrimary"))
                    
                    Text("Choose Appearance")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Select how FPL.stats should appear")
                        .font(.subheadline)
                        .foregroundColor(Color("FplTextSecondary"))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Theme Options
                VStack(spacing: 16) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        ThemeOptionCard(
                            mode: mode,
                            isSelected: themeManager.currentMode == mode,
                            action: {
                                withAnimation(.spring()) {
                                    themeManager.setTheme(mode)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Preview Note
                VStack(spacing: 8) {
                    Text("💡 Theme Tip")
                        .font(.headline)
                    
                    Text("System mode automatically switches between light and dark based on your device settings")
                        .font(.caption)
                        .foregroundColor(Color("FplTextSecondary"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .background(Color("FplBackground"))
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Theme Option Card
struct ThemeOptionCard: View {
    let mode: AppearanceMode
    let isSelected: Bool
    let action: () -> Void
    
    private var description: String {
        switch mode {
        case .system:
            return "Follows your device's appearance setting"
        case .light:
            return "Always uses light appearance"
        case .dark:
            return "Always uses dark appearance"
        }
    }
    
    private var previewColors: [Color] {
        switch mode {
        case .system:
            return [Color("FplBackground"), Color("FplSurface"), Color("FplPrimary")]
        case .light:
            return [Color.white, Color.gray.opacity(0.1), Color("FplPrimary")]
        case .dark:
            return [Color.black, Color.gray.opacity(0.3), Color("FplPrimary")]
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Theme Preview
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(previewColors[index])
                            .frame(width: 20, height: 20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color("FplDivider"), lineWidth: 0.5)
                            )
                    }
                }
                
                // Theme Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: mode.icon)
                            .foregroundColor(Color("FplPrimary"))
                        
                        Text(mode.displayName)
                            .font(.headline)
                            .foregroundColor(Color("FplTextPrimary"))
                    }
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(Color("FplTextSecondary"))
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                // Selection Indicator
                ZStack {
                    Circle()
                        .stroke(Color("FplDivider"), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color("FplPrimary"))
                            .frame(width: 16, height: 16)
                            .scaleEffect(isSelected ? 1.0 : 0.0)
                            .animation(.spring(response: 0.3), value: isSelected)
                    }
                }
            }
            .padding()
            .background(Color("FplSurface"))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color("FplPrimary") : Color("FplDivider"),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .cornerRadius(12)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Quick Theme Toggle Button
struct QuickThemeToggle: View {
    @ObservedObject var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: {
            withAnimation(.spring()) {
                themeManager.toggleTheme()
            }
        }) {
            ZStack {
                Circle()
                    .fill(Color("FplSurface"))
                    .frame(width: 44, height: 44)
                    .shadow(color: .black.opacity(0.1), radius: 2)
                
                Image(systemName: themeManager.currentMode.icon)
                    .foregroundColor(Color("FplPrimary"))
                    .font(.title3)
                    .symbolEffect(.bounce, value: themeManager.currentMode)
            }
        }
    }
}

// MARK: - Settings Row for Theme
struct ThemeSettingsRow: View {
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var showingThemeSheet = false
    
    var body: some View {
        Button(action: { showingThemeSheet = true }) {
            HStack {
                Image(systemName: "paintbrush.fill")
                    .foregroundColor(Color("FplPrimary"))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Appearance")
                        .font(.subheadline)
                        .foregroundColor(Color("FplTextPrimary"))
                    
                    Text(themeManager.currentMode.displayName)
                        .font(.caption)
                        .foregroundColor(Color("FplTextSecondary"))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Color("FplTextSecondary"))
                    .font(.caption)
            }
            .padding()
            .background(Color("FplSurface"))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingThemeSheet) {
            ThemeSelectionSheet()
        }
    }
}
