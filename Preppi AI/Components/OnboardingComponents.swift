 
//  OnboardingComponents.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 7/25/25.
//

import SwiftUI

// MARK: - Onboarding Container
struct OnboardingContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.1), Color.white]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            content
                .padding()
        }
    }
}

// MARK: - Onboarding Navigation Bar
struct OnboardingNavigationBar: View {
    let currentStep: Int
    let totalSteps: Int
    let canGoBack: Bool
    let onBackTapped: () -> Void
    
    var progressValue: Double {
        Double(currentStep) / Double(totalSteps)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                // Back button
                if canGoBack {
                    Button(action: onBackTapped) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.green.opacity(0.1))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    // Empty space to maintain layout
                    HStack {
                        Text("")
                            .font(.system(size: 16, weight: .medium))
                            .opacity(0)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                
                Spacer()
                
                Text("Step \(currentStep) of \(totalSteps)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Progress bar
            // Custom progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: geometry.size.width * progressValue, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal)
    }
}

// MARK: - Onboarding Progress View (Deprecated - keeping for backward compatibility)
struct OnboardingProgressView: View {
    let currentStep: Int
    let totalSteps: Int
    
    var progressValue: Double {
        Double(currentStep) / Double(totalSteps)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Step \(currentStep) of \(totalSteps)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // Custom progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: geometry.size.width * progressValue, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal)
    }
}

// MARK: - Onboarding Step Enum
enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case name = 1
    case sex = 2
    case country = 3
    case cookingPreference = 4
    case marketing = 5
    case calorieTrackingExperience = 6
    case mealPlanningExperience = 7
    case motivation = 8
    case challenge = 9
    case healthGoals = 10
    case goalConfirmation = 11
    case physicalStats = 12
    case targetWeight = 13
    case weightLossSpeed = 14
    case threeMonthCommitment = 15
    case thankYou = 16
    case dietaryRestrictions = 17
    case nutritionPlanLoading = 18
    case nutritionPlanDisplay = 19
    case budget = 20

    var title: String {
        switch self {
        case .welcome: return "Welcome to Preppi AI"
        case .name: return "What's your name?"
        case .sex: return "What's your sex?"
        case .country: return "What country are you from?"
        case .cookingPreference: return "Do you like to cook?"
        case .marketing: return "How did you hear about us?"
        case .calorieTrackingExperience: return "Calorie tracking experience"
        case .mealPlanningExperience: return "Meal planning experience"
        case .motivation: return "What's your main reason for trying PREPPI AI?"
        case .challenge: return "What's your biggest challenge with meal planning right now?"
        case .healthGoals: return "What are your health goals?"
        case .goalConfirmation: return "How Preppi Helps You"
        case .physicalStats: return "Tell us about yourself"
        case .targetWeight: return "What's your target weight?"
        case .weightLossSpeed: return "How fast do you want to reach your goal?"
        case .threeMonthCommitment: return "The Preppi Approach"
        case .thankYou: return "Thank You"
        case .dietaryRestrictions: return "Any dietary restrictions?"
        case .budget: return "Weekly grocery budget"
        case .nutritionPlanLoading: return "Customizing Your Plan"
        case .nutritionPlanDisplay: return "Your Custom Plan"
        }
    }

    var stepNumber: Int {
        return self.rawValue + 1
    }

    static var totalSteps: Int {
        return OnboardingStep.allCases.count
    }
}