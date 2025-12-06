import SwiftUI

struct WelcomeView: View {
    var body: some View {
        ZStack {
            // --- 1. The Cool Background ---
            // A diagonal gradient from Blue to Purple feels academic yet modern.
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea() // Extends to the very edge of the screen
            
            VStack(spacing: 25) {
                Spacer()
                
                // Logo
                // We use your custom "AppLogo" asset here.
                // .renderingMode(.template) combined with the asset setting ensures
                // we can recolor the black logo to white using .foregroundColor.
                Image("AppLogo")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white) // Turns the black logo shape to white
                    .shadow(radius: 10) // Adds a subtle "lift"
                    .padding(.bottom, 10)
                
                Text("Scholarix")
                    .font(.system(size: 40, weight: .heavy, design: .default))
                    .foregroundColor(.white)
                    .shadow(radius: 5)
                
                Text("Your all-in-one student OS.\nTrack grades, deadlines, and more.")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9)) // Slightly transparent white
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 15) {
                    NavigationLink(destination: LoginView()) {
                        Text("Log In")
                            .font(.headline)
                            .foregroundColor(.blue) // Blue text
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white) // White button
                            .cornerRadius(15)
                            .shadow(radius: 5)
                    }
                    
                    NavigationLink(destination: SignUpView()) {
                        Text("Create Account")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            // A semi-transparent glass effect button
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationView {
        WelcomeView()
    }
}
