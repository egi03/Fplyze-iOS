//
//  HeadToHeadTab.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 21.06.2025..
//

import SwiftUI

struct HeadToHeadTab: View {
    let records: [HeadToHeadRecord]
    @State private var selectedRecord: HeadToHeadRecord?
    @State private var searchText = ""
    
    var filteredRecords: [HeadToHeadRecord] {
        if searchText.isEmpty {
            return records
        }
        return records.filter {
            $0.manager1Name.localizedCaseInsensitiveContains(searchText) ||
            $0.manager2Name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            SearchBar(text: $searchText)
                .padding()
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredRecords) { record in
                        HeadToHeadCard(
                            record: record,
                            isExpanded: selectedRecord?.id == record.id,
                            onTap: {
                                withAnimation(.spring()) {
                                    selectedRecord = selectedRecord?.id == record.id ? nil : record
                                }
                            }
                        )
                    }
                }
                .padding()
            }
        }
        .background(Color("FplBackground"))
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search managers...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
}

// MARK: - Head to Head Card
struct HeadToHeadCard: View {
    let record: HeadToHeadRecord
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Content
            HStack {
                // Manager 1
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.manager1Name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if isExpanded {
                        Text("\(record.totalPointsFor) pts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Score Display
                VStack(spacing: 4) {
                    HStack(spacing: 12) {
                        // Wins
                        VStack(spacing: 2) {
                            Text("\(record.wins)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("W")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        // Draws
                        VStack(spacing: 2) {
                            Text("\(record.draws)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                            Text("D")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        // Losses
                        VStack(spacing: 2) {
                            Text("\(record.losses)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                            Text("L")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Win Percentage
                    if isExpanded {
                        let total = record.wins + record.draws + record.losses
                        let winPercentage = total > 0 ? (Double(record.wins) / Double(total)) * 100 : 0
                        
                        Text("\(Int(winPercentage))% Win Rate")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Manager 2
                VStack(alignment: .trailing, spacing: 4) {
                    Text(record.manager2Name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if isExpanded {
                        Text("\(record.totalPointsAgainst) pts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding()
            
            // Expanded Content
            if isExpanded {
                Divider()
                
                VStack(spacing: 16) {
                    // Biggest Results
                    HStack(spacing: 20) {
                        if let biggestWin = record.biggestWin {
                            BigResultView(
                                title: "Biggest Win",
                                comparison: biggestWin,
                                color: .green
                            )
                        }
                        
                        if let biggestLoss = record.biggestLoss {
                            BigResultView(
                                title: "Biggest Loss",
                                comparison: biggestLoss,
                                color: .red
                            )
                        }
                    }
                    
                    // Points Comparison
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total Points For")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(record.totalPointsFor)")
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Total Points Against")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(record.totalPointsAgainst)")
                                .font(.headline)
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5)
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Big Result View
struct BigResultView: View {
    let title: String
    let comparison: GameweekComparison
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(comparison.manager1Points) - \(comparison.manager2Points)")
                .font(.headline)
                .foregroundColor(color)
            
            Text("GW \(comparison.gameweek)")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text("+\(comparison.difference)")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(color.opacity(0.2))
                .foregroundColor(color)
                .cornerRadius(4)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}
