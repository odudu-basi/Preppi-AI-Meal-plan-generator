//
//  SexSelectionView.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 7/25/25.
//

import SwiftUI

struct SexSelectionView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var selectedSex: Sex? = nil
    @State private var animateHeader = false
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
                
                // Premium Header Section
                VStack(spacing: 25) {
                    // Animated emoji with background
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
                        
                        Text("👤")
                            .font(.system(size: 50))
                            .scaleEffect(animateHeader ? 1.0 : 0.8)
                            .rotationEffect(.degrees(animateHeader ? 0 : -10))
                    }
                    
                    VStack(spacing: 15) {
                        Text("What's your sex?")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
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
                        
                        Text("This helps us create personalized meal plans based on your nutritional needs")
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
                
                // Sex Selection Options
                VStack(spacing: 20) {
                    ForEach(Sex.allCases) { sex in
                        SexSelectionButton(
                            sex: sex,
                            isSelected: selectedSex == sex,
                            animateContent: animateContent
                        ) {
                            selectedSex = sex
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Continue Button
                PremiumContinueButton(
                    isEnabled: selectedSex != nil,
                    animateContent: animateContent
                ) {
                    coordinator.userData.sex = selectedSex
                    coordinator.nextStep()
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .onAppear {
            // Set initial selection if already set
            selectedSex = coordinator.userData.sex
            
            withAnimation(.easeOut(duration: 0.8)) {
                animateHeader = true
            }
            
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                animateContent = true
            }
        }
    }
}

// MARK: - Sex Selection Button

struct SexSelectionButton: View {
    let sex: Sex
    let isSelected: Bool
    let animateContent: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 20) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isSelected ? [.green.opacity(0.2), .mint.opacity(0.1)] : [Color(.systemGray6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Text(sex.emoji)
                        .font(.system(size: 30))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(sex.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(sex.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? Color.green : Color(.systemGray4),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? 
                                LinearGradient(colors: [.green.opacity(0.6), .green.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                LinearGradient(colors: [Color(.systemGray4).opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .scaleEffect(animateContent ? 1.0 : 0.95)
        .opacity(animateContent ? 1.0 : 0.0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SexSelectionView(coordinator: OnboardingCoordinator())
}