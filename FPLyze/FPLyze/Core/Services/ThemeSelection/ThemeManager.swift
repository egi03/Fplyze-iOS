//
//  ThemeManager.swift
//  FPL.stats
//
//  Created by Eugen Sedlar on 09.07.2025..
//

import SwiftUI
import Combine

enum AppearanceMode: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var displayName: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .system: return "gear"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentMode: AppearanceMode {
        didSet {
            saveThemePreference()
            updateAppearance()
        }
    }
    
    @Published var isDarkMode: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let themeKey = "app_theme_preference"
    
    private init() {
        // Load saved preference or default to system
        let savedTheme = userDefaults.string(forKey: themeKey) ?? AppearanceMode.system.rawValue
        self.currentMode = AppearanceMode(rawValue: savedTheme) ?? .system
        
        updateAppearance()
        observeSystemChanges()
    }
    
    private func saveThemePreference() {
        userDefaults.set(currentMode.rawValue, forKey: themeKey)
    }
    private func setAppearance(_ style: UIUserInterfaceStyle) {
        if let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = style
            }
        }
    }
    
    private func observeSystemChanges() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateAppearance()
        }
    }
    
    func toggleTheme() {
        switch currentMode {
        case .system, .light:
            currentMode = .dark
        case .dark:
            currentMode = .light
        }
    }
    
    func setTheme(_ mode: AppearanceMode) {
        currentMode = mode
    }
    
    func updateAppearance() {
        DispatchQueue.main.async {
            switch self.currentMode {
            case .system:
                // Follow system appearance
                if let windowScene = UIApplication.shared.connectedScenes
                    .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                    
                    windowScene.windows.forEach { window in
                        window.overrideUserInterfaceStyle = .unspecified
                    }
                    
                    // Update isDarkMode based on current system setting
                    self.isDarkMode = windowScene.traitCollection.userInterfaceStyle == .dark
                }
                
            case .light:
                self.setAppearance(.light)
                self.isDarkMode = false
                
            case .dark:
                self.setAppearance(.dark)
                self.isDarkMode = true
            }
        }
    }
}

// MARK: - Theme Environment Key
struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: ThemeManager = ThemeManager.shared
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}
