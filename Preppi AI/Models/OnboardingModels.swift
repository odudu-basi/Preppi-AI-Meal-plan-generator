 
//  OnboardingModels.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 7/25/25.
//

import Foundation

// MARK: - User Data Models
struct UserOnboardingData: Equatable {
    var name: String = ""
    var likesToCook: Bool? = nil
    var cookingPreference: CookingPreference? = nil
    var marketingSource: MarketingSource? = nil
    var motivations: Set<Motivation> = []
    var motivationOther: String = ""
    var challenges: Set<Challenge> = []
    var healthGoals: [HealthGoal] = []
    var age: Int = 0
    var weight: Double = 0.0
    var height: Int = 0
    var activityLevel: ActivityLevel = .sedentary
    var dietaryRestrictions: Set<DietaryRestriction> = []
    var foodAllergies: Set<Allergy> = []
    var weeklyBudget: Double? = nil
}



// MARK: - Enums

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
        }
    }
}

enum MarketingSource: String, CaseIterable, Identifiable, Codable {
    case instagram = "Instagram"
    case tiktok = "TikTok"
    case friend = "Friend"
    case x = "X (Twitter)"
    
    var id: String { self.rawValue }
    
    var emoji: String {
        switch self {
        case .instagram: return "📷"
        case .tiktok: return "🎵"
        case .friend: return "👥"
        case .x: return "🐦"
        }
    }
    
    var icon: String {
        switch self {
        case .instagram: return "camera.fill"
        case .tiktok: return "music.note"
        case .friend: return "person.2.fill"
        case .x: return "bird.fill"
        }
    }
    
    var title: String {
        return self.rawValue
    }
    
    var description: String {
        switch self {
        case .instagram: return "Found us through Instagram posts or ads"
        case .tiktok: return "Discovered us on TikTok videos"
        case .friend: return "A friend recommended Preppi to me"
        case .x: return "Saw us on X (formerly Twitter)"
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