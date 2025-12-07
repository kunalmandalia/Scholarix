import Foundation

struct Constants {
    static let appId = "scholarix-app"
    
    struct Firestore {
        static let root = "artifacts"
        static let users = "users"
        static let courses = "courses"
        static let deadlines = "deadlines"
    }
    
    struct Keys {
        // Dark mode is handled by the system; no appTheme key needed
        static let notificationsEnabled = "notificationsEnabled"
    }
}
