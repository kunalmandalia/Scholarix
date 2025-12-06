//
//  ScholarixApp.swift
//  Scholarix
//
//  Created by Kunal Mandalia on 10/12/25.
//

import SwiftUI
import FirebaseCore

@main
struct ScholarixApp: App {
    // This line connects your AppDelegate file for Firebase setup.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // This creates one instance of our SessionManager and keeps it alive
    // for the entire time the app is running.
    @StateObject private var sessionManager = SessionManager()
    
    // Watch the stored theme setting from UserDefaults
    @AppStorage("appTheme") private var appTheme: String = "system"

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Inject the SessionManager into the environment
                .environmentObject(sessionManager)
                // Apply the animation to the CONTENT changes (colors, backgrounds)
                .animation(.easeInOut(duration: 0.8), value: appTheme)
                // Force the color scheme based on the user's setting
                .preferredColorScheme(selectedScheme)
        }
    }
    
    // Helper to convert the string setting to a SwiftUI ColorScheme
    var selectedScheme: ColorScheme? {
        switch appTheme {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil // This means "System Default"
        }
    }
}
