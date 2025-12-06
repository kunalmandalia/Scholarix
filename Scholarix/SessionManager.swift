import Foundation
import Combine
import FirebaseAuth

class SessionManager: ObservableObject {
    @Published var user: FirebaseAuth.User?
    @Published var isLoading = true
    private var listenerHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        self.listenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.isLoading = false
            }
        }
    }
    
    deinit {
        if let handle = listenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
