//
//  DemoLeagueStatisticsView.swift
//  FPL.stats
//
//  Created by Eugen Sedlar on 08.07.2025..
//

import SwiftUI

struct DemoLeagueStatisticsView: View {
    @State private var selectedTab: StatisticsTab = .records
    @State private var selectedManagerId: Int?
    @State private var showShareSheet = false
    @State private var showDemoInfo = false
    @Environment(\.dismiss) var dismiss
    @StateObject private var preferences = UserPreferences.shared
    
    // Load demo data immediately
    private let demoStatistics = MockDataService.shared.generateDemoLeagueData()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Demo Banner
                demoBanner
                
                StatisticsTabBar(
                    selectedTab: $selectedTab,
                    onTabSelected: { tab in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = tab
                        }
                    }
                )
                
                TabView(selection: $selectedTab) {
                    RecordsTab(records: demoStatistics.records)
                        .tag(StatisticsTab.records)
                    
                    RankingsTab(statistics: demoStatistics.managerStatistics)
                        .tag(StatisticsTab.rankings)
                    
                    HeadToHeadTab(records: demoStatistics.headToHeadStatistics)
                        .tag(StatisticsTab.headToHead)
                    
                    ChipsTab(members: demoStatistics.members)
                        .tag(StatisticsTab.chips)
                    
                    TrendsTab(members: demoStatistics.members)
                        .tag(StatisticsTab.trends)
                    
                    PlayerAnalysisTab(
                        missedAnalyses: demoStatistics.missedPlayerAnalyses,
                        underperformerAnalyses: demoStatistics.underperformerAnalyses
                    )
                    .tag(StatisticsTab.playerAnalysis)
                    
                    DifferentialAnalysisTab(analyses: demoStatistics.differentialAnalyses)
                        .tag(StatisticsTab.differentials)
                    
                    WhatIfScenariosTab(scenarios: demoStatistics.whatIfScenarios)
                        .tag(StatisticsTab.whatIf)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: selectedTab)
            }
            .navigationTitle(demoStatistics.leagueName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Demo Info Button
                        Button(action: {
                            showDemoInfo = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title3)
                            }
                        }
                        
                        // Share Button
                        Button(action: {
                            showShareSheet = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.black)
                                    .font(.title3)
                                    .shadow(color: .white, radius: 2)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(
                    activityItems: [generateShareText()]
                )
            }
            .sheet(isPresented: $showDemoInfo) {
                DemoInfoSheet()
            }
            .onAppear {
                // Add demo to recent searches
                preferences.addDemoToRecentSearches()
            }
        }
    }
    
    // MARK: - Demo Banner
    
    private var demoBanner: some View {
        HStack {
            Image(systemName: "play.circle.fill")
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Demo Mode")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                Text("This is sample data to showcase app features")
                    .font(.caption2)
                    .foregroundColor(Color("FplTextSecondary"))
            }
            
            Spacer()
            
            Button("Learn More") {
                showDemoInfo = true
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.1))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.blue.opacity(0.3)),
            alignment: .bottom
        )
    }
    
    private func generateShareText() -> String {
        var text = "\(demoStatistics.leagueName) - Demo\n\n"
        
        if let bestGW = demoStatistics.records.first(where: { $0.type == .bestGameweek }) {
            text += "🏆 Best Gameweek: \(bestGW.managerName) - \(bestGW.value) pts\n"
        }
        
        if let topManager = demoStatistics.managerStatistics.max(by: { $0.averagePoints < $1.averagePoints }) {
            text += "👑 Top Average: \(topManager.managerName) - \(String(format: "%.1f", topManager.averagePoints)) pts/gw\n"
        }
        
        text += "\nTry FPL.stats for your own league analysis!"
        
        return text
    }
}

// MARK: - Demo Info Sheet

struct DemoInfoSheet: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Welcome to FPL.stats Demo!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("This demo showcases all the powerful features available for analyzing your Fantasy Premier League performance.")
                            .font(.subheadline)
                            .foregroundColor(Color("FplTextSecondary"))
                    }
                    
                    // Features Overview
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Explore These Features:")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        DemoFeature(
                            icon: "trophy.fill",
                            title: "Records",
                            description: "Best and worst performances, including enhanced chip analysis with captain details"
                        )
                        
                        DemoFeature(
                            icon: "list.number",
                            title: "Rankings",
                            description: "Manager performance rankings by various metrics like consistency and average points"
                        )
                        
                        DemoFeature(
                            icon: "person.2.fill",
                            title: "Head-to-Head",
                            description: "Direct comparisons between managers with win/loss records and biggest victories"
                        )
                        
                        DemoFeature(
                            icon: "star.circle.fill",
                            title: "Chips Analysis",
                            description: "Detailed breakdown of chip usage effectiveness with timing recommendations"
                        )
                        
                        DemoFeature(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Trends",
                            description: "Visual charts showing performance progression over gameweeks"
                        )
                        
                        DemoFeature(
                            icon: "magnifyingglass.circle.fill",
                            title: "Player Analysis",
                            description: "Identify missed opportunities and underperforming players in your squad"
                        )
                        
                        DemoFeature(
                            icon: "star.slash.fill",
                            title: "Differentials",
                            description: "Analysis of unique picks and their impact on league standings"
                        )
                        
                        DemoFeature(
                            icon: "questionmark.circle.fill",
                            title: "What-If Scenarios",
                            description: "Explore alternative timelines and decision impacts"
                        )
                    }
                    
                    // Call to Action
                    VStack(spacing: 16) {
                        Divider()
                        
                        VStack(alignment: .center, spacing: 12) {
                            Text("Ready to analyze your real league?")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                            
                            Text("Close this demo and enter your league ID to get started with real data analysis!")
                                .font(.subheadline)
                                .foregroundColor(Color("FplTextSecondary"))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("FplPrimary").opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Disclaimer
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About This Demo")
                            .font(.headline)
                        
                        Text("All data shown in this demo is simulated and does not represent real FPL managers or performance. The demo is designed to showcase the app's analytical capabilities.")
                            .font(.caption)
                            .foregroundColor(Color("FplTextSecondary"))
                            .padding()
                            .background(Color("FplBackground"))
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Demo Information")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct DemoFeature: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color("FplPrimary").opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(Color("FplPrimary"))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(Color("FplTextSecondary"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

#Preview {
    DemoLeagueStatisticsView()
}
