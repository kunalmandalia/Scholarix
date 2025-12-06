import SwiftUI

struct LoadingView: View {
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            // Modern Gradient Background (Subtle)
            LinearGradient(
                colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Animated Logo Container
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
                .scaleEffect(showContent ? 1.0 : 0.5)
                .opacity(showContent ? 1.0 : 0.0)
                
                // Text
                VStack(spacing: 8) {
                    Text("Scholarix")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Your Academic Hub")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .tracking(1) // Letter spacing
                }
                .offset(y: showContent ? 0 : 20)
                .opacity(showContent ? 1.0 : 0.0)
                
                // Custom Loading Spinner
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.blue)
                    .padding(.top, 20)
                    .opacity(showContent ? 1.0 : 0.0)
            }
        }
        .onAppear {
            // Trigger animation on appearance
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                showContent = true
            }
        }
    }
}

#Preview {
    LoadingView()
}
