//
//  MealPlanningExperienceView.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 10/25/25.
//

import SwiftUI

struct MealPlanningExperienceView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var selectedAnswer: Bool?
    @State private var animateHeader = false
    @State private var animateOptions = false

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

                // Header Section with Icon
                VStack(spacing: 25) {
                    // Animated icon with gradient background
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

                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 45))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(animateHeader ? 1.0 : 0.8)
                    }

                    // Question
                    VStack(spacing: 15) {
                        Text("Have you tried other meal planning apps?")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.primary, .green],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(nil)
                            .padding(.horizontal, 20)
                            .opacity(animateHeader ? 1.0 : 0.0)
                            .offset(y: animateHeader ? 0 : 20)

                        Text("Help us understand your experience")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 20)
                            .opacity(animateHeader ? 1.0 : 0.0)
                            .offset(y: animateHeader ? 0 : 20)
                    }
                }
                .padding(.top, 10)

                Spacer()

                // Options
                VStack(spacing: 16) {
                    // No Button
                    PremiumYesNoButton(
                        text: "No",
                        icon: "xmark.circle.fill",
                        isSelected: selectedAnswer == false,
                        isPositive: false
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedAnswer = false
                            coordinator.userData.hasTriedMealPlanning = false
                        }
                    }
                    .opacity(animateOptions ? 1.0 : 0.0)
                    .offset(y: animateOptions ? 0 : 30)

                    // Yes Button
                    PremiumYesNoButton(
                        text: "Yes",
                        icon: "checkmark.circle.fill",
                        isSelected: selectedAnswer == true,
                        isPositive: true
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedAnswer = true
                            coordinator.userData.hasTriedMealPlanning = true
                        }
                    }
                    .opacity(animateOptions ? 1.0 : 0.0)
                    .offset(y: animateOptions ? 0 : 30)
                }
                .padding(.horizontal, 20)

                Spacer()

                // Continue Button
                Button(action: {
                    coordinator.nextStep()
                }) {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: selectedAnswer != nil ? [.green, .mint] : [.gray, .gray],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: selectedAnswer != nil ? .green.opacity(0.4) : .clear, radius: 12, x: 0, y: 6)
                        )
                }
                .disabled(selectedAnswer == nil)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                .opacity(animateOptions ? 1.0 : 0.0)
            }
        }
        .onAppear {
            selectedAnswer = coordinator.userData.hasTriedMealPlanning

            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                animateHeader = true
            }

            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                animateOptions = true
            }
        }
    }
}

// MARK: - Premium Yes/No Button Component
struct PremiumYesNoButton: View {
    let text: String
    let icon: String
    let isSelected: Bool
    let isPositive: Bool
    let action: () -> Void
    @State private var isPressed = false

    var brandColor: Color {
        isPositive ? .green : .red
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                // Icon Section
                ZStack {
                    Circle()
                        .fill(isSelected ?
                              brandColor :
                              brandColor.opacity(0.1)
                        )
                        .frame(width: 60, height: 60)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(isSelected ? .white : brandColor)
                        .scaleEffect(isPressed ? 1.1 : 1.0)
                }
                
                // Content Section
                VStack(alignment: .leading, spacing: 8) {
                    Text(text)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)
                    
                    Text(isPositive ? "I have experience with meal planning" : "I'm new to meal planning")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)
                }
                
                Spacer()
                
                // Selection Indicator
                ZStack {
                    Circle()
                        .fill(isSelected ? brandColor : Color(.systemGray5))
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ?
                                    brandColor.opacity(0.5) :
                                    Color(.systemGray4).opacity(0.3),
                                    lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(color: isSelected ? brandColor.opacity(0.2) : .black.opacity(0.05),
                           radius: isSelected ? 12 : 8,
                           x: 0,
                           y: isSelected ? 6 : 2)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

#Preview {
    MealPlanningExperienceView(coordinator: OnboardingCoordinator())
}
