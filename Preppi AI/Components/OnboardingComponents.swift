 
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
            ProgressView(value: progressValue)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .scaleEffect(x: 1, y: 2, anchor: .center)
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
            
            ProgressView(value: progressValue)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding(.horizontal)
    }
}

// MARK: - Onboarding Step Enum
enum OnboardingStep: Int, CaseIterable {
    case name = 0
    case sex = 1
    case cookingPreference = 2
    case marketing = 3
    case motivation = 4
    case challenge = 5
    case healthGoals = 6
    case physicalStats = 7
    case dietaryRestrictions = 8
    case budget = 9
    
    var title: String {
        switch self {
        case .name: return "What's your name?"
        case .sex: return "What's your sex?"
        case .cookingPreference: return "Do you like to cook?"
        case .marketing: return "How did you hear about us?"
        case .motivation: return "What's your main reason for trying PREPPI AI?"
        case .challenge: return "What's your biggest challenge with meal planning right now?"
        case .healthGoals: return "What are your health goals?"
        case .physicalStats: return "Tell us about yourself"
        case .dietaryRestrictions: return "Any dietary restrictions?"
        case .budget: return "Weekly grocery budget"
        }
    }
    
    var stepNumber: Int {
        return self.rawValue + 1
    }
    
    static var totalSteps: Int {
        return OnboardingStep.allCases.count
    }
}