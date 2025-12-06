import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    // CHANGED: Binding ensures the parent (AcademicView) updates instantly
    @Binding var isDarkMode: Bool
    
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @State private var showingSignOutAlert = false
    
    // Get current user email safely
    private var userEmail: String {
        Auth.auth().currentUser?.email ?? "Guest User"
    }
    
    // Get app version
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var body: some View {
        List {
            // --- SECTION 1: PROFILE ---
            Section {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 60, height: 60)
                        
                        Text(String(userEmail.prefix(1)).uppercased())
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Signed in as")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        Text(userEmail)
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color(.secondarySystemGroupedBackground))
            
            // --- SECTION 2: PREFERENCES ---
            Section(header: Text("Preferences")) {
                // Notifications: Set to OFF and Disabled
                Toggle(isOn: .constant(false)) {
                    Label {
                        Text("Notifications (Coming Soon)")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.secondary)
                    } icon: {
                        Image(systemName: "bell.slash.fill")
                            .foregroundColor(.gray)
                    }
                }
                .disabled(true)
                
                // Dark Mode: Functional via Binding
                Toggle(isOn: $isDarkMode) {
                    Label {
                        Text("Dark Mode")
                            .font(.system(.body, design: .rounded))
                    } icon: {
                        Image(systemName: "moon.fill")
                            .foregroundColor(.indigo)
                    }
                }
            }
            .listRowBackground(Color(.secondarySystemGroupedBackground))
            
            // --- SECTION 3: SUPPORT ---
            Section(header: Text("About")) {
                HStack {
                    Label {
                        Text("Version")
                            .font(.system(.body, design: .rounded))
                    } icon: {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                    }
                    Spacer()
                    Text(appVersion)
                        .font(.system(.callout, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Link(destination: URL(string: "https://www.google.com")!) {
                    Label {
                        Text("Help Center")
                            .font(.system(.body, design: .rounded))
                    } icon: {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            .listRowBackground(Color(.secondarySystemGroupedBackground))
            
            // --- SECTION 4: ACTIONS ---
            Section {
                Button(role: .destructive, action: {
                    showingSignOutAlert = true
                }) {
                    HStack {
                        Spacer()
                        Text("Sign Out")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.bold)
                        Spacer()
                    }
                }
            }
            .listRowBackground(Color(.secondarySystemGroupedBackground))
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .scrollContentBackground(.hidden)
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                do {
                    try Auth.auth().signOut()
                } catch {
                    print("Error signing out: \(error.localizedDescription)")
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}
