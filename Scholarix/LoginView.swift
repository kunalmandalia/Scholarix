import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    
    // --- State variables for inline error messages ---
    @State private var emailError: String? = nil
    @State private var passwordError: String? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // --- Logo / Branding ---
            // If you have added your AppIcon to Assets, you can use it here.
            // For now, we use a system image as a placeholder.
            Image(systemName: "graduationcap.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)
            
            Text("Scholarix")
                .font(.largeTitle)
                .fontWeight(.heavy)
                .foregroundColor(.primary)
            
            Text("Welcome Back.")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)

            // --- Email Field ---
            VStack(alignment: .leading) {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                
                if let emailError = emailError {
                    Text(emailError)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }

            // --- Password Field ---
            VStack(alignment: .leading) {
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                
                if let passwordError = passwordError {
                    Text(passwordError)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            // --- Forgot Password Link ---
            HStack {
                Spacer()
                NavigationLink(destination: ForgotPasswordView()) {
                    Text("Forgot Password?")
                        .font(.callout)
                        .foregroundColor(.blue)
                }
            }

            // --- Login Button ---
            Button(action: logInUser) {
                Text("Log In")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top)
            
            Spacer()
            
            // --- Sign Up Link ---
            HStack {
                Text("Don't have an account?")
                    .foregroundColor(.secondary)
                NavigationLink("Sign Up", destination: SignUpView())
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            .padding(.bottom, 20)
        }
        .padding()
        .navigationBarHidden(true)
    }
    
    // --- Login Logic ---
    
    func logInUser() {
        // Clear previous errors
        emailError = nil
        passwordError = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    let nsError = error as NSError
                    switch nsError.code {
                    case AuthErrorCode.wrongPassword.rawValue,
                         AuthErrorCode.userNotFound.rawValue,
                         AuthErrorCode.invalidEmail.rawValue:
                        self.emailError = "We couldn't find an account with those credentials."
                    default:
                        self.emailError = "An error occurred. Please try again."
                    }
                } else {
                    print("Successfully logged in user: \(authResult?.user.uid ?? "unknown")")
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        LoginView()
    }
}
