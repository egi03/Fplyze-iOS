//
//  FPLyzeApp.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 15.06.2025..
//

import SwiftUI

@main
struct FPLyzeApp: App {
    init() {
        // Table and Collection View backgrounds
        UITableView.appearance().backgroundColor = UIColor(Color("FplBackground"))
        UICollectionView.appearance().backgroundColor = UIColor(Color("FplBackground"))
        
        // Navigation Bar styling
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color("FplSurface"))
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(Color("FplTextPrimary"))
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Color("FplTextPrimary"))
        ]
        
        // Remove the bottom border
        appearance.shadowColor = .clear
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // Tab Bar styling (if you add one later)
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(Color("FplSurface"))
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
// 788680
