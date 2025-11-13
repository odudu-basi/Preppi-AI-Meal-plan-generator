//
//  GoalConfirmationView.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 10/25/25.
//

import SwiftUI

struct GoalConfirmationView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var animateContent = false
    @State private var animateIcon = false

    var selectedGoal: HealthGoal? {
        coordinator.userData.healthGoals.first
    }

    var goalActionText: String {
        guard let goal = selectedGoal else { return "achieve your goals" }

        switch goal {
        case .loseWeight:
            return "lose weight"
        case .buildMuscle:
            return "build muscle"
        case .maintainWeight:
            return "maintain your weight"
        case .improveHealth:
            return "improve your overall health"
        case .gainWeight:
            return "gain weight"
        case .increaseEnergy:
            return "increase your energy"
        case .betterSleep:
            return "improve your sleep"
        case .reduceStress:
            return "reduce stress"
        }
    }

    var body: some View {
        OnboardingContainer {
            VStack(spacing: 20) {
                // Navigation bar with back button
                OnboardingNavigationBar(
                    currentStep: coordinator.currentStep.stepNumber,
                    totalSteps: OnboardingStep.totalSteps,
                    canGoBack: true,
                    onBackTapped: {
                        coordinator.previousStep()
                    }
                )

                Spacer()

                // Main Content
                VStack(spacing: 30) {
                    // Animated Icon
                    ZStack {
                        // Pulsing background circles
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.green.opacity(0.1), .blue.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 140, height: 140)
                            .scaleEffect(animateIcon ? 1.1 : 1.0)
                            .opacity(animateIcon ? 0.5 : 0.8)

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.green.opacity(0.15), .mint.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .scaleEffect(animateIcon ? 1.0 : 0.9)

                        // Main icon
                        if let goal = selectedGoal {
                            Image(systemName: goal.icon)
                                .font(.system(size: 50, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .scaleEffect(animateIcon ? 1.0 : 0.8)
                        }
                    }
                    .opacity(animateContent ? 1.0 : 0.0)

                    // Title and Description
                    VStack(spacing: 16) {
                        Text("Preppi AI helps you")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)

                        Text(goalActionText)
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(nil)
                            .padding(.horizontal, 20)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)

                        Text("by planning your meals and tracking your calories")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(nil)
                            .padding(.horizontal, 30)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)
                    }
                    .padding(.horizontal, 10)

                    // Feature highlights
                    VStack(spacing: 16) {
                        FeatureRow(
                            icon: "calendar.badge.plus",
                            title: "Smart Meal Planning",
                            description: "Personalized weekly meal plans",
                            delay: 0.1
                        )
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(x: animateContent ? 0 : -50)

                        FeatureRow(
                            icon: "flame.fill",
                            title: "Calorie Tracking",
                            description: "Effortless nutrition monitoring",
                            delay: 0.2
                        )
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(x: animateContent ? 0 : -50)

                        FeatureRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Progress Tracking",
                            description: "See your journey unfold",
                            delay: 0.3
                        )
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(x: animateContent ? 0 : -50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }

                Spacer()

                // Continue Button
                Button(action: {
                    coordinator.nextStep()
                }) {
                    HStack(spacing: 8) {
                        Text("Continue")
                            .font(.system(size: 18, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .green.opacity(0.4), radius: 12, x: 0, y: 6)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                .opacity(animateContent ? 1.0 : 0.0)
            }
        }
        .onAppear {
            // Animate content in sequence
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                animateContent = true
            }

            // Continuous icon animation
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animateIcon = true
            }
        }
    }
}

// MARK: - Feature Row Component
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let delay: Double

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.15), .mint.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.green)
            }

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

#Preview {
    GoalConfirmationView(coordinator: OnboardingCoordinator())
}
