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
    @State private var email = ""
    @State private var password = ""
    @State private var showForgotPassword = false
    @State private var animateContent = false
    
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

                                // Error Message
                                if let errorMessage = authService.errorMessage {
                                    Text(errorMessage)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }

                                // Sign In Button
                                Button(action: handleSignIn) {
                                    HStack {
                                        if authService.isLoading {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        }

                                        Text("Sign In")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(isFormValid ? Color.green : Color.gray)
                                    )
                                }
                                .disabled(!isFormValid || authService.isLoading)

                                // Forgot Password
                                Button("Forgot Password?") {
                                    showForgotPassword = true
                                }
                                .font(.subheadline)
                                .foregroundColor(.green)
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
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateContent = true
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
    }

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        let emailValid = email.contains("@") && email.contains(".")
        let passwordValid = password.count >= 6
        return emailValid && passwordValid
    }

    // MARK: - Actions

    private func handleSignIn() {
        authService.clearError()
        hideKeyboard()

        Task {
            await authService.signIn(email: email, password: password)
            
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

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    SignInOnlyView(isPostOnboarding: false)
        .environmentObject(AppState())
}
