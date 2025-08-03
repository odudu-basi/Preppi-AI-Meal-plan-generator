 
//  OnboardingCoordinator.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 7/25/25.
//

import SwiftUI
import RevenueCat

class OnboardingCoordinator: ObservableObject {
    @Published var currentStep: OnboardingStep = .name
    @Published var userData = UserOnboardingData()
    @Published var isOnboardingComplete = false
    @Published var isSaving = false
    @Published var saveError: String?
    @Published var showPaywall = false
    @Published var isPurchaseCompleted = false
    
    weak var appState: AppState?
    
    init(appState: AppState? = nil) {
        self.appState = appState
    }
    
    func nextStep() {
        switch currentStep {
        case .name:
            currentStep = .cookingPreference
        case .cookingPreference:
            currentStep = .marketing
        case .marketing:
            currentStep = .motivation
        case .motivation:
            currentStep = .challenge
        case .challenge:
            currentStep = .healthGoals
        case .healthGoals:
            currentStep = .physicalStats
        case .physicalStats:
            currentStep = .dietaryRestrictions
        case .dietaryRestrictions:
            currentStep = .budget
        case .budget:
            completeOnboarding()
        }
    }
    
    func previousStep() {
        switch currentStep {
        case .name:
            break
        case .cookingPreference:
            currentStep = .name
        case .marketing:
            currentStep = .cookingPreference
        case .motivation:
            currentStep = .marketing
        case .challenge:
            currentStep = .motivation
        case .healthGoals:
            currentStep = .challenge
        case .physicalStats:
            currentStep = .healthGoals
        case .dietaryRestrictions:
            currentStep = .physicalStats
        case .budget:
            currentStep = .dietaryRestrictions
        }
    }
    
    func completeOnboarding() {
        // First save the onboarding data
        isSaving = true
        saveError = nil
        
        Task { @MainActor in
            do {
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
                    } else {
                        // Show paywall
                        showPaywall = true
                        print("💰 Showing paywall for Pro subscription")
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
    }
    

    
    var progressValue: Double {
        switch currentStep {
        case .name: return 1.0/9.0
        case .cookingPreference: return 2.0/9.0
        case .marketing: return 3.0/9.0
        case .motivation: return 4.0/9.0
        case .challenge: return 5.0/9.0
        case .healthGoals: return 6.0/9.0
        case .physicalStats: return 7.0/9.0
        case .dietaryRestrictions: return 8.0/9.0
        case .budget: return 1.0
        }
    }
    
    var stepTitle: String {
        switch currentStep {
        case .name: return "What's your name?"
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
}