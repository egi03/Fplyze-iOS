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
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.error {
                    errorView(error: error)
                } else if let statistics = viewModel.statistics {
                    mainContent(statistics: statistics)
                }
            }
            .navigationTitle("League Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await viewModel.loadStatistics(for: leagueId)
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color("FplPrimary"),
                Color("FplSecondary").opacity(animateGradient ? 0.8 : 0.6),
                Color("FplPrimary")
            ],
            startPoint: .topLeading,
            endPoint: animateGradient ? .bottomTrailing : .bottomLeading
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("Loading statistics...")
                .foregroundColor(.white)
                .font(.headline)
        }
    }
    
    private func errorView(error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)

            Text("Error Loading Statistics")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(error)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
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
        .padding()
        .background(Color.white)
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
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: viewModel.selectedTab)
        }
    }
}

struct StatisticsTabBar: View {
    @Binding var selectedTab: StatisticsTab
    let onTabSelected: (StatisticsTab) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20){
                ForEach(StatisticsTab.allCases, id: \.self) { tab in
                    TabButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        action: { onTabSelected(tab) }
                    )
                }
            }
            .padding()
        }
        .background(Color.white)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 5)
    }
}

struct TabButton: View {
    let tab: StatisticsTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: tab.icon).font(.title2)
                
                Text(tab.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
            }
            .foregroundColor(isSelected ? Color("FplPrimary") : .gray)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color("FplAccent").opacity(0.2) : Color.clear)
            )
            
        }
    }
}
