import Foundation
import Mixpanel

class MixpanelService: ObservableObject {
    static let shared = MixpanelService()
    
    private init() {
        configure()
    }
    
    private func configure() {
        let token = ConfigurationService.shared.mixpanelToken
        Mixpanel.initialize(token: token, trackAutomaticEvents: false)
        print("✅ Mixpanel initialized with token: \(String(token.prefix(8)))...")
    }
    
    // MARK: - Tracking Methods
    
    /// Track an event with optional properties
    func track(event: String, properties: [String: MixpanelType]? = nil) {
        Mixpanel.mainInstance().track(event: event, properties: properties)
        print("📊 Mixpanel tracked: \(event)")
    }
    
    /// Set user properties
    func setUserProperties(_ properties: [String: MixpanelType]) {
        Mixpanel.mainInstance().people.set(properties: properties)
        print("👤 Mixpanel user properties set")
    }
    
    /// Identify a user
    func identify(distinctId: String) {
        Mixpanel.mainInstance().identify(distinctId: distinctId)
        print("🆔 Mixpanel identified user: \(distinctId)")
    }
    
    /// Reset user data (useful for logout)
    func reset() {
        Mixpanel.mainInstance().reset()
        print("🔄 Mixpanel user data reset")
    }
    
    /// Flush events immediately
    func flush() {
        Mixpanel.mainInstance().flush()
        print("🚀 Mixpanel events flushed")
    }
}

// MARK: - Event Names
extension MixpanelService {
    struct Events {
        // App Lifecycle
        static let appLaunched = "App Launched"
        static let appBackgrounded = "App Backgrounded"
        static let appForegrounded = "App Foregrounded"
        
        // User Authentication
        static let userSignedUp = "User Signed Up"
        static let userSignedIn = "User Signed In"
        static let userSignedOut = "User Signed Out"
        
        // Meal Planning
        static let mealPlanGenerated = "Meal Plan Generated"
        static let mealPlanSaved = "Meal Plan Saved"
        static let mealPlanDeleted = "Meal Plan Deleted"
        static let mealImageGenerated = "Meal Image Generated"
        static let detailedRecipeGenerated = "Detailed Recipe Generated"
        
        // Shopping List
        static let shoppingListViewed = "Shopping List Viewed"
        static let shoppingItemChecked = "Shopping Item Checked"
        static let shoppingItemUnchecked = "Shopping Item Unchecked"
        
        // Onboarding
        static let onboardingStarted = "Onboarding Started"
        static let onboardingCompleted = "Onboarding Completed"
        static let onboardingStepCompleted = "Onboarding Step Completed"
        
        // Subscription/Paywall
        static let paywallViewed = "Paywall Viewed"
        static let subscriptionPurchased = "Subscription Purchased"
        static let subscriptionRestored = "Subscription Restored"
        
        // Preferences
        static let dietaryRestrictionsSet = "Dietary Restrictions Set"
        static let physicalStatsSet = "Physical Stats Set"
        static let cookingPreferencesSet = "Cooking Preferences Set"
        
        // Meal Button Interactions
        static let mealButtonTapped = "Meal Button Tapped"
    }
}

// MARK: - Property Names
extension MixpanelService {
    struct Properties {
        // User Properties
        static let userId = "user_id"
        static let isPremium = "is_premium"
        static let signUpMethod = "signup_method"
        
        // Meal Planning Properties
        static let mealCount = "meal_count"
        static let cuisineTypes = "cuisine_types"
        static let preparationStyle = "preparation_style"
        static let mealName = "meal_name"
        static let cookTime = "cook_time"
        static let calories = "calories"
        static let mealType = "meal_type"
        
        // Onboarding Properties
        static let onboardingStep = "onboarding_step"
        static let stepName = "step_name"
        
        // App Properties
        static let screenName = "screen_name"
        static let source = "source"
    }
}