//
//  ThemeComponents.swift
//  FPL.stats
//
//  Created by Eugen Sedlar on 09.07.2025..
//

import SwiftUI

// MARK: - Floating Theme Toggle
struct FloatingThemeToggle: View {
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var isExpanded = false
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                ZStack {
                    // Expanded options
                    if isExpanded {
                        VStack(spacing: 12) {
                            ForEach(AppearanceMode.allCases.reversed(), id: \.self) { mode in
                                Button(action: {
                                    withAnimation(.spring()) {
                                        themeManager.setTheme(mode)
                                        isExpanded = false
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(themeManager.currentMode == mode ? Color("FplPrimary") : Color("FplSurface"))
                                            .frame(width: 44, height: 44)
                                            .shadow(color: .black.opacity(0.1), radius: 3)
                                        
                                        Image(systemName: mode.icon)
                                            .foregroundColor(themeManager.currentMode == mode ? .white : Color("FplTextPrimary"))
                                            .font(.system(size: 18))
                                    }
                                }
                                .scaleEffect(isExpanded ? 1.0 : 0.0)
                                .opacity(isExpanded ? 1.0 : 0.0)
                                .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(AppearanceMode.allCases.firstIndex(of: mode) ?? 0) * 0.1), value: isExpanded)
                            }
                        }
                        .offset(y: -60)
                    }
                    
                    // Main toggle button
                    Button(action: {
                        withAnimation(.spring()) {
                            isExpanded.toggle()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color("FplPrimary"))
                                .frame(width: 56, height: 56)
                                .shadow(color: Color("FplPrimary").opacity(0.3), radius: 10, x: 0, y: 5)
                            
                            Image(systemName: isExpanded ? "xmark" : themeManager.currentMode.icon)
                                .foregroundColor(.white)
                                .font(.system(size: 20, weight: .semibold))
                                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                                .animation(.spring(response: 0.3), value: isExpanded)
                        }
                    }
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Theme Status Indicator
struct ThemeStatusIndicator: View {
    @ObservedObject var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: themeManager.currentMode.icon)
                .font(.caption2)
                .foregroundColor(Color("FplTextSecondary"))
            
            Text(themeManager.currentMode.displayName)
                .font(.caption2)
                .foregroundColor(Color("FplTextSecondary"))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color("FplSurface").opacity(0.8))
        .cornerRadius(8)
    }
}

// MARK: - Adaptive Color Preview
struct AdaptiveColorPreview: View {
    let colorName: String
    
    var body: some View {
        VStack(spacing: 4) {
            Rectangle()
                .fill(Color(colorName))
                .frame(height: 30)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color("FplDivider"), lineWidth: 1)
                )
            
            Text(colorName)
                .font(.caption2)
                .foregroundColor(Color("FplTextSecondary"))
        }
    }
}

// MARK: - Theme Preview Grid
struct ThemePreviewGrid: View {
    let colorNames = [
        "FplBackground",
        "FplSurface",
        "FplCardBackground",
        "FplTextPrimary",
        "FplTextSecondary",
        "FplPrimary",
        "FplAccent",
        "FplDivider"
    ]
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
            ForEach(colorNames, id: \.self) { colorName in
                AdaptiveColorPreview(colorName: colorName)
            }
        }
        .padding()
        .background(Color("FplSurface"))
        .cornerRadius(12)
    }
}

// MARK: - Animated Theme Transition
struct AnimatedThemeTransition: ViewModifier {
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var animationTrigger = false
    
    func body(content: Content) -> some View {
        content
            .animation(.easeInOut(duration: 0.3), value: themeManager.isDarkMode)
            .onChange(of: themeManager.currentMode) { _ in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    animationTrigger.toggle()
                }
            }
    }
}

extension View {
    func animatedThemeTransition() -> some View {
        modifier(AnimatedThemeTransition())
    }
}

// MARK: - Dark Mode Aware Shadow
struct AdaptiveShadow: ViewModifier {
    @ObservedObject var themeManager = ThemeManager.shared
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: themeManager.isDarkMode ?
                    Color.white.opacity(0.1) : Color.black.opacity(0.1),
                radius: radius,
                x: x,
                y: y
            )
    }
}

extension View {
    func adaptiveShadow(radius: CGFloat = 5, x: CGFloat = 0, y: CGFloat = 2) -> some View {
        modifier(AdaptiveShadow(radius: radius, x: x, y: y))
    }
}

// MARK: - Theme Debug View (for development)
struct ThemeDebugView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Theme Debug")
                .font(.headline)
            
            HStack {
                Text("Current Mode:")
                Text(themeManager.currentMode.displayName)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack {
                Text("Is Dark Mode:")
                Text(themeManager.isDarkMode ? "Yes" : "No")
                    .fontWeight(.semibold)
                Spacer()
            }
            
            ThemePreviewGrid()
            
            HStack {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    Button(mode.displayName) {
                        themeManager.setTheme(mode)
                    }
                    .buttonStyle(.bordered)
                    .disabled(themeManager.currentMode == mode)
                }
            }
        }
        .padding()
        .background(Color("FplSurface"))
        .cornerRadius(12)
    }
}

#if DEBUG
struct ThemeDebugOverlay: View {
    @State private var isVisible = false
    
    var body: some View {
        VStack {
            Spacer()
            
            if isVisible {
                ThemeDebugView()
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            HStack {
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isVisible.toggle()
                    }
                }) {
                    Image(systemName: "eye.circle.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                        .background(Circle().fill(Color.white))
                }
                .padding()
            }
        }
    }
}
#endif
