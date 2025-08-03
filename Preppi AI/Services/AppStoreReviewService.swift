 
import StoreKit
import SwiftUI

class AppStoreReviewService {
    static let shared = AppStoreReviewService()
    
    private init() {}
    
    /// Request an App Store review from the user
    /// This should be called sparingly and at appropriate moments in the user flow
    func requestReview() {
        // Only request review if the app is running on a real device (not simulator)
        #if !targetEnvironment(simulator)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
        #else
        print("App Store review request skipped in simulator")
        #endif
    }
    
    /// Check if we should request a review based on app usage patterns
    /// You can customize this logic based on your app's needs
    func shouldRequestReview() -> Bool {
        let launchCount = UserDefaults.standard.integer(forKey: "AppLaunchCount")
        let lastReviewRequestVersion = UserDefaults.standard.string(forKey: "LastReviewRequestVersion")
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        
        // Request review on 3rd launch, and again for each new version after 10 launches
        if launchCount == 3 || (launchCount >= 10 && lastReviewRequestVersion != currentVersion) {
            UserDefaults.standard.set(currentVersion, forKey: "LastReviewRequestVersion")
            return true
        }
        
        return false
    }
    
    /// Increment app launch count
    func incrementLaunchCount() {
        let currentCount = UserDefaults.standard.integer(forKey: "AppLaunchCount")
        UserDefaults.standard.set(currentCount + 1, forKey: "AppLaunchCount")
    }
    
    /// Request review at an appropriate moment (like after completing onboarding)
    func requestReviewIfAppropriate() {
        if shouldRequestReview() {
            // Add a small delay to ensure the UI is settled
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.requestReview()
            }
        }
    }
}