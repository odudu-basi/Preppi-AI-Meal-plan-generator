//
//  Preppi_AIApp.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 7/25/25.
//

import SwiftUI

@main
struct Preppi_AIApp: App {
    init() {
        // Initialize RevenueCat service on app launch
        _ = RevenueCatService.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
