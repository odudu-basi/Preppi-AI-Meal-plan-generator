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
        // Initialize services on app launch
        _ = RevenueCatService.shared
        _ = MixpanelService.shared
        
        // Initialize storage bucket for meal images
        Task {
            do {
                try await ImageStorageService.shared.ensureBucketExists()
            } catch {
                print("⚠️ Failed to initialize storage bucket: \(error)")
            }
        }
        
        // Track app launch
        MixpanelService.shared.track(event: MixpanelService.Events.appLaunched)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
