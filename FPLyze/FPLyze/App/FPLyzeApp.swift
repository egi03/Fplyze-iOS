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
        UITableView.appearance().backgroundColor = .white
        UICollectionView.appearance().backgroundColor = .white
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}

// 788680
