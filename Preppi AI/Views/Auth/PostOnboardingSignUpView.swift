//
//  PostOnboardingSignUpView.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 10/25/25.
//

import SwiftUI

struct PostOnboardingSignUpView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var authService = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var animateContent = false
    @State private var showSignIn = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color.green.opacity(0.02)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        Spacer(minLength: 40)

                        // Success Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.green.opacity(0.2), .mint.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)

                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .scaleEffect(animateContent ? 1.0 : 0.8)
                        .opacity(animateContent ? 1.0 : 0.0)

                        // Welcome Text
                        VStack(spacing: 15) {
                            Text("You're Almost There!")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            Text("Create your account to save your personalized meal plans and start your journey")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 20)

                        // Form
                        VStack(spacing: 20) {
                            // Email Field
                            AuthTextField(
                                title: "Email",
                                text: $email,
                                keyboardType: .emailAddress,
                                systemImage: "envelope"
                            )

                            // Password Field
                            AuthPasswordField(
                                title: "Password",
                                text: $password
                            )

                            // Confirm Password
                            AuthPasswordField(
                                title: "Confirm Password",
                                text: $confirmPassword
                            )

                            // Error Message
                            if let errorMessage = authService.errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }

                            // Create Account Button
                            Button(action: handleSignUp) {
                                HStack {
                                    if authService.isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    }

                                    Text("Create Account")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            isFormValid ?
                                            LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing) :
                                            LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing)
                                        )
                                        .shadow(color: isFormValid ? .green.opacity(0.3) : .clear, radius: 12, x: 0, y: 6)
                                )
                            }
                            .disabled(!isFormValid || authService.isLoading)
                        }
                        .padding(.horizontal, 30)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 30)

                        // Already have account
                        Button(action: {
                            showSignIn = true
                        }) {
                            Text("Already have an account? Sign In")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                        .opacity(animateContent ? 1.0 : 0.0)

                        Spacer(minLength: 40)
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
        .sheet(isPresented: $showSignIn) {
            SignInOnlyView(isPostOnboarding: true)
                .environmentObject(appState)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateContent = true
            }
            
            // Debug: Check what onboarding data is available when signup screen appears
            print("🔍 PostOnboardingSignUpView appeared - checking available data:")
            print("   - User Name: \(appState.userData.name)")
            print("   - Marketing Source: \(appState.userData.marketingSource?.rawValue ?? "None")")
            print("   - Cooking Preference: \(appState.userData.cookingPreference?.rawValue ?? "None")")
            print("   - Health Goals: \(appState.userData.healthGoals.map { $0.rawValue })")
            print("   - Weekly Budget: $\(appState.userData.weeklyBudget ?? 0)")
            print("   - needsSignUpAfterOnboarding: \(appState.needsSignUpAfterOnboarding)")
        }
        .onTapGesture {
            hideKeyboard()
        }
    }

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        let emailValid = email.contains("@") && email.contains(".")
        let passwordValid = password.count >= 6
        let passwordsMatch = password == confirmPassword
        return emailValid && passwordValid && passwordsMatch
    }

    // MARK: - Actions

    private func handleSignUp() {
        authService.clearError()
        hideKeyboard()

        Task {
            await authService.signUp(email: email, password: password)

            // If signup successful, save the onboarding data to Supabase
            if authService.isAuthenticated {
                // Reset the signup flag BEFORE calling completeOnboarding so it actually saves
                await MainActor.run {
                    appState.needsSignUpAfterOnboarding = false
                    print("🔄 Resetting needsSignUpAfterOnboarding flag before save")
                }
                
                // The onboarding data is already stored in appState.userData
                // Now we need to save it to Supabase with the new user's ID
                await appState.completeOnboarding(with: appState.userData)

                // Mark that we should show paywall next
                await MainActor.run {
                    appState.isOnboardingComplete = true
                    print("✅ Post-onboarding signup completed - onboarding data saved to Supabase")
                    print("   - Final AppState userData name: \(appState.userData.name)")
                    print("   - Final AppState isOnboardingComplete: \(appState.isOnboardingComplete)")
                    print("   - Final needsSignUpAfterOnboarding: \(appState.needsSignUpAfterOnboarding)")
                }
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    PostOnboardingSignUpView()
        .environmentObject(AppState())
}
