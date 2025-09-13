 import Foundation

class OpenAIService: ObservableObject {
    static let shared = OpenAIService()
    
    private let apiKey = ConfigurationService.shared.openAIAPIKey
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let imageGenerationURL = "https://api.openai.com/v1/images/generations"
    
    @Published var isGenerating = false
    @Published var errorMessage: String?
    
    private init() {}
    
    // MARK: - Week Identifier Helper
    
    /// Generate a week identifier from a given date (format: yyyy-MM-dd for week start)
    private func getWeekIdentifier(for date: Date) -> String {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Sunday is first day
        
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: weekStart)
    }
    
    /// Get the current week identifier
    private func getCurrentWeekIdentifier() -> String {
        return getWeekIdentifier(for: Date())
    }
    
    /// Get the current authenticated user's ID
    private func getCurrentUserId() async throws -> UUID? {
        do {
            let session = try await SupabaseService.shared.auth.session
            return UUID(uuidString: session.user.id.uuidString)
        } catch {
            print("❌ Error getting current user: \(error)")
            return nil
        }
    }
    
    func generateMealPlan(for userData: UserOnboardingData, cuisines: [String] = [], mealType: String = "dinner", preparationStyle: MealPlanInfoView.MealPreparationStyle = .newMealEveryTime, mealCount: Int = 3, weekIdentifier: String? = nil) async throws -> [DayMeal] {
        await MainActor.run {
            isGenerating = true
            errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                isGenerating = false
            }
        }
        
        let prompt = createMealPlanPrompt(from: userData, cuisines: cuisines, mealType: mealType, preparationStyle: preparationStyle, mealCount: mealCount)
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "system",
                    "content": "You are a professional nutritionist and chef. Create meal plans that are healthy, delicious, and tailored to the user's preferences and goals. Always respond with valid JSON format."
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 2000,
            "temperature": 0.7
        ]
        
        guard let url = URL(string: baseURL) else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw OpenAIError.invalidRequest
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                await MainActor.run {
                    errorMessage = message
                }
                throw OpenAIError.apiError(message)
            }
            throw OpenAIError.invalidResponse
        }
        
        do {
            let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            let content = openAIResponse.choices.first?.message.content ?? ""
            
            // Clean the content to extract JSON (remove markdown formatting if present)
            let cleanedContent = content
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Parse the JSON response from OpenAI
            guard let contentData = cleanedContent.data(using: .utf8),
                  let mealPlanJSON = try JSONSerialization.jsonObject(with: contentData) as? [String: Any],
                  let mealsArray = mealPlanJSON["meals"] as? [[String: Any]] else {
                print("❌ Failed to parse OpenAI response: \(content)")
                throw OpenAIError.parsingError
            }
            
            // Parse shopping list
            var shoppingList: [String: [String]] = [:]
            if let shoppingListData = mealPlanJSON["shoppingList"] as? [String: [String]] {
                shoppingList = shoppingListData
            }
            
            var dayMeals: [DayMeal] = []
            let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
            
            for (index, mealData) in mealsArray.enumerated() {
                guard index < weekdays.count,
                      let name = mealData["name"] as? String,
                      let description = mealData["description"] as? String,
                      let calories = mealData["calories"] as? Int,
                      let cookTime = mealData["cookTime"] as? Int,
                      let ingredients = mealData["ingredients"] as? [String] else {
                    continue
                }
                
                let originalCookingDay = mealData["originalCookingDay"] as? String
                
                // Parse macros if available
                var macros: Macros? = nil
                if let macrosData = mealData["macros"] as? [String: Any],
                   let protein = macrosData["protein"] as? Double,
                   let carbohydrates = macrosData["carbohydrates"] as? Double,
                   let fat = macrosData["fat"] as? Double,
                   let fiber = macrosData["fiber"] as? Double,
                   let sugar = macrosData["sugar"] as? Double,
                   let sodium = macrosData["sodium"] as? Double {
                    macros = Macros(
                        protein: protein,
                        carbohydrates: carbohydrates,
                        fat: fat,
                        fiber: fiber,
                        sugar: sugar,
                        sodium: sodium
                    )
                }
                
                // Calculate recommended calories based on meal type and user goals
                let recommendedCalories: Int
                if mealType == "breakfast" {
                    // For breakfast, use a portion of daily calories (typically 20-25%)
                    let totalDailyCalories = CalorieCalculationService.shared.calculateDailyCalorieGoal(for: userData)
                    recommendedCalories = Int(Double(totalDailyCalories) * 0.8) // 80% remaining after breakfast
                } else {
                    // For dinner, use existing logic
                    recommendedCalories = CalorieCalculationService.shared.calculateRecommendedCaloriesBeforeDinner(for: userData)
                }
                
                let meal = Meal(
                    id: UUID(),
                    name: name,
                    description: description,
                    calories: calories,
                    cookTime: cookTime,
                    ingredients: ingredients,
                    instructions: [], // Will be generated later when viewing recipe details
                    originalCookingDay: originalCookingDay,
                    imageUrl: nil, // No image initially - will be generated on demand
                    recommendedCaloriesBeforeDinner: recommendedCalories,
                    macros: macros, // Include parsed macros
                    detailedIngredients: nil, // Will be generated when detailed recipe is requested
                    detailedInstructions: nil,
                    cookingTips: nil,
                    servingInfo: nil
                )
                
                let dayMeal = DayMeal(
                    day: weekdays[index],
                    meal: meal
                )
                
                dayMeals.append(dayMeal)
            }
            
            // Store shopping list in UserDefaults for access across the app
            // Use user-specific, meal type and week specific key to prevent data mixing between users
            if let shoppingListData = try? JSONSerialization.data(withJSONObject: shoppingList),
               let shoppingListString = String(data: shoppingListData, encoding: .utf8) {
                let weekKey = weekIdentifier ?? getCurrentWeekIdentifier()
                
                // Get current user ID for user-specific storage
                let userId = try? await getCurrentUserId()
                let userKey = userId?.uuidString ?? "unknown"
                
                let storageKey = "user_\(userKey)_weeklyShoppingList_\(mealType)_\(weekKey)"
                UserDefaults.standard.set(shoppingListString, forKey: storageKey)
                
                print("🛒 Stored shopping list with user-specific key: \(storageKey)")
            }
            
            // Track meal plan generation success
            MixpanelService.shared.track(
                event: MixpanelService.Events.mealPlanGenerated,
                properties: [
                    MixpanelService.Properties.mealCount: mealCount,
                    MixpanelService.Properties.cuisineTypes: cuisines.joined(separator: ", "),
                    MixpanelService.Properties.preparationStyle: preparationStyle.rawValue,
                    "total_meals_generated": dayMeals.count,
                    "has_macros": dayMeals.first?.meal.macros != nil
                ]
            )
            
            return dayMeals
            
        } catch {
            throw OpenAIError.parsingError
        }
    }
    
    private func createMealPlanPrompt(from userData: UserOnboardingData, cuisines: [String], mealType: String = "dinner", preparationStyle: MealPlanInfoView.MealPreparationStyle, mealCount: Int = 3) -> String {
        let mealTypeCapitalized = mealType.capitalized
        var prompt = """
        Create a 7-day \(mealType) meal plan for a person with the following profile:
        
        Name: \(userData.name)
        Sex: \(userData.sex?.rawValue ?? "Not specified")
        Age: \(userData.age)
        Weight: \(userData.weight) lbs
        Height: \(userData.height) inches
        Activity Level: \(userData.activityLevel.rawValue)
        Weekly Budget: $\(userData.weeklyBudget ?? 0)
        """
        
        if let cookingPref = userData.cookingPreference {
            prompt += "\nCooking Preference: \(cookingPref.rawValue)"
        }
        
        if !userData.motivations.isEmpty {
            let motivations = userData.motivations.map { $0.rawValue }.joined(separator: ", ")
            prompt += "\nMotivations: \(motivations)"
            if userData.motivations.contains(.other) && !userData.motivationOther.isEmpty {
                prompt += " (Other: \(userData.motivationOther))"
            }
        }
        
        if !userData.challenges.isEmpty {
            let challenges = userData.challenges.map { $0.rawValue }.joined(separator: ", ")
            prompt += "\nChallenges: \(challenges)"
        }
        
        if !userData.healthGoals.isEmpty {
            let goals = userData.healthGoals.map { $0.rawValue }.joined(separator: ", ")
            prompt += "\nHealth Goals: \(goals)"
        }
        
        if !userData.dietaryRestrictions.isEmpty {
            let restrictions = userData.dietaryRestrictions.map { $0.rawValue }.joined(separator: ", ")
            prompt += "\nDietary Restrictions: \(restrictions)"
        }
        
        if !userData.foodAllergies.isEmpty {
            let allergies = userData.foodAllergies.map { $0.rawValue }.joined(separator: ", ")
            prompt += "\nFood Allergies: \(allergies)"
        }
        
        // Add cuisine preferences
        if !cuisines.isEmpty {
            prompt += "\nSelected Cuisines: \(cuisines.joined(separator: ", "))"
            prompt += "\nSTRICT REQUIREMENT: Create meals ONLY from these selected cuisine styles. Do not include any meals from other cuisines not listed above. Each meal must clearly belong to one of the specified cuisines."
        }
        
        // Add meal preparation style
        prompt += "\nMeal Preparation Style: \(preparationStyle.rawValue)"
        prompt += "\n\(preparationStyle.description)"
        
        switch preparationStyle {
        case .newMealEveryTime:
            prompt += "\nEnsure each meal is unique and different from the others. Vary cooking methods, ingredients, and flavors throughout the week."
        case .multiplePortions:
            prompt += "\nDesign meals for BATCH COOKING with planned leftovers. Create exactly \(mealCount) unique meals that will be cooked in large portions and repeated throughout the week to fill all 7 days. For repeated meals, indicate which day the meal was originally prepared. Include make-ahead tips and storage suggestions."
        }
        
        let calorieRange = CalorieCalculationService.shared.calculateMealCalorieRange(for: userData, mealType: mealType)
        
        prompt += """
        
        Please create exactly 7 \(mealType) meals (one for each day of the week: Sunday through Saturday) AND a comprehensive shopping list.
        
        For each meal, provide:
        1. A creative and appealing meal name
        2. A brief but appealing description (2-3 sentences) highlighting the main flavors and appeal
        3. Calorie count (realistic for \(mealType), typically \(calorieRange) calories)
        4. Cook time in minutes
        5. Main ingredients list (5-8 key ingredients)
        6. Original cooking day (if this is a repeated/leftover meal, specify which day it was originally prepared, e.g., "Monday". If it's a fresh meal, use the current day)
        7. Detailed macronutrient breakdown with accurate values based on ingredients and portions
        
        For ingredients, include:
        - Key ingredients without specific quantities (e.g., "chicken breasts", "quinoa", "olive oil")
        - Main proteins, vegetables, and grains
        - Essential seasonings and herbs
        
        For the shopping list, provide:
        - Consolidated list of ALL ingredients needed for the entire week
        - Organized by categories (Proteins, Vegetables, Pantry Items, Dairy, etc.)
        - Estimated quantities needed for all 7 meals
        - Include both main ingredients and seasonings/condiments
        
        Ensure the meals:
        - Fit within their budget when divided by 7 days
        - Match their dietary restrictions and allergies
        - Align with their health goals
        - Are appropriate for their cooking skill level
        - Provide balanced nutrition with protein, vegetables, and healthy carbs
        - Use ONLY the user's selected cuisine styles (if cuisines are specified, do not include any other cuisine types)
        - Follow the specified meal preparation approach (variety vs. batch cooking)
        - Include both familiar comfort foods and exciting new flavors but ONLY within the selected cuisines
        - If no specific cuisines are selected, then provide varied international cuisine options
        
        Respond ONLY with valid JSON in this exact format:
        {
          "meals": [
            {
              "name": "Meal Name",
              "description": "Brief appealing description of the meal",
              "calories": 650,
              "cookTime": 35,
              "ingredients": ["chicken breasts", "quinoa", "olive oil", "lemon", "garlic", "oregano", "bell pepper", "zucchini"],
              "originalCookingDay": "Sunday",
              "macros": {
                "protein": 45.5,
                "carbohydrates": 55.2,
                "fat": 18.7,
                "fiber": 8.3,
                "sugar": 12.1,
                "sodium": 890.5
              }
            }
          ],
          "shoppingList": {
            "Proteins": ["2 lbs chicken breasts", "1 lb ground turkey", "1 lb salmon fillets"],
            "Vegetables": ["2 large bell peppers", "1 lb zucchini", "2 lbs mixed greens", "1 lb tomatoes"],
            "Pantry Items": ["2 cups quinoa", "1 bottle olive oil", "1 jar coconut oil", "Rice vinegar"],
            "Dairy": ["1 container Greek yogurt", "8 oz feta cheese", "1 dozen eggs"],
            "Herbs & Spices": ["Fresh basil", "Dried oregano", "Garlic powder", "Sea salt", "Black pepper"]
          }
        }
        """
        
        return prompt
    }
    
    func generateDetailedRecipe(for dayMeal: DayMeal, userData: UserOnboardingData) async throws -> DetailedRecipe {
        await MainActor.run {
            isGenerating = true
            errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                isGenerating = false
            }
        }
        
        let prompt = createDetailedRecipePrompt(for: dayMeal, userData: userData)
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "system",
                    "content": "You are a professional chef and recipe writer. Create comprehensive, restaurant-quality recipes with detailed instructions, exact measurements, and professional cooking techniques. Always respond with valid JSON format."
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 2000,
            "temperature": 0.7
        ]
        
        guard let url = URL(string: baseURL) else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw OpenAIError.invalidRequest
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                await MainActor.run {
                    errorMessage = message
                }
                throw OpenAIError.apiError(message)
            }
            throw OpenAIError.invalidResponse
        }
        
        do {
            let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            let content = openAIResponse.choices.first?.message.content ?? ""
            
            // Clean the content to extract JSON
            let cleanedContent = content
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Parse the JSON response
            guard let contentData = cleanedContent.data(using: .utf8),
                  let recipeJSON = try JSONSerialization.jsonObject(with: contentData) as? [String: Any],
                  let detailedIngredients = recipeJSON["detailedIngredients"] as? [String],
                  let instructions = recipeJSON["instructions"] as? [String],
                  let cookingTips = recipeJSON["cookingTips"] as? [String],
                  let servingInfo = recipeJSON["servingInfo"] as? String else {
                print("❌ Failed to parse detailed recipe response: \(content)")
                throw OpenAIError.parsingError
            }
            
            return DetailedRecipe(
                detailedIngredients: detailedIngredients,
                instructions: instructions,
                cookingTips: cookingTips,
                servingInfo: servingInfo
            )
            
        } catch {
            throw OpenAIError.parsingError
        }
    }
    
    private func createDetailedRecipePrompt(for dayMeal: DayMeal, userData: UserOnboardingData) -> String {
        var prompt = """
        Create a comprehensive, professional recipe for "\(dayMeal.meal.name)".
        
        Basic meal information:
        - Description: \(dayMeal.meal.description)
        - Estimated calories: \(dayMeal.meal.calories)
        - Cook time: \(dayMeal.meal.cookTime) minutes
        - Basic ingredients: \(dayMeal.meal.ingredients.joined(separator: ", "))
        
        User profile for customization:
        - Cooking experience: \(userData.cookingPreference?.rawValue ?? "Intermediate")
        - Dietary restrictions: \(userData.dietaryRestrictions.map { $0.rawValue }.joined(separator: ", "))
        - Food allergies: \(userData.foodAllergies.map { $0.rawValue }.joined(separator: ", "))
        """
        
        prompt += """
        
        Create a detailed recipe with:
        
        1. **Detailed Ingredients** (8-12 items with exact measurements):
           - Specific quantities and measurements
           - Exact cuts and types (e.g., "2 boneless skinless chicken breasts (6 oz each)")
           - All seasonings, herbs, and spices
           - Any garnishes or finishing touches
        
        2. **Step-by-Step Instructions** (6-10 comprehensive steps):
           - Detailed preparation and cooking techniques
           - Specific temperatures, times, and visual cues
           - Professional cooking tips integrated into steps
           - Clear sequence from prep to plating
        
        3. **Cooking Tips** (3-5 professional tips):
           - Key techniques for best results
           - Common mistakes to avoid
           - Flavor enhancement suggestions
           - Make-ahead or storage tips
        
        4. **Serving Information**:
           - Portion size and servings
           - Best accompaniments or sides
           - Presentation suggestions
        
        Ensure the recipe:
        - Respects dietary restrictions and allergies
        - Matches the user's cooking skill level
        - Achieves the target calorie count
        - Can be completed in the estimated time
        - Uses accessible ingredients within reasonable budget
        
        Respond ONLY with valid JSON in this exact format:
        {
          "detailedIngredients": [
            "2 boneless skinless chicken breasts (6 oz each)",
            "1 cup quinoa",
            "3 tbsp extra virgin olive oil",
            "1 large lemon (juiced and zested)",
            "3 cloves garlic (minced)",
            "2 tsp dried oregano",
            "1 tsp kosher salt",
            "1/2 tsp black pepper",
            "1 large red bell pepper (chopped)",
            "1 medium zucchini (sliced)",
            "1/4 cup fresh parsley (chopped)"
          ],
          "instructions": [
            "Preheat your oven to 425°F and line a large baking sheet with parchment paper for easy cleanup.",
            "In a bowl, whisk together 2 tbsp olive oil, lemon juice, lemon zest, minced garlic, oregano, salt, and pepper to create the marinade.",
            "Place chicken breasts between plastic wrap and gently pound to even 3/4-inch thickness. Add to marinade and coat both sides thoroughly.",
            "Let chicken marinate for 15-20 minutes while you prepare the vegetables and quinoa.",
            "Rinse quinoa under cold water until water runs clear. Cook according to package directions with a pinch of salt until fluffy, about 15 minutes.",
            "Toss chopped bell pepper and sliced zucchini with remaining olive oil, salt, and pepper on the prepared baking sheet.",
            "Heat a large oven-safe skillet over medium-high heat. Remove chicken from marinade and sear for 3-4 minutes per side until golden.",
            "Transfer skillet to oven and roast chicken and vegetables simultaneously for 12-15 minutes until chicken reaches 165°F internal temperature.",
            "Remove from oven and let chicken rest for 5 minutes before slicing against the grain into 1/2-inch thick pieces.",
            "Fluff quinoa with a fork, stir in fresh parsley, and serve topped with sliced chicken and roasted vegetables."
          ],
          "cookingTips": [
            "Pound chicken to even thickness for uniform cooking and better marinade absorption",
            "Don't move chicken too early when searing - let it develop a golden crust for maximum flavor",
            "Use a meat thermometer to ensure chicken reaches exactly 165°F to avoid overcooking",
            "Let chicken rest before slicing to retain juices and ensure tender, moist meat",
            "Toast quinoa in a dry pan for 2-3 minutes before adding liquid for enhanced nutty flavor"
          ],
          "servingInfo": "Serves 2-3 people as a main course. Pairs beautifully with a simple green salad and crusty bread. Can be served warm or at room temperature, making it perfect for meal prep."
        }
        """
        
        return prompt
    }
    
    /// Generates a meal image and saves it permanently to Supabase Storage
    func generateMealImage(for meal: Meal) async throws -> String {
        // Note: Not setting global isGenerating to avoid full-page loading view
        // Individual views should manage their own loading states
        
        await MainActor.run {
            errorMessage = nil
        }
        
        let prompt = createImagePrompt(for: meal)
        
        let requestBody: [String: Any] = [
            "model": "dall-e-3",
            "prompt": prompt,
            "n": 1,
            "size": "1024x1024",
            "quality": "hd",
            "style": "natural"
        ]
        
        guard let url = URL(string: imageGenerationURL) else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw OpenAIError.invalidRequest
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                await MainActor.run {
                    errorMessage = message
                }
                throw OpenAIError.apiError(message)
            }
            throw OpenAIError.invalidResponse
        }
        
        do {
            let imageResponse = try JSONDecoder().decode(ImageGenerationResponse.self, from: data)
            guard let temporaryImageUrl = imageResponse.data.first?.url else {
                throw OpenAIError.parsingError
            }
            
            print("🔗 Generated temporary DALL-E URL: \(temporaryImageUrl)")
            
            // Download and store the image permanently in Supabase Storage
            print("📥 Downloading and storing image permanently...")
            let permanentImageUrl = try await ImageStorageService.shared.downloadAndStoreImage(
                from: temporaryImageUrl,
                for: meal.id
            )
            
            print("✅ Image stored permanently: \(permanentImageUrl)")
            return permanentImageUrl
            
        } catch {
            if error is ImageStorageError {
                // Re-throw image storage errors as-is
                throw error
            } else {
                throw OpenAIError.parsingError
            }
        }
    }
    
    /// Generates a meal image temporarily (returns DALL-E URL without saving to storage)
    /// Use this during meal planning when you don't want to save the image permanently yet
    func generateMealImageTemporary(for meal: Meal) async throws -> String {
        // Note: Not setting global isGenerating to avoid full-page loading view
        // Individual views should manage their own loading states
        
        await MainActor.run {
            errorMessage = nil
        }
        
        let prompt = createImagePrompt(for: meal)
        
        let requestBody: [String: Any] = [
            "model": "dall-e-3",
            "prompt": prompt,
            "n": 1,
            "size": "1024x1024",
            "quality": "hd",
            "style": "natural"
        ]
        
        guard let url = URL(string: imageGenerationURL) else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw OpenAIError.invalidRequest
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                await MainActor.run {
                    errorMessage = message
                }
                throw OpenAIError.apiError(message)
            }
            throw OpenAIError.invalidResponse
        }
        
        do {
            let imageResponse = try JSONDecoder().decode(ImageGenerationResponse.self, from: data)
            guard let temporaryImageUrl = imageResponse.data.first?.url else {
                throw OpenAIError.parsingError
            }
            
            print("🔗 Generated temporary DALL-E URL (not saved): \(temporaryImageUrl)")
            return temporaryImageUrl
            
        } catch {
            throw OpenAIError.parsingError
        }
    }
    
    private func createImagePrompt(for meal: Meal) -> String {
        // Extract ingredients for more realistic context
        let ingredientContext = meal.ingredients.prefix(5).joined(separator: ", ")
        
        return """
        Create a photorealistic, professional food photography image of "\(meal.name)".
        
        Meal Description: \(meal.description)
        Key Ingredients: \(ingredientContext)
        
        Technical Photography Specifications:
        - Shot with a high-end DSLR camera (Canon 5D Mark IV or similar)
        - 85mm macro lens for perfect food detail capture
        - f/2.8 aperture for shallow depth of field
        - Natural window lighting with soft diffuser
        - ISO 200 for minimal noise and maximum detail
        - Professional food styling with garnish and props
        
        Visual Requirements:
        - Photorealistic textures showing every detail (steam, moisture, crispy edges, fresh herbs)
        - Restaurant-quality plating on elegant dishware
        - Authentic food colors and natural shadows
        - Shallow depth of field with bokeh background
        - Perfect focus on the main dish elements
        - Realistic food proportions and sizing
        - Natural imperfections that make food look real (slight irregularities, natural textures)
        - Ambient lighting that enhances food appeal
        - Clean, neutral background (marble, wood, or linen)
        - Professional food styling with complementary garnishes
        
        Composition:
        - 45-degree angle or slight overhead shot
        - Rule of thirds composition
        - Negative space for visual balance
        - Depth and dimension showing food layers/height
        
        Style: Hyperrealistic food photography, magazine-quality, commercial food advertising style, natural and appetizing.
        """
    }
}

// MARK: - Data Models
struct OpenAIResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}

struct Message: Codable {
    let content: String
}

struct DetailedRecipe: Codable {
    let detailedIngredients: [String]
    let instructions: [String]
    let cookingTips: [String]
    let servingInfo: String
}

struct ImageGenerationResponse: Codable {
    let data: [ImageData]
}

struct ImageData: Codable {
    let url: String
}

// MARK: - Error Handling
enum OpenAIError: Error, LocalizedError {
    case invalidURL
    case invalidRequest
    case invalidResponse
    case apiError(String)
    case parsingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidRequest:
            return "Invalid request"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let message):
            return "API Error: \(message)"
        case .parsingError:
            return "Failed to parse response"
        }
    }
}