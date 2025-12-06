import SwiftUI

struct ExtracurricularsView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Resume Builder")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Track your clubs, service hours, and achievements here to build the perfect resume.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Resume")
        }
    }
}

#Preview {
    ExtracurricularsView()
}
