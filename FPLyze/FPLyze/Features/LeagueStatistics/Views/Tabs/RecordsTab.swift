//
//  RecordsTab.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 21.06.2025..
//

import SwiftUI

struct RecordsTab: View {
    let records: [LeagueRecord]
    @State private var expandedRecord: LeagueRecord?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                recordSection(
                    title: "Best Performances",
                    icon: "star.fill",
                    color: .yellow,
                    recordTypes: [
                        .bestGameweek,
                        .bestCaptain,
                        .bestBenchBoost,
                        .bestTripleCaptain,
                        .bestFreeHit,
                        .bestWildcard
                    ]
                )
                
                recordSection(
                    title: "Hall of Shame",
                    icon: "hand.thumbsdown.fill",
                    color: .red,
                    recordTypes: [
                        .worstGameweek,
                        .worstCaptain,
                        .biggestFall
                    ]
                )
            }
            .padding()
        }
        .background(Color("FplBackground"))
    }
    
    private func recordSection(
        title: String,
        icon: String,
        color: Color,
        recordTypes: [RecordType]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            ForEach(recordTypes, id: \.self) { recordType in
                if let record = records.first(where: { $0.type == recordType }) {
                    RecordCard(
                        record: record,
                        isExpanded: expandedRecord?.id == record.id,
                        onTap: {
                            withAnimation(.spring()) {
                                expandedRecord = expandedRecord?.id == record.id ? nil : record
                            }
                        }
                    )
                }
            }
        }
    }
}

