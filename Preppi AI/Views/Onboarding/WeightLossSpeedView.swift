//
//  WeightLossSpeedView.swift
//  Preppi AI
//
//  Created for weight loss speed selection
//

import SwiftUI

struct WeightLossSpeedView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var selectedSpeed: WeightLossSpeed? = nil
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

                // Scrollable content
                ScrollView {
                    VStack(spacing: 35) {
                        // Header Section
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.green.opacity(0.2), Color.green.opacity(0.1)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                    .scaleEffect(animateContent ? 1.0 : 0.8)
                                    .opacity(animateContent ? 1.0 : 0.0)

                                Image(systemName: "speedometer")
                                    .font(.system(size: 50, weight: .medium))
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.green, Color.green.opacity(0.7)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .scaleEffect(animateContent ? 1.0 : 0.8)
                                    .opacity(animateContent ? 1.0 : 0.0)
                            }

                            VStack(spacing: 8) {
                                Text("Your Pace")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.green, .mint],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .opacity(animateContent ? 1.0 : 0.0)
                                    .offset(y: animateContent ? 0 : 20)

                                Text(coordinator.userData.healthGoals.contains(.loseWeight) ? 
                                     "How fast do you want to lose weight?" : 
                                     "How fast do you want to gain weight?")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .opacity(animateContent ? 1.0 : 0.0)
                                    .offset(y: animateContent ? 0 : 20)
                            }
                        }
                        .padding(.top, 30)

                        // Speed Options
                        VStack(spacing: 16) {
                            ForEach(WeightLossSpeed.allCases) { speed in
                                SpeedOptionCard(
                                    speed: speed,
                                    isSelected: selectedSpeed == speed,
                                    isWeightLoss: coordinator.userData.healthGoals.contains(.loseWeight),
                                    onTap: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedSpeed = speed
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 30)

                        // Timeline estimate
                        if let speed = selectedSpeed,
                           coordinator.userData.weight > 0,
                           let targetWeight = coordinator.userData.targetWeight {
                            let currentWeight = coordinator.userData.weight
                            let weightDifference = abs(currentWeight - targetWeight)
                            let weeksToGoal = weightDifference / speed.weeklyWeightLossLbs
                            let monthsToGoal = weeksToGoal / 4.33

                            VStack(spacing: 12) {
                                Text("Estimated Timeline")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)

                                HStack(spacing: 12) {
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.system(size: 24))
                                        .foregroundColor(.green)

                                    VStack(alignment: .leading, spacing: 4) {
                                        if monthsToGoal < 1 {
                                            Text("~\(Int(weeksToGoal)) weeks")
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.primary)
                                        } else {
                                            Text("~\(Int(monthsToGoal)) months")
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.primary)
                                        }

                                        Text("to reach your goal")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.green.opacity(0.1))
                            )
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        Spacer(minLength: 20)
                    }
                }

                // Continue button
                VStack(spacing: 25) {
                    PremiumContinueButton(
                        isEnabled: selectedSpeed != nil,
                        animateContent: animateContent
                    ) {
                        coordinator.userData.weightLossSpeed = selectedSpeed
                        coordinator.nextStep()
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 10)
            }
        }
        .onAppear {
            // Set initial value from coordinator if available
            if let speed = coordinator.userData.weightLossSpeed {
                selectedSpeed = speed
            }

            // Animate content
            withAnimation(.easeOut(duration: 0.8)) {
                animateContent = true
            }
        }
    }
}

// MARK: - Speed Option Card
struct SpeedOptionCard: View {
    let speed: WeightLossSpeed
    let isSelected: Bool
    let isWeightLoss: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.green : Color.green.opacity(0.1))
                        .frame(width: 60, height: 60)

                    Text(speed.emoji)
                        .font(.system(size: 30))
                }

                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text(speed.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)

                    Text(speed.description(isWeightLoss: isWeightLoss))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(speed.detailedDescription(isWeightLoss: isWeightLoss))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary.opacity(0.8))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(isSelected ? 0.12 : 0.06), radius: isSelected ? 15 : 10, x: 0, y: isSelected ? 8 : 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    WeightLossSpeedView(coordinator: OnboardingCoordinator())
}
