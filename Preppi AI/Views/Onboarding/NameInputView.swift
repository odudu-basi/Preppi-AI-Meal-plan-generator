//
//  NameInputView.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 7/25/25.
//

import SwiftUI

struct NameInputView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var name: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var animateHeader = false
    @State private var animateContent = false
    
    var body: some View {
        OnboardingContainer {
            VStack(spacing: 20) {
                // Navigation bar with progress
                OnboardingNavigationBar(
                    currentStep: coordinator.currentStep.stepNumber,
                    totalSteps: OnboardingStep.totalSteps,
                    canGoBack: true,
                    onBackTapped: {
                        coordinator.previousStep()
                    }
                )
                
                // Premium Header Section
                VStack(spacing: 25) {
                    // Animated emoji with background
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.green.opacity(0.1), .blue.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .scaleEffect(animateHeader ? 1.0 : 0.8)
                            .opacity(animateHeader ? 1.0 : 0.0)
                        
                        Text("👋")
                            .font(.system(size: 50))
                            .scaleEffect(animateHeader ? 1.0 : 0.8)
                            .rotationEffect(.degrees(animateHeader ? 0 : -10))
                    }
                    
                    VStack(spacing: 15) {
                        Text("What's your name?")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.primary, .green],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 20)
                            .opacity(animateHeader ? 1.0 : 0.0)
                            .offset(y: animateHeader ? 0 : 20)
                        
                        Text("Let's personalize your experience with Preppi AI")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .padding(.horizontal, 20)
                            .opacity(animateHeader ? 1.0 : 0.0)
                            .offset(y: animateHeader ? 0 : 20)
                    }
                }
                .padding(.top, 20)
            
                Spacer()
                
                // Premium Name Input Section
                VStack(spacing: 25) {
                    PremiumNameTextField(
                        name: $name,
                        isTextFieldFocused: $isTextFieldFocused,
                        animateContent: animateContent
                    )
                    
                    // Premium Continue Button
                    PremiumContinueButton(
                        isEnabled: !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                        animateContent: animateContent
                    ) {
                        coordinator.userData.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        coordinator.nextStep()
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateHeader = true
            }
            
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                animateContent = true
            }
            
            // Focus text field after animations
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isTextFieldFocused = true
            }
        }
    }
}

// MARK: - Premium Components

struct PremiumNameTextField: View {
    @Binding var name: String
    @FocusState.Binding var isTextFieldFocused: Bool
    let animateContent: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Name")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.green)
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(x: animateContent ? 0 : -20)
            
            HStack(spacing: 15) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.green.opacity(0.7))
                
                TextField("Enter your first name", text: $name)
                    .font(.system(size: 18, weight: .medium))
                    .textContentType(.givenName)
                    .autocapitalization(.words)
                    .disableAutocorrection(true)
                    .focused($isTextFieldFocused)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isTextFieldFocused ? 
                                LinearGradient(colors: [.green.opacity(0.6), .green.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                LinearGradient(colors: [Color(.systemGray4).opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: isTextFieldFocused ? 2 : 1
                            )
                    )
            )
            .scaleEffect(animateContent ? 1.0 : 0.95)
            .opacity(animateContent ? 1.0 : 0.0)
            .offset(y: animateContent ? 0 : 20)
        }
    }
}

struct PremiumContinueButton: View {
    let isEnabled: Bool
    let animateContent: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold))
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: isEnabled ? [.green, .mint] : [.gray.opacity(0.6), .gray.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: isEnabled ? .green.opacity(0.4) : .clear,
                        radius: isEnabled ? 12 : 0,
                        x: 0,
                        y: 6
                    )
            )
        }
        .disabled(!isEnabled)
        .scaleEffect(isEnabled ? 1.0 : 0.98)
        .opacity(animateContent ? 1.0 : 0.0)
        .offset(y: animateContent ? 0 : 30)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NameInputView(coordinator: OnboardingCoordinator())
}