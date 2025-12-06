import FirebaseCore
import UIKit

// This class handles the app's startup process, like connecting to Firebase.
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    // This is the line that officially configures and "turns on" Firebase.
    FirebaseApp.configure()
    return true
  }
}
