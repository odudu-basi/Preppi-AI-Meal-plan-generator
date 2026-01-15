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
    @State private var animateContent = false
    @State private var showSignIn = false
    @State private var showEmailSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

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

                        // Sign Up Options
                        VStack(spacing: 20) {
                            // Error Message
                            if let errorMessage = authService.errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }

                            // Google Sign Up Button
                            Button(action: handleGoogleSignUp) {
                                HStack(spacing: 12) {
                                    if authService.isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "g.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                    }

                                    Text("Continue with Google")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
                                        )
                                        .shadow(color: .green.opacity(0.3), radius: 12, x: 0, y: 6)
                                )
                            }
                            .disabled(authService.isLoading)

                            // Divider with text
                            HStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 1)

                                Text("Quick & Secure")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)

                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.vertical, 5)

                            // Collapsible Email/Password Section
                            VStack(spacing: 16) {
                                // Expand/Collapse Button
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        showEmailSignUp.toggle()
                                    }
                                }) {
                                    HStack {
                                        Text("Sign up without Google")
                                            .font(.subheadline)
                                            .foregroundColor(.green)

                                        Spacer()

                                        Image(systemName: showEmailSignUp ? "chevron.up" : "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemBackground))
                                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                    )
                                }

                                // Email/Password Fields (Collapsible)
                                if showEmailSignUp {
                                    VStack(spacing: 16) {
                                        // Email Field
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Email")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)

                                            TextField("Enter your email", text: $email)
                                                .textFieldStyle(.plain)
                                                .textContentType(.emailAddress)
                                                .autocapitalization(.none)
                                                .keyboardType(.emailAddress)
                                                .padding()
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color(.systemGray6))
                                                )
                                        }

                                        // Password Field
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Password")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)

                                            SecureField("Enter your password", text: $password)
                                                .textFieldStyle(.plain)
                                                .textContentType(.newPassword)
                                                .padding()
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color(.systemGray6))
                                                )
                                        }

                                        // Confirm Password Field
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Confirm Password")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)

                                            SecureField("Confirm your password", text: $confirmPassword)
                                                .textFieldStyle(.plain)
                                                .textContentType(.newPassword)
                                                .padding()
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color(.systemGray6))
                                                )
                                        }

                                        // Sign Up Button
                                        Button(action: handleEmailSignUp) {
                                            HStack {
                                                if authService.isLoading {
                                                    ProgressView()
                                                        .scaleEffect(0.8)
                                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                } else {
                                                    Text("Sign Up")
                                                        .font(.headline)
                                                        .fontWeight(.semibold)
                                                }
                                            }
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 50)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [.green, .mint],
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        )
                                                    )
                                            )
                                        }
                                        .disabled(authService.isLoading || email.isEmpty || password.isEmpty || confirmPassword.isEmpty)
                                        .opacity((email.isEmpty || password.isEmpty || confirmPassword.isEmpty) ? 0.6 : 1.0)
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
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
        .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                print("✅ User authenticated via Google - handling post-auth flow")
                Task {
                    await handlePostAuthFlow()
                }
            }
        }
    }

    // MARK: - Actions

    private func handleGoogleSignUp() {
        authService.clearError()

        Task {
            do {
                try await authService.signInWithGoogle()

                // The OAuth flow will handle the callback
                // We'll handle the post-auth flow via the auth state listener
                // Once authenticated, we need to save the onboarding data

            } catch {
                print("❌ Google sign-up error: \(error)")
            }
        }
    }

    private func handleEmailSignUp() {
        authService.clearError()

        // Validate passwords match
        guard password == confirmPassword else {
            authService.errorMessage = "Passwords do not match"
            return
        }

        // Validate password length
        guard password.count >= 6 else {
            authService.errorMessage = "Password must be at least 6 characters"
            return
        }

        Task {
            await authService.signUp(email: email, password: password)

            // If signup successful, the auth state listener will trigger handlePostAuthFlow
        }
    }

    private func handlePostAuthFlow() async {
        // If signup/signin successful, save the onboarding data to Supabase
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

#Preview {
    PostOnboardingSignUpView()
        .environmentObject(AppState())
}
