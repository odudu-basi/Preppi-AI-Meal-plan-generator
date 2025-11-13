//
//  MotivationView.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 7/25/25.
//

import SwiftUI

struct MotivationView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var animateHeader = false
    @State private var animateContent = false
    @State private var showOtherInput = false
    @State private var otherText = ""
    @FocusState private var isOtherFieldFocused: Bool
    
    var body: some View {
        OnboardingContainer {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Progress indicator
                    OnboardingNavigationBar(
                        currentStep: coordinator.currentStep.stepNumber,
                        totalSteps: OnboardingStep.totalSteps,
                        canGoBack: true,
                        onBackTapped: {
                            coordinator.previousStep()
                        }
                    )
                    
                    // Header Section
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
                            
                            Image(systemName: "heart.circle.fill")
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
                        
                        VStack(spacing: 15) {
                            Text("What's your main reason for trying PREPPI AI?")
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
                                .padding(.horizontal, 20)
                                .opacity(animateHeader ? 1.0 : 0.0)
                                .offset(y: animateHeader ? 0 : 20)
                            
                            Text("Select all that apply to you")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .opacity(animateHeader ? 1.0 : 0.0)
                                .offset(y: animateHeader ? 0 : 20)
                        }
                    }
                    .padding(.top, 10)
                    
                    // Motivation Options
                    VStack(spacing: 16) {
                        ForEach(Array(Motivation.allCases.enumerated()), id: \.element.id) { index, motivation in
                            MotivationOptionCard(
                                motivation: motivation,
                                isSelected: coordinator.userData.motivations.contains(motivation),
                                animateContent: animateContent,
                                index: index,
                                showOtherInput: $showOtherInput,
                                otherText: $otherText,
                                isOtherFieldFocused: $isOtherFieldFocused
                            ) {
                                selectMotivation(motivation)
                            }
                        }
                        
                        // Other text input (only shows when "Other" is selected)
                        if showOtherInput {
                            MotivationOtherInputCard(
                                text: $otherText,
                                isFieldFocused: $isOtherFieldFocused,
                                animateContent: animateContent
                            )
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity
                            ))
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Continue Button
                    MotivationContinueButton(
                        isEnabled: !coordinator.userData.motivations.isEmpty,
                        animateContent: animateContent
                    ) {
                        coordinator.userData.motivationOther = otherText
                        coordinator.nextStep()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40) // Add bottom padding for better spacing
                }
            }
        }
        .onAppear {
            // Set initial state for "Other" option
            showOtherInput = coordinator.userData.motivations.contains(.other)
            otherText = coordinator.userData.motivationOther
            
            withAnimation(.easeOut(duration: 0.8)) {
                animateHeader = true
            }
            
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                animateContent = true
            }
        }
        .onChange(of: showOtherInput) { oldValue, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isOtherFieldFocused = true
                }
            }
        }
    }
    
    private func selectMotivation(_ motivation: Motivation) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if coordinator.userData.motivations.contains(motivation) {
                coordinator.userData.motivations.remove(motivation)
                
                // Hide "Other" input if "Other" is deselected
                if motivation == .other {
                    showOtherInput = false
                    otherText = ""
                    isOtherFieldFocused = false
                }
            } else {
                coordinator.userData.motivations.insert(motivation)
                
                // Show "Other" input if "Other" is selected
                if motivation == .other {
                    showOtherInput = true
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct MotivationOptionCard: View {
    let motivation: Motivation
    let isSelected: Bool
    let animateContent: Bool
    let index: Int
    @Binding var showOtherInput: Bool
    @Binding var otherText: String
    @FocusState.Binding var isOtherFieldFocused: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var glowIntensity: Double = 0.0
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Selection indicator with glow animation
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                        .shadow(color: isSelected ? .green.opacity(glowIntensity) : .clear, radius: 8)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 16, height: 16)
                            .shadow(color: .green.opacity(glowIntensity), radius: 4)
                    }
                }
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: glowIntensity)
                
                // Icon
                Image(systemName: motivation.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .green : .secondary)
                    .frame(width: 30)
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(motivation.rawValue)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isSelected ? .green : .primary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? 
                          LinearGradient(colors: [Color.green.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                          LinearGradient(colors: [Color(.systemBackground)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? 
                                    LinearGradient(colors: [.green.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                    LinearGradient(colors: [Color(.systemGray4).opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(color: isSelected ? .green.opacity(0.2) : .black.opacity(0.05), 
                           radius: isSelected ? 8 : 4, 
                           x: 0, 
                           y: isSelected ? 4 : 2)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .opacity(animateContent ? 1.0 : 0.0)
            .offset(y: animateContent ? 0 : 30)
            .animation(.easeOut(duration: 0.6).delay(Double(index) * 0.1), value: animateContent)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .onAppear {
            if isSelected {
                glowIntensity = 0.6
            }
        }
        .onChange(of: isSelected) { oldValue, newValue in
            if newValue {
                glowIntensity = 0.6
            } else {
                glowIntensity = 0.0
            }
        }
    }
}

struct MotivationOtherInputCard: View {
    @Binding var text: String
    @FocusState.Binding var isFieldFocused: Bool
    let animateContent: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Please specify:")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            TextField("Tell us more about your motivation...", text: $text, axis: .vertical)
                .font(.system(size: 16))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isFieldFocused ?
                                    LinearGradient(colors: [.green.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                    LinearGradient(colors: [Color(.systemGray4).opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: isFieldFocused ? 2 : 1
                                )
                        )
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
                .focused($isFieldFocused)
                .lineLimit(3...6)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.5))
        )
        .opacity(animateContent ? 1.0 : 0.0)
    }
}

struct MotivationContinueButton: View {
    let isEnabled: Bool
    let animateContent: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold))
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: isEnabled ? [.green, .mint] : [.gray.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: isEnabled ? .green.opacity(0.4) : .clear,
                        radius: isEnabled ? 12 : 0,
                        x: 0,
                        y: 6
                    )
            )
        }
        .disabled(!isEnabled)
        .scaleEffect(isEnabled ? 1.0 : 0.98)
        .opacity(animateContent ? 1.0 : 0.0)
        .offset(y: animateContent ? 0 : 30)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MotivationView(coordinator: OnboardingCoordinator())
}