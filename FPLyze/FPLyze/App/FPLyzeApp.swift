//
//  FPLyzeApp.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 15.06.2025..
//

import SwiftUI

@main
struct FPLyzeApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    
    init() {
        setupAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(themeManager)
                .environment(\.themeManager, themeManager)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Update theme when app becomes active (handles system changes)
                    if themeManager.currentMode == .system {
                        themeManager.updateAppearance()
                    }
                }
        }
    }
    
    private func setupAppearance() {
        // Configure UI appearance that adapts to theme changes
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // These will be overridden by theme manager, but set defaults
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label
        ]
        
        // Remove the bottom border
        appearance.shadowColor = .clear
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // Tab Bar styling (adapts automatically to dark mode)
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Table and Collection View backgrounds (adapts automatically)
        UITableView.appearance().backgroundColor = UIColor.systemBackground
        UICollectionView.appearance().backgroundColor = UIColor.systemBackground
    }
}
