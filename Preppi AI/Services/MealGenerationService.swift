import Foundation
import UIKit

@MainActor
class MealGenerationService: ObservableObject {
    static let shared = MealGenerationService()

    private let openAIService = OpenAIService.shared
    @Published var isGenerating = false
    @Published var errorMessage: String?

    private init() {}

    // MARK: - Generate Meal from Description
    func generateMealFromDescription(description: String, dayOfWeek: String) async throws -> DayMeal {
        print("🍽️ Generating meal from description: \(description)")

        let prompt = """
        Based on the following meal description, create a detailed meal:

        Description: \(description)

        Provide the meal information in the following JSON format:
        {
            "name": "Meal name",
            "description": "Detailed description of the meal",
            "calories": 500,
            "cookTime": 25,
            "protein": 30.0,
            "carbohydrates": 45.0,
            "fat": 15.0,
            "fiber": 8.0,
            "sugar": 5.0,
            "sodium": 400.0,
            "ingredients": ["ingredient 1", "ingredient 2", "ingredient 3"],
            "instructions": ["step 1", "step 2", "step 3"]
        }

        Ensure the meal is balanced, nutritious, and matches the user's description.
        """

        // Get AI response for meal details
        let response = try await openAIService.analyzeMealText(prompt)
        print("🤖 AI Response: \(response)")

        // Parse JSON response
        guard let data = response.data(using: .utf8) else {
            throw NSError(domain: "MealGenerationService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert response to data"])
        }

        let mealData = try JSONDecoder().decode(GeneratedMealData.self, from: data)

        // Create temporary meal without image
        let tempMeal = Meal(
            id: UUID(),
            name: mealData.name,
            description: mealData.description,
            calories: mealData.calories,
            cookTime: mealData.cookTime,
            ingredients: mealData.ingredients,
            instructions: mealData.instructions,
            originalCookingDay: nil,
            imageUrl: nil,
            recommendedCaloriesBeforeDinner: 0,
            macros: Macros(
                protein: mealData.protein,
                carbohydrates: mealData.carbohydrates,
                fat: mealData.fat,
                fiber: mealData.fiber,
                sugar: mealData.sugar,
                sodium: mealData.sodium
            ),
            detailedIngredients: nil,
            detailedInstructions: nil,
            cookingTips: nil,
            servingInfo: nil
        )

        print("🖼️ Generating image for meal...")
        let imageUrl = try await openAIService.generateMealImage(for: tempMeal)
        print("✅ Image generated: \(imageUrl)")

        // Create final meal with image
        let finalMeal = Meal(
            id: tempMeal.id,
            name: tempMeal.name,
            description: tempMeal.description,
            calories: tempMeal.calories,
            cookTime: tempMeal.cookTime,
            ingredients: tempMeal.ingredients,
            instructions: tempMeal.instructions,
            originalCookingDay: nil,
            imageUrl: imageUrl,
            recommendedCaloriesBeforeDinner: 0,
            macros: tempMeal.macros,
            detailedIngredients: nil,
            detailedInstructions: nil,
            cookingTips: nil,
            servingInfo: nil
        )

        return DayMeal(
            day: dayOfWeek,
            meal: finalMeal
        )
    }

    // MARK: - Generate Similar Meals
    func generateSimilarMeals(to originalMeal: DayMeal, count: Int = 5) async throws -> [DayMeal] {
        print("🍽️ Generating \(count) similar meals to: \(originalMeal.meal.name)")

        let prompt = """
        Generate \(count) meal alternatives similar to the following meal:

        Original Meal: \(originalMeal.meal.name)
        Description: \(originalMeal.meal.description)
        Calories: \(originalMeal.meal.calories)
        Protein: \(originalMeal.meal.macros?.protein ?? 0)g
        Carbs: \(originalMeal.meal.macros?.carbohydrates ?? 0)g
        Fat: \(originalMeal.meal.macros?.fat ?? 0)g

        Requirements:
        - Similar calorie count (within 50 calories)
        - Similar macronutrient profile
        - Similar ingredients or cuisine style
        - Different names and variations

        Provide the meals in the following JSON array format:
        [
            {
                "name": "Meal name",
                "description": "Detailed description",
                "calories": 500,
                "cookTime": 25,
                "protein": 30.0,
                "carbohydrates": 45.0,
                "fat": 15.0,
                "fiber": 8.0,
                "sugar": 5.0,
                "sodium": 400.0,
                "ingredients": ["ingredient 1", "ingredient 2"],
                "instructions": ["step 1", "step 2"]
            }
        ]
        """

        // Get AI response
        let response = try await openAIService.analyzeMealText(prompt)
        print("🤖 AI Response: \(response)")

        // Parse JSON response
        guard let data = response.data(using: .utf8) else {
            throw NSError(domain: "MealGenerationService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert response to data"])
        }

        let mealsData = try JSONDecoder().decode([GeneratedMealData].self, from: data)

        // Generate images for all meals
        var generatedMeals: [DayMeal] = []

        for mealData in mealsData {
            let tempMeal = Meal(
                id: UUID(),
                name: mealData.name,
                description: mealData.description,
                calories: mealData.calories,
                cookTime: mealData.cookTime,
                ingredients: mealData.ingredients,
                instructions: mealData.instructions,
                originalCookingDay: nil,
                imageUrl: nil,
                recommendedCaloriesBeforeDinner: 0,
                macros: Macros(
                    protein: mealData.protein,
                    carbohydrates: mealData.carbohydrates,
                    fat: mealData.fat,
                    fiber: mealData.fiber,
                    sugar: mealData.sugar,
                    sodium: mealData.sodium
                ),
                detailedIngredients: nil,
                detailedInstructions: nil,
                cookingTips: nil,
                servingInfo: nil
            )

            print("🖼️ Generating image for: \(tempMeal.name)")
            let imageUrl = try await openAIService.generateMealImage(for: tempMeal)

            let finalMeal = Meal(
                id: tempMeal.id,
                name: tempMeal.name,
                description: tempMeal.description,
                calories: tempMeal.calories,
                cookTime: tempMeal.cookTime,
                ingredients: tempMeal.ingredients,
                instructions: tempMeal.instructions,
                originalCookingDay: nil,
                imageUrl: imageUrl,
                recommendedCaloriesBeforeDinner: 0,
                macros: tempMeal.macros,
                detailedIngredients: nil,
                detailedInstructions: nil,
                cookingTips: nil,
                servingInfo: nil
            )

            generatedMeals.append(DayMeal(
                day: originalMeal.day,
                meal: finalMeal
            ))
        }

        print("✅ Generated \(generatedMeals.count) similar meals")
        return generatedMeals
    }
}

// MARK: - Generated Meal Data Model
private struct GeneratedMealData: Codable {
    let name: String
    let description: String
    let calories: Int
    let cookTime: Int
    let protein: Double
    let carbohydrates: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let ingredients: [String]
    let instructions: [String]
}
