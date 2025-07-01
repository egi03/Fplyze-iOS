//
//  HomeView.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 25.06.2025..
//

import SwiftUI

struct HomeView: View {
    @State private var leagueId = ""
    @State private var isShowingStatistics = false
    @State private var navigateToLeague = false
    @State private var showInvalidIdAlert = false
    @FocusState private var isSearchFocused: Bool
    @State private var animateGradient = false
    
    var body: some View {
        NavigationStack {
            ZStack {
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
                
                VStack(spacing: 40) {
                    // Logo and Title
                    VStack(spacing: 20) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 10)
                        
                        Text("FPL.stats")
                            .font(.system(size: 50, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Fantasy Premier League Statistics")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.top, 60)
                    
                    // Search Section
                    VStack(spacing: 20) {
                        Text("Enter your league ID")
                            .font(.title3)
                            .foregroundColor(.white)
                        
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .font(.title2)
                            
                            TextField("League ID", text: $leagueId)
                                .keyboardType(.numberPad)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.title3)
                                .focused($isSearchFocused)
                                .onSubmit {
                                    searchLeague()
                                }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.2), radius: 10)
                        .frame(maxWidth: 350)
                        
                        // Search Button
                        Button(action: searchLeague) {
                            HStack {
                                Text("View Statistics")
                                    .fontWeight(.semibold)
                                
                                Image(systemName: "arrow.right.circle.fill")
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(
                                LinearGradient(
                                    colors: [Color("FplAccent"), Color("FplAccent").opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(30)
                            .shadow(color: Color("FplAccent").opacity(0.3), radius: 10)
                        }
                        .disabled(leagueId.isEmpty)
                        .opacity(leagueId.isEmpty ? 0.6 : 1.0)
                        .scaleEffect(leagueId.isEmpty ? 0.95 : 1.0)
                        .animation(.spring(response: 0.3), value: leagueId.isEmpty)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Footer
                    VStack(spacing: 10) {
                        Text("How to find your league ID:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Go to your league page on fantasy.premierleague.com\nThe ID is in the URL: /leagues/[ID]/standings")
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.bottom, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToLeague) {
                if let id = Int(leagueId) {
                    LeagueStatisticsView(leagueId: id)
                        .navigationBarHidden(true)
                }
            }
            .alert("Invalid League ID", isPresented: $showInvalidIdAlert) {
                Button("OK") {
                    leagueId = ""
                    isSearchFocused = true
                }
            } message: {
                Text("Please enter a valid league ID number")
            }
            .onTapGesture {
                isSearchFocused = false
            }
        }
    }
    
    private func searchLeague() {
        isSearchFocused = false
        
        guard !leagueId.isEmpty, Int(leagueId) != nil else {
            showInvalidIdAlert = true
            return
        }
        
        navigateToLeague = true
    }
}

// Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
