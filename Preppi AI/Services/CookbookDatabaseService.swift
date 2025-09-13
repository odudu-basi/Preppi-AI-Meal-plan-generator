import Foundation
import Supabase

class CookbookDatabaseService: ObservableObject {
    static let shared = CookbookDatabaseService()
    
    @Published var cookbooks: [Cookbook] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseService.shared.client
    
    private init() {}
    
    // MARK: - Cookbook Operations
    
    /// Fetch all cookbooks for the current user
    func fetchUserCookbooks() async throws -> [Cookbook] {
        guard let userId = await getCurrentUserId() else {
            throw CookbookError.userNotAuthenticated
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let response = try await supabase
                .from("cookbooks")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
            
            // Parse response manually to handle UUID -> String conversion
            let data = response.data
            print("🔍 Raw response data size: \(data.count) bytes")
            
            guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                print("❌ Failed to parse JSON array from response")
                print("❌ Raw data: \(String(data: data, encoding: .utf8) ?? "Unable to convert to string")")
                throw CookbookError.databaseError("Failed to parse cookbook response")
            }
            
            print("✅ Parsed JSON array with \(jsonArray.count) items")
            
            var cookbooksWithCounts: [Cookbook] = []
            for (index, item) in jsonArray.enumerated() {
                print("🔍 Processing cookbook \(index + 1): \(item)")
                if let cookbook = try parseCookbookFromDictionary(item) {
                    print("✅ Successfully parsed cookbook: \(cookbook.name) (ID: \(cookbook.id))")
                    let count = try await getRecipeCount(for: cookbook.id)
                    print("📊 Got recipe count \(count) for cookbook \(cookbook.name)")
                    var cookbookWithCount = cookbook
                    cookbookWithCount.recipeCount = count
                    cookbooksWithCounts.append(cookbookWithCount)
                    print("✅ Added cookbook with count: \(cookbookWithCount.name) - \(cookbookWithCount.recipeCount) recipes")
                } else {
                    print("❌ Failed to parse cookbook from item: \(item)")
                }
            }
            
            await MainActor.run {
                self.cookbooks = cookbooksWithCounts
                isLoading = false
            }
            
            return cookbooksWithCounts
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch cookbooks: \(error.localizedDescription)"
                isLoading = false
            }
            throw CookbookError.databaseError(error.localizedDescription)
        }
    }
    
    /// Create a new cookbook
    func createCookbook(name: String, description: String? = nil) async throws -> Cookbook {
        guard let userId = await getCurrentUserId() else {
            throw CookbookError.userNotAuthenticated
        }
        
        // Check for duplicate names
        let existingCookbooks = try await fetchUserCookbooks()
        if existingCookbooks.contains(where: { $0.name.lowercased() == name.lowercased() }) {
            throw CookbookError.duplicateName
        }
        
        let cookbook = Cookbook(userId: userId.uuidString, name: name, description: description)
        
        do {
            print("🔍 Creating cookbook with data:")
            print("  - ID: \(cookbook.id)")
            print("  - User ID: \(userId)")
            print("  - Name: \(cookbook.name)")
            print("  - Description: \(cookbook.description ?? "nil")")
            
            var insertData: [String: AnyJSON] = [
                "id": try AnyJSON(cookbook.id),
                "user_id": try AnyJSON(userId),
                "name": try AnyJSON(cookbook.name)
                // created_at and updated_at will be set automatically by database DEFAULT NOW()
            ]
            
            // Only add description if it's not nil
            if let description = cookbook.description {
                insertData["description"] = try AnyJSON(description)
            }
            
            print("📤 Sending insert data to Supabase...")
            try await supabase
                .from("cookbooks")
                .insert(insertData)
                .execute()
            
            print("✅ Cookbook insert successful")
            
            // Refresh cookbooks list
            _ = try await fetchUserCookbooks()
            
            print("✅ Cookbook created successfully: \(cookbook.name)")
            return cookbook
            
        } catch {
            throw CookbookError.databaseError(error.localizedDescription)
        }
    }
    
    /// Update cookbook details
    func updateCookbook(_ cookbook: Cookbook) async throws {
        var updateData: [String: AnyJSON] = [
            "name": try AnyJSON(cookbook.name)
            // updated_at will be set automatically by database trigger
        ]
        
        // Only add description if it's not nil
        if let description = cookbook.description {
            updateData["description"] = try AnyJSON(description)
        }
        
        do {
            try await supabase
                .from("cookbooks")
                .update(updateData)
                .eq("id", value: cookbook.id.uuidString)
                .execute()
            
            // Refresh cookbooks list
            _ = try await fetchUserCookbooks()
            
        } catch {
            throw CookbookError.databaseError(error.localizedDescription)
        }
    }
    
    /// Delete a cookbook and all its recipes
    func deleteCookbook(_ cookbook: Cookbook) async throws {
        do {
            // First delete all recipes in the cookbook
            try await supabase
                .from("saved_recipes")
                .delete()
                .eq("cookbook_id", value: cookbook.id.uuidString)
                .execute()
            
            // Then delete the cookbook
            try await supabase
                .from("cookbooks")
                .delete()
                .eq("id", value: cookbook.id.uuidString)
                .execute()
            
            // Refresh cookbooks list
            _ = try await fetchUserCookbooks()
            
            print("✅ Cookbook deleted successfully: \(cookbook.name)")
            
        } catch {
            throw CookbookError.databaseError(error.localizedDescription)
        }
    }
    
    // MARK: - Recipe Operations
    
    /// Save a recipe to a cookbook
    func saveRecipe(_ recipe: SavedRecipe) async throws {
        do {
            let ingredientsData = try JSONEncoder().encode(recipe.ingredients).base64EncodedString()
            let instructionsData = try JSONEncoder().encode(recipe.instructions).base64EncodedString()
            let nutritionData = try JSONEncoder().encode(recipe.nutrition).base64EncodedString()
            let shoppingListData = try JSONEncoder().encode(recipe.shoppingList).base64EncodedString()
            
            var insertData: [String: AnyJSON] = [
                "id": try AnyJSON(recipe.id),
                "cookbook_id": try AnyJSON(recipe.cookbookId),
                "user_id": try AnyJSON(UUID(uuidString: recipe.userId)!),
                "recipe_name": try AnyJSON(recipe.recipeName),
                "recipe_description": try AnyJSON(recipe.recipeDescription),
                "ingredients": try AnyJSON(ingredientsData),
                "instructions": try AnyJSON(instructionsData),
                "nutrition": try AnyJSON(nutritionData),
                "difficulty_rating": try AnyJSON(recipe.difficultyRating),
                "prep_time": try AnyJSON(recipe.prepTime),
                "cook_time": try AnyJSON(recipe.cookTime),
                "total_time": try AnyJSON(recipe.totalTime),
                "servings": try AnyJSON(recipe.servings),
                "shopping_list": try AnyJSON(shoppingListData),
                "is_favorite": try AnyJSON(recipe.isFavorite)
                // created_at and updated_at will be set automatically by database DEFAULT NOW()
            ]
            
            // Only add optional fields if they're not nil
            if let imageUrl = recipe.imageUrl {
                insertData["image_url"] = try AnyJSON(imageUrl)
            }
            if let notes = recipe.notes {
                insertData["notes"] = try AnyJSON(notes)
            }
            
            try await supabase
                .from("saved_recipes")
                .insert(insertData)
                .execute()
            
            print("✅ Recipe saved successfully: \(recipe.recipeName)")
            
        } catch {
            throw CookbookError.databaseError(error.localizedDescription)
        }
    }
    
    /// Fetch recipes for a specific cookbook
    func fetchRecipes(for cookbookId: UUID) async throws -> [SavedRecipe] {
        do {
            let response = try await supabase
                .from("saved_recipes")
                .select()
                .eq("cookbook_id", value: cookbookId.uuidString)
                .order("created_at", ascending: false)
                .execute()
            
            // Parse the response manually since we're using base64 encoded JSON
            let data = response.data
            guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                return []
            }
            
            var recipes: [SavedRecipe] = []
            
            for item in jsonArray {
                if let recipe = try parseRecipeFromDictionary(item) {
                    recipes.append(recipe)
                }
            }
            
            return recipes
            
        } catch {
            throw CookbookError.databaseError(error.localizedDescription)
        }
    }
    
    /// Delete a recipe
    func deleteRecipe(_ recipe: SavedRecipe) async throws {
        do {
            try await supabase
                .from("saved_recipes")
                .delete()
                .eq("id", value: recipe.id.uuidString)
                .execute()
            
            print("✅ Recipe deleted successfully: \(recipe.recipeName)")
            
        } catch {
            throw CookbookError.databaseError(error.localizedDescription)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUserId() async -> UUID? {
        do {
            let user = try await supabase.auth.user()
            return user.id
        } catch {
            print("❌ Failed to get current user: \(error)")
            return nil
        }
    }
    
    private func getRecipeCount(for cookbookId: UUID) async throws -> Int {
        do {
            print("🔍 Getting recipe count for cookbook ID: \(cookbookId)")
            
            // First, let's try a simple select to see what recipes exist
            let allRecipesResponse = try await supabase
                .from("saved_recipes")
                .select("id, recipe_name")
                .eq("cookbook_id", value: cookbookId.uuidString)
                .execute()
            
            let allRecipesData = allRecipesResponse.data
            if let recipesJson = try JSONSerialization.jsonObject(with: allRecipesData) as? [[String: Any]] {
                let count = recipesJson.count
                print("📊 Found \(count) recipes for cookbook \(cookbookId)")
                print("📊 Recipe names: \(recipesJson.compactMap { $0["recipe_name"] as? String })")
                return count
            } else {
                print("❌ Failed to parse recipes JSON")
                return 0
            }
            
        } catch {
            print("❌ Failed to get recipe count: \(error)")
            return 0
        }
    }
    
    private func parseRecipeFromDictionary(_ dict: [String: Any]) throws -> SavedRecipe? {
        guard let idString = dict["id"] as? String,
              let id = UUID(uuidString: idString),
              let cookbookIdString = dict["cookbook_id"] as? String,
              let cookbookId = UUID(uuidString: cookbookIdString),
              let userId = dict["user_id"] as? String,
              let recipeName = dict["recipe_name"] as? String,
              let recipeDescription = dict["recipe_description"] as? String else {
            return nil
        }
        
        // Decode base64 encoded JSON fields
        let ingredients = try decodeBase64JSON(dict["ingredients"] as? String, as: [RecipeIngredient].self) ?? []
        let instructions = try decodeBase64JSON(dict["instructions"] as? String, as: [String].self) ?? []
        let nutrition = try decodeBase64JSON(dict["nutrition"] as? String, as: NutritionInfo.self) ?? NutritionInfo(calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0, sugar: 0)
        let shoppingList = try decodeBase64JSON(dict["shopping_list"] as? String, as: [String].self) ?? []
        
        let difficultyRating = dict["difficulty_rating"] as? Int ?? 1
        let prepTime = dict["prep_time"] as? String ?? ""
        let cookTime = dict["cook_time"] as? String ?? ""
        let totalTime = dict["total_time"] as? String ?? ""
        let servings = dict["servings"] as? Int ?? 1
        let imageUrl = dict["image_url"] as? String
        let notes = dict["notes"] as? String
        let isFavorite = dict["is_favorite"] as? Bool ?? false
        
        let createdAt = parseDate(dict["created_at"] as? String) ?? Date()
        let updatedAt = parseDate(dict["updated_at"] as? String) ?? Date()
        
        // Create SavedRecipe manually since we can't use the convenience initializer
        var recipe = SavedRecipe(
            from: RecipeAnalysis(
                foodIdentification: recipeName,
                description: recipeDescription,
                recipe: RecipeDetails(
                    ingredients: ingredients,
                    instructions: instructions,
                    prepTime: prepTime,
                    cookTime: cookTime,
                    totalTime: totalTime
                ),
                nutrition: nutrition,
                shoppingList: shoppingList,
                difficultyRating: difficultyRating
            ),
            cookbookId: cookbookId,
            userId: userId,
            servings: servings,
            imageUrl: imageUrl
        )
        
        // Update with actual values from database
        recipe = SavedRecipe(
            id: id,
            cookbookId: cookbookId,
            userId: userId,
            recipeName: recipeName,
            recipeDescription: recipeDescription,
            ingredients: ingredients,
            instructions: instructions,
            nutrition: nutrition,
            difficultyRating: difficultyRating,
            prepTime: prepTime,
            cookTime: cookTime,
            totalTime: totalTime,
            servings: servings,
            shoppingList: shoppingList,
            imageUrl: imageUrl,
            notes: notes,
            isFavorite: isFavorite,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
        
        return recipe
    }
    
    private func decodeBase64JSON<T: Codable>(_ base64String: String?, as type: T.Type) throws -> T? {
        guard let base64String = base64String,
              let data = Data(base64Encoded: base64String) else {
            return nil
        }
        
        return try JSONDecoder().decode(type, from: data)
    }
    
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { 
            print("❌ Date string is nil")
            return nil 
        }
        
        print("🔍 Parsing date string: \(dateString)")
        
        // Try different date formatters
        let formatters: [DateFormatter] = [
            // ISO8601 with fractional seconds
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS+00:00"
                formatter.timeZone = TimeZone(abbreviation: "UTC")
                return formatter
            }(),
            // Standard ISO8601
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                formatter.timeZone = TimeZone(abbreviation: "UTC")
                return formatter
            }(),
            // Postgres timestamp
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS+00"
                formatter.timeZone = TimeZone(abbreviation: "UTC")
                return formatter
            }()
        ]
        
        // Try ISO8601DateFormatter first
        if let date = ISO8601DateFormatter().date(from: dateString) {
            print("✅ Date parsed successfully with ISO8601DateFormatter: \(date)")
            return date
        }
        
        // Try custom formatters
        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                print("✅ Date parsed successfully with custom formatter: \(date)")
                return date
            }
        }
        
        print("❌ Failed to parse date string: \(dateString)")
        return nil
    }
    
    private func parseCookbookFromDictionary(_ dict: [String: Any]) throws -> Cookbook? {
        print("🔍 Parsing cookbook dictionary keys: \(dict.keys)")
        print("🔍 Dictionary values: \(dict)")
        
        guard let idString = dict["id"] as? String else {
            print("❌ Missing or invalid 'id' field. Value: \(dict["id"] ?? "nil")")
            return nil
        }
        
        guard let id = UUID(uuidString: idString) else {
            print("❌ Invalid UUID string for id: \(idString)")
            return nil
        }
        
        guard let userIdString = dict["user_id"] as? String else {
            print("❌ Missing or invalid 'user_id' field. Value: \(dict["user_id"] ?? "nil")")
            return nil
        }
        
        guard let name = dict["name"] as? String else {
            print("❌ Missing or invalid 'name' field. Value: \(dict["name"] ?? "nil")")
            return nil
        }
        
        print("✅ Successfully extracted required fields: id=\(id), userId=\(userIdString), name=\(name)")
        
        let description = dict["description"] as? String
        
        // Parse dates with proper fallback
        let createdAt: Date
        if let parsedCreatedAt = parseDate(dict["created_at"] as? String) {
            createdAt = parsedCreatedAt
            print("✅ Created at parsed: \(createdAt)")
        } else {
            // Fallback to a reasonable past date instead of current time
            createdAt = Date().addingTimeInterval(-3600) // 1 hour ago
            print("⚠️ Using fallback created at: \(createdAt)")
        }
        
        let updatedAt: Date
        if let parsedUpdatedAt = parseDate(dict["updated_at"] as? String) {
            updatedAt = parsedUpdatedAt
            print("✅ Updated at parsed: \(updatedAt)")
        } else {
            updatedAt = createdAt // Use created date as fallback
            print("⚠️ Using created date as updated at: \(updatedAt)")
        }
        
        // Create cookbook with actual database values
        let cookbook = Cookbook(
            id: id,
            userId: userIdString, // UUID from database converted to String for model
            name: name,
            description: description,
            createdAt: createdAt,
            updatedAt: updatedAt,
            recipeCount: 0 // Will be updated later
        )
        
        return cookbook
    }
}

// MARK: - Cookbook Manual Initializer
extension Cookbook {
    init(id: UUID, userId: String, name: String, description: String?, createdAt: Date, updatedAt: Date, recipeCount: Int) {
        self.id = id
        self.userId = userId
        self.name = name
        self.description = description
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.recipeCount = recipeCount
    }
}

// MARK: - SavedRecipe Manual Initializer
extension SavedRecipe {
    init(id: UUID, cookbookId: UUID, userId: String, recipeName: String, recipeDescription: String, 
         ingredients: [RecipeIngredient], instructions: [String], nutrition: NutritionInfo, 
         difficultyRating: Int, prepTime: String, cookTime: String, totalTime: String, 
         servings: Int, shoppingList: [String], imageUrl: String?, notes: String?, 
         isFavorite: Bool, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.cookbookId = cookbookId
        self.userId = userId
        self.recipeName = recipeName
        self.recipeDescription = recipeDescription
        self.ingredients = ingredients
        self.instructions = instructions
        self.nutrition = nutrition
        self.difficultyRating = difficultyRating
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.totalTime = totalTime
        self.servings = servings
        self.shoppingList = shoppingList
        self.imageUrl = imageUrl
        self.notes = notes
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
