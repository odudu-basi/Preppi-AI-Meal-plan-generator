//
//  AuthService.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 7/25/25.
//

import Foundation
import SwiftUI
import Auth
import Mixpanel

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let auth = SupabaseService.shared.auth
    
    private init() {
        checkAuthStatus()
        setupAuthListener()
    }
    
    // MARK: - Authentication Status
    
    private func checkAuthStatus() {
        Task {
            do {
                let session = try await auth.session
                self.currentUser = session.user
                self.isAuthenticated = true
                print("✅ User is authenticated: \(session.user.email ?? "No email")")
            } catch {
                self.currentUser = nil
                self.isAuthenticated = false
                print("❌ No active session: \(error)")
            }
        }
    }
    
    private func setupAuthListener() {
        Task {
            for await state in auth.authStateChanges {
                switch state.event {
                case .signedIn:
                    self.currentUser = state.session?.user
                    self.isAuthenticated = true
                    print("✅ User signed in: \(state.session?.user.email ?? "No email")")
                    
                    // Track user identification and properties in Mixpanel
                    if let user = state.session?.user {
                        self.trackUserIdentification(user: user, isNewUser: false)
                    }
                    
                case .signedOut:
                    self.currentUser = nil
                    self.isAuthenticated = false
                    print("👋 User signed out")
                    
                    // Track sign out and reset Mixpanel
                    MixpanelService.shared.track(event: MixpanelService.Events.userSignedOut)
                    MixpanelService.shared.reset()
                    
                case .tokenRefreshed:
                    self.currentUser = state.session?.user
                    print("🔄 Token refreshed")
                    
                default:
                    break
                }
            }
        }
    }
    
    // MARK: - Sign Up
    
    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await auth.signUp(
                email: email,
                password: password
            )
            
            if let session = response.session {
                self.currentUser = session.user
                self.isAuthenticated = true
                print("✅ Sign up successful: \(email)")
                
                // Track successful sign up in Mixpanel
                self.trackUserIdentification(user: session.user, isNewUser: true)
                MixpanelService.shared.track(
                    event: MixpanelService.Events.userSignedUp,
                    properties: [
                        MixpanelService.Properties.signUpMethod: "email",
                        MixpanelService.Properties.source: "native_app"
                    ]
                )
            } else {
                // Email confirmation required
                self.errorMessage = "Please check your email to confirm your account"
                print("📧 Email confirmation required for: \(email)")
            }
            
        } catch {
            self.errorMessage = "Sign up failed: \(error.localizedDescription)"
            print("❌ Sign up error: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Sign In
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await auth.signIn(
                email: email,
                password: password
            )
            
            self.currentUser = session.user
            self.isAuthenticated = true
            print("✅ Sign in successful: \(email)")
            
            // Track successful sign in in Mixpanel
            self.trackUserIdentification(user: session.user, isNewUser: false)
            MixpanelService.shared.track(
                event: MixpanelService.Events.userSignedIn,
                properties: [
                    MixpanelService.Properties.signUpMethod: "email"
                ]
            )
            
        } catch {
            self.errorMessage = "Sign in failed: \(error.localizedDescription)"
            print("❌ Sign in error: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Out
    
    func signOut() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await auth.signOut()
            self.currentUser = nil
            self.isAuthenticated = false
            print("✅ Sign out successful")
            
            // Clear all user-specific data from UserDefaults
            await clearUserDefaultsData()
            
        } catch {
            self.errorMessage = "Sign out failed: \(error.localizedDescription)"
            print("❌ Sign out error: \(error)")
        }
        
        isLoading = false
    }
    
    /// Clear all user-specific data from UserDefaults when signing out
    private func clearUserDefaultsData() async {
        print("🧹 Clearing user-specific data from UserDefaults...")
        
        // Get all UserDefaults keys
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        
        // Clear ALL shopping list related keys (both old and new format)
        let shoppingListKeys = allKeys.filter { key in
            key.hasPrefix("weeklyShoppingList_") || 
            key.hasPrefix("user_") ||
            key.hasPrefix("mealPlan_") ||
            key.hasPrefix("shoppingList_")
        }
        
        for key in shoppingListKeys {
            UserDefaults.standard.removeObject(forKey: key)
            print("🗑️ Cleared UserDefaults key: \(key)")
        }
        
        // Clear other user-specific keys (keep app-wide settings)
        let userSpecificKeys = allKeys.filter { key in
            key.hasPrefix("userProfile_") ||
            key.hasPrefix("onboarding_") ||
            key.hasPrefix("preferences_")
        }
        
        for key in userSpecificKeys {
            UserDefaults.standard.removeObject(forKey: key)
            print("🗑️ Cleared UserDefaults key: \(key)")
        }
        
        // Keep essential app keys like "hasSeenGetStarted"
        print("✅ UserDefaults cleanup completed - cleared \(shoppingListKeys.count) shopping list keys and \(userSpecificKeys.count) user profile keys")
    }
    
    // MARK: - Password Reset
    
    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await auth.resetPasswordForEmail(email)
            self.errorMessage = "Password reset email sent"
            print("✅ Password reset email sent to: \(email)")
            
        } catch {
            self.errorMessage = "Password reset failed: \(error.localizedDescription)"
            print("❌ Password reset error: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Mixpanel Tracking
    
    private func trackUserIdentification(user: User, isNewUser: Bool) {
        // Identify the user in Mixpanel with their unique ID
        let userId = user.id.uuidString
        MixpanelService.shared.identify(distinctId: userId)
        
        // Set user properties
        var userProperties: [String: MixpanelType] = [
            MixpanelService.Properties.userId: userId,
            "$email": user.email ?? "",
            "$created": user.createdAt.ISO8601Format()
        ]
        
        // Add user metadata if available
        let userMetadata = user.userMetadata
        if case let .string(name) = userMetadata["full_name"] {
            userProperties["$name"] = name
        }
        if case let .string(firstName) = userMetadata["first_name"] {
            userProperties["$first_name"] = firstName
        }
        if case let .string(lastName) = userMetadata["last_name"] {
            userProperties["$last_name"] = lastName
        }
        
        // Set premium status (initially false for new users)
        userProperties[MixpanelService.Properties.isPremium] = false
        
        // Set user type
        userProperties["user_type"] = isNewUser ? "new_user" : "returning_user"
        
        MixpanelService.shared.setUserProperties(userProperties)
        
        print("📊 Mixpanel user identified: \(userId)")
        print("📊 User properties set: \(userProperties)")
    }
    
    // MARK: - Premium Status Updates
    
    func updatePremiumStatus(isPremium: Bool) {
        guard let currentUser = currentUser else { return }
        
        let properties: [String: MixpanelType] = [
            MixpanelService.Properties.isPremium: isPremium,
            "$plan": isPremium ? "Premium" : "Free"
        ]
        
        MixpanelService.shared.setUserProperties(properties)
        
        if isPremium {
            MixpanelService.shared.track(event: MixpanelService.Events.subscriptionPurchased)
        }
        
        print("📊 Mixpanel premium status updated: \(isPremium)")
    }
}