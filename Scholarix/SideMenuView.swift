import SwiftUI
import FirebaseAuth

struct SideMenuView: View {
    @EnvironmentObject var menuManager: MenuManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 30) {
                // --- Header ---
                VStack(alignment: .leading) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text(Auth.auth().currentUser?.email ?? "User")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .padding(.top, 50)
                
                Divider()
                
                // --- Menu Options ---
                
                Button(action: { menuManager.close() }) {
                    Label("Profile", systemImage: "person.fill")
                        .font(.headline).foregroundColor(.primary)
                }
                
                Button(action: {
                    // --- FIX: Use the manager function to switch views ---
                    menuManager.openSettings()
                }) {
                    Label("Settings", systemImage: "gearshape.fill")
                        .font(.headline).foregroundColor(.primary)
                }
                
                Button(action: { menuManager.close() }) {
                    Label("About", systemImage: "info.circle.fill")
                        .font(.headline).foregroundColor(.primary)
                }
                
                Spacer()
                
                Button(action: {
                    try? Auth.auth().signOut()
                    menuManager.close()
                }) {
                    Label("Log Out", systemImage: "arrow.left.square.fill")
                        .font(.headline).foregroundColor(.red)
                }
                .padding(.bottom, 50)
            }
            .padding(.horizontal)
            .frame(maxWidth: 270)
            .background(Color(UIColor.secondarySystemBackground))
            .edgesIgnoringSafeArea(.vertical)
            
            Spacer()
        }
        // Note: We removed the .fullScreenCover modifier from here.
        // The ContentView now handles showing the Settings view.
    }
}

#Preview {
    SideMenuView()
        .environmentObject(MenuManager())
}
