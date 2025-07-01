//
//  ViewModifiers.swift
//  FPLyze
//
//  Created by Eugen Sedlar on 01.07.2025..
//

import SwiftUI

// MARK: - Card Modifier
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color("FplCardBackground"))
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.1), radius: 5)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}

// MARK: - Loading Overlay
struct LoadingOverlay: ViewModifier {
    let isLoading: Bool
    let message: String?
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
                .blur(radius: isLoading ? 3 : 0)
            
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color("FplPrimary")))
                        .scaleEffect(1.5)
                    
                    if let message = message {
                        Text(message)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
                .padding(30)
                .background(Color("FplCardBackground"))
                .cornerRadius(20)
                .shadow(radius: 10)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(), value: isLoading)
    }
}

extension View {
    func loadingOverlay(isLoading: Bool, message: String? = nil) -> some View {
        modifier(LoadingOverlay(isLoading: isLoading, message: message))
    }
}

// MARK: - Shimmer Effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    let animation: Animation
    
    init(animation: Animation = .linear(duration: 1.5).repeatForever(autoreverses: false)) {
        self.animation = animation
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.3),
                        Color.white.opacity(0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase * 200 - 100)
                .mask(content)
            )
            .onAppear {
                withAnimation(animation) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Bounce Animation
struct BounceModifier: ViewModifier {
    @State private var scale: CGFloat = 1
    let trigger: Bool
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .scaleEffect(scale)
                .onChange(of: trigger) {
                    performBounce()
                }
        } else {
            content
                .scaleEffect(scale)
                .onChange(of: trigger) { _ in
                    performBounce()
                }
        }
    }
    
    private func performBounce() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.3)) {
            scale = 1.2
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8).delay(0.1)) {
            scale = 1.0
        }
    }
}

extension View {
    func bounce(trigger: Bool) -> some View {
        modifier(BounceModifier(trigger: trigger))
    }
}

// MARK: - Success/Error Banner
struct BannerModifier: ViewModifier {
    @Binding var show: Bool
    let message: String
    let type: BannerType
    
    enum BannerType {
        case success, error, info
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .info: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if show {
                HStack {
                    Image(systemName: type.icon)
                        .foregroundColor(.white)
                    
                    Text(message)
                        .foregroundColor(.white)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Button(action: { show = false }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                }
                .padding()
                .background(type.color)
                .cornerRadius(10)
                .shadow(radius: 5)
                .padding()
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            show = false
                        }
                    }
                }
            }
        }
        .animation(.spring(), value: show)
    }
}

extension View {
    func banner(show: Binding<Bool>, message: String, type: BannerModifier.BannerType) -> some View {
        modifier(BannerModifier(show: show, message: message, type: type))
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let action: (() -> Void)?
    let actionTitle: String?
    
    init(
        icon: String,
        title: String,
        message: String,
        action: (() -> Void)? = nil,
        actionTitle: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.action = action
        self.actionTitle = actionTitle
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(Color("FplTextSecondary"))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(Color("FplTextSecondary"))
                    .multilineTextAlignment(.center)
            }
            
            if let action = action, let actionTitle = actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color("FplPrimary"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Number Animation
struct AnimatedNumber: View {
    let value: Int
    @State private var animatedValue: Int = 0
    
    var body: some View {
        Text("\(animatedValue)")
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    animatedValue = value
                }
            }
            .onChangeCompat(of: value) {
                withAnimation(.easeOut(duration: 0.5)) {
                    animatedValue = value
                }
            }
    }
}

// MARK: - Backward Compatible onChange
extension View {
    @ViewBuilder
    func onChangeCompat<T: Equatable>(of value: T, perform: @escaping () -> Void) -> some View {
        if #available(iOS 17.0, *) {
            self.onChange(of: value) {
                perform()
            }
        } else {
            self.onChange(of: value) { _ in
                perform()
            }
        }
    }
}
