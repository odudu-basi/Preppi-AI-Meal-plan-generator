//
//  ChallengeView.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 7/25/25.
//

import SwiftUI

struct ChallengeView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var animateHeader = false
    @State private var animateContent = false
    
    var body: some View {
        OnboardingContainer {
            VStack(spacing: 20) {
                // Progress indicator
                OnboardingNavigationBar(
                    currentStep: 5,
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
                                    colors: [.orange.opacity(0.1), .red.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .scaleEffect(animateHeader ? 1.0 : 0.8)
                            .opacity(animateHeader ? 1.0 : 0.0)
                        
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 45))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(animateHeader ? 1.0 : 0.8)
                    }
                    
                    VStack(spacing: 15) {
                        Text("What's your biggest challenge with meal planning right now?")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.primary, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
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
                
                // Challenge Options
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(Array(Challenge.allCases.enumerated()), id: \.element.id) { index, challenge in
                            ChallengeOptionCard(
                                challenge: challenge,
                                isSelected: coordinator.userData.challenges.contains(challenge),
                                animateContent: animateContent,
                                index: index
                            ) {
                                selectChallenge(challenge)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Continue Button
                ChallengeContinueButton(
                    isEnabled: !coordinator.userData.challenges.isEmpty,
                    animateContent: animateContent
                ) {
                    coordinator.nextStep()
                }
                .padding(.horizontal, 20)
            }
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
    
    private func selectChallenge(_ challenge: Challenge) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if coordinator.userData.challenges.contains(challenge) {
                coordinator.userData.challenges.remove(challenge)
            } else {
                coordinator.userData.challenges.insert(challenge)
            }
        }
    }
}

// MARK: - Supporting Views

struct ChallengeOptionCard: View {
    let challenge: Challenge
    let isSelected: Bool
    let animateContent: Bool
    let index: Int
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var glowIntensity: Double = 0.0
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Selection indicator with glow animation
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.orange : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                        .shadow(color: isSelected ? .orange.opacity(glowIntensity) : .clear, radius: 8)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 16, height: 16)
                            .shadow(color: .orange.opacity(glowIntensity), radius: 4)
                    }
                }
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: glowIntensity)
                
                // Icon
                Image(systemName: challenge.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .orange : .secondary)
                    .frame(width: 30)
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.rawValue)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isSelected ? .orange : .primary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? 
                          LinearGradient(colors: [Color.orange.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                          LinearGradient(colors: [Color(.systemBackground)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? 
                                    LinearGradient(colors: [.orange.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                    LinearGradient(colors: [Color(.systemGray4).opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(color: isSelected ? .orange.opacity(0.2) : .black.opacity(0.05), 
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

struct ChallengeContinueButton: View {
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
                            colors: isEnabled ? [.orange, .red] : [.gray.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: isEnabled ? .orange.opacity(0.4) : .clear,
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
    ChallengeView(coordinator: OnboardingCoordinator())
}