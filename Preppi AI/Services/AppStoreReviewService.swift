 
import StoreKit
import SwiftUI

class AppStoreReviewService {
    static let shared = AppStoreReviewService()
    
    private init() {}
    
    /// Request an App Store review from the user
    /// This should be called sparingly and at appropriate moments in the user flow
    func requestReview() {
        print("📝 Requesting App Store review...")
        
        // Only request review if the app is running on a real device (not simulator)
        #if !targetEnvironment(simulator)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
            print("✅ App Store review prompt displayed")
            
            // Track that we requested a review
            UserDefaults.standard.set(Date(), forKey: "LastReviewRequestDate")
            MixpanelService.shared.track(event: "App Store Review Requested")
        } else {
            print("❌ No active window scene found for review request")
        }
        #else
        print("⚠️ App Store review request skipped in simulator")
        #endif
    }
    
    /// Check if we should request a review based on app usage patterns
    /// You can customize this logic based on your app's needs
    func shouldRequestReview() -> Bool {
        let launchCount = UserDefaults.standard.integer(forKey: "AppLaunchCount")
        let lastReviewRequestVersion = UserDefaults.standard.string(forKey: "LastReviewRequestVersion")
        let lastReviewRequestDate = UserDefaults.standard.object(forKey: "LastReviewRequestDate") as? Date
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        
        // Don't request too frequently - wait at least 30 days between requests
        if let lastDate = lastReviewRequestDate,
           Date().timeIntervalSince(lastDate) < 30 * 24 * 60 * 60 {
            print("⏰ Too soon since last review request (within 30 days)")
            return false
        }
        
        // Request review on 3rd launch, and again for each new version after 10 launches
        let shouldRequest = launchCount == 3 || (launchCount >= 10 && lastReviewRequestVersion != currentVersion)
        
        if shouldRequest {
            UserDefaults.standard.set(currentVersion, forKey: "LastReviewRequestVersion")
            print("✅ Should request review: Launch count \(launchCount), Version \(currentVersion ?? "unknown")")
            return true
        }
        
        print("⏭️ Not requesting review: Launch count \(launchCount), Version \(currentVersion ?? "unknown")")
        return false
    }
    
    /// Increment app launch count
    func incrementLaunchCount() {
        let currentCount = UserDefaults.standard.integer(forKey: "AppLaunchCount")
        let newCount = currentCount + 1
        UserDefaults.standard.set(newCount, forKey: "AppLaunchCount")
        print("📊 App launch count: \(newCount)")
    }
    
    /// Debug method to check current review request status
    func printDebugInfo() {
        let launchCount = UserDefaults.standard.integer(forKey: "AppLaunchCount")
        let lastReviewRequestVersion = UserDefaults.standard.string(forKey: "LastReviewRequestVersion")
        let lastReviewRequestDate = UserDefaults.standard.object(forKey: "LastReviewRequestDate") as? Date
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        
        print("\n📊 App Store Review Debug Info:")
        print("   - Launch Count: \(launchCount)")
        print("   - Current Version: \(currentVersion ?? "unknown")")
        print("   - Last Review Request Version: \(lastReviewRequestVersion ?? "none")")
        print("   - Last Review Request Date: \(lastReviewRequestDate?.description ?? "none")")
        print("   - Should Request Review: \(shouldRequestReview())")
        print()
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