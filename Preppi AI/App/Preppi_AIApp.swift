//
//  Preppi_AIApp.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 7/25/25.
//

import SwiftUI
import Mixpanel

@main
struct Preppi_AIApp: App {
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
            
            print("🎯 Initializing Superwall...")
            _ = SuperwallService.shared
            print("✅ Superwall initialized")
            
            // RevenueCat handles purchases, Superwall handles paywall UI
            print("✅ RevenueCat configured for purchases, Superwall for paywall UI")
            
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
            
            print("✅ App initialization completed successfully")
        } catch {
            print("❌ CRITICAL: App initialization failed: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
