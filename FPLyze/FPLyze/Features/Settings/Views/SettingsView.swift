//
//  SettingsView.swift
//  FPL.stats
//
//  Created by Eugen Sedlar on 09.07.2025..
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var preferences = UserPreferences.shared
    @State private var showingThemeSheet = false
    @State private var showingAbout = false
    @State private var showingClearDataAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "gear")
                            .font(.system(size: 50))
                            .foregroundColor(Color("FplPrimary"))
                        
                        Text("Settings")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Customize your FPL.stats experience")
                            .font(.subheadline)
                            .foregroundColor(Color("FplTextSecondary"))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Settings Sections
                    VStack(spacing: 16) {
                        // Appearance Section
                        SettingsSection(title: "Appearance", icon: "paintbrush") {
                            ThemeSettingsRow()
                        }
                        
                        // Data Section
                        SettingsSection(title: "Data", icon: "internaldrive") {
                            SettingsRow(
                                title: "Favorite Leagues",
                                subtitle: "\(preferences.favoriteLeagues.count) saved",
                                icon: "star",
                                action: {}
                            )
                            
                            SettingsRow(
                                title: "Recent Searches",
                                subtitle: "\(preferences.recentSearches.count) items",
                                icon: "clock.arrow.circlepath",
                                action: {
                                    preferences.clearRecentSearches()
                                },
                                isDestructive: true,
                                actionTitle: "Clear"
                            )
                            
                            SettingsRow(
                                title: "Clear All Data",
                                subtitle: "Remove all saved preferences",
                                icon: "trash",
                                action: {
                                    showingClearDataAlert = true
                                },
                                isDestructive: true
                            )
                        }
                        
                        // About Section
                        SettingsSection(title: "About", icon: "info.circle") {
                            SettingsRow(
                                title: "Version",
                                subtitle: "1.0.0",
                                icon: "number",
                                action: {}
                            )
                            
                            SettingsRow(
                                title: "About FPL.stats",
                                subtitle: "Learn more about the app",
                                icon: "questionmark.circle",
                                action: {
                                    showingAbout = true
                                }
                            )
                        }
                    }
                    
                    Spacer(minLength: 20)
                    
                    // Footer
                    VStack(spacing: 8) {
                        Text("Made with ❤️ for FPL managers")
                            .font(.caption)
                            .foregroundColor(Color("FplTextSecondary"))
                        
                        Text("Data from fantasy.premierleague.com")
                            .font(.caption2)
                            .foregroundColor(Color("FplTextSecondary"))
                    }
                    .padding(.bottom, 20)
                }
                .padding()
            }
            .background(Color("FplBackground"))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .alert("Clear All Data", isPresented: $showingClearDataAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("This will remove all your favorites, recent searches, and preferences. This action cannot be undone.")
        }
    }
    
    private func clearAllData() {
        preferences.clearRecentSearches()
        preferences.favoriteLeagues.removeAll()
        // Reset theme to system
        themeManager.setTheme(.system)
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color("FplPrimary"))
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal)
            
            VStack(spacing: 8) {
                content
            }
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    let isDestructive: Bool
    let actionTitle: String?
    
    init(
        title: String,
        subtitle: String,
        icon: String,
        action: @escaping () -> Void,
        isDestructive: Bool = false,
        actionTitle: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.action = action
        self.isDestructive = isDestructive
        self.actionTitle = actionTitle
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(isDestructive ? .red : Color("FplPrimary"))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(isDestructive ? .red : Color("FplTextPrimary"))
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(Color("FplTextSecondary"))
                }
                
                Spacer()
                
                if let actionTitle = actionTitle {
                    Text(actionTitle)
                        .font(.caption)
                        .foregroundColor(isDestructive ? .red : Color("FplPrimary"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background((isDestructive ? Color.red : Color("FplPrimary")).opacity(0.1))
                        .cornerRadius(6)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color("FplTextSecondary"))
                        .font(.caption)
                }
            }
            .padding()
            .background(Color("FplSurface"))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Icon and Info
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color("FplPrimary"), Color("FplAccent")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        VStack(spacing: 8) {
                            Text("FPL.stats")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Version 1.0.0")
                                .font(.subheadline)
                                .foregroundColor(Color("FplTextSecondary"))
                        }
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About")
                            .font(.headline)
                        
                        Text("FPL.stats provides comprehensive statistics and analysis for Fantasy Premier League mini-leagues. Track records, analyze performance, and discover insights to improve your FPL game.")
                            .font(.subheadline)
                            .foregroundColor(Color("FplTextSecondary"))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("Features")
                            .font(.headline)
                            .padding(.top)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FeatureRow(icon: "trophy", text: "League records and achievements")
                            FeatureRow(icon: "chart.bar", text: "Manager performance analysis")
                            FeatureRow(icon: "star", text: "Chip usage tracking")
                            FeatureRow(icon: "person.2", text: "Head-to-head comparisons")
                            FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Performance trends")
                        }
                    }
                    
                    Spacer()
                    
                    // Footer
                    VStack(spacing: 8) {
                        Text("Data provided by fantasy.premierleague.com")
                            .font(.caption)
                            .foregroundColor(Color("FplTextSecondary"))
                            .multilineTextAlignment(.center)
                        
                        Text("Not affiliated with the Premier League")
                            .font(.caption2)
                            .foregroundColor(Color("FplTextSecondary"))
                    }
                    .padding(.bottom, 20)
                }
                .padding()
            }
            .background(Color("FplBackground"))
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color("FplPrimary"))
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(Color("FplTextPrimary"))
        }
    }
}
