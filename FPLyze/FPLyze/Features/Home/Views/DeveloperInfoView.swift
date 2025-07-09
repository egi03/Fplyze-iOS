//
//  DeveloperInfoView.swift
//  FPL.stats
//
//  Created by Eugen Sedlar on 09.07.2025..
//

import SwiftUI

struct DeveloperInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showingEmailComposer = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header with app info
                    VStack(spacing: 16) {
                        // App icon placeholder (replace with your actual icon)
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color("FplPrimary"), Color("FplAccent")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        .shadow(color: Color("FplPrimary").opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        VStack(spacing: 8) {
                            Text("FPL.stats")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("v1.0.0")
                                .font(.caption)
                                .foregroundColor(Color("FplTextSecondary"))
                        }
                    }
                    
                    // Developer info
                    VStack(spacing: 20) {
                        VStack(spacing: 12) {
                            Text("👋 Meet the Developer")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            Text("Hi! I'm Eugen Sedlar, a 22-year-old computer science student from Croatia 🇭🇷. I created FPL.stats to help fellow managers analyze their leagues and improve their game.")
                                .font(.subheadline)
                                .foregroundColor(Color("FplTextSecondary"))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .padding()
                        .background(Color("FplSurface"))
                        .cornerRadius(16)
                        
                        // Contact section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Get in Touch")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            VStack(spacing: 12) {
                                ContactRow(
                                    icon: "envelope.fill",
                                    title: "Email",
                                    subtitle: "eugen.sedlar@fpl.com",
                                    color: .blue,
                                    action: {
                                        sendEmail()
                                    }
                                )
                                
                                ContactRow(
                                    icon: "link",
                                    title: "LinkedIn",
                                    subtitle: "Connect with me",
                                    color: Color(red: 0.0, green: 0.47, blue: 0.75),
                                    action: {
                                        openURL("https://linkedin.com/in/eugen-sedlar")
                                    }
                                )
                                
                                ContactRow(
                                    icon: "chevron.left.forwardslash.chevron.right",
                                    title: "GitHub",
                                    subtitle: "Check out my other projects",
                                    color: Color(white: 0.1),
                                    action: {
                                        openURL("https://github.com/egi03")
                                    }
                                )
                            }
                        }
                        .padding()
                        .background(Color("FplSurface"))
                        .cornerRadius(16)
                        
                        // App info
                        VStack(alignment: .leading, spacing: 16) {
                            Text("About FPL.stats")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                InfoRow(
                                    icon: "shield.checkered",
                                    title: "Privacy First",
                                    description: "No data collection, no tracking, no ads. Your league data stays on your device."
                                )
                                
                                InfoRow(
                                    icon: "globe",
                                    title: "Data Source",
                                    description: "All statistics are sourced directly from the official Fantasy Premier League API."
                                )
                                
                                InfoRow(
                                    icon: "heart.fill",
                                    title: "Made with Love",
                                    description: "Built by a fellow FPL manager and made avaliable for free to everyone!"
                                )
                            }
                        }
                        .padding()
                        .background(Color("FplSurface"))
                        .cornerRadius(16)
                        
                        // Fun fact
                        VStack(spacing: 8) {
                            Text("🏆 Goal")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text("My main goal is to deliver interesting insights about your league all completly free, without any ads, tracking, data collecting or registration required.")
                                .font(.caption)
                                .foregroundColor(Color("FplTextSecondary"))
                                .multilineTextAlignment(.center)
                                .italic()
                        }
                        .padding()
                        .background(Color("FplAccent").opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .background(Color("FplBackground"))
            .navigationTitle("Developer Info")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func sendEmail() {
        let email = "eugen.sedlar@fpl.com"
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Supporting Views

struct ContactRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("FplTextPrimary"))
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(Color("FplTextSecondary"))
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(Color("FplTextSecondary"))
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color("FplAccent"))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(Color("FplTextSecondary"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
