//
//  HealthGoalsView.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 7/25/25.
//

import SwiftUI

struct HealthGoalsView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var selectedGoal: HealthGoal? = nil
    @State private var animateHeader = false
    
    private let healthGoals: [HealthGoal] = [
        .loseWeight,
        .maintainWeight,
        .gainWeight,
        .improveHealth
    ]
    
    var body: some View {
        OnboardingContainer {
            VStack(spacing: 20) {
                // Navigation bar with back button
                OnboardingNavigationBar(
                    currentStep: 6,
                    totalSteps: OnboardingStep.totalSteps,
                    canGoBack: true,
                    onBackTapped: {
                        coordinator.previousStep()
                    }
                )
                
                // Header with enhanced styling
                VStack(spacing: 20) {
                    // Icon with gradient background
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.green.opacity(0.1), .blue.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .scaleEffect(animateHeader ? 1.0 : 0.8)
                            .opacity(animateHeader ? 1.0 : 0.0)
                        
                        Image(systemName: "target")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(animateHeader ? 1.0 : 0.8)
                    }
                    
                    VStack(spacing: 12) {
                        Text("What's Your Health Goal?")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.primary, .green],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .padding(.horizontal, 20)
                            .opacity(animateHeader ? 1.0 : 0.0)
                            .offset(y: animateHeader ? 0 : 20)
                        
                        Text("Choose the primary goal that best describes your current health and wellness journey")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .padding(.horizontal, 20)
                            .opacity(animateHeader ? 1.0 : 0.0)
                            .offset(y: animateHeader ? 0 : 20)
                    }
                }
                .padding(.vertical, 10)
            
            // Health Goals Selection
            VStack(spacing: 16) {
                ForEach(healthGoals, id: \.self) { goal in
                    PremiumHealthGoalCard(
                        goal: goal,
                        isSelected: selectedGoal == goal
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedGoal = goal
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Navigation Buttons
            HealthGoalsNavigationButtons(
                onBack: { coordinator.previousStep() },
                onNext: { 
                    if let goal = selectedGoal {
                        coordinator.userData.healthGoals = [goal]
                        coordinator.nextStep()
                    }
                },
                isNextEnabled: selectedGoal != nil
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
            }
        }
        .onAppear {
            // Set initial selection from coordinator data
            selectedGoal = coordinator.userData.healthGoals.first
            
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                animateHeader = true
            }
        }
    }
}

// MARK: - Premium Components

struct PremiumHealthGoalCard: View {
    let goal: HealthGoal
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                // Icon Section
                ZStack {
                    Circle()
                        .fill(isSelected ? 
                              LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing) :
                              LinearGradient(colors: [.green.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: goal.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .green)
                        .scaleEffect(isPressed ? 1.1 : 1.0)
                }
                
                // Content Section
                VStack(alignment: .leading, spacing: 8) {
                    Text(goal.title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(goal.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Selection Indicator
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.green : Color(.systemGray5))
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
                                    LinearGradient(colors: [.green.opacity(0.5), .green.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                    LinearGradient(colors: [Color(.systemGray4).opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(color: isSelected ? .green.opacity(0.2) : .black.opacity(0.05), 
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

struct HealthGoalsNavigationButtons: View {
    let onBack: () -> Void
    let onNext: () -> Void
    let isNextEnabled: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Back Button
            Button(action: onBack) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.green)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [.green.opacity(0.6), .green.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: .green.opacity(0.2), radius: 8, x: 0, y: 4)
                )
            }
            
            // Next Button
            Button(action: onNext) {
                HStack(spacing: 8) {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: isNextEnabled ? [.green, .mint] : [.gray, .gray],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: isNextEnabled ? .green.opacity(0.4) : .clear, radius: 12, x: 0, y: 6)
                )
            }
            .disabled(!isNextEnabled)
        }
    }
}

#Preview {
    HealthGoalsView(coordinator: OnboardingCoordinator())
}