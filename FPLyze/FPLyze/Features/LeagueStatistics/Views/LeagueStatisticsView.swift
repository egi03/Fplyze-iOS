//
//  LeagueStatisticsView.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 21.06.2025..
//

import SwiftUI

struct LeagueStatisticsView: View {
    let leagueId: Int
    @StateObject private var viewModel = LeagueStatisticsViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var animateGradient = false
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                switch viewModel.state {
                case .idle:
                    Color.clear
                        .onAppear {
                            Task {
                                await viewModel.loadStatistics(for: leagueId)
                            }
                        }
                    
                case .loading:
                    loadingView
                    
                case .loaded:
                    if let statistics = viewModel.statistics {
                        mainContent(statistics: statistics)
                    }
                    
                case .error:
                    errorView(error: viewModel.error ?? "Unknown error")
                }
            }
            .navigationTitle(viewModel.leagueName ?? "League Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Enhanced Favorite Button with visible outline
                        Button(action: {
                            withAnimation(.spring()) {
                                viewModel.toggleFavorite(leagueId: leagueId)
                            }
                        }) {
                            ZStack {
                                // Background circle for better visibility
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: viewModel.isFavorite ? "star.fill" : "star")
                                    .foregroundColor(viewModel.isFavorite ? .yellow : .black)
                                    .font(.title3)
                                    .scaleEffect(viewModel.isFavorite ? 1.2 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.isFavorite)
                                    // Add shadow for better visibility on light backgrounds
                                    .shadow(color: .white, radius: viewModel.isFavorite ? 0 : 2)
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
                if let statistics = viewModel.statistics {
                    ShareSheet(
                        activityItems: [generateShareText(for: statistics)]
                    )
                }
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 30) {
            // Custom Loading Animation
            ZStack {
                Circle()
                    .stroke(Color("FplDivider"), lineWidth: 4)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: viewModel.loadingProgress)
                    .stroke(
                        LinearGradient(
                            colors: [Color("FplPrimary"), Color("FplAccent")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(Angle(degrees: -90))
                    .animation(.spring(), value: viewModel.loadingProgress)
                
                Text("\(Int(viewModel.loadingProgress * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color("FplTextPrimary"))
            }
            
            VStack(spacing: 8) {
                Text(viewModel.loadingMessage)
                    .foregroundColor(Color("FplTextPrimary"))
                    .font(.headline)
                    .animation(.easeInOut, value: viewModel.loadingMessage)
                
                Text("League ID: \(leagueId)")
                    .foregroundColor(Color("FplTextSecondary"))
                    .font(.caption)
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("FplCardBackground"))
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color("FplDivider"), lineWidth: 1)
        )
    }
    
    private func errorView(error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
                .symbolEffect(.bounce, value: error)

            Text("Error Loading Statistics")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(error)
                .multilineTextAlignment(.center)
                .foregroundColor(Color("FplTextSecondary"))
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                Button(action: {
                    Task {
                        await viewModel.loadStatistics(for: leagueId)
                    }
                }) {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color("FplSurface"))
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding()
    }
    
    private func mainContent(statistics: LeagueStatisticsData) -> some View {
        VStack(spacing: 0) {
            StatisticsTabBar(
                selectedTab: $viewModel.selectedTab,
                onTabSelected: viewModel.selectTab
            )
            
            TabView(selection: $viewModel.selectedTab) {
                RecordsTab(records: statistics.records)
                    .tag(StatisticsTab.records)
                
                RankingsTab(statistics: statistics.managerStatistics)
                    .tag(StatisticsTab.rankings)
                
                HeadToHeadTab(records: statistics.headToHeadStatistics)
                    .tag(StatisticsTab.headToHead)
                
                ChipsTab(members: statistics.members)
                    .tag(StatisticsTab.chips)
                
                TrendsTab(members: statistics.members)
                    .tag(StatisticsTab.trends)
                
                PlayerAnalysisTab(
                    missedAnalyses: statistics.missedPlayerAnalyses,
                    underperformerAnalyses: statistics.underperformerAnalyses
                )
                .tag(StatisticsTab.playerAnalysis)
                
                DifferentialAnalysisTab(analyses: statistics.differentialAnalyses)
                    .tag(StatisticsTab.differentials)
                
                WhatIfScenariosTab(scenarios: statistics.whatIfScenarios)
                    .tag(StatisticsTab.whatIf)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: viewModel.selectedTab)
            .refreshable {
                await viewModel.refresh(leagueId: leagueId)
            }
        }
    }
    
    private func generateShareText(for statistics: LeagueStatisticsData) -> String {
        var text = "\(statistics.leagueName) (ID: \(leagueId))\n\n"
        
        if let bestGW = statistics.records.first(where: { $0.type == .bestGameweek }) {
            text += "🏆 Best Gameweek: \(bestGW.managerName) - \(bestGW.value) pts\n"
        }
        
        if let topManager = statistics.managerStatistics.max(by: { $0.averagePoints < $1.averagePoints }) {
            text += "👑 Top Average: \(topManager.managerName) - \(String(format: "%.1f", topManager.averagePoints)) pts/gw\n"
        }
        
        text += "\nView more stats with FPL.stats!"
        
        return text
    }
}

// MARK: - Statistics tab bar
struct StatisticsTabBar: View {
    @Binding var selectedTab: StatisticsTab
    let onTabSelected: (StatisticsTab) -> Void
    @Namespace private var animation
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16){
                ForEach(StatisticsTab.allCases, id: \.self) { tab in
                    EnhancedTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        namespace: animation,
                        action: { onTabSelected(tab) }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color("FplBackground"))
        .shadow(color: .black.opacity(0.1), radius: 5, y: 5)
    }
}

struct EnhancedTabButton: View {
    let tab: StatisticsTab
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color("FplPrimary") : Color.clear)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: tab.icon)
                        .font(.title3)
                        .foregroundColor(isSelected ? .white : Color("FplTextSecondary"))
                        .symbolEffect(.bounce, value: isSelected)
                }
                
                Text(tab.rawValue)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? Color("FplPrimary") : Color("FplTextSecondary"))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .frame(minWidth: 60)
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("FplPrimary").opacity(0.1))
                            .matchedGeometryEffect(id: "tab_background", in: namespace)
                    }
                }
            )
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct TabBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color)
            .clipShape(Capsule())
            .scaleEffect(0.8)
    }
}

struct TabButton: View {
    let tab: StatisticsTab
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.title2)
                    .symbolEffect(.bounce, value: isSelected)
                
                Text(tab.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
            }
            .foregroundColor(isSelected ? Color("FplPrimary") : Color("FplTextSecondary"))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color("FplPrimary").opacity(0.1))
                            .matchedGeometryEffect(id: "tab", in: namespace)
                    }
                }
            )
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
