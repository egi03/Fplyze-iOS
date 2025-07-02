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
                        // Favorite Button
                        Button(action: {
                            withAnimation(.spring()) {
                                viewModel.toggleFavorite(leagueId: leagueId)
                            }
                        }) {
                            Image(systemName: viewModel.isFavorite ? "star.fill" : "star")
                                .foregroundColor(viewModel.isFavorite ? .yellow : .white)
                                .scaleEffect(viewModel.isFavorite ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.isFavorite)
                        }
                        
                        // Share Button
                        Button(action: {
                            showShareSheet = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
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
                    .stroke(Color("FplSurface"), lineWidth: 4)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: viewModel.loadingProgress)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white, Color("FplAccent")],
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
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text(viewModel.loadingMessage)
                    .foregroundColor(.white)
                    .font(.headline)
                    .animation(.easeInOut, value: viewModel.loadingMessage)
                
                Text("League ID: \(leagueId)")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.caption)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.3))
                .blur(radius: 20)
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
        
        text += "\nView more stats with FPLyze!"
        
        return text
    }
}

// MARK: - Enhanced Tab Bar
struct StatisticsTabBar: View {
    @Binding var selectedTab: StatisticsTab
    let onTabSelected: (StatisticsTab) -> Void
    @Namespace private var animation
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20){
                ForEach(StatisticsTab.allCases, id: \.self) { tab in
                    TabButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        namespace: animation,
                        action: { onTabSelected(tab) }
                    )
                }
            }
            .padding()
        }
        .background(Color("FplBackground"))
        .shadow(color: .black.opacity(0.1), radius: 5, y: 5)
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
            .foregroundColor(isSelected ? Color("FplPrimary") : .gray)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color("FplAccent").opacity(0.2))
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
