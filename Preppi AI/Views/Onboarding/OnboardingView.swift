//
//  OnboardingView.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 7/25/25.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var coordinator = OnboardingCoordinator()
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            // Premium gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color.green.opacity(0.02),
                    Color.blue.opacity(0.01)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            NavigationView {
                Group {
                    if isLoading {
                        PremiumLoadingView()
                            .transition(.opacity)
                    } else {
                        Group {
                            switch coordinator.currentStep {
                            case .welcome:
                                WelcomeView(coordinator: coordinator)
                            case .name:
                                NameInputView(coordinator: coordinator)
                            case .sex:
                                SexSelectionView(coordinator: coordinator)
                            case .country:
                                CountryInputView(coordinator: coordinator)
                            case .cookingPreference:
                                CookingPreferenceView(coordinator: coordinator)
                            case .marketing:
                                MarketingSourceView(coordinator: coordinator)
                            case .calorieTrackingExperience:
                                CalorieTrackingExperienceView(coordinator: coordinator)
                            case .mealPlanningExperience:
                                MealPlanningExperienceView(coordinator: coordinator)
                            case .motivation:
                                MotivationView(coordinator: coordinator)
                            case .challenge:
                                ChallengeView(coordinator: coordinator)
                            case .healthGoals:
                                HealthGoalsView(coordinator: coordinator)
                            case .goalConfirmation:
                                GoalConfirmationView(coordinator: coordinator)
                            case .physicalStats:
                                PhysicalStatsView(coordinator: coordinator)
                            case .targetWeight:
                                TargetWeightView(coordinator: coordinator)
                            case .weightLossSpeed:
                                WeightLossSpeedView(coordinator: coordinator)
                            case .threeMonthCommitment:
                                ThreeMonthCommitmentView(coordinator: coordinator)
                            case .thankYou:
                                ThankYouView(coordinator: coordinator)
                            case .dietaryRestrictions:
                                DietaryRestrictionsView(coordinator: coordinator)
                            case .budget:
                                BudgetView(coordinator: coordinator)
                            case .nutritionPlanLoading:
                                NutritionPlanLoadingView(coordinator: coordinator)
                            case .nutritionPlanDisplay:
                                NutritionPlanDisplayView(coordinator: coordinator)
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }
                }
                .navigationBarHidden(true)
                .animation(.easeInOut(duration: 0.4), value: coordinator.currentStep)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
        .onAppear {
            // Connect the coordinator to the app state
            coordinator.appState = appState

            // Show loading for a brief moment
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeOut(duration: 0.6)) {
                    isLoading = false
                }
            }
        }
        .onChange(of: coordinator.isOnboardingComplete) { oldValue, newValue in
            if newValue {
                // Onboarding is complete, update AppState
                print("✅ OnboardingView detected completion - updating AppState")
                appState.isOnboardingComplete = true
            }
        }
        .onChange(of: appState.isOnboardingComplete) { oldValue, newValue in
            if newValue {
                // AppState confirms onboarding complete, this view will be dismissed automatically
                print("✅ AppState onboarding complete - OnboardingView will be dismissed")
            }
        }
    }

}

// MARK: - Premium Components

struct PremiumLoadingView: View {
    @State private var animateGradient = false
    @State private var animateLogo = false
    @State private var animateText = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Animated Logo
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.2), .blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateLogo ? 1.0 : 0.8)
                    .opacity(animateLogo ? 1.0 : 0.0)
                
                Text("🥗")
                    .font(.system(size: 60))
                    .scaleEffect(animateLogo ? 1.0 : 0.8)
                    .rotationEffect(.degrees(animateLogo ? 0 : -10))
            }
            
            VStack(spacing: 15) {
                Text("Preppi AI")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(animateText ? 1.0 : 0.0)
                    .offset(y: animateText ? 0 : 20)
                
                Text("Personalizing your nutrition journey")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(animateText ? 1.0 : 0.0)
                    .offset(y: animateText ? 0 : 20)
            }
            
            Spacer()
            
            // Premium Loading Indicator
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 12, height: 12)
                        .scaleEffect(animateGradient ? 1.2 : 0.8)
                        .opacity(animateGradient ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: animateGradient
                        )
                }
            }
            .padding(.bottom, 50)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateLogo = true
            }
            
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                animateText = true
            }
            
            withAnimation(.easeInOut(duration: 0.6).delay(0.6)) {
                animateGradient = true
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}