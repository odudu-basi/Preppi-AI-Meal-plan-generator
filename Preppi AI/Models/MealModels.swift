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

// MARK: - Meal Analysis Result
struct MealAnalysisResult {
    let mealName: String
    let description: String
    let macros: Macros
    let calories: Int
    let healthScore: Int
}

// MARK: - Logged Meal (for scanned meals)
struct LoggedMeal: Identifiable, Codable {
    let id: UUID
    let userId: UUID?
    let mealName: String
    let description: String
    let macros: Macros
    let calories: Int
    let healthScore: Int
    let imageUrl: String?
    let mealType: String? // "breakfast", "lunch", "dinner", or nil for extra meals
    let loggedAt: Date
    let createdAt: Date
    let updatedAt: Date
    let isFromMealPlan: Bool? // Track if logged from meal plan (manual) vs photo

    // Local-only properties for UI
    var imageData: Data? // Temporary storage before upload
    
    init(from analysisResult: MealAnalysisResult, image: UIImage?, mealType: String? = nil, userId: UUID? = nil) {
        self.id = UUID()
        self.userId = userId
        self.mealName = analysisResult.mealName
        self.description = analysisResult.description
        self.macros = analysisResult.macros
        self.calories = analysisResult.calories
        self.healthScore = analysisResult.healthScore
        self.imageUrl = nil // Will be set after upload
        self.mealType = mealType
        self.loggedAt = Date()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isFromMealPlan = false // Photo logging
        self.imageData = image?.jpegData(compressionQuality: 0.8)
    }

    // Initializer for logging meals from meal plan (manual)
    init(from dayMeal: DayMeal, mealType: String, userId: UUID? = nil) {
        self.id = UUID()
        self.userId = userId
        self.mealName = dayMeal.meal.name
        self.description = dayMeal.meal.description
        self.macros = Macros(
            protein: dayMeal.meal.macros?.protein ?? 0,
            carbohydrates: dayMeal.meal.macros?.carbohydrates ?? 0,
            fat: dayMeal.meal.macros?.fat ?? 0,
            fiber: dayMeal.meal.macros?.fiber ?? 0,
            sugar: dayMeal.meal.macros?.sugar ?? 0,
            sodium: dayMeal.meal.macros?.sodium ?? 0
        )
        self.calories = dayMeal.meal.calories
        self.healthScore = 75 // Default health score
        self.imageUrl = dayMeal.meal.imageUrl // Use meal plan image
        self.mealType = mealType
        self.loggedAt = Date()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isFromMealPlan = true // Manual logging from meal plan
        self.imageData = nil // No local image data for meal plan meals
    }

    // Database initializer
    init(id: UUID, userId: UUID?, mealName: String, description: String, macros: Macros, calories: Int, healthScore: Int, imageUrl: String?, mealType: String?, loggedAt: Date, createdAt: Date, updatedAt: Date, isFromMealPlan: Bool? = nil) {
        self.id = id
        self.userId = userId
        self.mealName = mealName
        self.description = description
        self.macros = macros
        self.calories = calories
        self.healthScore = healthScore
        self.imageUrl = imageUrl
        self.mealType = mealType
        self.loggedAt = loggedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isFromMealPlan = isFromMealPlan
        self.imageData = nil
    }
    
    var image: UIImage? {
        guard let imageData = imageData else { return nil }
        return UIImage(data: imageData)
    }
}

// MARK: - Database LoggedMeal Response
struct DatabaseLoggedMeal: Codable {
    let id: UUID
    let userId: UUID
    let mealName: String
    let description: String?
    let calories: Int
    let protein: Double?
    let carbohydrates: Double?
    let fat: Double?
    let fiber: Double?
    let sugar: Double?
    let sodium: Double?
    let healthScore: Int?
    let imageUrl: String?
    let mealType: String?
    let isFromMealPlan: Bool?
    let loggedAt: String // ISO8601 string from database
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, calories
        case userId = "user_id"
        case mealName = "meal_name"
        case description, protein, carbohydrates, fat, fiber, sugar, sodium
        case healthScore = "health_score"
        case imageUrl = "image_url"
        case mealType = "meal_type"
        case isFromMealPlan = "is_from_meal_plan"
        case loggedAt = "logged_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    func toLoggedMeal() -> LoggedMeal {
        let dateFormatter = ISO8601DateFormatter()

        return LoggedMeal(
            id: id,
            userId: userId,
            mealName: mealName,
            description: description ?? "",
            macros: Macros(
                protein: protein ?? 0,
                carbohydrates: carbohydrates ?? 0,
                fat: fat ?? 0,
                fiber: fiber ?? 0,
                sugar: sugar ?? 0,
                sodium: sodium ?? 0
            ),
            calories: calories,
            healthScore: healthScore ?? 5,
            imageUrl: imageUrl,
            mealType: mealType,
            loggedAt: dateFormatter.date(from: loggedAt) ?? Date(),
            createdAt: dateFormatter.date(from: createdAt) ?? Date(),
            updatedAt: dateFormatter.date(from: updatedAt) ?? Date(),
            isFromMealPlan: isFromMealPlan
        )
    }
}

// MARK: - Meal Insert Data (for database inserts)
struct MealInsertData: Codable {
    let userId: String
    let mealName: String
    let description: String
    let calories: Int
    let protein: Double
    let carbohydrates: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let healthScore: Int
    let imageUrl: String?
    let mealType: String?
    let isFromMealPlan: Bool?
    let loggedAt: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case mealName = "meal_name"
        case description, calories, protein, carbohydrates, fat, fiber, sugar, sodium
        case healthScore = "health_score"
        case imageUrl = "image_url"
        case mealType = "meal_type"
        case isFromMealPlan = "is_from_meal_plan"
        case loggedAt = "logged_at"
    }
}
