//  CookingPreferenceView.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 7/25/25.
//

import SwiftUI

struct CookingPreferenceView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var selectedPreference: CookingPreference?
    @State private var animateHeader = false
    @State private var animateContent = false
    
    var body: some View {
        OnboardingContainer {
            VStack(spacing: 0) {
                // Navigation bar with back button - Fixed at top
                OnboardingNavigationBar(
                    currentStep: 2,
                    totalSteps: OnboardingStep.totalSteps,
                    canGoBack: true,
                    onBackTapped: {
                        coordinator.previousStep()
                    }
                )
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Scrollable content
                ScrollView {
                    VStack(spacing: 25) {
                        // Premium Header Section
                        VStack(spacing: 25) {
                    // Animated icon with gradient background
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.green.opacity(0.1), .orange.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .scaleEffect(animateHeader ? 1.0 : 0.8)
                            .opacity(animateHeader ? 1.0 : 0.0)
                        
                        Image(systemName: "chef.hat.fill")
                            .font(.system(size: 45))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(animateHeader ? 1.0 : 0.8)
                    }
                    
                    VStack(spacing: 15) {
                        Text("Do you like to cook?")
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
                            .padding(.horizontal, 20)
                            .opacity(animateHeader ? 1.0 : 0.0)
                            .offset(y: animateHeader ? 0 : 20)
                        
                        Text("This helps us personalize your meal recommendations")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .padding(.horizontal, 20)
                            .opacity(animateHeader ? 1.0 : 0.0)
                            .offset(y: animateHeader ? 0 : 20)
                    }
                }
                .padding(.top, 10)
                
                // Premium Cooking Preference Options
                VStack(spacing: 16) {
                    ForEach(Array(CookingPreference.allCases.enumerated()), id: \.element) { index, preference in
                        PremiumCookingPreferenceCard(
                            preference: preference,
                            isSelected: selectedPreference == preference,
                            animateContent: animateContent
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedPreference = preference
                                coordinator.userData.cookingPreference = preference
                            }
                        }
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 30)
                        .animation(.easeOut(duration: 0.6).delay(Double(index) * 0.1), value: animateContent)
                    }
                        }
                        .padding(.horizontal, 20)
                        
                        // Add bottom padding for scroll
                        Color.clear.frame(height: 120)
                    }
                }
                
                // Premium Navigation Buttons - Fixed at bottom
                VStack {
                    CookingPreferenceNavigationButtons(
                        onBack: { coordinator.previousStep() },
                        onNext: { coordinator.nextStep() },
                        isNextEnabled: selectedPreference != nil,
                        animateContent: animateContent
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
        .onAppear {
            selectedPreference = coordinator.userData.cookingPreference
            
            withAnimation(.easeOut(duration: 0.8)) {
                animateHeader = true
            }
            
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                animateContent = true
            }
        }
    }
}

// MARK: - Premium Components

struct PremiumCookingPreferenceCard: View {
    let preference: CookingPreference
    let isSelected: Bool
    let animateContent: Bool
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
                    
                    Image(systemName: preference.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .green)
                        .scaleEffect(isPressed ? 1.1 : 1.0)
                }
                
                // Content Section
                VStack(alignment: .leading, spacing: 8) {
                    Text(preference.title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(preference.description)
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

struct CookingPreferenceNavigationButtons: View {
    let onBack: () -> Void
    let onNext: () -> Void
    let isNextEnabled: Bool
    let animateContent: Bool
    
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
        .opacity(animateContent ? 1.0 : 0.0)
        .offset(y: animateContent ? 0 : 30)
    }
}

#Preview {
    CookingPreferenceView(coordinator: OnboardingCoordinator())
}