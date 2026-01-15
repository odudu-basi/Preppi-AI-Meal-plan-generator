//
//  MealPlanOnboardingView.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 10/26/25.
//

import SwiftUI

struct MealPlanOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var selectedAnswer: Bool?
    @State private var animateHeader = false
    @State private var animateContent = false
    @State private var showMealLoggingInfo = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Navigation bar
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color(.systemGray6)))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Header Section with Icon
                VStack(spacing: 25) {
                    // Animated icon with gradient background
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.green.opacity(0.1), .mint.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width:100, height: 100)
                            .scaleEffect(animateHeader ? 1.0 : 0.8)
                            .opacity(animateHeader ? 1.0 : 0.0)

                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 45))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(animateHeader ? 1.0 : 0.8)
                    }

                    // Question
                    VStack(spacing: 15) {
                        Text("Would you like a meal plan to help you reach your calorie goals for the week?")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
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

                        Text("We'll create a personalized plan based on your goals")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 20)
                            .opacity(animateHeader ? 1.0 : 0.0)
                            .offset(y: animateHeader ? 0 : 20)
                    }
                }
                .padding(.top, 20)

                Spacer()

                // Options
                VStack(spacing: 16) {
                    // Yes Button
                    MealPlanYesNoButton(
                        text: "Yes",
                        icon: "hand.thumbsup.fill",
                        isSelected: selectedAnswer == true,
                        isPositive: true
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedAnswer = true

                            // Track Yes selection in Mixpanel
                            MixpanelService.shared.track(
                                event: "meal_plan_preference_selected",
                                properties: [
                                    "selection": "yes",
                                    "source": "meal_plan_onboarding"
                                ]
                            )

                            print("User selected YES for meal plan assistance")
                        }
                    }
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(y: animateContent ? 0 : 30)

                    // No Button
                    MealPlanYesNoButton(
                        text: "No",
                        icon: "hand.thumbsdown.fill",
                        isSelected: selectedAnswer == false,
                        isPositive: false
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedAnswer = false

                            // Track No selection in Mixpanel
                            MixpanelService.shared.track(
                                event: "meal_plan_preference_selected",
                                properties: [
                                    "selection": "no",
                                    "source": "meal_plan_onboarding"
                                ]
                            )

                            print("User selected NO for meal plan assistance")
                        }
                    }
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(y: animateContent ? 0 : 30)
                }
                .padding(.horizontal, 20)

                Spacer()

                // Continue Button (optional - for future use)
                if selectedAnswer != nil {
                    Button(action: {
                        if selectedAnswer == false {
                            // User selected "No" - show meal logging info
                            showMealLoggingInfo = true
                        } else {
                            // User selected "Yes" - set weekly meal plan preference and dismiss
                            appState.setWeeklyMealPlanPreference(true)
                            dismiss()
                        }
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
                                            colors: [.green, .mint],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .green.opacity(0.4), radius: 12, x: 0, y: 6)
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showMealLoggingInfo) {
            MealLoggingInfoView()
                .environmentObject(appState)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateHeader = true
            }
            
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                animateContent = true
            }
        }
    }
}

// MARK: - Meal Plan Yes/No Button Component
struct MealPlanYesNoButton: View {
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
                    
                    Text(isPositive ? "I'd like help with meal planning" : "I'll log my meals with AI")
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
    MealPlanOnboardingView()
}
