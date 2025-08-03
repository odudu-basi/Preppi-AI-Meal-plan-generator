//
//  AuthService.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 7/25/25.
//

import Foundation
import SwiftUI
import Auth

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
                    
                case .signedOut:
                    self.currentUser = nil
                    self.isAuthenticated = false
                    print("👋 User signed out")
                    
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
            
        } catch {
            self.errorMessage = "Sign out failed: \(error.localizedDescription)"
            print("❌ Sign out error: \(error)")
        }
        
        isLoading = false
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
}