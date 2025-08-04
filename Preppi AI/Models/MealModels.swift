import Foundation

// MARK: - Meal Data Models
struct Meal: Identifiable, Codable {
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
    
    // Detailed recipe fields
    let detailedIngredients: [String]? // Detailed ingredients with measurements
    let detailedInstructions: [String]? // Detailed cooking instructions
    let cookingTips: [String]? // Professional cooking tips
    let servingInfo: String? // Serving information and presentation
}

struct DayMeal: Identifiable, Codable {
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
    static let weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
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
