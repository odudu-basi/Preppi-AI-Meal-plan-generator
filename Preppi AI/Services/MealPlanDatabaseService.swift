import Foundation
import Supabase

// MARK: - Database Models
struct DatabaseMealPlan: Codable {
    let id: UUID?
    let userId: UUID
    let name: String
    let weekStartDate: String // ISO date string
    let mealPreparationStyle: String
    let selectedCuisines: [String]
    let mealCount: Int
    let isActive: Bool
    let isCompleted: Bool
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case weekStartDate = "week_start_date"
        case mealPreparationStyle = "meal_preparation_style"
        case selectedCuisines = "selected_cuisines"
        case mealCount = "meal_count"
        case isActive = "is_active"
        case isCompleted = "is_completed"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct DatabaseMeal: Codable {
    let id: UUID?
    let name: String
    let description: String
    let calories: Int
    let cookTime: Int
    let originalCookingDay: String?
    let imageUrl: String?
    let recommendedCaloriesBeforeDinner: Int
    let detailedIngredients: [String]?
    let detailedInstructions: [String]?
    let cookingTips: [String]?
    let servingInfo: String?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case calories
        case cookTime = "cook_time"
        case originalCookingDay = "original_cooking_day"
        case imageUrl = "image_url"
        case recommendedCaloriesBeforeDinner = "recommended_calories_before_dinner"
        case detailedIngredients = "detailed_ingredients"
        case detailedInstructions = "detailed_instructions"
        case cookingTips = "cooking_tips"
        case servingInfo = "serving_info"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct DatabaseDayMeal: Codable {
    let id: UUID?
    let mealPlanId: UUID
    let mealId: UUID
    let dayName: String
    let dayOrder: Int
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case mealPlanId = "meal_plan_id"
        case mealId = "meal_id"
        case dayName = "day_name"
        case dayOrder = "day_order"
        case createdAt = "created_at"
    }
}

struct DatabaseMealIngredient: Codable {
    let id: UUID?
    let mealId: UUID
    let ingredient: String
    let ingredientOrder: Int
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case mealId = "meal_id"
        case ingredient
        case ingredientOrder = "ingredient_order"
        case createdAt = "created_at"
    }
}

struct DatabaseMealInstruction: Codable {
    let id: UUID?
    let mealId: UUID
    let instruction: String
    let stepOrder: Int
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case mealId = "meal_id"
        case instruction
        case stepOrder = "step_order"
        case createdAt = "created_at"
    }
}

// MARK: - Meal Plan Database Service
class MealPlanDatabaseService {
    static let shared = MealPlanDatabaseService()
    
    private let supabase = SupabaseService.shared
    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Save a complete meal plan to the database
    func saveMealPlan(
        dayMeals: [DayMeal],
        selectedCuisines: [String],
        mealPreparationStyle: MealPlanInfoView.MealPreparationStyle,
        mealCount: Int
    ) async throws -> UUID {
        
        let session = try await supabase.auth.session
        let userId = session.user.id
        
        let weekStartDate = getWeekStartDate()
        
        // Create the main meal plan record
        let mealPlan = DatabaseMealPlan(
            id: nil,
            userId: userId,
            name: "Weekly Meal Plan",
            weekStartDate: dateFormatter.string(from: weekStartDate),
            mealPreparationStyle: mealPreparationStyle.rawValue,
            selectedCuisines: selectedCuisines,
            mealCount: mealCount,
            isActive: true,
            isCompleted: false,
            createdAt: nil,
            updatedAt: nil
        )
        
        // Insert meal plan and get the ID
        do {
            print("🔄 Inserting meal plan: \(mealPlan)")
            
            let response = try await supabase.database
                .from("meal_plans")
                .insert(mealPlan)
                .select()
                .execute()
            
            print("📥 Raw response data: \(String(data: response.data, encoding: .utf8) ?? "Unable to decode data")")
            
            // Handle response - could be array or single object
            let decodedResponse = try JSONDecoder().decode([DatabaseMealPlan].self, from: response.data)
            
            guard let insertedMealPlan = decodedResponse.first else {
                throw MealPlanDatabaseError.failedToCreateMealPlan
            }
            
            print("✅ Successfully parsed meal plan: \(insertedMealPlan)")
            
            guard let mealPlanId = insertedMealPlan.id else {
                throw MealPlanDatabaseError.failedToCreateMealPlan
            }
            
            // Save all meals and create day_meals relationships
            try await saveMealsForMealPlan(dayMeals: dayMeals, mealPlanId: mealPlanId)
            
            return mealPlanId
            
        } catch {
            print("❌ Error in saveMealPlan: \(error)")
            if let decodingError = error as? DecodingError {
                print("🔍 Decoding error details: \(decodingError)")
            }
            throw error
        }
    }
    
    /// Retrieve user's meal plans
    func getUserMealPlans() async throws -> [DatabaseMealPlan] {
        let response: [DatabaseMealPlan] = try await supabase.database
            .from("meal_plans")
            .select()
            .eq("is_active", value: true)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// Get a specific meal plan with all related data
    func getMealPlanDetails(mealPlanId: UUID) async throws -> MealPlan? {
        // This would use the complete_meal_plans view to get all related data
        // For now, we'll implement a basic version
        let mealPlan: DatabaseMealPlan = try await supabase.database
            .from("meal_plans")
            .select()
            .eq("id", value: mealPlanId.uuidString)
            .single()
            .execute()
            .value
        
        // Get day meals for this meal plan
        let dayMeals = try await getDayMealsForMealPlan(mealPlanId: mealPlanId)
        
        return MealPlan(dayMeals: dayMeals)
    }
    
    /// Mark a meal plan as completed
    func completeMealPlan(mealPlanId: UUID) async throws {
        let update = ["is_completed": true]
        
        let _: DatabaseMealPlan = try await supabase.database
            .from("meal_plans")
            .update(update)
            .eq("id", value: mealPlanId.uuidString)
            .single()
            .execute()
            .value
    }
    
    /// Delete a meal plan (sets is_active to false)
    func deleteMealPlan(mealPlanId: UUID) async throws {
        let update = ["is_active": false]
        
        let _: DatabaseMealPlan = try await supabase.database
            .from("meal_plans")
            .update(update)
            .eq("id", value: mealPlanId.uuidString)
            .single()
            .execute()
            .value
    }
    
    /// Update a meal's image URL
    func updateMealImage(mealId: UUID, imageUrl: String) async throws {
        let update = ["image_url": imageUrl]
        
        let _: DatabaseMeal = try await supabase.database
            .from("meals")
            .update(update)
            .eq("id", value: mealId.uuidString)
            .single()
            .execute()
            .value
        
        print("✅ Successfully updated meal image URL for meal ID: \(mealId)")
    }
    
    /// Debug: Check what recipe data actually exists for a specific meal ID
    func debugMealRecipeData(mealId: UUID) async {
        do {
            print("🔍 DEBUG: Checking database for meal ID: \(mealId)")
            
            let response = try await supabase.database
                .from("meals")
                .select("id, name, detailed_ingredients, detailed_instructions, cooking_tips, serving_info")
                .eq("id", value: mealId.uuidString)
                .execute()
            
            if let jsonObj = try? JSONSerialization.jsonObject(with: response.data) as? [[String: Any]],
               let meal = jsonObj.first {
                
                print("🔍 Database contains:")
                print("   - Name: \(meal["name"] as? String ?? "unknown")")
                print("   - detailed_ingredients: \((meal["detailed_ingredients"] as? [Any])?.count ?? 0) items")
                print("   - detailed_instructions: \((meal["detailed_instructions"] as? [Any])?.count ?? 0) items")
                print("   - cooking_tips: \((meal["cooking_tips"] as? [Any])?.count ?? 0) items")
                print("   - serving_info: \(meal["serving_info"] != nil ? "exists" : "null")")
                
                if let ingredients = meal["detailed_ingredients"] as? [String], !ingredients.isEmpty {
                    print("   - First ingredient: \(ingredients.first ?? "none")")
                }
                if let instructions = meal["detailed_instructions"] as? [String], !instructions.isEmpty {
                    print("   - First instruction: \(instructions.first ?? "none")")
                }
            } else {
                print("❌ No meal found with ID: \(mealId)")
            }
        } catch {
            print("❌ Debug query failed: \(error)")
        }
    }
    
    /// Check if the recipe columns exist in the database
    func checkRecipeColumnsExist() async throws -> Bool {
        do {
            // Simple query to test if the recipe columns exist without decoding to DatabaseMeal
            let response = try await supabase.database
                .from("meals")
                .select("detailed_ingredients, detailed_instructions, cooking_tips, serving_info")
                .limit(1)
                .execute()
            
            print("✅ Recipe columns exist in database")
            return true
        } catch {
            print("❌ Recipe columns missing or migration not applied: \(error)")
            return false
        }
    }
    
    /// Update a meal's detailed recipe
    func updateMealDetailedRecipe(mealId: UUID, detailedRecipe: DetailedRecipe) async throws {
        print("🔄 Updating detailed recipe for meal ID: \(mealId)")
        print("   - Ingredients: \(detailedRecipe.detailedIngredients.count) items")
        print("   - Instructions: \(detailedRecipe.instructions.count) items")
        print("   - Tips: \(detailedRecipe.cookingTips.count) items")
        print("   - Serving info: \(detailedRecipe.servingInfo.isEmpty ? "empty" : "provided")")
        
        // Create a partial DatabaseMeal for update with only the recipe fields
        struct MealRecipeUpdate: Codable {
            let detailedIngredients: [String]
            let detailedInstructions: [String]
            let cookingTips: [String]
            let servingInfo: String
            
            enum CodingKeys: String, CodingKey {
                case detailedIngredients = "detailed_ingredients"
                case detailedInstructions = "detailed_instructions"
                case cookingTips = "cooking_tips"
                case servingInfo = "serving_info"
            }
        }
        
        let update = MealRecipeUpdate(
            detailedIngredients: detailedRecipe.detailedIngredients,
            detailedInstructions: detailedRecipe.instructions,
            cookingTips: detailedRecipe.cookingTips,
            servingInfo: detailedRecipe.servingInfo
        )
        
        // Execute the update
        do {
            try await supabase.database
                .from("meals")
                .update(update)
                .eq("id", value: mealId.uuidString)
                .execute()
            
            print("✅ Successfully updated meal detailed recipe for meal ID: \(mealId)")
            
        } catch {
            print("❌ Database update failed: \(error)")
            print("   - Error description: \(error.localizedDescription)")
            
            // Try to extract more details from the error
            if let errorData = (error as NSError).userInfo["data"] as? Data,
               let errorString = String(data: errorData, encoding: .utf8) {
                print("   - Raw error data: \(errorString)")
            }
            
            throw error
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func saveMealsForMealPlan(dayMeals: [DayMeal], mealPlanId: UUID) async throws {
        for (index, dayMeal) in dayMeals.enumerated() {
            // Save the meal
            let databaseMeal = DatabaseMeal(
                id: nil,
                name: dayMeal.meal.name,
                description: dayMeal.meal.description,
                calories: dayMeal.meal.calories,
                cookTime: dayMeal.meal.cookTime,
                originalCookingDay: dayMeal.meal.originalCookingDay,
                imageUrl: dayMeal.meal.imageUrl,
                recommendedCaloriesBeforeDinner: dayMeal.meal.recommendedCaloriesBeforeDinner,
                detailedIngredients: dayMeal.meal.detailedIngredients,
                detailedInstructions: dayMeal.meal.detailedInstructions,
                cookingTips: dayMeal.meal.cookingTips,
                servingInfo: dayMeal.meal.servingInfo,
                createdAt: nil,
                updatedAt: nil
            )
            
            print("🔄 Inserting meal: \(databaseMeal)")
            
            let mealResponse = try await supabase.database
                .from("meals")
                .insert(databaseMeal)
                .select()
                .execute()
            
            print("📥 Meal response data: \(String(data: mealResponse.data, encoding: .utf8) ?? "Unable to decode data")")
            
            // Handle response - decode as array
            let decodedMeals = try JSONDecoder().decode([DatabaseMeal].self, from: mealResponse.data)
            
            guard let insertedMeal = decodedMeals.first else {
                throw MealPlanDatabaseError.failedToCreateMeal
            }
            
            print("✅ Successfully parsed meal: \(insertedMeal)")
            
            guard let mealId = insertedMeal.id else {
                throw MealPlanDatabaseError.failedToCreateMeal
            }
            
            // Create day_meal relationship
            let dayMealRecord = DatabaseDayMeal(
                id: nil,
                mealPlanId: mealPlanId,
                mealId: mealId,
                dayName: dayMeal.day,
                dayOrder: index + 1,
                createdAt: nil
            )
            
            print("🔄 Inserting day_meal: \(dayMealRecord)")
            
            let dayMealResponse = try await supabase.database
                .from("day_meals")
                .insert(dayMealRecord)
                .select()
                .execute()
            
            print("📥 Day meal response data: \(String(data: dayMealResponse.data, encoding: .utf8) ?? "Unable to decode data")")
            
            // Handle response - decode as array
            let decodedDayMeals = try JSONDecoder().decode([DatabaseDayMeal].self, from: dayMealResponse.data)
            
            guard decodedDayMeals.first != nil else {
                throw MealPlanDatabaseError.failedToCreateMeal
            }
            
            print("✅ Successfully inserted day_meal")
            
            // Save ingredients
            try await saveMealIngredients(mealId: mealId, ingredients: dayMeal.meal.ingredients)
            
            // Save instructions
            try await saveMealInstructions(mealId: mealId, instructions: dayMeal.meal.instructions)
        }
    }
    
    private func saveMealIngredients(mealId: UUID, ingredients: [String]) async throws {
        let ingredientRecords = ingredients.enumerated().map { index, ingredient in
            DatabaseMealIngredient(
                id: nil,
                mealId: mealId,
                ingredient: ingredient,
                ingredientOrder: index + 1,
                createdAt: nil
            )
        }
        
        if !ingredientRecords.isEmpty {
            print("🔄 Inserting \(ingredientRecords.count) ingredients")
            
            try await supabase.database
                .from("meal_ingredients")
                .insert(ingredientRecords)
                .execute()
            
            print("✅ Successfully inserted ingredients")
        } else {
            print("⏭️ No ingredients to insert")
        }
    }
    
    private func saveMealInstructions(mealId: UUID, instructions: [String]) async throws {
        let instructionRecords = instructions.enumerated().map { index, instruction in
            DatabaseMealInstruction(
                id: nil,
                mealId: mealId,
                instruction: instruction,
                stepOrder: index + 1,
                createdAt: nil
            )
        }
        
        if !instructionRecords.isEmpty {
            print("🔄 Inserting \(instructionRecords.count) instructions")
            
            try await supabase.database
                .from("meal_instructions")
                .insert(instructionRecords)
                .execute()
            
            print("✅ Successfully inserted instructions")
        } else {
            print("⏭️ No instructions to insert")
        }
    }
    
    private func getDayMealsForMealPlan(mealPlanId: UUID) async throws -> [DayMeal] {
        // This is a simplified version - in a full implementation, you'd use the view
        // to get all the data in one query with proper joins
        
        let dayMealRecords: [DatabaseDayMeal] = try await supabase.database
            .from("day_meals")
            .select()
            .eq("meal_plan_id", value: mealPlanId.uuidString)
            .order("day_order", ascending: true)
            .execute()
            .value
        
        var dayMeals: [DayMeal] = []
        
        for dayMealRecord in dayMealRecords {
            // Get the meal details
            do {
                let meal: DatabaseMeal = try await supabase.database
                    .from("meals")
                    .select()
                    .eq("id", value: dayMealRecord.mealId.uuidString)
                    .single()
                    .execute()
                    .value
                
                // Get ingredients
                let ingredients: [DatabaseMealIngredient] = try await supabase.database
                    .from("meal_ingredients")
                    .select()
                    .eq("meal_id", value: dayMealRecord.mealId.uuidString)
                    .order("ingredient_order", ascending: true)
                    .execute()
                    .value
                
                // Get instructions
                let instructions: [DatabaseMealInstruction] = try await supabase.database
                    .from("meal_instructions")
                    .select()
                    .eq("meal_id", value: dayMealRecord.mealId.uuidString)
                    .order("step_order", ascending: true)
                    .execute()
                    .value
                
                // CRITICAL: Use the database meal ID, not generate a new UUID
                let actualMealId = meal.id ?? dayMealRecord.mealId
                
                // Convert to app models
                let appMeal = Meal(
                    id: actualMealId,  // Use actual database ID
                    name: meal.name,
                    description: meal.description,
                    calories: meal.calories,
                    cookTime: meal.cookTime,
                    ingredients: ingredients.map { $0.ingredient },
                    instructions: instructions.map { $0.instruction },
                    originalCookingDay: meal.originalCookingDay,
                    imageUrl: meal.imageUrl,
                    recommendedCaloriesBeforeDinner: meal.recommendedCaloriesBeforeDinner,
                    detailedIngredients: meal.detailedIngredients,
                    detailedInstructions: meal.detailedInstructions,
                    cookingTips: meal.cookingTips,
                    servingInfo: meal.servingInfo
                )
                
                let dayMeal = DayMeal(day: dayMealRecord.dayName, meal: appMeal)
                dayMeals.append(dayMeal)
                
            } catch {
                print("❌ Failed to load meal with ID \(dayMealRecord.mealId): \(error)")
                // Continue with next meal instead of failing completely
            }
        }
        return dayMeals
    }
    
    private func getWeekStartDate() -> Date {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7 // Convert Sunday=1 to Monday=0 system
        return calendar.date(byAdding: .day, value: -daysFromMonday, to: today) ?? today
    }
}

// MARK: - Error Types
enum MealPlanDatabaseError: LocalizedError {
    case userNotAuthenticated
    case failedToCreateMealPlan
    case failedToCreateMeal
    case networkError(Error)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User is not authenticated"
        case .failedToCreateMealPlan:
            return "Failed to create meal plan"
        case .failedToCreateMeal:
            return "Failed to create meal"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidData:
            return "Invalid data received from server"
        }
    }
}