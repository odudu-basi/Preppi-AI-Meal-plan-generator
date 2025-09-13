import Foundation
import SwiftUI

// MARK: - Cookbook Model
struct Cookbook: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: String  // To associate with specific user
    var name: String
    var description: String?
    var createdAt: Date
    var updatedAt: Date
    var recipeCount: Int // Computed from saved recipes
    
    init(userId: String, name: String, description: String? = nil) {
        self.id = UUID()
        self.userId = userId
        self.name = name
        self.description = description
        self.createdAt = Date()
        self.updatedAt = Date()
        self.recipeCount = 0
    }
}

// MARK: - Saved Recipe Model
struct SavedRecipe: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    let cookbookId: UUID
    let userId: String
    var recipeName: String
    var recipeDescription: String
    var ingredients: [RecipeIngredient]
    var instructions: [String]
    var nutrition: NutritionInfo
    var difficultyRating: Int
    var prepTime: String
    var cookTime: String
    var totalTime: String
    var servings: Int
    var shoppingList: [String]
    var imageUrl: String? // URL to stored image
    var notes: String? // User's personal notes
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(from recipeAnalysis: RecipeAnalysis, cookbookId: UUID, userId: String, servings: Int, imageUrl: String? = nil) {
        self.id = UUID()
        self.cookbookId = cookbookId
        self.userId = userId
        self.recipeName = recipeAnalysis.foodIdentification
        self.recipeDescription = recipeAnalysis.description
        self.ingredients = recipeAnalysis.recipe.ingredients
        self.instructions = recipeAnalysis.recipe.instructions
        self.nutrition = recipeAnalysis.nutrition
        self.difficultyRating = recipeAnalysis.difficultyRating
        self.prepTime = recipeAnalysis.recipe.prepTime
        self.cookTime = recipeAnalysis.recipe.cookTime
        self.totalTime = recipeAnalysis.recipe.totalTime
        self.servings = servings
        self.shoppingList = recipeAnalysis.shoppingList
        self.imageUrl = imageUrl
        self.notes = nil
        self.isFavorite = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Hashable & Equatable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SavedRecipe, rhs: SavedRecipe) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Cookbook Summary (for list views)
struct CookbookSummary: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String?
    let recipeCount: Int
    let createdAt: Date
    let lastRecipeAdded: Date?
    
    init(from cookbook: Cookbook, recipeCount: Int, lastRecipeAdded: Date?) {
        self.id = cookbook.id
        self.name = cookbook.name
        self.description = cookbook.description
        self.recipeCount = recipeCount
        self.createdAt = cookbook.createdAt
        self.lastRecipeAdded = lastRecipeAdded
    }
}

// MARK: - Database Operations Results
enum CookbookError: Error, LocalizedError {
    case userNotAuthenticated
    case cookbookNotFound
    case recipeNotFound
    case databaseError(String)
    case duplicateName
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        case .cookbookNotFound:
            return "Cookbook not found"
        case .recipeNotFound:
            return "Recipe not found"
        case .databaseError(let message):
            return "Database error: \(message)"
        case .duplicateName:
            return "A cookbook with this name already exists"
        case .invalidData:
            return "Invalid data provided"
        }
    }
}

// MARK: - Extensions for UI
extension Cookbook {
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: createdAt)
    }
    
    var isEmpty: Bool {
        return recipeCount == 0
    }
}

extension SavedRecipe {
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: createdAt)
    }
    
    var totalTimeInMinutes: Int? {
        // Extract minutes from time strings like "15 min" or "1 hour 30 min"
        let prepMinutes = extractMinutes(from: prepTime)
        let cookMinutes = extractMinutes(from: cookTime)
        return prepMinutes + cookMinutes
    }
    
    private func extractMinutes(from timeString: String) -> Int {
        let components = timeString.lowercased().components(separatedBy: " ")
        var minutes = 0
        
        for i in 0..<components.count {
            if let value = Int(components[i]) {
                let unit = i + 1 < components.count ? components[i + 1] : ""
                if unit.contains("hour") {
                    minutes += value * 60
                } else if unit.contains("min") {
                    minutes += value
                }
            }
        }
        
        return minutes
    }
}

// MARK: - Sample Data (for previews and testing)
extension Cookbook {
    static let sampleCookbooks = [
        Cookbook(userId: "user123", name: "Weeknight Dinners", description: "Quick and easy meals for busy evenings"),
        Cookbook(userId: "user123", name: "Healthy Options", description: "Nutritious recipes for a balanced diet"),
        Cookbook(userId: "user123", name: "Special Occasions", description: "Impressive dishes for entertaining")
    ]
}

extension SavedRecipe {
    static let sampleRecipe = SavedRecipe(
        from: RecipeAnalysis(
            foodIdentification: "Chicken Stir Fry",
            description: "A delicious and healthy stir fry with fresh vegetables",
            recipe: RecipeDetails(
                ingredients: [
                    RecipeIngredient(item: "chicken breast", amount: "200", unit: "g"),
                    RecipeIngredient(item: "bell peppers", amount: "1", unit: "cup")
                ],
                instructions: ["Heat oil in pan", "Add chicken and cook", "Add vegetables and stir fry"],
                prepTime: "15 min",
                cookTime: "10 min",
                totalTime: "25 min"
            ),
            nutrition: NutritionInfo(calories: 350, protein: 30.0, carbs: 15.0, fat: 12.0, fiber: 3.0, sugar: 8.0),
            shoppingList: ["chicken breast", "bell peppers", "soy sauce"],
            difficultyRating: 4
        ),
        cookbookId: UUID(),
        userId: "user123",
        servings: 2
    )
}
