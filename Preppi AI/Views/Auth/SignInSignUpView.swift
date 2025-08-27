//
//  SignInSignUpView.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 7/25/25.
//

import SwiftUI

enum AuthMode {
    case signIn
    case signUp
}

struct SignInSignUpView: View {
    @StateObject private var authService = AuthService.shared
    @State private var isSignUpMode: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showForgotPassword = false
    @State private var animateContent = false
    
    // Initializer to support setting initial mode
    init(initialMode: AuthMode = .signIn) {
        _isSignUpMode = State(initialValue: initialMode == .signUp)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.green.opacity(0.1), Color.white]),
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
                            Text(isSignUpMode ? "Create Account" : "Welcome Back")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(isSignUpMode ? "Join Preppi to start your healthy eating journey" : "Sign in to continue your meal planning")
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
                            
                            // Confirm Password (Sign Up only)
                            if isSignUpMode {
                                AuthPasswordField(
                                    title: "Confirm Password",
                                    text: $confirmPassword
                                )
                            }
                            
                            // Error Message
                            if let errorMessage = authService.errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(errorMessage.contains("sent") ? .green : .red)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            
                            // Action Button
                            Button(action: handlePrimaryAction) {
                                HStack {
                                    if authService.isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    }
                                    
                                    Text(isSignUpMode ? "Create Account" : "Sign In")
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
                            
                            // Forgot Password (Sign In only)
                            if !isSignUpMode {
                                Button("Forgot Password?") {
                                    showForgotPassword = true
                                }
                                .font(.subheadline)
                                .foregroundColor(.green)
                            }
                        }
                        .padding(.horizontal, 30)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 30)
                        
                        // Toggle Mode
                        VStack(spacing: 15) {
                            HStack {
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(.gray.opacity(0.3))
                                
                                Text("or")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(.gray.opacity(0.3))
                            }
                            .padding(.horizontal, 30)
                            
                            Button(action: toggleMode) {
                                Text(isSignUpMode ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }
                        }
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 20)
                        
                        Spacer(minLength: 40)
                    }
                    .frame(minHeight: geometry.size.height)
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
        
        if isSignUpMode {
            return emailValid && passwordValid && password == confirmPassword
        } else {
            return emailValid && passwordValid
        }
    }
    
    // MARK: - Actions
    
    private func handlePrimaryAction() {
        authService.clearError()
        hideKeyboard()
        
        Task {
            if isSignUpMode {
                await authService.signUp(email: email, password: password)
            } else {
                await authService.signIn(email: email, password: password)
            }
        }
    }
    
    private func toggleMode() {
        withAnimation(.spring()) {
            isSignUpMode.toggle()
            authService.clearError()
            
            // Clear form when switching modes
            if isSignUpMode {
                confirmPassword = ""
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Supporting Views

struct AuthTextField: View {
    let title: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let systemImage: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(.green)
                    .frame(width: 20)
                
                TextField("Enter \(title.lowercased())", text: $text)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .background(Color(.systemBackground))
            )
        }
    }
}

struct AuthPasswordField: View {
    let title: String
    @Binding var text: String
    @State private var isSecure = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "lock")
                    .foregroundColor(.green)
                    .frame(width: 20)
                
                if isSecure {
                    SecureField("Enter \(title.lowercased())", text: $text)
                } else {
                    TextField("Enter \(title.lowercased())", text: $text)
                }
                
                Button(action: { isSecure.toggle() }) {
                    Image(systemName: isSecure ? "eye" : "eye.slash")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .background(Color(.systemBackground))
            )
        }
    }
}

struct ForgotPasswordView: View {
    @StateObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Reset Password")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Enter your email address and we'll send you a link to reset your password.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                AuthTextField(
                    title: "Email",
                    text: $email,
                    keyboardType: .emailAddress,
                    systemImage: "envelope"
                )
                .padding(.horizontal)
                
                if let errorMessage = authService.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(errorMessage.contains("sent") ? .green : .red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Button("Send Reset Link") {
                    Task {
                        await authService.resetPassword(email: email)
                        if authService.errorMessage?.contains("sent") == true {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                dismiss()
                            }
                        }
                    }
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(email.contains("@") ? Color.green : Color.gray)
                )
                .padding(.horizontal)
                .disabled(!email.contains("@") || authService.isLoading)
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SignInSignUpView()
}