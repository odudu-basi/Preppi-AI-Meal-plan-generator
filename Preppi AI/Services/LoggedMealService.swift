import Foundation
import SwiftUI
import Supabase

class LoggedMealService: ObservableObject {
    static let shared = LoggedMealService()
    
    @Published var loggedMeals: [LoggedMeal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseService.shared.client
    
    private init() {
        Task {
            await loadLoggedMeals()
        }
    }
    
    // MARK: - Public Methods
    
    func logMeal(from analysisResult: MealAnalysisResult, image: UIImage?, mealType: String? = nil, loggedDate: Date = Date()) {
        Task {
            await saveMealToDatabase(from: analysisResult, image: image, mealType: mealType, loggedDate: loggedDate)
            
            // Notify streak service about the logged meal
            await notifyStreakService(mealType: mealType, loggedDate: loggedDate)
        }
    }
    
    func getLoggedMealsForDate(_ date: Date) -> [LoggedMeal] {
        let calendar = Calendar.current
        return loggedMeals.filter { loggedMeal in
            calendar.isDate(loggedMeal.loggedAt, inSameDayAs: date)
        }
    }
    
    func getLoggedMealForDateAndType(_ date: Date, mealType: String) -> LoggedMeal? {
        let calendar = Calendar.current
        return loggedMeals.first { loggedMeal in
            calendar.isDate(loggedMeal.loggedAt, inSameDayAs: date) && 
            loggedMeal.mealType == mealType
        }
    }
    
    func hasLoggedMealForDateAndType(_ date: Date, mealType: String) -> Bool {
        return getLoggedMealForDateAndType(date, mealType: mealType) != nil
    }
    
    func getTotalCaloriesForDate(_ date: Date) -> Int {
        let mealsForDate = getLoggedMealsForDate(date)
        return mealsForDate.reduce(0) { total, meal in
            total + meal.calories
        }
    }
    
    func deleteMeal(withId id: UUID) {
        Task {
            await deleteMealFromDatabase(id: id)
        }
    }
    
    func refreshMeals() {
        Task {
            await loadLoggedMeals()
        }
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func notifyStreakService(mealType: String?, loggedDate: Date) async {
        // Notify StreakService that a meal was logged
        // This counts towards the daily streak
        let streakService = StreakService.shared
        
        if let mealType = mealType {
            // For meal replacements (breakfast/lunch/dinner), mark as completed
            do {
                try await streakService.markMeal(date: loggedDate, mealType: mealType, as: .ateSimilar)
                print("✅ Marked \(mealType) as logged in streak service for \(loggedDate)")
            } catch {
                print("❌ Failed to mark \(mealType) in streak service: \(error)")
            }
        } else {
            // For extra meals, we need a different approach
            // We'll create a general "logged_meal" completion
            do {
                try await streakService.markMeal(date: loggedDate, mealType: "logged_meal", as: .ateSimilar)
                print("✅ Marked extra meal as logged in streak service for \(loggedDate)")
            } catch {
                print("❌ Failed to mark extra meal in streak service: \(error)")
            }
        }
    }
    
    @MainActor
    private func saveMealToDatabase(from analysisResult: MealAnalysisResult, image: UIImage?, mealType: String? = nil, loggedDate: Date) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get current user
            let user = try await supabase.auth.user()
            let userId = user.id
            
            var imageUrl: String? = nil
            
            // Upload image if provided
            if let image = image, let imageData = image.jpegData(compressionQuality: 0.8) {
                imageUrl = try await uploadMealImage(imageData: imageData, mealId: UUID())
            }
            
            // Create meal insert data
            let mealInsert = MealInsertData(
                userId: userId.uuidString,
                mealName: analysisResult.mealName,
                description: analysisResult.description,
                calories: analysisResult.calories,
                protein: analysisResult.macros.protein,
                carbohydrates: analysisResult.macros.carbohydrates,
                fat: analysisResult.macros.fat,
                fiber: analysisResult.macros.fiber,
                sugar: analysisResult.macros.sugar,
                sodium: analysisResult.macros.sodium,
                healthScore: analysisResult.healthScore,
                imageUrl: imageUrl,
                mealType: mealType,
                loggedAt: ISO8601DateFormatter().string(from: loggedDate)
            )
            
            // Insert into database
            let response: DatabaseLoggedMeal = try await supabase
                .from("logged_meals")
                .insert(mealInsert)
                .select()
                .single()
                .execute()
                .value
            
            // Add to local array
            let newLoggedMeal = response.toLoggedMeal()
            loggedMeals.insert(newLoggedMeal, at: 0)
            
            print("✅ Logged meal saved to database: \(newLoggedMeal.mealName)")
            
        } catch {
            print("❌ Failed to save logged meal: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    private func loadLoggedMeals() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get current user
            let user = try await supabase.auth.user()
            let userId = user.id
            
            // Fetch logged meals from database
            let response: [DatabaseLoggedMeal] = try await supabase
                .from("logged_meals")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("logged_at", ascending: false)
                .execute()
                .value
            
            // Convert to LoggedMeal objects
            loggedMeals = response.map { $0.toLoggedMeal() }
            
            print("✅ Loaded \(loggedMeals.count) logged meals from database")
            
        } catch {
            print("❌ Failed to load logged meals: \(error)")
            errorMessage = error.localizedDescription
            loggedMeals = []
        }
        
        isLoading = false
    }
    
    @MainActor
    private func deleteMealFromDatabase(id: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Delete from database
            try await supabase
                .from("logged_meals")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
            
            // Remove from local array
            loggedMeals.removeAll { $0.id == id }
            
            print("✅ Deleted logged meal from database")
            
        } catch {
            print("❌ Failed to delete logged meal: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func uploadMealImage(imageData: Data, mealId: UUID) async throws -> String {
        let fileName = "logged_meals/\(mealId.uuidString).jpg"
        
        try await supabase.storage
            .from("meal-images")
            .upload(path: fileName, file: imageData, options: FileOptions(contentType: "image/jpeg"))
        
        let url = try supabase.storage
            .from("meal-images")
            .getPublicURL(path: fileName)
        
        return url.absoluteString
    }
}
