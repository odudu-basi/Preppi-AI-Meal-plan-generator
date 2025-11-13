//
//  CountryInputView.swift
//  Preppi AI
//
//  Created for country input with voice or text
//

import SwiftUI

struct CountryInputView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @StateObject private var speechService = SpeechRecognitionService.shared
    @State private var countryText: String = ""
    @State private var animateContent = false
    @State private var pulseAnimation = false

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

                Spacer()

                // Content
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 15) {
                        Text("🌍")
                            .font(.system(size: 60))
                            .opacity(animateContent ? 1.0 : 0.0)
                            .scaleEffect(animateContent ? 1.0 : 0.5)

                        Text("What country are you from?")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .multilineTextAlignment(.center)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)

                        Text("This helps us personalize your meal recommendations")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)
                    }

                    // Input section
                    VStack(spacing: 20) {
                        // Text field
                        TextField("Type your country...", text: $countryText)
                            .font(.system(size: 18, weight: .medium))
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                            .opacity(animateContent ? 1.0 : 0.0)
                            .disabled(speechService.isRecording || speechService.isTranscribing)

                        // Divider with "OR"
                        HStack(spacing: 15) {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(height: 1)

                            Text("OR")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)

                            Rectangle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(height: 1)
                        }
                        .opacity(animateContent ? 1.0 : 0.0)

                        // Voice input button with visualizer
                        VoiceInputButton(
                            speechService: speechService,
                            title: "Speak your country",
                            subtitle: "Tap to start recording"
                        ) { transcribedText in
                            countryText = transcribedText
                        }
                        .opacity(animateContent ? 1.0 : 0.0)
                    }
                    .padding(.horizontal, 20)
                }

                Spacer()

                // Continue button
                VStack(spacing: 25) {
                    PremiumContinueButton(
                        isEnabled: !countryText.isEmpty,
                        animateContent: animateContent
                    ) {
                        coordinator.userData.country = countryText
                        coordinator.nextStep()
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
        .onAppear {
            // Set initial text from coordinator if available
            if let country = coordinator.userData.country {
                countryText = country
            }

            // Animate content
            withAnimation(.easeOut(duration: 0.8)) {
                animateContent = true
            }

            // Start pulse animation for recording indicator
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: false)) {
                pulseAnimation = true
            }
        }
    }
}

#Preview {
    CountryInputView(coordinator: OnboardingCoordinator())
}
