import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    @State private var emailError: String? = nil
    @State private var passwordError: String? = nil
    @State private var confirmPasswordError: String? = nil
    
    @State private var isSigningUp = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image("AppLogo")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .foregroundColor(.blue)
            
            Text("Create Your Account")
                .font(.largeTitle)
                .fontWeight(.heavy)
                .foregroundColor(.primary)
            
            Text("Start tracking your grades and schedule today.")
                .font(.callout)
                .foregroundColor(.secondary)
                .padding(.bottom, 10)

            // --- Inputs ---
            VStack(alignment: .leading) {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(15)
                
                if let emailError = emailError {
                    Text(emailError).foregroundColor(.red).font(.caption)
                }
            }

            VStack(alignment: .leading) {
                SecureField("Password (min 6 characters)", text: $password)
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(15)
                
                if let passwordError = passwordError {
                    Text(passwordError).foregroundColor(.red).font(.caption)
                }
            }
            
            VStack(alignment: .leading) {
                SecureField("Confirm Password", text: $confirmPassword)
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(15)
                
                if let confirmPasswordError = confirmPasswordError {
                    Text(confirmPasswordError).foregroundColor(.red).font(.caption)
                }
            }

            // --- Sign Up Button ---
            Button(action: signUpUser) {
                if isSigningUp {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Create Account")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(15)
            .disabled(isSigningUp || email.isEmpty || password.isEmpty)
            .padding(.top)
            
            Spacer()
            
            HStack {
                Text("Already have an account?")
                    .foregroundColor(.secondary)
                NavigationLink("Log In", destination: LoginView())
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 30)
        .navigationBarHidden(true)
    }
    
    func validateForm() -> Bool {
        emailError = nil; passwordError = nil; confirmPasswordError = nil;
        var isValid = true
        
        if !email.contains("@") || !email.contains(".") {
            emailError = "Please enter a valid email address."
            isValid = false
        }
        if password.count < 6 {
            passwordError = "Password must be at least 6 characters long."
            isValid = false
        }
        if password != confirmPassword {
            confirmPasswordError = "Passwords do not match."
            isValid = false
        }
        return isValid
    }
    
    func signUpUser() {
        if !validateForm() { return }
        isSigningUp = true
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            DispatchQueue.main.async {
                isSigningUp = false
                
                if let error = error {
                    let nsError = error as NSError
                    if nsError.code == AuthErrorCode.emailAlreadyInUse.rawValue {
                        self.emailError = "This email is already in use. Please log in."
                    } else {
                        self.emailError = error.localizedDescription
                    }
                } else {
                    // --- SUCCESS ---
                    // 1. Send email
                    authResult?.user.sendEmailVerification()
                    
                    // 2. Do nothing else.
                    // The user is now created and logged in.
                    // ContentView will detect this change and automatically show VerificationSentView.
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        SignUpView()
    }
}
