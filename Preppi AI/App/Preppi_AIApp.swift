//
//  Preppi_AIApp.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 7/25/25.
//

import SwiftUI
import Mixpanel
import UserNotifications

@main
struct Preppi_AIApp: App {
    @StateObject private var appState = AppState()
    init() {
        print("🚀 App initializing...")
        
        do {
            // Initialize services on app launch
            print("📱 Initializing RevenueCat...")
            _ = RevenueCatService.shared
            print("✅ RevenueCat initialized")
            
            print("📊 Initializing Mixpanel...")
            _ = MixpanelService.shared
            print("✅ Mixpanel initialized")
            
            print("✅ RevenueCat configured for purchases and paywall UI")
            
            // Initialize storage bucket for meal images
            print("🗄️ Initializing Image Storage...")
            Task {
                do {
                    try await ImageStorageService.shared.ensureBucketExists()
                    print("✅ Image storage initialized")
                } catch {
                    print("⚠️ Failed to initialize storage bucket: \(error)")
                }
            }
            
            // Track app launch
            print("📊 Tracking app launch...")
            MixpanelService.shared.track(event: MixpanelService.Events.appLaunched)
            print("✅ App launch tracked")
            
            // Setup notifications
            print("📱 Setting up notifications...")
            setupNotifications()
            print("✅ Notifications setup completed")
            
            print("✅ App initialization completed successfully")
        } catch {
            print("❌ CRITICAL: App initialization failed: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Check for shared images when app becomes active
                    checkForSharedImage()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didFinishLaunchingNotification)) { _ in
                    // Set notification delegate when app finishes launching
                    UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
                }
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        print("📱 Received URL: \(url)")

        // Handle OAuth callback (preppiai://auth/callback)
        if url.scheme == "preppiai" && url.host == "auth" {
            print("🔐 OAuth callback received")
            Task {
                await AuthService.shared.handleOAuthCallback(url: url)
            }
            return
        }

        // Handle other app URLs (preppi-ai://)
        guard url.scheme == "preppi-ai" else {
            print("❌ Invalid URL scheme: \(url.scheme ?? "nil")")
            return
        }

        if url.host == "shared-image" {
            // Handle shared image from extension
            handleSharedImageURL(url)
        }
    }
    
    private func handleSharedImageURL(_ url: URL) {
        print("📸 Processing shared image URL: \(url)")
        checkForSharedImage()
    }
    
    private func checkForSharedImage() {
        checkForSharedContent()
    }
    
    private func checkForSharedContent() {
        print("🔍 MainApp: Checking for shared images...")
        
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.-5.Preppi-AI.shared"
        ) else {
            return
        }
        
        let notificationURL = containerURL.appendingPathComponent("shared_image_notification.txt")
        let sharedImageURL = containerURL.appendingPathComponent("shared_image.jpg")
        
        // Check if both notification and image files exist
        guard FileManager.default.fileExists(atPath: notificationURL.path),
              FileManager.default.fileExists(atPath: sharedImageURL.path) else {
            return
        }
        
        print("✅ MainApp: Found shared image files")
        
        // Extract image data from shared container
        if let imageData = getSharedImageData() {
            if let image = UIImage(data: imageData) {
                print("✅ Successfully loaded shared image")
                
                // Clean up notification file
                try? FileManager.default.removeItem(at: notificationURL)
                
                // Send notification to UI
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SharedImageReceived"),
                        object: image
                    )
                }
            } else {
                print("❌ Failed to create UIImage from shared data")
            }
        } else {
            print("❌ No shared image data found")
        }
    }
    
    private func getSharedImageData() -> Data? {
        print("📱 MainApp: Attempting to read shared image data")
        
        // Access shared container between app and extension
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.-5.Preppi-AI.shared"
        ) else {
            print("❌ MainApp: Failed to access shared container - check App Groups configuration")
            return nil
        }
        
        print("✅ MainApp: Shared container URL: \(containerURL.path)")
        
        let sharedImageURL = containerURL.appendingPathComponent("shared_image.jpg")
        print("📁 MainApp: Looking for image at: \(sharedImageURL.path)")
        
        guard FileManager.default.fileExists(atPath: sharedImageURL.path) else {
            print("❌ MainApp: Shared image file not found at: \(sharedImageURL.path)")
            
            // List contents of shared container for debugging
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: containerURL.path)
                print("📋 MainApp: Shared container contents: \(contents)")
            } catch {
                print("❌ MainApp: Could not list shared container contents: \(error)")
            }
            
            return nil
        }
        
        do {
            let data = try Data(contentsOf: sharedImageURL)
            print("✅ MainApp: Successfully read shared image data (\(data.count) bytes)")
            
            // Clean up the shared file after reading
            try? FileManager.default.removeItem(at: sharedImageURL)
            print("🗑️ MainApp: Cleaned up shared image file")
            
            return data
        } catch {
            print("❌ MainApp: Failed to read shared image data: \(error)")
            return nil
        }
    }
    
    
    private func setupNotifications() {
        // Request notification permissions and schedule meal/plan reminders
        Task {
            let granted = await NotificationService.shared.requestPermission()
            if granted {
                print("✅ Notification permissions granted and reminders scheduled")

                // Track that notifications were enabled
                MixpanelService.shared.track(event: "notifications_enabled")
            } else {
                print("⚠️ Notification permissions denied")
            }
        }

        // Set up notification categories
        let openAction = UNNotificationAction(identifier: "OPEN_APP", title: "Open App", options: [.foreground])
        let mealReminderCategory = UNNotificationCategory(identifier: "MEAL_REMINDER", actions: [openAction], intentIdentifiers: [])
        let mealPlanCategory = UNNotificationCategory(identifier: "MEAL_PLAN_REMINDER", actions: [openAction], intentIdentifiers: [])
        let sharedImageCategory = UNNotificationCategory(identifier: "SHARED_IMAGE", actions: [openAction], intentIdentifiers: [])

        UNUserNotificationCenter.current().setNotificationCategories([mealReminderCategory, mealPlanCategory, sharedImageCategory])
    }
}

// MARK: - Notification Delegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    static let shared = NotificationDelegate()

    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("📱 Notification received while app in foreground")
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("📱 Notification tapped: \(response.notification.request.content.userInfo)")

        let userInfo = response.notification.request.content.userInfo

        // Handle shared image notifications
        if let action = userInfo["action"] as? String, action == "shared_image" {
            print("📸 Shared image notification tapped - checking for shared images")

            // Send notification to trigger shared image check
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("CheckForSharedImage"), object: nil)
            }
        }

        // Handle meal reminder and meal plan notifications
        if let action = userInfo["action"] as? String, action == "openHome" {
            print("🔔 Meal reminder notification tapped - opening Home tab")

            // Send notification to open Home tab
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("OpenHomeTab"), object: nil)
            }

            // Track notification interaction
            if let mealType = userInfo["mealType"] as? String {
                MixpanelService.shared.track(
                    event: "notification_tapped",
                    properties: ["meal_type": mealType]
                )
            } else {
                MixpanelService.shared.track(
                    event: "notification_tapped",
                    properties: ["type": "weekly_meal_plan"]
                )
            }
        }

        completionHandler()
    }
}
