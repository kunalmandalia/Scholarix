import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @StateObject private var menuManager = MenuManager()
    
    // NOTE: This AppStorage variable is kept for reference/consistency but is not used
    // to control the global theme, as ScholarixApp.swift handles the main scheme.
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        ZStack {
            if sessionManager.isLoading {
                // 1. Loading
                ProgressView().scaleEffect(1.5)
                
            } else if let user = sessionManager.user {
                // 2. User is Logged In... But are they verified?
                
                if user.isEmailVerified {
                    // A. YES: Show the Main App
                    mainAppInterface
                    
                    // Settings Layer
                    if menuManager.showSettings {
                        // WRAPPER: Wrap SettingsView in a NavigationView to provide a toolbar/navigation bar
                        NavigationView {
                            // FIX 1: SettingsView now takes no arguments.
                            SettingsView()
                                .navigationBarTitle("Settings", displayMode: .inline)
                                .navigationBarItems(leading: Button(action: {
                                    // Close settings manually since we are in a custom overlay
                                    withAnimation {
                                        menuManager.showSettings = false
                                    }
                                }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: "chevron.left")
                                        Text("Back")
                                    }
                                })
                        }
                        .transition(.move(edge: .trailing))
                        .zIndex(3)
                    }
                } else {
                    // B. NO: Show the Verification Waiting Screen
                    VerificationSentView(email: user.email ?? "your email")
                }
                
            } else {
                // 3. Logged Out -> Show Welcome
                NavigationView {
                    WelcomeView()
                }
            }
        }
        // Apply the dark mode setting to the entire view hierarchy
        // The global theme is now set in ScholarixApp.swift using the string key.
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .environmentObject(menuManager)
        .animation(.easeInOut(duration: 0.3), value: menuManager.isOpen)
        .animation(.easeInOut(duration: 0.3), value: menuManager.showSettings)
    }
    
    var mainAppInterface: some View {
        ZStack(alignment: .leading) {
            MainTabView()
                .offset(x: menuManager.isOpen ? 270 : 0)
                .disabled(menuManager.isOpen)
            
            if menuManager.isOpen {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture { menuManager.close() }
                    .zIndex(1)
                
                SideMenuView()
                    .transition(.move(edge: .leading))
                    .zIndex(2)
            }
        }
    }
}
