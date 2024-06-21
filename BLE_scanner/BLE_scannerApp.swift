import SwiftUI
import FirebaseCore
// Import the FirebaseFirestore library for interacting with Firestore database
import FirebaseFirestore
// Import the FirebaseFirestoreSwift library for using Swift-friendly Firestore features
import FirebaseFirestoreSwift


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct BLE_scannerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

