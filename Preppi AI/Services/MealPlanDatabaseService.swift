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
    let selectedMealTypes: [String] // New field for breakfast, lunch, dinner
    let mealPlanType: String // Identifier: "breakfast", "lunch", or "dinner"
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
        case selectedMealTypes = "selected_meal_types"
        case mealPlanType = "meal_plan_type"
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
    let protein: Double?
    let carbohydrates: Double?
    let fat: Double?
    let fiber: Double?
    let sugar: Double?
    let sodium: Double?
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
        case protein
        case carbohydrates
        case fat
        case fiber
        case sugar
        case sodium
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
    let mealType: String // New field for breakfast, lunch, dinner
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case mealPlanId = "meal_plan_id"
        case mealId = "meal_id"
        case dayName = "day_name"
        case dayOrder = "day_order"
        case mealType = "meal_type"
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
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current // Use local timezone for storing week dates
        return formatter
    }()
    
    private init() {}
    
    // MARK: - Public Methods
    

    /// Save a complete meal plan to the database
    func saveMealPlan(
        dayMeals: [DayMeal],
        selectedCuisines: [String],
        mealType: String = "dinner",
        mealPreparationStyle: MealPlanInfoView.MealPreparationStyle,
        mealCount: Int
    ) async throws -> UUID {
        
        let session = try await supabase.auth.session
        let userId = session.user.id
        
        let weekStartDate = getWeekStartDate()
        
        // Debug logging for week calculation
        print("🗓️ DEBUG: Creating meal plan for week starting: \(weekStartDate)")
        print("🗓️ DEBUG: Formatted week start date: \(dateFormatter.string(from: weekStartDate))")
        print("🗓️ DEBUG: Current date: \(Date())")
        
        // Create the main meal plan record
        let mealPlan = DatabaseMealPlan(
            id: nil,
            userId: userId,
            name: "Weekly Meal Plan",
            weekStartDate: dateFormatter.string(from: weekStartDate),
            mealPreparationStyle: mealPreparationStyle.rawValue,
            selectedCuisines: selectedCuisines,
            selectedMealTypes: [mealType], // Use the provided meal type
            mealPlanType: mealType, // Set the identifier for this meal plan type
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
            try await saveMealsForMealPlan(dayMeals: dayMeals, mealPlanId: mealPlanId, mealType: mealType)
            
            // Track meal plan saved in Mixpanel
            MixpanelService.shared.track(
                event: MixpanelService.Events.mealPlanSaved,
                properties: [
                    MixpanelService.Properties.mealCount: mealCount,
                    MixpanelService.Properties.cuisineTypes: selectedCuisines.joined(separator: ", "),
                    MixpanelService.Properties.preparationStyle: mealPreparationStyle.rawValue,
                    "total_meals": dayMeals.count,
                    "meal_plan_id": mealPlanId.uuidString
                ]
            )
            
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
        // Get the current user's session to ensure we're authenticated
        let session = try await supabase.auth.session
        let userId = session.user.id
        
        print("🔍 Getting meal plans for user: \(userId)")
        
        let response: [DatabaseMealPlan] = try await supabase.database
            .from("meal_plans")
            .select()
            .eq("user_id", value: userId)  // Explicit user filtering - keep as UUID
            .eq("is_active", value: true)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        print("📦 Found \(response.count) meal plans for user")
        
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
    
    /// Delete a meal plan (sets is_active to false) and cleans up associated images and shopping list items
    func deleteMealPlan(mealPlanId: UUID) async throws {
        print("🗑️ Starting meal plan deletion with full cleanup for: \(mealPlanId)")
        
        // Step 1: Get all meals in this meal plan to delete their images
        do {
            let dayMeals = try await getDayMealsForMealPlan(mealPlanId: mealPlanId)
            
            print("🔄 Found \(dayMeals.count) meals to clean up images for")
            
            // Step 2: Delete images from storage for each meal that has one
            for dayMeal in dayMeals {
                if let imageUrl = dayMeal.meal.imageUrl, 
                   !imageUrl.isEmpty,
                   !imageUrl.contains("oaidalleapiprodscus") { // Only delete permanent storage images, not temp DALL-E URLs
                    
                    do {
                        try await ImageStorageService.shared.deleteImage(for: dayMeal.meal.id)
                        print("✅ Deleted image for meal: \(dayMeal.meal.name)")
                    } catch {
                        print("⚠️ Failed to delete image for meal \(dayMeal.meal.name): \(error)")
                        // Continue with deletion even if image cleanup fails
                    }
                }
            }
            
            print("✅ Image cleanup completed")
            
        } catch {
            print("⚠️ Failed to get meals for image cleanup: \(error)")
            // Continue with meal plan deletion even if image cleanup fails
        }
        
        // Step 2: Delete associated shopping list items
        do {
            try await deleteShoppingListItemsForMealPlan(mealPlanId: mealPlanId)
            print("✅ Shopping list items deleted for meal plan: \(mealPlanId)")
        } catch {
            print("⚠️ Failed to delete shopping list items: \(error)")
            // Continue with meal plan deletion even if shopping list cleanup fails
        }
        
        // Step 3: Soft delete the meal plan
        let update = ["is_active": false]
        
        try await supabase.database
            .from("meal_plans")
            .update(update)
            .eq("id", value: mealPlanId.uuidString)
            .execute()
        
        print("✅ Meal plan soft deleted: \(mealPlanId)")
    }
    
    /// Delete all shopping list items associated with a meal plan
    private func deleteShoppingListItemsForMealPlan(mealPlanId: UUID) async throws {
        guard let userId = try await getCurrentUserId() else {
            throw DatabaseError.userNotAuthenticated
        }
        
        try await supabase.database
            .from("shopping_list_items")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .eq("meal_plan_id", value: mealPlanId.uuidString)
            .execute()
        
        print("✅ Deleted shopping list items for meal plan: \(mealPlanId)")
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

    /// Replace a meal in a meal plan for a specific date and meal type
    func replaceMealInPlan(date: Date, mealType: String, newMeal: Meal) async throws {
        print("🔄 Replacing \(mealType) meal for date: \(dateFormatter.string(from: date))")

        guard let userId = try await getCurrentUserId() else {
            throw DatabaseError.userNotAuthenticated
        }

        // 1. Find the meal plan for this week and meal type
        let weekStart = getWeekStartDate(for: date)
        let weekStartString = dateFormatter.string(from: weekStart)

        let mealPlans: [DatabaseMealPlan] = try await supabase.database
            .from("meal_plans")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("week_start_date", value: weekStartString)
            .eq("meal_plan_type", value: mealType)
            .eq("is_active", value: true)
            .execute()
            .value

        guard let mealPlan = mealPlans.first, let mealPlanId = mealPlan.id else {
            print("❌ No meal plan found for week \(weekStartString) and type \(mealType)")
            throw MealPlanDatabaseError.mealPlanNotFound
        }

        print("✅ Found meal plan: \(mealPlanId)")

        // 2. Get the day name for this date
        let dayName = getDayName(for: date)
        print("📅 Day name: \(dayName)")

        // 3. Create the new meal in the database
        let databaseMeal = DatabaseMeal(
            id: newMeal.id,
            name: newMeal.name,
            description: newMeal.description,
            calories: newMeal.calories,
            cookTime: newMeal.cookTime,
            originalCookingDay: nil,
            imageUrl: newMeal.imageUrl,
            recommendedCaloriesBeforeDinner: 0,
            protein: newMeal.macros?.protein,
            carbohydrates: newMeal.macros?.carbohydrates,
            fat: newMeal.macros?.fat,
            fiber: newMeal.macros?.fiber,
            sugar: newMeal.macros?.sugar,
            sodium: newMeal.macros?.sodium,
            detailedIngredients: nil,
            detailedInstructions: nil,
            cookingTips: nil,
            servingInfo: nil,
            createdAt: nil,
            updatedAt: nil
        )

        let mealResponse = try await supabase.database
            .from("meals")
            .insert(databaseMeal)
            .select()
            .execute()

        let insertedMeals = try JSONDecoder().decode([DatabaseMeal].self, from: mealResponse.data)
        guard let insertedMeal = insertedMeals.first, let newMealId = insertedMeal.id else {
            throw MealPlanDatabaseError.failedToCreateMeal
        }

        print("✅ New meal created with ID: \(newMealId)")

        // 4. Update the day_meal entry to point to the new meal
        struct DayMealUpdate: Codable {
            let mealId: String

            enum CodingKeys: String, CodingKey {
                case mealId = "meal_id"
            }
        }

        let update = DayMealUpdate(mealId: newMealId.uuidString)

        try await supabase.database
            .from("day_meals")
            .update(update)
            .eq("meal_plan_id", value: mealPlanId.uuidString)
            .eq("day_name", value: dayName)
            .eq("meal_type", value: mealType)
            .execute()

        print("✅ Meal replaced successfully for \(dayName) \(mealType)")
    }

    // MARK: - Private Helper Methods
    
    private func saveMealsForMealPlan(dayMeals: [DayMeal], mealPlanId: UUID, mealType: String) async throws {
        for (index, dayMeal) in dayMeals.enumerated() {
            // Save the meal with preserved ID for image updates
            let databaseMeal = DatabaseMeal(
                id: dayMeal.meal.id,
                name: dayMeal.meal.name,
                description: dayMeal.meal.description,
                calories: dayMeal.meal.calories,
                cookTime: dayMeal.meal.cookTime,
                originalCookingDay: dayMeal.meal.originalCookingDay,
                imageUrl: dayMeal.meal.imageUrl,
                recommendedCaloriesBeforeDinner: dayMeal.meal.recommendedCaloriesBeforeDinner,
                protein: dayMeal.meal.macros?.protein,
                carbohydrates: dayMeal.meal.macros?.carbohydrates,
                fat: dayMeal.meal.macros?.fat,
                fiber: dayMeal.meal.macros?.fiber,
                sugar: dayMeal.meal.macros?.sugar,
                sodium: dayMeal.meal.macros?.sodium,
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
                mealType: mealType, // Use the provided meal type
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
    
    func getDayMealsForMealPlan(mealPlanId: UUID) async throws -> [DayMeal] {
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
                
                // Create macros if all values are present
                var macros: Macros? = nil
                if let protein = meal.protein,
                   let carbohydrates = meal.carbohydrates,
                   let fat = meal.fat,
                   let fiber = meal.fiber,
                   let sugar = meal.sugar,
                   let sodium = meal.sodium {
                    macros = Macros(
                        protein: protein,
                        carbohydrates: carbohydrates,
                        fat: fat,
                        fiber: fiber,
                        sugar: sugar,
                        sodium: sodium
                    )
                }
                
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
                    macros: macros,
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
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Ensure Sunday is the first day (consistent with ContentView)
        calendar.timeZone = TimeZone.current // Use local timezone instead of UTC

        let today = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today

        print("🌍 DEBUG: Using timezone: \(calendar.timeZone.identifier)")
        print("🌍 DEBUG: Local today: \(today)")
        print("🌍 DEBUG: Local week start: \(weekStart)")

        return weekStart
    }

    private func getWeekStartDate(for date: Date) -> Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Ensure Sunday is the first day
        calendar.timeZone = TimeZone.current

        let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        return weekStart
    }

    private func getDayName(for date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE" // Full day name
        return dateFormatter.string(from: date)
    }
    
    /// Get the current authenticated user's ID
    private func getCurrentUserId() async throws -> UUID? {
        do {
            let session = try await supabase.auth.session
            return UUID(uuidString: session.user.id.uuidString)
        } catch {
            print("❌ Error getting current user: \(error)")
            return nil
        }
    }
    
    /// Get all meal plans for the current user
    func getAllMealPlans() async throws -> [DatabaseMealPlan] {
        guard let userId = try await getCurrentUserId() else {
            throw MealPlanDatabaseError.userNotAuthenticated
        }
        
        let mealPlans: [DatabaseMealPlan] = try await supabase.database
            .from("meal_plans")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("is_active", value: true)
            .execute()
            .value
        
        print("📋 Found \(mealPlans.count) active meal plans for user")
        return mealPlans
    }
}

// MARK: - Error Types
enum MealPlanDatabaseError: LocalizedError {
    case userNotAuthenticated
    case failedToCreateMealPlan
    case failedToCreateMeal
    case networkError(Error)
    case invalidData
    case mealPlanNotFound

    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User is not authenticated"
        case .mealPlanNotFound:
            return "Meal plan not found"
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