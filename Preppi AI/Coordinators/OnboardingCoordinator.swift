 
//  OnboardingCoordinator.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 7/25/25.
//

import SwiftUI
import RevenueCat

class OnboardingCoordinator: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var userData = UserOnboardingData()
    @Published var isOnboardingComplete = false
    @Published var isSaving = false
    @Published var saveError: String?
    @Published var showPaywall = false
    @Published var isPurchaseCompleted = false
    
    weak var appState: AppState?
    
    init(appState: AppState? = nil) {
        self.appState = appState
        
        // Track onboarding started
        MixpanelService.shared.track(
            event: MixpanelService.Events.onboardingStarted,
            properties: [
                MixpanelService.Properties.onboardingStep: currentStep.rawValue,
                MixpanelService.Properties.stepName: currentStep.title
            ]
        )
    }
    
    func nextStep() {
        let previousStep = currentStep

        switch currentStep {
        case .welcome:
            currentStep = .name
        case .name:
            currentStep = .sex
        case .sex:
            currentStep = .country
        case .country:
            currentStep = .cookingPreference
        case .cookingPreference:
            currentStep = .marketing
        case .marketing:
            currentStep = .calorieTrackingExperience
        case .calorieTrackingExperience:
            currentStep = .mealPlanningExperience
        case .mealPlanningExperience:
            currentStep = .motivation
        case .motivation:
            currentStep = .challenge
        case .challenge:
            currentStep = .healthGoals
        case .healthGoals:
            currentStep = .goalConfirmation
        case .goalConfirmation:
            currentStep = .physicalStats
        case .physicalStats:
            // Check if user needs target weight based on goals
            if userData.needsPaceSelection {
                currentStep = .targetWeight
            } else {
                // Skip to three month commitment for maintenance/health improvement
                currentStep = .threeMonthCommitment
            }
        case .targetWeight:
            currentStep = .weightLossSpeed
        case .weightLossSpeed:
            currentStep = .threeMonthCommitment
        case .threeMonthCommitment:
            currentStep = .thankYou
        case .thankYou:
            currentStep = .dietaryRestrictions
        case .dietaryRestrictions:
            currentStep = .nutritionPlanLoading
        case .nutritionPlanLoading:
            currentStep = .nutritionPlanDisplay
        case .nutritionPlanDisplay:
            currentStep = .budget
        case .budget:
            completeOnboarding()
            return // Don't track step completion for the last step since completeOnboarding handles it
        }

        // Track step completion
        MixpanelService.shared.track(
            event: MixpanelService.Events.onboardingStepCompleted,
            properties: [
                MixpanelService.Properties.onboardingStep: previousStep.rawValue,
                MixpanelService.Properties.stepName: previousStep.title,
                "next_step": currentStep.rawValue,
                "next_step_name": currentStep.title
            ]
        )
    }
    
    func previousStep() {
        switch currentStep {
        case .welcome:
            break
        case .name:
            currentStep = .welcome
        case .sex:
            currentStep = .name
        case .country:
            currentStep = .sex
        case .cookingPreference:
            currentStep = .country
        case .marketing:
            currentStep = .cookingPreference
        case .calorieTrackingExperience:
            currentStep = .marketing
        case .mealPlanningExperience:
            currentStep = .calorieTrackingExperience
        case .motivation:
            currentStep = .mealPlanningExperience
        case .challenge:
            currentStep = .motivation
        case .healthGoals:
            currentStep = .challenge
        case .goalConfirmation:
            currentStep = .healthGoals
        case .physicalStats:
            currentStep = .goalConfirmation
        case .targetWeight:
            currentStep = .physicalStats
        case .threeMonthCommitment:
            // Check if user came from weightLossSpeed or directly from physicalStats
            if userData.needsPaceSelection {
                currentStep = .weightLossSpeed
            } else {
                currentStep = .physicalStats
            }
        case .weightLossSpeed:
            currentStep = .targetWeight
        case .thankYou:
            currentStep = .threeMonthCommitment
        case .dietaryRestrictions:
            currentStep = .thankYou
        case .nutritionPlanLoading:
            currentStep = .dietaryRestrictions
        case .nutritionPlanDisplay:
            currentStep = .nutritionPlanLoading
        case .budget:
            currentStep = .nutritionPlanDisplay
        }
    }
    
    func completeOnboarding() {
        // First save the onboarding data
        isSaving = true
        saveError = nil

        Task { @MainActor in
            do {
                // Check if this is guest onboarding (not authenticated yet)
                if appState?.isGuestOnboarding == true {
                    print("🎯 Guest onboarding completed - redirecting to signup")
                    
                    // CRITICAL: Transfer onboarding data to AppState before completing
                    print("📤 Transferring onboarding data to AppState...")
                    print("   - User Name: \(userData.name)")
                    print("   - Marketing Source: \(userData.marketingSource?.rawValue ?? "None")")
                    print("   - Cooking Preference: \(userData.cookingPreference?.rawValue ?? "None")")
                    print("   - Health Goals: \(userData.healthGoals.map { $0.rawValue })")
                    print("   - Weekly Budget: $\(userData.weeklyBudget ?? 0)")
                    
                    appState?.userData = userData
                    
                    isSaving = false
                    isOnboardingComplete = true

                    // Notify AppState to show signup screen
                    appState?.completeGuestOnboarding()

                    // Track onboarding completion (before signup)
                    MixpanelService.shared.track(
                        event: MixpanelService.Events.onboardingStepCompleted,
                        properties: [
                            "step": "onboarding_completed_guest",
                            "total_steps": OnboardingStep.totalSteps
                        ]
                    )
                    return
                }

                // Regular authenticated flow
                // Save all onboarding data to local storage
                await appState?.completeOnboarding(with: userData)

                // Only proceed to paywall if save was successful
                if appState?.errorMessage == nil {
                    isSaving = false

                    // Check if user already has Pro entitlement
                    let revenueCatService = RevenueCatService.shared
                    if revenueCatService.isProUser {
                        // User already has Pro, complete onboarding
                        isOnboardingComplete = true
                        print("✅ User already has Pro entitlement - onboarding completed")

                        // Track onboarding completion
                        MixpanelService.shared.track(
                            event: MixpanelService.Events.onboardingCompleted,
                            properties: [
                                "completion_method": "existing_premium",
                                "total_steps": OnboardingStep.totalSteps
                            ]
                        )
                    } else {
                        // User completed onboarding but doesn't have Pro access
                        // Show RevenueCat paywall after budget completion
                        print("💰 Onboarding completed - showing RevenueCat paywall")
                        showPaywall = true

                        // Track paywall shown
                        MixpanelService.shared.track(event: MixpanelService.Events.paywallViewed)
                    }
                } else {
                    isSaving = false
                    saveError = appState?.errorMessage ?? "Failed to save profile data"
                    print("❌ Failed to save onboarding data to local storage")
                }
            } catch {
                isSaving = false
                saveError = "Failed to save onboarding data: \(error.localizedDescription)"
                print("❌ Onboarding save error: \(error)")
            }
        }
    }
    
    // Retry saving onboarding data to local storage
    func retrySave() {
        completeOnboarding()
    }
    
    // Handle successful purchase completion
    func handlePurchaseCompletion() {
        showPaywall = false
        isPurchaseCompleted = true
        isOnboardingComplete = true
        print("✅ Purchase completed - onboarding finished")
        
        // Track purchase completion and onboarding completion
        MixpanelService.shared.track(event: MixpanelService.Events.subscriptionPurchased)
        MixpanelService.shared.track(
            event: MixpanelService.Events.onboardingCompleted,
            properties: [
                "completion_method": "purchase",
                "total_steps": OnboardingStep.totalSteps
            ]
        )
        
        // Update premium status in AuthService
        Task { @MainActor in
            AuthService.shared.updatePremiumStatus(isPremium: true)
        }
        
        // Request App Store review after successful purchase (great moment!)
        AppStoreReviewService.shared.requestReviewIfAppropriate()
    }
    

    
    var progressValue: Double {
        switch currentStep {
        case .welcome: return 1.0/21.0
        case .name: return 2.0/21.0
        case .sex: return 3.0/21.0
        case .country: return 4.0/21.0
        case .cookingPreference: return 5.0/21.0
        case .marketing: return 6.0/21.0
        case .calorieTrackingExperience: return 7.0/21.0
        case .mealPlanningExperience: return 8.0/21.0
        case .motivation: return 9.0/21.0
        case .challenge: return 10.0/21.0
        case .healthGoals: return 11.0/21.0
        case .goalConfirmation: return 12.0/21.0
        case .physicalStats: return 13.0/21.0
        case .targetWeight: return 14.0/21.0
        case .weightLossSpeed: return 15.0/21.0
        case .threeMonthCommitment: return 16.0/21.0
        case .thankYou: return 17.0/21.0
        case .dietaryRestrictions: return 18.0/21.0
        case .budget: return 19.0/21.0
        case .nutritionPlanLoading: return 20.0/21.0
        case .nutritionPlanDisplay: return 1.0
        }
    }

    var stepTitle: String {
        switch currentStep {
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
}