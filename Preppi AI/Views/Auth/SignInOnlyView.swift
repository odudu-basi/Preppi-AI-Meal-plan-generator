//
//  SignInOnlyView.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 10/25/25.
//

import SwiftUI

struct SignInOnlyView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var animateContent = false
    @State private var showEmailSignIn = false
    @State private var email = ""
    @State private var password = ""

    // NEW: Parameter to indicate if this is shown after onboarding completion
    let isPostOnboarding: Bool

    // Initializer to support the new parameter
    init(isPostOnboarding: Bool = false) {
        self.isPostOnboarding = isPostOnboarding
    }

    var body: some View {
        NavigationView {
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
                            Spacer(minLength: 60)

                            // App Logo
                            PreppiLogo()
                                .scaleEffect(animateContent ? 1.0 : 0.8)
                                .opacity(animateContent ? 1.0 : 0.0)

                            // Welcome Text
                            VStack(spacing: 15) {
                                Text("Welcome Back")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)

                                Text("Sign in to continue your meal planning journey")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)

                            // Sign In Options
                            VStack(spacing: 20) {
                                // Error Message
                                if let errorMessage = authService.errorMessage {
                                    Text(errorMessage)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }

                                // Google Sign In Button
                                Button(action: handleGoogleSignIn) {
                                    HStack(spacing: 12) {
                                        if authService.isLoading {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                                        } else {
                                            Image(systemName: "g.circle.fill")
                                                .font(.title2)
                                        }

                                        Text("Continue with Google")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 55)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemBackground))
                                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .disabled(authService.isLoading)

                                // Divider with text
                                HStack {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 1)

                                    Text("Secure sign-in")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)

                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 1)
                                }
                                .padding(.vertical, 10)

                                // Collapsible Email/Password Section
                                VStack(spacing: 16) {
                                    // Expand/Collapse Button
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            showEmailSignIn.toggle()
                                        }
                                    }) {
                                        HStack {
                                            Text("Sign in without Google")
                                                .font(.subheadline)
                                                .foregroundColor(.green)

                                            Spacer()

                                            Image(systemName: showEmailSignIn ? "chevron.up" : "chevron.down")
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
                                    if showEmailSignIn {
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
                                                    .textContentType(.password)
                                                    .padding()
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .fill(Color(.systemGray6))
                                                    )
                                            }

                                            // Sign In Button
                                            Button(action: handleEmailSignIn) {
                                                HStack {
                                                    if authService.isLoading {
                                                        ProgressView()
                                                            .scaleEffect(0.8)
                                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                    } else {
                                                        Text("Sign In")
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
                                            .disabled(authService.isLoading || email.isEmpty || password.isEmpty)
                                            .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                                        }
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                    }
                                }
                            }
                            .padding(.horizontal, 30)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 30)

                            Spacer(minLength: 40)
                        }
                        .frame(minHeight: geometry.size.height)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateContent = true
            }
        }
        .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated && isPostOnboarding {
                print("✅ User authenticated via Google (sign-in) - handling post-auth flow")
                handlePostAuthFlow()
            }
        }
    }

    // MARK: - Actions

    private func handleGoogleSignIn() {
        authService.clearError()

        Task {
            do {
                try await authService.signInWithGoogle()

                // The OAuth flow will handle the callback
                // When successful, handlePostAuthFlow will be called via the auth state listener

            } catch {
                print("❌ Google sign-in error: \(error)")
            }
        }
    }

    private func handleEmailSignIn() {
        authService.clearError()

        Task {
            await authService.signIn(email: email, password: password)

            // If sign-in successful and this is post-onboarding, the auth state listener will trigger handlePostAuthFlow
            // For normal sign-in, AppState will handle navigation
        }
    }

    private func handlePostAuthFlow() {
        Task {
            // If this is post-onboarding sign-in and authentication was successful
            if isPostOnboarding && authService.isAuthenticated {
                // Reset the signup flag BEFORE calling completeOnboarding so it actually saves
                await MainActor.run {
                    appState.needsSignUpAfterOnboarding = false
                    print("🔄 Resetting needsSignUpAfterOnboarding flag before save (sign-in)")
                }

                // Save the onboarding data that was collected during guest onboarding
                await appState.completeOnboarding(with: appState.userData)

                // Mark onboarding as complete
                await MainActor.run {
                    appState.isOnboardingComplete = true
                    print("✅ Post-onboarding sign-in completed - onboarding data saved to Supabase")
                }
            }
            // For normal sign-in, AppState will handle navigation based on profile completion and subscription status
        }
    }
}

#Preview {
    SignInOnlyView(isPostOnboarding: false)
        .environmentObject(AppState())
}
