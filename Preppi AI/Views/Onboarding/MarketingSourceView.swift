 //
//  MarketingSourceView.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 7/25/25.
//

import SwiftUI

struct MarketingSourceView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var selectedSource: MarketingSource?
    @State private var animateHeader = false
    @State private var animateContent = false
    
    var body: some View {
        OnboardingContainer {
            // Make the entire page scrollable
            ScrollView(showsIndicators: false) {
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

                    // Premium Header Section
                    VStack(spacing: 25) {
                        // Animated icon with gradient background
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.green.opacity(0.1), .purple.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .scaleEffect(animateHeader ? 1.0 : 0.8)
                                .opacity(animateHeader ? 1.0 : 0.0)

                            Image(systemName: "speaker.wave.3.fill")
                                .font(.system(size: 45))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .scaleEffect(animateHeader ? 1.0 : 0.8)
                        }

                        VStack(spacing: 15) {
                            Text("How did you hear about us?")
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
                                .padding(.horizontal, 20)
                                .opacity(animateHeader ? 1.0 : 0.0)
                                .offset(y: animateHeader ? 0 : 20)

                            Text("Help us understand how you found us")
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

                    // Premium Marketing Source Options
                    VStack(spacing: 16) {
                        ForEach(Array(MarketingSource.allCases.enumerated()), id: \.element) { index, source in
                            PremiumMarketingSourceCard(
                                source: source,
                                isSelected: selectedSource == source,
                                animateContent: animateContent
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedSource = source
                                    coordinator.userData.marketingSource = source
                                }
                            }
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 30)
                            .animation(.easeOut(duration: 0.6).delay(Double(index) * 0.1), value: animateContent)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Premium Navigation Buttons
                    MarketingSourceNavigationButtons(
                        onBack: { coordinator.previousStep() },
                        onNext: { coordinator.nextStep() },
                        isNextEnabled: selectedSource != nil,
                        animateContent: animateContent
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            selectedSource = coordinator.userData.marketingSource
            
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

struct PremiumMarketingSourceCard: View {
    let source: MarketingSource
    let isSelected: Bool
    let animateContent: Bool
    let action: () -> Void
    @State private var isPressed = false

    // Brand colors for each source
    var brandColor: Color {
        switch source {
        case .appStore:
            return Color.blue
        case .instagram:
            return Color(red: 0.83, green: 0.15, blue: 0.55) // Instagram gradient pink
        case .tiktok:
            return Color.black
        case .facebook:
            return Color(red: 0.23, green: 0.35, blue: 0.60) // Facebook blue
        case .google:
            return Color(red: 0.26, green: 0.52, blue: 0.96) // Google blue
        case .youtube:
            return Color.red
        case .friendOrFamily:
            return Color.purple
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                // Icon Section with brand colors or custom logo
                ZStack {
                    Circle()
                        .fill(isSelected ?
                              brandColor :
                              brandColor.opacity(0.1)
                        )
                        .frame(width: 60, height: 60)

                    // Try to load custom brand logo, fallback to SF Symbol
                    Group {
                        if let customImageName = source.customImageName,
                           UIImage(named: customImageName) != nil {
                            Image(customImageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                                .scaleEffect(isPressed ? 1.1 : 1.0)
                        } else {
                            Image(systemName: source.icon)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(isSelected ? .white : brandColor)
                                .scaleEffect(isPressed ? 1.1 : 1.0)
                        }
                    }
                }
                
                // Content Section
                VStack(alignment: .leading, spacing: 8) {
                    Text(source.title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)
                    
                    Text(source.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
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

struct MarketingSourceNavigationButtons: View {
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
                        .fixedSize(horizontal: true, vertical: false)
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
                        .fixedSize(horizontal: true, vertical: false)
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
    MarketingSourceView(coordinator: OnboardingCoordinator())
}