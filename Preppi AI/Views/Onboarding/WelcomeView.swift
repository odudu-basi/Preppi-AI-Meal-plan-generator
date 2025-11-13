//
//  WelcomeView.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 7/25/25.
//

import SwiftUI

struct WelcomeView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @ObservedObject private var speechService = ElevenLabsSpeechService.shared
    @State private var animateHeader = false
    @State private var animateContent = false
    @State private var animateMascot = false
    @State private var hasSpoken = false

    var body: some View {
        OnboardingContainer {
            VStack(spacing: 20) {
                // Navigation bar with progress
                OnboardingNavigationBar(
                    currentStep: coordinator.currentStep.stepNumber,
                    totalSteps: OnboardingStep.totalSteps,
                    canGoBack: false, // First step, no back button
                    onBackTapped: {}
                )

                Spacer()

                // Mascot Animation Section
                VStack(spacing: 30) {
                    // Animated Mascot - waving and talking
                    AnimatedMascot(
                        animation: speechService.isSpeaking ? .talking : .waving,
                        size: 250
                    )
                    .scaleEffect(animateMascot ? 1.0 : 0.8)
                    .opacity(animateMascot ? 1.0 : 0.0)

                    // Welcome Message
                    VStack(spacing: 15) {
                        Text("Welcome!")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .multilineTextAlignment(.center)
                            .opacity(animateHeader ? 1.0 : 0.0)
                            .offset(y: animateHeader ? 0 : 20)

                        Text("Let's start your journey to healthier eating together with Preppi AI")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(nil)
                            .padding(.horizontal, 30)
                            .opacity(animateHeader ? 1.0 : 0.0)
                            .offset(y: animateHeader ? 0 : 20)
                    }
                }

                Spacer()

                // Continue Button
                VStack(spacing: 25) {
                    PremiumContinueButton(
                        isEnabled: true,
                        animateContent: animateContent
                    ) {
                        coordinator.nextStep()
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
        .onAppear {
            print("👋 WelcomeView: View appeared")

            // Animate mascot first
            withAnimation(.easeOut(duration: 0.8)) {
                animateMascot = true
            }

            // Then animate header text
            withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
                animateHeader = true
            }

            // Finally animate continue button
            withAnimation(.easeOut(duration: 0.8).delay(0.7)) {
                animateContent = true
            }

            // Voice disabled for now
            // Start mascot speech after animations
            if !hasSpoken {
                print("🔊 WelcomeView: Voice disabled - skipping speech")
                // DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                //     print("🎯 WelcomeView: Triggering speech now")
                //     speechService.speak("Welcome! Let's start your journey to healthier eating together with Preppi AI")
                //     hasSpoken = true
                // }
                hasSpoken = true
            } else {
                print("⏭️ WelcomeView: Speech already played, skipping")
            }
        }
        .onDisappear {
            // Stop speech when leaving the view
            speechService.stop()
        }
    }
}

#Preview {
    WelcomeView(coordinator: OnboardingCoordinator())
}
