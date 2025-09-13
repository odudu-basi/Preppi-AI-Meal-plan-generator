import Foundation
import SwiftUI

// MARK: - Macros Data Model
struct Macros: Codable, Hashable {
    let protein: Double      // grams
    let carbohydrates: Double // grams  
    let fat: Double          // grams
    let fiber: Double        // grams
    let sugar: Double        // grams
    let sodium: Double       // milligrams
    
    // Computed calories (4 kcal/g protein, 4 kcal/g carbs, 9 kcal/g fat)
    var totalCalories: Int {
        Int((protein * 4) + (carbohydrates * 4) + (fat * 9))
    }
}

// MARK: - Meal Data Models
struct Meal: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let calories: Int
    let cookTime: Int // in minutes
    let ingredients: [String]
    let instructions: [String]
    let originalCookingDay: String? // Day when meal was originally prepared (for leftovers)
    let imageUrl: String? // URL for AI-generated meal image
    let recommendedCaloriesBeforeDinner: Int // Recommended calories to consume before dinner based on user goals
    let macros: Macros? // Nutritional macronutrients information
    
    // Detailed recipe fields
    let detailedIngredients: [String]? // Detailed ingredients with measurements
    let detailedInstructions: [String]? // Detailed cooking instructions
    let cookingTips: [String]? // Professional cooking tips
    let servingInfo: String? // Serving information and presentation
}

struct DayMeal: Identifiable, Codable, Hashable {
    let id: UUID
    let day: String
    let meal: Meal
    
    // Custom initializer to use meal ID for DayMeal ID to maintain consistency
    init(day: String, meal: Meal) {
        self.id = meal.id
        self.day = day
        self.meal = meal
    }
}

struct MealPlan: Identifiable, Codable {
    var id = UUID()
    let dayMeals: [DayMeal]
    let createdAt: Date
    
    init(dayMeals: [DayMeal]) {
        self.dayMeals = dayMeals
        self.createdAt = Date()
    }
}

// MARK: - Extensions
extension DayMeal {
    static let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    var dayIndex: Int {
        Self.weekdays.firstIndex(of: day) ?? 0
    }
}

extension MealPlan {
    var totalCalories: Int {
        dayMeals.reduce(0) { $0 + $1.meal.calories }
    }
    
    var averageCalories: Int {
        dayMeals.isEmpty ? 0 : totalCalories / dayMeals.count
    }
    
    var averageCookTime: Int {
        let totalTime = dayMeals.reduce(0) { $0 + $1.meal.cookTime }
        return dayMeals.isEmpty ? 0 : totalTime / dayMeals.count
    }
}

// MARK: - Streaks Configuration
enum DayCompletionRule: String, CaseIterable {
    case anyMeal = "anyMeal"
    case allMeals = "allMeals"
}

// MARK: - Meal Completion Types
enum MealCompletionType: String, Codable, CaseIterable {
    case none = "none"
    case ateExact = "ateExact"
    case ateSimilar = "ateSimilar"
    
    var displayName: String {
        switch self {
        case .none: return "Not Completed"
        case .ateExact: return "Ate Exact Meal"
        case .ateSimilar: return "Ate Similar Meal"
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "circle"
        case .ateExact: return "checkmark.circle.fill"
        case .ateSimilar: return "checkmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .none: return .gray
        case .ateExact: return .green
        case .ateSimilar: return .blue
        }
    }
}

// MARK: - Meal Instance for Completions
struct MealInstance: Identifiable, Codable {
    let id: UUID
    let date: Date
    let mealType: String
    var completion: MealCompletionType
    var completedAt: Date?
    
    init(id: UUID, date: Date, mealType: String, completion: MealCompletionType = .none, completedAt: Date? = nil) {
        self.id = id
        self.date = date
        self.mealType = mealType
        self.completion = completion
        self.completedAt = completedAt
    }
}

// MARK: - Day Streak State
struct DayStreakState: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let isComplete: Bool
    
    init(date: Date, isComplete: Bool) {
        self.date = date
        self.isComplete = isComplete
    }
}

// MARK: - Streak Summary
struct StreakSummary: Codable {
    let currentStreak: Int
    let longestStreak: Int
    let totalCompletedDays: Int
    let lastCompletedDate: Date?
    
    init(currentStreak: Int = 0, longestStreak: Int = 0, totalCompletedDays: Int = 0, lastCompletedDate: Date? = nil) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalCompletedDays = totalCompletedDays
        self.lastCompletedDate = lastCompletedDate
    }
}
