import Foundation

class CalorieCalculationService {
    static let shared = CalorieCalculationService()
    
    private init() {}
    
    /// Calculate recommended calories before dinner based on user data and goals
    func calculateRecommendedCaloriesBeforeDinner(for userData: UserOnboardingData) -> Int {
        // Calculate Total Daily Energy Expenditure (TDEE)
        let tdee = calculateTDEE(for: userData)
        
        // Adjust based on health goals
        let adjustedTotalCalories = adjustCaloriesForGoals(tdee: tdee, healthGoals: userData.healthGoals)
        
        // Calculate calories before dinner (typically 60-70% of daily calories)
        // This accounts for breakfast, lunch, and snacks, leaving dinner as the remaining portion
        let caloriesBeforeDinner = Int(adjustedTotalCalories * 0.65)
        
        return caloriesBeforeDinner
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
    
    private func adjustCaloriesForGoals(tdee: Double, healthGoals: [HealthGoal]) -> Double {
        var adjustedCalories = tdee
        
        // Primary goal takes precedence if multiple goals exist
        let primaryGoal = determinePrimaryGoal(from: healthGoals)
        
        switch primaryGoal {
        case .loseWeight:
            // Create a moderate caloric deficit (500 calories per day for 1 lb/week loss)
            adjustedCalories = tdee - 500
            // Ensure we don't go below minimum safe level
            adjustedCalories = max(adjustedCalories, 1200)
            
        case .gainWeight:
            // Create a moderate caloric surplus (300-500 calories per day)
            adjustedCalories = tdee + 400
            
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
}