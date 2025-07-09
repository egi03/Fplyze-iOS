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
            
            CustomRefreshableTabView(
                selectedTab: $viewModel.selectedTab,
                statistics: statistics,
                isRefreshing: viewModel.refreshing,
                onRefresh: {
                    Task {
                        await viewModel.refresh(leagueId: leagueId)
                    }
                }
            )
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
            HStack(spacing: 8){  // Reduced from 16 to 8
                ForEach(StatisticsTab.allCases, id: \.self) { tab in
                    EnhancedTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        namespace: animation,
                        action: { onTabSelected(tab) }
                    )
                }
            }
            .padding(.horizontal, 12)  // Reduced from default to 12
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
            VStack(spacing: 4) {  // Reduced from 6 to 4
                ZStack {
                    Circle()
                        .fill(isSelected ? Color("FplPrimary") : Color.clear)
                        .frame(width: 36, height: 36)  // Reduced from 40 to 36
                    
                    Image(systemName: tab.icon)
                        .font(.system(size: 16))  // More specific size instead of title3
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
            .frame(minWidth: 50)  // Reduced from 60 to 50
            .padding(.vertical, 6)  // Reduced from 8 to 6
            .padding(.horizontal, 6)  // Reduced from 8 to 6
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)  // Reduced from 12 to 10
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
            VStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18))  // More specific size
                    .symbolEffect(.bounce, value: isSelected)
                
                Text(tab.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
            }
            .foregroundColor(isSelected ? Color("FplPrimary") : Color("FplTextSecondary"))
            .padding(.horizontal, 12)  // Reduced from 16
            .padding(.vertical, 6)  // Reduced from 8
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)  // Reduced from 10
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

// MARK: - Custom Refreshable TabView
struct CustomRefreshableTabView: View {
    @Binding var selectedTab: StatisticsTab
    let statistics: LeagueStatisticsData
    let isRefreshing: Bool
    let onRefresh: () -> Void
    
    @State private var pullProgress: CGFloat = 0
    @State private var isPulling: Bool = false
    @State private var showRefreshHint: Bool = false
    
    // Customizable thresholds
    private let refreshThreshold: CGFloat = 80.0  // Require 80pt pull instead of default ~50pt
    private let maxPullDistance: CGFloat = 120.0
    
    var refreshProgress: CGFloat {
        min(pullProgress / refreshThreshold, 1.0)
    }
    
    var pullHintText: String {
        if refreshProgress >= 1.0 {
            return "Release to refresh"
        } else if refreshProgress > 0.3 {
            return "Pull further to refresh"
        } else if refreshProgress > 0 {
            return "Keep pulling..."
        } else {
            return ""
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        // Custom refresh indicator
                        refreshIndicator
                        
                        // Tab content
                        tabContent
                    }
                    .background(
                        GeometryReader { contentGeometry in
                            Color.clear
                                .onChangeCompat(of: contentGeometry.frame(in: .global).minY) {
                                    handleScrollChange(
                                        scrollY: contentGeometry.frame(in: .global).minY,
                                        geometryHeight: geometry.size.height
                                    )
                                }
                        }
                    )
                }
                .coordinateSpace(name: "scroll")
            }
        }
        .onChangeCompat(of: isRefreshing) {
            if !isRefreshing {
                withAnimation(.spring()) {
                    pullProgress = 0
                    isPulling = false
                    showRefreshHint = false
                }
            }
        }
    }
    
    private var refreshIndicator: some View {
        VStack(spacing: 8) {
            if pullProgress > 0 || isRefreshing {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Color("FplDivider"), lineWidth: 3)
                            .frame(width: 30, height: 30)
                        
                        Circle()
                            .trim(from: 0, to: isRefreshing ? 1 : refreshProgress)
                            .stroke(
                                Color("FplPrimary"),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: 30, height: 30)
                            .rotationEffect(.degrees(-90))
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(
                                isRefreshing ?
                                .linear(duration: 1.0).repeatForever(autoreverses: false) :
                                .spring(),
                                value: isRefreshing ? 360 : refreshProgress
                            )
                        
                        if !isRefreshing && refreshProgress >= 1.0 {
                            Image(systemName: "arrow.up")
                                .font(.caption)
                                .foregroundColor(Color("FplPrimary"))
                                .scaleEffect(0.8)
                        }
                    }
                    
                    if showRefreshHint && !pullHintText.isEmpty {
                        Text(pullHintText)
                            .font(.caption)
                            .foregroundColor(Color("FplTextSecondary"))
                            .transition(.opacity.combined(with: .scale))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color("FplBackground"))
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(height: max(0, pullProgress * 0.6)) // Visual height based on pull
        .clipped()
    }
    
    private var tabContent: some View {
        TabView(selection: $selectedTab) {
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
        .animation(.easeInOut, value: selectedTab)
        .frame(height: UIScreen.main.bounds.height - 200) // Give it a reasonable height
    }
    
    private func handleScrollChange(scrollY: CGFloat, geometryHeight: CGFloat) {
        // Only respond to pulls when at the top of the content
        if scrollY > 0 && !isRefreshing {
            let newProgress = min(scrollY, maxPullDistance)
            
            withAnimation(.interactiveSpring()) {
                pullProgress = newProgress
                isPulling = newProgress > 10
                showRefreshHint = newProgress > 20
            }
            
            // Trigger refresh when threshold is met and user releases
            if newProgress >= refreshThreshold && !isPulling {
                triggerRefresh()
            }
        } else if scrollY <= 0 && isPulling {
            // User released the pull
            if pullProgress >= refreshThreshold {
                triggerRefresh()
            } else {
                // Reset if didn't pull far enough
                withAnimation(.spring()) {
                    pullProgress = 0
                    isPulling = false
                    showRefreshHint = false
                }
            }
        }
    }
    
    private func triggerRefresh() {
        guard !isRefreshing else { return }
        
        withAnimation(.spring()) {
            isPulling = false
            showRefreshHint = false
        }
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        onRefresh()
    }
}
