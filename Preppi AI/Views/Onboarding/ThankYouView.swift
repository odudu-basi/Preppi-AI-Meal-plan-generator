//
//  ThankYouView.swift
//  Preppi AI
//
//  Gratitude page after three month commitment
//

import SwiftUI

struct ThankYouView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var animateContent = false
    @State private var animateHeart = false

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

                // Scrollable main content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        // Top spacing
                        Spacer(minLength: 40)
                        // Animated heart/mascot icon
                        ZStack {
                            // Outer glow circle
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            Color.green.opacity(0.3),
                                            Color.green.opacity(0.1),
                                            Color.green.opacity(0.05),
                                            Color.clear
                                        ]),
                                        center: .center,
                                        startRadius: 30,
                                        endRadius: 100
                                    )
                                )
                                .frame(width: 200, height: 200)
                                .scaleEffect(animateHeart ? 1.1 : 1.0)
                                .opacity(animateContent ? 1.0 : 0.0)

                            // Inner circle background
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.green.opacity(0.15),
                                            Color.green.opacity(0.08)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .scaleEffect(animateContent ? 1.0 : 0.8)
                                .opacity(animateContent ? 1.0 : 0.0)

                            // Heart icon
                            Image(systemName: "heart.fill")
                                .font(.system(size: 60, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.green,
                                            Color.mint
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .scaleEffect(animateHeart ? 1.05 : 1.0)
                                .opacity(animateContent ? 1.0 : 0.0)
                        }
                        .padding(.bottom, 20)

                        // Main thank you message
                        VStack(spacing: 16) {
                            Text("Thank You for Trusting Us")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .offset(y: animateContent ? 0 : 20)

                            Text("We're honored to be part of your health journey")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .offset(y: animateContent ? 0 : 20)
                                .padding(.horizontal, 30)
                        }

                        // Supporting message
                        VStack(spacing: 20) {
                            MessageCard(
                                icon: "sparkles",
                                title: "Your Success is Our Mission",
                                message: "Every meal plan, every recipe, and every recommendation is crafted with care to help you reach your goals.",
                                iconColor: .orange
                            )
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 30)

                            MessageCard(
                                icon: "hands.sparkles.fill",
                                title: "We're Here for You",
                                message: "Together, we'll make healthy eating simple, sustainable, and enjoyable—one meal at a time.",
                                iconColor: .green
                            )
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 30)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // Bottom spacing
                        Spacer(minLength: 60)
                    }
                }

                // Continue button
                VStack(spacing: 25) {
                    PremiumContinueButton(
                        isEnabled: true,
                        animateContent: animateContent
                    ) {
                        coordinator.nextStep()
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 10)
            }
        }
        .onAppear {
            // Animate content
            withAnimation(.easeOut(duration: 0.8)) {
                animateContent = true
            }

            // Continuous heart pulse animation
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                animateHeart = true
            }
        }
    }
}

// MARK: - Message Card Component
struct MessageCard: View {
    let icon: String
    let title: String
    let message: String
    let iconColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(iconColor)
            }

            // Text content
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                Text(message)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 15, x: 0, y: 5)
        )
    }
}

#Preview {
    ThankYouView(coordinator: OnboardingCoordinator())
}
