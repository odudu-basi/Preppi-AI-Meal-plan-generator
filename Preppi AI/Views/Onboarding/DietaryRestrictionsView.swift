 
//  DietaryRestrictionsView.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 7/25/25.
//

import SwiftUI

struct DietaryRestrictionsView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var animateHeader = false
    
    var body: some View {
        OnboardingContainer {
            VStack(spacing: 0) {
                // Progress indicator - Fixed at top
                OnboardingNavigationBar(
                    currentStep: coordinator.currentStep.stepNumber,
                    totalSteps: OnboardingStep.totalSteps,
                    canGoBack: true,
                    onBackTapped: {
                        coordinator.previousStep()
                    }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                
                // Scrollable content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
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
                                
                                Image(systemName: "leaf.circle.fill")
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
                                Text("Dietary Preferences")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.primary, .green],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .opacity(animateHeader ? 1.0 : 0.0)
                                    .offset(y: animateHeader ? 0 : 20)
                                
                                Text("Help us personalize your meal plans by sharing any dietary restrictions or allergies")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.horizontal, 20)
                                    .opacity(animateHeader ? 1.0 : 0.0)
                                    .offset(y: animateHeader ? 0 : 20)
                                
                                // Skip guidance text
                                Text("Don't have any dietary restrictions? You can continue to the next step.")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.green)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 8)
                                    .opacity(animateHeader ? 1.0 : 0.0)
                                    .offset(y: animateHeader ? 0 : 20)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Content Sections
                        VStack(spacing: 25) {
                            // Dietary Restrictions Section
                            PremiumSection(
                                title: "Dietary Restrictions", 
                                icon: "leaf.fill",
                                iconColor: .green
                            ) {
                                VStack(spacing: 12) {
                                    ForEach(DietaryRestriction.allCases, id: \.self) { restriction in
                                        ImprovedCheckboxRow(
                                            title: restriction.rawValue,
                                            emoji: restriction.emoji,
                                            isChecked: coordinator.userData.dietaryRestrictions.contains(restriction)
                                        ) {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                if coordinator.userData.dietaryRestrictions.contains(restriction) {
                                                    coordinator.userData.dietaryRestrictions.remove(restriction)
                                                } else {
                                                    coordinator.userData.dietaryRestrictions.insert(restriction)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Allergies Section
                            PremiumSection(
                                title: "Food Allergies", 
                                icon: "exclamationmark.shield.fill",
                                iconColor: .orange
                            ) {
                                VStack(spacing: 12) {
                                    ForEach(Allergy.allCases, id: \.self) { allergy in
                                        ImprovedCheckboxRow(
                                            title: allergy.rawValue,
                                            emoji: allergy.emoji,
                                            isChecked: coordinator.userData.foodAllergies.contains(allergy)
                                        ) {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                if coordinator.userData.foodAllergies.contains(allergy) {
                                                    coordinator.userData.foodAllergies.remove(allergy)
                                                } else {
                                                    coordinator.userData.foodAllergies.insert(allergy)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Navigation Buttons
                        PremiumNavigationButtons(
                            onBack: { coordinator.previousStep() },
                            onNext: { coordinator.nextStep() }
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                animateHeader = true
            }
        }
    }
}

// MARK: - Premium Components

struct PremiumSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    init(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            content
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [iconColor.opacity(0.2), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

struct ImprovedCheckboxRow: View {
    let title: String
    let emoji: String
    let isChecked: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Emoji circle
                ZStack {
                    Circle()
                        .fill(isChecked ? 
                              LinearGradient(colors: [.green.opacity(0.2), .mint.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                              LinearGradient(colors: [Color(.systemGray6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(isChecked ? Color.green.opacity(0.4) : Color.clear, lineWidth: 2)
                        )
                    
                    Text(emoji)
                        .font(.system(size: 24))
                        .scaleEffect(isPressed ? 1.1 : 1.0)
                }
                
                // Title and checkbox
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Checkbox
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isChecked ? 
                                  LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                  LinearGradient(colors: [Color(.systemGray5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 28, height: 28)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isChecked ? Color.clear : Color(.systemGray4), lineWidth: 1.5)
                            )
                        
                        if isChecked {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .scaleEffect(isPressed ? 1.2 : 1.0)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isChecked ? 
                          LinearGradient(colors: [Color.green.opacity(0.08), Color.mint.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                          LinearGradient(colors: [Color(.systemBackground)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isChecked ? 
                                   LinearGradient(colors: [Color.green.opacity(0.4), Color.mint.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                   LinearGradient(colors: [Color(.systemGray5)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                   lineWidth: 1.5
                            )
                    )
                    .shadow(color: isChecked ? .green.opacity(0.15) : .black.opacity(0.05), radius: isChecked ? 8 : 4, x: 0, y: 2)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// Keep the old component for compatibility
struct PremiumCheckboxRow: View {
    let title: String
    let isChecked: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isChecked ? 
                              LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing) :
                              LinearGradient(colors: [Color(.systemGray5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 24, height: 24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isChecked ? Color.clear : Color(.systemGray4), lineWidth: 1)
                        )
                    
                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(isPressed ? 1.2 : 1.0)
                    }
                }
                
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isChecked ? Color.green.opacity(0.08) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isChecked ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct PremiumNavigationButtons: View {
    let onBack: () -> Void
    let onNext: () -> Void
    
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
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .green.opacity(0.4), radius: 12, x: 0, y: 6)
                )
            }
        }
    }
}

#Preview {
    DietaryRestrictionsView(coordinator: OnboardingCoordinator())
}