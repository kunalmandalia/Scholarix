import SwiftUI

struct MainTabView: View {
    // We use this state to track which tab is currently active
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Hub 1: Academic (Your GPA + Calendar)
            AcademicView()
                .tabItem {
                    Label("Academic", systemImage: "book.fill")
                }
                .tag(0)
            
            // Hub 2: Health & Wellness (Placeholder)
            Text("Health Hub\n(Coming Soon)")
                .multilineTextAlignment(.center)
                .tabItem {
                    Label("Wellness", systemImage: "heart.fill")
                }
                .tag(1)
            
            // Hub 3: AI Coach (Placeholder)
            Text("AI Coach\n(Coming Soon)")
                .multilineTextAlignment(.center)
                .tabItem {
                    Label("AI Coach", systemImage: "brain.head.profile")
                }
                .tag(2)
            
            // Hub 4: Resume Builder (Replaced Settings)
            ExtracurricularsView()
                .tabItem {
                    Label("Extracurriculars", systemImage: "doc.text.fill")
                }
                .tag(3)
        }
        // This sets the color of the active tab icon to blue
        .accentColor(.blue)
        .toolbar(.visible, for: .tabBar)
    }
}

#Preview {
    MainTabView()
}
