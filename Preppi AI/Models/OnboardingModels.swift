 
//  OnboardingModels.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 7/25/25.
//

import Foundation

// MARK: - User Data Models
struct WeightRange: Equatable, Codable {
    let min: Double
    let max: Double
    
    init(min: Double, max: Double) {
        self.min = min
        self.max = max
    }
}

struct UserOnboardingData: Equatable {
    var name: String = ""
    var sex: Sex? = nil
    var country: String? = nil
    var likesToCook: Bool? = nil
    var cookingPreference: CookingPreference? = nil
    var marketingSource: MarketingSource? = nil
    var hasTriedCalorieTracking: Bool? = nil
    var hasTriedMealPlanning: Bool? = nil
    var motivations: Set<Motivation> = []
    var motivationOther: String = ""
    var challenges: Set<Challenge> = []
    var healthGoals: [HealthGoal] = []
    var age: Int = 0
    var weight: Double = 0.0
    var height: Int = 0
    var activityLevel: ActivityLevel = .sedentary
    var targetWeight: Double? = nil
    var targetWeightRange: WeightRange? = nil
    var weightLossSpeed: WeightLossSpeed? = nil
    var dietaryRestrictions: Set<DietaryRestriction> = []
    var foodAllergies: Set<Allergy> = []
    var weeklyBudget: Double? = nil
    var nutritionPlan: NutritionPlan? = nil
    var onboardingCompletedAt: Date? = nil // Date when user completed onboarding
    var accountCreatedAt: Date? = nil // Date when user account was created (fallback for start date)
    var progressStartDate: Date? = nil // Date when user started their 3-month progress tracking journey

    // Helper to check if user needs pace selection
    var needsPaceSelection: Bool {
        return healthGoals.contains(.loseWeight) || healthGoals.contains(.gainWeight)
    }
}



// MARK: - Enums

enum Sex: String, CaseIterable, Identifiable, Codable {
    case male = "Male"
    case female = "Female"
    
    var id: String { self.rawValue }
    
    var emoji: String {
        switch self {
        case .male: return "👨"
        case .female: return "👩"
        }
    }
    
    var icon: String {
        switch self {
        case .male: return "person.fill"
        case .female: return "person.fill"
        }
    }
    
    var title: String {
        return self.rawValue
    }
    
    var description: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        }
    }
}

enum CookingPreference: String, CaseIterable, Identifiable, Codable {
    case loveCooking = "I love cooking!"
    case enjoysCooking = "I enjoy cooking occasionally"
    case basicCooking = "I can do basic cooking"
    case preferNotToCook = "I prefer not to cook"
    case neverCook = "I never cook"
    
    var id: String { self.rawValue }
    
    var emoji: String {
        switch self {
        case .loveCooking: return "👨‍🍳"
        case .enjoysCooking: return "😊"
        case .basicCooking: return "🥘"
        case .preferNotToCook: return "🍕"
        case .neverCook: return "📱"
        }
    }
    
    var icon: String {
        switch self {
        case .loveCooking: return "book.fill"
        case .enjoysCooking: return "heart.fill"
        case .basicCooking: return "fork.knife"
        case .preferNotToCook: return "takeoutbag.and.cup.and.straw"
        case .neverCook: return "phone.and.waveform"
        }
    }
    
    var title: String {
        switch self {
        case .loveCooking: return "Love Cooking"
        case .enjoysCooking: return "Enjoy Cooking"
        case .basicCooking: return "Basic Cooking"
        case .preferNotToCook: return "Prefer Not to Cook"
        case .neverCook: return "Never Cook"
        }
    }
    
    var description: String {
        switch self {
        case .loveCooking: return "I spend lots of time in the kitchen"
        case .enjoysCooking: return "I cook a few times a week"
        case .basicCooking: return "Simple meals work for me"
        case .preferNotToCook: return "Quick and easy options please"
        case .neverCook: return "Takeout and delivery are my go-to"
        }
    }
}

enum HealthGoal: String, CaseIterable, Identifiable, Codable {
    case loseWeight = "Lose Weight"
    case buildMuscle = "Build Muscle"
    case maintainWeight = "Maintain Weight"
    case improveHealth = "Improve Overall Health"
    case gainWeight = "Gain Weight"
    case increaseEnergy = "Increase Energy"
    case betterSleep = "Better Sleep"
    case reduceStress = "Reduce Stress"
    
    var id: String { self.rawValue }
    
    var emoji: String {
        switch self {
        case .loseWeight: return "⚖️"
        case .buildMuscle: return "💪"
        case .maintainWeight: return "🎯"
        case .improveHealth: return "❤️"
        case .gainWeight: return "📈"
        case .increaseEnergy: return "⚡"
        case .betterSleep: return "😴"
        case .reduceStress: return "🧘"
        }
    }
    
    var icon: String {
        switch self {
        case .loseWeight: return "scalemass"
        case .buildMuscle: return "figure.strengthtraining.traditional"
        case .maintainWeight: return "target"
        case .improveHealth: return "heart.fill"
        case .gainWeight: return "chart.line.uptrend.xyaxis"
        case .increaseEnergy: return "bolt.fill"
        case .betterSleep: return "moon.fill"
        case .reduceStress: return "figure.mind.and.body"
        }
    }
    
    var title: String {
        return self.rawValue
    }
    
    var description: String {
        switch self {
        case .loseWeight: return "Reduce body weight through healthy eating"
        case .buildMuscle: return "Build strength and muscle mass"
        case .maintainWeight: return "Keep your current weight stable"
        case .improveHealth: return "Focus on overall wellness and vitality"
        case .gainWeight: return "Increase body weight in a healthy way"
        case .increaseEnergy: return "Boost daily energy and stamina"
        case .betterSleep: return "Improve sleep quality and duration"
        case .reduceStress: return "Lower stress through mindful nutrition"
        }
    }
}

enum ActivityLevel: String, CaseIterable, Identifiable, Codable {
    case sedentary = "Sedentary (little to no exercise)"
    case lightlyActive = "Lightly Active (light exercise 1-3 days/week)"
    case moderatelyActive = "Moderately Active (moderate exercise 3-5 days/week)"
    case veryActive = "Very Active (hard exercise 6-7 days/week)"
    case extremelyActive = "Extremely Active (very hard exercise, physical job)"
    
    var id: String { self.rawValue }
    
    var shortName: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .lightlyActive: return "Lightly Active"
        case .moderatelyActive: return "Moderately Active"
        case .veryActive: return "Very Active"
        case .extremelyActive: return "Extremely Active"
        }
    }
    
    var title: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .lightlyActive: return "Lightly Active"
        case .moderatelyActive: return "Moderately Active"
        case .veryActive: return "Very Active"
        case .extremelyActive: return "Extremely Active"
        }
    }
    
    var description: String {
        switch self {
        case .sedentary: return "Little to no exercise"
        case .lightlyActive: return "Light exercise 1-3 days/week"
        case .moderatelyActive: return "Moderate exercise 3-5 days/week"
        case .veryActive: return "Hard exercise 6-7 days/week"
        case .extremelyActive: return "Very hard exercise, physical job"
        }
    }
    
    var emoji: String {
        switch self {
        case .sedentary: return "🛋️"
        case .lightlyActive: return "🚶"
        case .moderatelyActive: return "🏃"
        case .veryActive: return "💪"
        case .extremelyActive: return "🏋️"
        }
    }
}

enum DietaryRestriction: String, CaseIterable, Identifiable, Codable {
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case glutenFree = "Gluten-Free"
    case dairyFree = "Dairy-Free"
    case keto = "Ketogenic"
    case paleo = "Paleo"
    case lowCarb = "Low Carb"
    case lowFat = "Low Fat"
    case lowSodium = "Low Sodium"
    case diabetic = "Diabetic-Friendly"
    case heartHealthy = "Heart Healthy"
    case mediterraneanDiet = "Mediterranean Diet"
    case highProtein = "High Protein"
    
    var id: String { self.rawValue }
    
    var emoji: String {
        switch self {
        case .vegetarian: return "🥬"
        case .vegan: return "🌱"
        case .glutenFree: return "🌾"
        case .dairyFree: return "🥛"
        case .keto: return "🥑"
        case .paleo: return "🦴"
        case .lowCarb: return "🥩"
        case .lowFat: return "🐟"
        case .lowSodium: return "🧂"
        case .diabetic: return "📊"
        case .heartHealthy: return "❤️"
        case .mediterraneanDiet: return "🫒"
        case .highProtein: return "💪"
        }
    }
}

enum MarketingSource: String, CaseIterable, Identifiable, Codable {
    case appStore = "App Store"
    case instagram = "Instagram"
    case tiktok = "TikTok"
    case facebook = "Facebook"
    case google = "Google"
    case youtube = "Youtube"
    case friendOrFamily = "Friend or family"

    var id: String { self.rawValue }

    var emoji: String {
        switch self {
        case .appStore: return "📱"
        case .instagram: return "📷"
        case .tiktok: return "🎵"
        case .facebook: return "👍"
        case .google: return "🔍"
        case .youtube: return "📺"
        case .friendOrFamily: return "👥"
        }
    }

    var icon: String {
        switch self {
        case .appStore: return "app.badge"
        case .instagram: return "camera.circle.fill"
        case .tiktok: return "music.note"
        case .facebook: return "person.3.fill"
        case .google: return "globe"
        case .youtube: return "play.tv.fill"
        case .friendOrFamily: return "person.2.circle.fill"
        }
    }

    var title: String {
        return self.rawValue
    }

    var description: String {
        switch self {
        case .appStore: return "Found us in the App Store"
        case .instagram: return "Discovered us on Instagram"
        case .tiktok: return "Found us on TikTok"
        case .facebook: return "Saw us on Facebook"
        case .google: return "Found us through Google Search"
        case .youtube: return "Discovered us on YouTube"
        case .friendOrFamily: return "Recommended by someone I know"
        }
    }

    var customImageName: String? {
        switch self {
        case .appStore: return "logo-appstore"
        case .instagram: return "logo-instagram"
        case .tiktok: return "logo-tiktok"
        case .facebook: return "logo-facebook"
        case .google: return "logo-google"
        case .youtube: return "logo-youtube"
        case .friendOrFamily: return nil // Use SF Symbol for this one
        }
    }
}

enum Motivation: String, CaseIterable, Identifiable, Codable {
    case eatHealthier = "I want to eat healthier and stick to my goals"
    case avoidDecisions = "I'm tired of deciding what to cook every day"
    case saveTime = "I want to save time on meal planning and shopping"
    case stayOnBudget = "I want to stay on budget with my groceries"
    case exploreNewMeals = "I want to explore new meals I'll actually enjoy"
    case other = "Other"
    
    var id: String { self.rawValue }
    
    var emoji: String {
        switch self {
        case .eatHealthier: return "🥗"
        case .avoidDecisions: return "🤔"
        case .saveTime: return "⏰"
        case .stayOnBudget: return "💰"
        case .exploreNewMeals: return "🍽️"
        case .other: return "✏️"
        }
    }
    
    var icon: String {
        switch self {
        case .eatHealthier: return "heart.fill"
        case .avoidDecisions: return "questionmark.circle.fill"
        case .saveTime: return "clock.fill"
        case .stayOnBudget: return "dollarsign.circle.fill"
        case .exploreNewMeals: return "sparkles"
        case .other: return "pencil.circle.fill"
        }
    }
}

enum Challenge: String, CaseIterable, Identifiable, Codable {
    case dontKnowWhatToCook = "I don't know what to cook"
    case noTimeToPlan = "I don't have time to plan meals"
    case overspendOnGroceries = "I overspend on groceries"
    case wasteFood = "I waste food because I don't use everything I buy"
    case cantStickToDiet = "I can't stick to a diet or health goal"
    case wantCulturalMeals = "I want meals that fit my culture or taste"
    
    var id: String { self.rawValue }
    
    var emoji: String {
        switch self {
        case .dontKnowWhatToCook: return "🤷"
        case .noTimeToPlan: return "⏱️"
        case .overspendOnGroceries: return "🛒"
        case .wasteFood: return "🗑️"
        case .cantStickToDiet: return "😔"
        case .wantCulturalMeals: return "🌍"
        }
    }
    
    var icon: String {
        switch self {
        case .dontKnowWhatToCook: return "questionmark.app.fill"
        case .noTimeToPlan: return "timer"
        case .overspendOnGroceries: return "cart.fill"
        case .wasteFood: return "trash.fill"
        case .cantStickToDiet: return "arrow.down.circle.fill"
        case .wantCulturalMeals: return "globe"
        }
    }
}

enum Allergy: String, CaseIterable, Identifiable, Codable {
    case nuts = "Tree Nuts"
    case peanuts = "Peanuts"
    case dairy = "Dairy/Milk"
    case eggs = "Eggs"
    case soy = "Soy"
    case wheat = "Wheat"
    case fish = "Fish"
    case shellfish = "Shellfish"
    case sesame = "Sesame"
    case sulfites = "Sulfites"
    case mustard = "Mustard"
    case celery = "Celery"

    var id: String { self.rawValue }

    var emoji: String {
        switch self {
        case .nuts: return "🌰"
        case .peanuts: return "🥜"
        case .dairy: return "🥛"
        case .eggs: return "🥚"
        case .soy: return "🫘"
        case .wheat: return "🌾"
        case .fish: return "🐟"
        case .shellfish: return "🦐"
        case .sesame: return "🧈"
        case .sulfites: return "🍇"
        case .mustard: return "🟡"
        case .celery: return "🥬"
        }
    }
}

enum WeightLossSpeed: String, CaseIterable, Identifiable, Codable {
    case slow = "Slow & Steady"
    case medium = "Balanced"
    case fast = "Aggressive"

    var id: String { self.rawValue }

    var emoji: String {
        switch self {
        case .slow: return "🐢"
        case .medium: return "🚶"
        case .fast: return "🏃"
        }
    }

    var icon: String {
        switch self {
        case .slow: return "tortoise.fill"
        case .medium: return "figure.walk"
        case .fast: return "figure.run"
        }
    }

    var title: String {
        return self.rawValue
    }

    var weeklyWeightLossLbs: Double {
        switch self {
        case .slow: return 0.5
        case .medium: return 1.0
        case .fast: return 2.0
        }
    }

    var weeklyWeightLossKg: Double {
        switch self {
        case .slow: return 0.25
        case .medium: return 0.5
        case .fast: return 1.0
        }
    }

    // For weight gain (positive values)
    var weeklyWeightGainKg: Double {
        switch self {
        case .slow: return 0.25
        case .medium: return 0.4
        case .fast: return 0.5
        }
    }

    var weeklyWeightGainLbs: Double {
        switch self {
        case .slow: return 0.5
        case .medium: return 0.9
        case .fast: return 1.1
        }
    }

    func description(isWeightLoss: Bool) -> String {
        if isWeightLoss {
            switch self {
            case .slow:
                return "Lose ~0.5 lbs (0.25 kg) per week. Safe, sustainable, and easier to maintain."
            case .medium:
                return "Lose ~1 lb (0.5 kg) per week. The recommended standard for healthy weight loss."
            case .fast:
                return "Lose ~2 lbs (1 kg) per week. Aggressive approach for faster results."
            }
        } else {
            // Weight gain
            switch self {
            case .slow:
                return "Gain ~0.5 lbs (0.25 kg) per week. Slow, lean muscle-focused gain."
            case .medium:
                return "Gain ~0.9 lbs (0.4 kg) per week. Balanced muscle gain with minimal fat."
            case .fast:
                return "Gain ~1.1 lbs (0.5 kg) per week. Faster bulk with controlled surplus."
            }
        }
    }

    func detailedDescription(isWeightLoss: Bool) -> String {
        if isWeightLoss {
            switch self {
            case .slow:
                return "This gentle approach focuses on building sustainable habits. You'll have more flexibility with your diet and won't feel deprived."
            case .medium:
                return "A balanced approach that combines effectiveness with sustainability. This is what most health professionals recommend."
            case .fast:
                return "An aggressive but safe approach. Requires more discipline and dietary restrictions. Best for those highly motivated."
            }
        } else {
            // Weight gain
            switch self {
            case .slow:
                return "A methodical approach focusing on lean muscle gain with minimal fat. Perfect for those who want quality gains."
            case .medium:
                return "A balanced approach to building muscle while keeping fat gain minimal. Recommended for most people."
            case .fast:
                return "An assertive approach for faster muscle and weight gain. Requires consistent training and nutrition discipline."
            }
        }
    }

    // Legacy properties for backward compatibility
    var description: String {
        return description(isWeightLoss: true)
    }

    var detailedDescription: String {
        return detailedDescription(isWeightLoss: true)
    }
}