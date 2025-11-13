import Foundation

class CalorieCalculationService {
    static let shared = CalorieCalculationService()
    
    private init() {}
    
    /// Calculate recommended calories before dinner based on user data and goals
    func calculateRecommendedCaloriesBeforeDinner(for userData: UserOnboardingData) -> Int {
        // Get the daily calorie goal (which now prioritizes nutrition plan data)
        let dailyCalorieGoal = Double(calculateDailyCalorieGoal(for: userData))
        
        // Calculate calories before dinner (typically 60-70% of daily calories)
        // This accounts for breakfast, lunch, and snacks, leaving dinner as the remaining portion
        let caloriesBeforeDinner = Int(dailyCalorieGoal * 0.65)
        
        return caloriesBeforeDinner
    }
    
    /// Calculate total daily calorie goal based on user data and goals
    func calculateDailyCalorieGoal(for userData: UserOnboardingData) -> Int {
        // If user has a nutrition plan, use it as the single source of truth
        if let nutritionPlan = userData.nutritionPlan {
            return nutritionPlan.dailyCalories
        }
        
        // Fallback calculation for users without a nutrition plan
        let tdee = calculateTDEE(for: userData)
        let adjustedTotalCalories = adjustCaloriesForGoals(tdee: tdee, healthGoals: userData.healthGoals, weightLossSpeed: userData.weightLossSpeed)
        
        return Int(adjustedTotalCalories)
    }
    
    private func calculateTDEE(for userData: UserOnboardingData) -> Double {
        // First calculate BMR (Basal Metabolic Rate) using Mifflin-St Jeor Equation
        // Since we don't have gender data, we'll use a neutral approach or estimate
        let bmr = calculateBMR(age: userData.age, weight: userData.weight, height: userData.height)
        
        // Apply activity level multiplier
        let activityMultiplier = getActivityMultiplier(for: userData.activityLevel)
        
        return bmr * activityMultiplier
    }
    
    private func calculateBMR(age: Int, weight: Double, height: Int) -> Double {
        // Using a gender-neutral approach based on average of male/female formulas
        // Mifflin-St Jeor: 
        // Male: BMR = 10 × weight(kg) + 6.25 × height(cm) - 5 × age(years) + 5
        // Female: BMR = 10 × weight(kg) + 6.25 × height(cm) - 5 × age(years) - 161
        // Average: BMR = 10 × weight(kg) + 6.25 × height(cm) - 5 × age(years) - 78
        
        let weightInKg = weight * 0.453592 // Convert pounds to kg
        let heightInCm = Double(height) * 2.54 // Convert inches to cm
        
        let bmr = 10 * weightInKg + 6.25 * heightInCm - 5 * Double(age) - 78
        
        // Ensure minimum BMR
        return max(bmr, 1200)
    }
    
    private func getActivityMultiplier(for activityLevel: ActivityLevel) -> Double {
        switch activityLevel {
        case .sedentary:
            return 1.2
        case .lightlyActive:
            return 1.375
        case .moderatelyActive:
            return 1.55
        case .veryActive:
            return 1.725
        case .extremelyActive:
            return 1.9
        }
    }
    
    private func adjustCaloriesForGoals(tdee: Double, healthGoals: [HealthGoal], weightLossSpeed: WeightLossSpeed? = nil) -> Double {
        var adjustedCalories = tdee
        
        // Primary goal takes precedence if multiple goals exist
        let primaryGoal = determinePrimaryGoal(from: healthGoals)
        
        switch primaryGoal {
        case .loseWeight:
            // Use weight loss speed to determine caloric deficit
            let deficit: Double
            if let speed = weightLossSpeed {
                // 1 lb = 3500 calories, so deficit per day = (lbs per week * 3500) / 7
                deficit = (speed.weeklyWeightLossLbs * 3500) / 7
            } else {
                // Default moderate deficit (500 calories per day for 1 lb/week loss)
                deficit = 500
            }
            adjustedCalories = tdee - deficit
            // Ensure we don't go below minimum safe level
            adjustedCalories = max(adjustedCalories, 1200)
            
        case .gainWeight:
            // Use weight loss speed to determine caloric surplus (for weight gain)
            let surplus: Double
            if let speed = weightLossSpeed {
                // 1 lb = 3500 calories, so surplus per day = (lbs per week * 3500) / 7
                surplus = (speed.weeklyWeightGainLbs * 3500) / 7
            } else {
                // Default moderate surplus (400 calories per day)
                surplus = 400
            }
            adjustedCalories = tdee + surplus
            
        case .buildMuscle:
            // Slight caloric surplus for muscle building
            adjustedCalories = tdee + 200
            
        case .maintainWeight, .improveHealth, .increaseEnergy, .betterSleep, .reduceStress:
            // Maintain current TDEE for these goals
            adjustedCalories = tdee
        }
        
        return adjustedCalories
    }
    
    private func determinePrimaryGoal(from healthGoals: [HealthGoal]) -> HealthGoal {
        // Priority order for conflicting goals
        let goalPriority: [HealthGoal] = [
            .loseWeight,
            .gainWeight, 
            .buildMuscle,
            .maintainWeight,
            .improveHealth,
            .increaseEnergy,
            .betterSleep,
            .reduceStress
        ]
        
        for priorityGoal in goalPriority {
            if healthGoals.contains(priorityGoal) {
                return priorityGoal
            }
        }
        
        // Default to maintain weight if no goals specified
        return .maintainWeight
    }
    
    /// Calculate personalized calorie range for a specific meal type based on user's profile and goals
    func calculateMealCalorieRange(for userData: UserOnboardingData, mealType: String) -> String {
        let totalDailyCalories = Double(calculateDailyCalorieGoal(for: userData))
        
        // Define typical meal distribution percentages
        let mealPercentages: (min: Double, max: Double) = {
            switch mealType.lowercased() {
            case "breakfast":
                // Breakfast: 20-25% of daily calories
                return (0.20, 0.25)
            case "lunch":
                // Lunch: 25-30% of daily calories
                return (0.25, 0.30)
            case "dinner":
                // Dinner: 30-35% of daily calories
                return (0.30, 0.35)
            default:
                // Default fallback
                return (0.25, 0.30)
            }
        }()
        
        // Calculate calorie range for this meal type
        let minCalories = Int(totalDailyCalories * mealPercentages.min)
        let maxCalories = Int(totalDailyCalories * mealPercentages.max)
        
        // Ensure reasonable minimums based on meal type
        let adjustedMin = max(minCalories, mealType.lowercased() == "breakfast" ? 250 : (mealType.lowercased() == "lunch" ? 350 : 400))
        let adjustedMax = max(maxCalories, adjustedMin + 100)
        
        return "\(adjustedMin)-\(adjustedMax)"
    }
    
    /// Update or create a nutrition plan based on current user goals and pace
    func updateNutritionPlan(for userData: UserOnboardingData) -> NutritionPlan {
        // Calculate new daily calorie goal based on current goals and pace
        let tdee = calculateTDEE(for: userData)
        let dailyCalories = Int(adjustCaloriesForGoals(tdee: tdee, healthGoals: userData.healthGoals, weightLossSpeed: userData.weightLossSpeed))
        
        // Calculate macros based on the new calorie goal
        let macros = calculateMacros(for: dailyCalories, userData: userData)
        
        // Calculate predicted weight after 3 months based on current pace and goals
        let predictedWeight = calculatePredictedWeight(for: userData, dailyCalories: dailyCalories)
        let weightChange = predictedWeight - userData.weight
        
        // Create updated nutrition plan
        return NutritionPlan(
            dailyCalories: dailyCalories,
            dailyCarbs: Int(macros.carbohydrates),
            dailyProtein: Int(macros.protein),
            dailyFats: Int(macros.fat),
            predictedWeightAfter3Months: predictedWeight,
            weightChange: weightChange,
            healthScore: calculateHealthScore(for: userData, dailyCalories: dailyCalories),
            healthScoreReasoning: generateHealthScoreReasoning(for: userData, dailyCalories: dailyCalories),
            createdDate: Date()
        )
    }
    
    /// Calculate macros based on daily calorie goal and user preferences
    private func calculateMacros(for dailyCalories: Int, userData: UserOnboardingData) -> Macros {
        // Use existing nutrition plan ratios if available, otherwise use defaults
        let (proteinRatio, carbRatio, fatRatio): (Double, Double, Double)
        
        if let existingPlan = userData.nutritionPlan, existingPlan.dailyCalories > 0 {
            // Preserve existing macro ratios
            let totalCalories = Double(existingPlan.dailyCalories)
            proteinRatio = (Double(existingPlan.dailyProtein) * 4) / totalCalories // 4 cal/g protein
            carbRatio = (Double(existingPlan.dailyCarbs) * 4) / totalCalories // 4 cal/g carbs
            fatRatio = (Double(existingPlan.dailyFats) * 9) / totalCalories // 9 cal/g fat
        } else {
            // Default macro ratios based on health goals
            let primaryGoal = determinePrimaryGoal(from: userData.healthGoals)
            switch primaryGoal {
            case .loseWeight:
                // Higher protein for weight loss (35% protein, 35% carbs, 30% fat)
                proteinRatio = 0.35
                carbRatio = 0.35
                fatRatio = 0.30
            case .gainWeight, .buildMuscle:
                // Balanced for muscle gain (30% protein, 40% carbs, 30% fat)
                proteinRatio = 0.30
                carbRatio = 0.40
                fatRatio = 0.30
            default:
                // Standard balanced ratio (25% protein, 45% carbs, 30% fat)
                proteinRatio = 0.25
                carbRatio = 0.45
                fatRatio = 0.30
            }
        }
        
        // Calculate macro grams
        let proteinCalories = Double(dailyCalories) * proteinRatio
        let carbCalories = Double(dailyCalories) * carbRatio
        let fatCalories = Double(dailyCalories) * fatRatio
        
        let protein = proteinCalories / 4.0 // 4 calories per gram
        let carbohydrates = carbCalories / 4.0 // 4 calories per gram
        let fat = fatCalories / 9.0 // 9 calories per gram
        
        // Calculate fiber and sugar based on carbs
        let fiber = carbohydrates * 0.15 // ~15% of carbs as fiber
        let sugar = carbohydrates * 0.25 // ~25% of carbs as sugar
        
        // Calculate sodium (aim for 2300mg or less per day)
        let sodium = min(2300.0, Double(dailyCalories) * 1.15) // ~1.15mg per calorie, capped at 2300mg
        
        return Macros(
            protein: protein,
            carbohydrates: carbohydrates,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium
        )
    }
    
    /// Calculate predicted weight after 3 months based on calorie deficit/surplus
    private func calculatePredictedWeight(for userData: UserOnboardingData, dailyCalories: Int) -> Double {
        let currentWeight = userData.weight
        let tdee = calculateTDEE(for: userData)
        let dailyCalorieBalance = Double(dailyCalories) - tdee // negative = deficit, positive = surplus
        
        // 1 pound = 3500 calories
        // 90 days * daily balance / 3500 = total weight change in pounds
        let totalCalorieBalance = dailyCalorieBalance * 90 // 3 months = 90 days
        let weightChangeLbs = totalCalorieBalance / 3500
        
        // Convert to kg if needed (assuming weight is in lbs for now)
        let predictedWeight = currentWeight + weightChangeLbs
        
        // Ensure reasonable bounds
        return max(predictedWeight, currentWeight * 0.7) // Don't predict more than 30% weight loss
    }
    
    /// Calculate health score based on user data and calorie goal
    private func calculateHealthScore(for userData: UserOnboardingData, dailyCalories: Int) -> Int {
        var score = 70 // Base score
        
        // Adjust based on calorie appropriateness
        let tdee = calculateTDEE(for: userData)
        let calorieRatio = Double(dailyCalories) / tdee
        
        if calorieRatio >= 0.8 && calorieRatio <= 1.2 {
            score += 20 // Good calorie range
        } else if calorieRatio >= 0.6 && calorieRatio <= 1.4 {
            score += 10 // Acceptable range
        }
        
        // Adjust based on health goals alignment
        let primaryGoal = determinePrimaryGoal(from: userData.healthGoals)
        switch primaryGoal {
        case .loseWeight:
            if calorieRatio < 1.0 { score += 10 } // Deficit for weight loss
        case .gainWeight:
            if calorieRatio > 1.0 { score += 10 } // Surplus for weight gain
        default:
            if calorieRatio >= 0.95 && calorieRatio <= 1.05 { score += 10 } // Maintenance
        }
        
        return min(max(score, 1), 100) // Clamp between 1-100
    }
    
    /// Generate health score reasoning
    private func generateHealthScoreReasoning(for userData: UserOnboardingData, dailyCalories: Int) -> String {
        let tdee = calculateTDEE(for: userData)
        let calorieBalance = Double(dailyCalories) - tdee
        let primaryGoal = determinePrimaryGoal(from: userData.healthGoals)
        
        var reasoning = "Your nutrition plan is designed for "
        
        switch primaryGoal {
        case .loseWeight:
            reasoning += "sustainable weight loss with a daily deficit of \(Int(abs(calorieBalance))) calories."
        case .gainWeight:
            reasoning += "healthy weight gain with a daily surplus of \(Int(calorieBalance)) calories."
        case .maintainWeight:
            reasoning += "weight maintenance with balanced calorie intake."
        default:
            reasoning += "overall health improvement with balanced nutrition."
        }
        
        reasoning += " This plan ensures adequate nutrition while supporting your goals."
        
        return reasoning
    }
}