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
    
    // Using system theme by default

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Inject the SessionManager into the environment
                .environmentObject(sessionManager)
        }
    }
}
