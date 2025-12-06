import SwiftUI
import FirebaseAuth
import Combine

struct VerificationSentView: View {
    let email: String
    
    // We need access to the SessionManager to update the user state instantly
    @EnvironmentObject var sessionManager: SessionManager
    
    // --- State for Feedback ---
    @State private var resendMessage: String? = nil
    @State private var isResending = false
    
    // --- Cooldown State ---
    @State private var timeRemaining = 0
    let cooldownTime = 30
    
    // --- Timers ---
    // Timer 1: Checks for verification every 2 seconds
    let verificationTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    // Timer 2: Handles the countdown for the button
    let cooldownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 25) {
            Spacer()
            
            Image(systemName: "envelope.open.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Verification Link Sent")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("We've sent a verification email to **\(email)**. Please check your inbox and click the link to activate your account.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Text("This screen will update automatically once verified.")
                .font(.caption)
                .foregroundColor(.gray)
                .italic()
            
            // --- Resend Feedback Message ---
            if let message = resendMessage {
                Text(message)
                    .font(.callout)
                    .foregroundColor(message.contains("Success") ? .green : .red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            
            Spacer()
            
            // --- Resend Button with Cooldown ---
            Button(action: resendVerificationEmail) {
                if isResending {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .blue))
                } else if timeRemaining > 0 {
                    Text("Resend in \(timeRemaining)s")
                        .font(.headline)
                        .foregroundColor(.gray)
                } else {
                    Text("Resend Email")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
            .disabled(isResending || timeRemaining > 0)
            .padding(.top, -10)
            
            // Return to Login Button
            Button(action: {
                try? Auth.auth().signOut()
            }) {
                Text("Return to Login")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(15)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
        .navigationBarHidden(true)
        
        // --- TIMER 1: Auto-Check Verification ---
        .onReceive(verificationTimer) { _ in
            checkVerificationStatus()
        }
        
        // --- TIMER 2: Cooldown Countdown ---
        .onReceive(cooldownTimer) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            }
        }
    }
    
    // --- Logic to check if verified ---
    private func checkVerificationStatus() {
        // We must reload the user to get the latest 'isEmailVerified' status from Firebase
        Auth.auth().currentUser?.reload { error in
            if error == nil {
                if let user = Auth.auth().currentUser, user.isEmailVerified {
                    // If verified, update the SessionManager.
                    // This triggers ContentView to switch to the Main App instantly.
                    sessionManager.user = user
                }
            }
        }
    }
    
    // --- Logic to resend email ---
    private func resendVerificationEmail() {
        guard timeRemaining == 0 else { return }
        
        isResending = true
        resendMessage = nil
        
        Auth.auth().currentUser?.sendEmailVerification() { error in
            DispatchQueue.main.async {
                isResending = false
                if let error = error {
                    self.resendMessage = "Error: \(error.localizedDescription)"
                } else {
                    self.resendMessage = "Success! Email sent."
                    self.timeRemaining = cooldownTime // Start cooldown
                }
            }
        }
    }
}

#Preview {
    // We need a SessionManager for the preview
    VerificationSentView(email: "test@example.com")
        .environmentObject(SessionManager())
}
