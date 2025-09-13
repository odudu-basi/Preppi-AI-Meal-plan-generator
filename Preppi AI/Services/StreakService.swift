
import Supabase
import SwiftUI
import Combine

// MARK: - Streaks Configuration
// DayCompletionRule is defined in MealModels.swift

// MARK: - Streak Service
@MainActor
class StreakService: ObservableObject {
    static let shared = StreakService()
    
    // MARK: - Published Properties
    @Published var weekCompletions: [Date: [MealInstance]] = [:]
    @Published var dayIsComplete: [Date: Bool] = [:]
    @Published var currentStreak: Int = 0
    @Published var bestStreak: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Configuration
    private let DAY_COMPLETION_RULE: DayCompletionRule = .anyMeal // Per request
    
    // MARK: - Services
    private let supabaseService = SupabaseService.shared
    private let authService = AuthService.shared
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupAuthObserver()
    }
    
    // MARK: - Setup
    private func setupAuthObserver() {
        authService.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    self?.loadStreakData()
                } else {
                    self?.resetStreakData()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Mark a meal as completed for a specific date
    func markMeal(date: Date, mealType: String, as completion: MealCompletionType) async throws {
        guard let userId = authService.currentUser?.id else {
            throw StreakError.userNotAuthenticated
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let dateString = formatDateForDatabase(date)
            
            print("🔄 MARKING MEAL: Starting to mark \(mealType) as \(completion.rawValue) on \(dateString)")
            print("   - User ID: \(userId.uuidString)")
            print("   - Date object: \(date)")
            print("   - Formatted date: \(dateString)")
            
            if completion == .none {
                // Delete the completion record if marking as not completed
                try await supabaseService.database
                    .from("meal_completions")
                    .delete()
                    .eq("user_id", value: userId.uuidString)
                    .eq("date", value: dateString)
                    .eq("meal_type", value: mealType)
                    .execute()
                
                print("✅ Meal completion deleted: \(mealType) on \(dateString)")
            } else {
                // Use upsert (insert with conflict resolution) to ensure data is saved
                let upsertData: [String: String] = [
                    "user_id": userId.uuidString,
                    "date": dateString,
                    "meal_type": mealType,
                    "completion": completion.rawValue,
                    "completed_at": ISO8601DateFormatter().string(from: Date())
                ]
                
                print("📝 Upserting meal completion:")
                print("   - Data: \(upsertData)")
                print("   - User ID: \(userId.uuidString)")
                print("   - Date: \(dateString)")
                print("   - Meal type: \(mealType)")
                
                // Use upsert with conflict resolution on the unique constraint
                let upsertResponse = try await supabaseService.database
                    .from("meal_completions")
                    .upsert(upsertData, onConflict: "user_id,date,meal_type")
                    .execute()
                
                print("✅ Meal completion upserted: \(mealType) on \(dateString) as \(completion.rawValue)")
                print("   - Upsert response: \(upsertResponse)")
                print("   - Upsert successful!")
            }
            
            // Update local state
            await updateLocalCompletions(date: date, mealType: mealType, completion: completion)
            
            // Recompute streak data
            recomputeStreakData()
            
            print("✅ Meal completion saved successfully:")
            print("   - Date: \(formatDateForDatabase(date))")
            print("   - Meal Type: \(mealType)")
            print("   - Completion: \(completion.rawValue)")
            print("   - User ID: \(userId.uuidString)")
            
            // Verify the data was actually saved to the database
            await verifyDatabaseSave(date: date, mealType: mealType, completion: completion)
            
        } catch {
            print("❌ Error marking meal completion: \(error)")
            print("   - Date: \(formatDateForDatabase(date))")
            print("   - Meal Type: \(mealType)")
            print("   - Completion: \(completion.rawValue)")
            print("   - User ID: \(userId.uuidString)")
            throw StreakError.databaseError(error.localizedDescription)
        }
    }
    
    /// Fetch completions for a specific week
    func fetchCompletions(for week: DateInterval) async throws -> [MealInstance] {
        guard let userId = authService.currentUser?.id else {
            throw StreakError.userNotAuthenticated
        }
        
        do {
            let startDate = formatDateForDatabase(week.start)
            let endDate = formatDateForDatabase(week.end)
            
            print("🔍 Fetching completions from \(startDate) to \(endDate) for user \(userId.uuidString)")
            print("   - Week start: \(week.start)")
            print("   - Week end: \(week.end)")
            print("   - Formatted start: \(startDate)")
            print("   - Formatted end: \(endDate)")
            
            let response: [DatabaseMealCompletion] = try await supabaseService.database
                .from("meal_completions")
                .select()
                .eq("user_id", value: userId.uuidString)
                .gte("date", value: startDate)
                .lte("date", value: endDate)
                .execute()
                .value
            
            let completions = response
            print("📊 Fetched \(completions.count) completions from database")
            
            // Log each completion for debugging
            for completion in completions {
                print("   - \(completion.date): \(completion.mealType) -> \(completion.completion)")
            }
            
            let mealInstances = completions.map { $0.toMealInstance() }
            print("📊 Converted to \(mealInstances.count) MealInstance objects:")
            for instance in mealInstances {
                print("   - \(instance.mealType) on \(instance.date): \(instance.completion)")
            }
            
            return mealInstances
            
        } catch {
            print("❌ Error fetching completions: \(error)")
            print("   - Start date: \(formatDateForDatabase(week.start))")
            print("   - End date: \(formatDateForDatabase(week.end))")
            print("   - User ID: \(userId.uuidString)")
            throw StreakError.databaseError(error.localizedDescription)
        }
    }
    
    /// Load streak data for the current user
    func loadStreakData() {
        // Always reload from database to ensure we have the latest data
        Task {
            await loadStreakDataAsync()
        }
    }
    
    /// Force refresh streak data from database
    func refreshStreakData() {
        Task {
            await loadStreakDataAsync()
        }
    }

    
    /// Verify that a meal completion was actually saved to the database
    private func verifyDatabaseSave(date: Date, mealType: String, completion: MealCompletionType) async {
        guard let userId = authService.currentUser?.id else { return }
        
        print("🔍 VERIFYING: Checking if meal completion was saved to database...")
        
        do {
            let dateString = formatDateForDatabase(date)
            
            let response: [DatabaseMealCompletion] = try await supabaseService.database
                .from("meal_completions")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("date", value: dateString)
                .eq("meal_type", value: mealType)
                .execute()
                .value
            
            if let savedCompletion = response.first {
                print("✅ VERIFICATION SUCCESS: Found saved completion in database:")
                print("   - Date: \(savedCompletion.date)")
                print("   - Meal Type: \(savedCompletion.mealType)")
                print("   - Completion: \(savedCompletion.completion)")
                print("   - Completed At: \(savedCompletion.completedAt ?? "nil")")
            } else {
                print("❌ VERIFICATION FAILED: No completion found in database after save!")
                print("   - Expected: \(mealType) on \(dateString) as \(completion.rawValue)")
                print("   - User ID: \(userId.uuidString)")
            }
            
        } catch {
            print("❌ VERIFICATION ERROR: \(error)")
        }
    }
    
    /// Reset streak data when user signs out
    func resetStreakData() {
        weekCompletions.removeAll()
        dayIsComplete.removeAll()
        currentStreak = 0
        bestStreak = 0
    }
    
    // MARK: - Private Methods
    
    private func loadStreakDataAsync() async {
        guard authService.isAuthenticated else { 
            print("🔒 Not authenticated, skipping streak data load")
            return 
        }
        
        print("🔄 Loading streak data from database...")
        print("   - Current local state before loading:")
        for (date, meals) in weekCompletions {
            print("     - \(date): \(meals.count) meals - \(meals.map { "\($0.mealType): \($0.completion)" })")
        }
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load completions for the current week and previous weeks (for streak calculation)
            let calendar = Calendar.current
            let today = Date()
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
            
            print("📅 Loading completions for week starting: \(weekStart)")
            
            // Load current week
            let currentWeek = DateInterval(start: weekStart, duration: 7 * 24 * 60 * 60)
            let currentWeekCompletions = try await fetchCompletions(for: currentWeek)
            print("📊 Current week completions: \(currentWeekCompletions.count)")
            
            // Load previous weeks for streak calculation (go back 30 days to be safe)
            let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today) ?? today
            let previousWeeks = DateInterval(start: thirtyDaysAgo, duration: 30 * 24 * 60 * 60)
            let previousCompletions = try await fetchCompletions(for: previousWeeks)
            print("📊 Previous weeks completions: \(previousCompletions.count)")
            
            // Check for overlap between current and previous weeks
            print("📅 Date ranges:")
            print("   - Current week: \(formatDateForDatabase(currentWeek.start)) to \(formatDateForDatabase(currentWeek.end))")
            print("   - Previous weeks: \(formatDateForDatabase(previousWeeks.start)) to \(formatDateForDatabase(previousWeeks.end))")
            print("   - Overlap: \(currentWeek.start < previousWeeks.end)")
            
            // Combine all completions and deduplicate
            let allCompletions = currentWeekCompletions + previousCompletions
            print("📊 Total completions loaded: \(allCompletions.count)")
            
            // Deduplicate completions based on date, meal type, and completion status
            var uniqueCompletions: [MealInstance] = []
            var seenKeys: Set<String> = []
            
            for completion in allCompletions {
                let key = "\(formatDateForDatabase(completion.date))_\(completion.mealType)_\(completion.completion.rawValue)"
                if !seenKeys.contains(key) {
                    seenKeys.insert(key)
                    uniqueCompletions.append(completion)
                } else {
                    print("🔄 Skipping duplicate: \(completion.mealType) on \(completion.date) as \(completion.completion.rawValue)")
                }
            }
            
            print("📊 After deduplication: \(uniqueCompletions.count) unique completions")
            
            // Update local state
            await MainActor.run {
                print("🔄 Updating local state with \(uniqueCompletions.count) unique completions...")
                print("   - Completions to add:")
                for completion in uniqueCompletions {
                    print("     - \(completion.mealType) on \(completion.date): \(completion.completion)")
                }
                
                updateWeekCompletions(from: uniqueCompletions)
                recomputeDayCompletions()
                recomputeStreakData()
                
                print("✅ Streak data loading completed successfully")
                print("   - Final local state:")
                for (date, meals) in weekCompletions {
                    print("     - Date \(date): \(meals.map { "\($0.mealType): \($0.completion)" })")
                }
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load streak data: \(error.localizedDescription)"
            }
            print("❌ Error loading streak data: \(error)")
        }
    }
    
    private func updateLocalCompletions(date: Date, mealType: String, completion: MealCompletionType) async {
        await MainActor.run {
            let normalizedDate = normalizeDate(date)
            
            // Update weekCompletions
            if weekCompletions[normalizedDate] == nil {
                weekCompletions[normalizedDate] = []
            }
            
            // Remove existing completion for this meal type if it exists
            weekCompletions[normalizedDate]?.removeAll { $0.mealType == mealType }
            
            // Add new completion if not .none
            if completion != .none {
                let mealInstance = MealInstance(
                    id: UUID(),
                    date: normalizedDate,
                    mealType: mealType,
                    completion: completion,
                    completedAt: Date()
                )
                weekCompletions[normalizedDate]?.append(mealInstance)
            }
            
            // Update day completion status
            recomputeDayCompletions()
        }
    }
    
    private func updateWeekCompletions(from completions: [MealInstance]) {
        print("🔄 Updating week completions from \(completions.count) completions")
        print("   - Before update: \(weekCompletions.count) dates in local state")
        
        // Clear existing data completely
        weekCompletions.removeAll()
        
        // Group completions by normalized date
        for completion in completions {
            let normalizedDate = normalizeDate(completion.date)
            if weekCompletions[normalizedDate] == nil {
                weekCompletions[normalizedDate] = []
            }
            weekCompletions[normalizedDate]?.append(completion)
        }
        
        print("   - After update: \(weekCompletions.count) dates in local state")
        for (date, meals) in weekCompletions {
            print("     - \(date): \(meals.count) meals - \(meals.map { "\($0.mealType): \($0.completion)" })")
        }
    }
    
    private func recomputeDayCompletions() {
        dayIsComplete.removeAll()
        
        for (date, meals) in weekCompletions {
            dayIsComplete[date] = computeDayCompletion(for: date, allMeals: meals)
        }
    }
    
    private func recomputeStreakData() {
        let (current, best) = computeCurrentAndBestStreak(days: Array(dayIsComplete.keys.map { DayStreakState(date: $0, isComplete: dayIsComplete[$0] ?? false) }))
        
        currentStreak = current
        bestStreak = best
        
        // Debug logging
        print("🔥 Streak calculation:")
        print("   - Current streak: \(current)")
        print("   - Best streak: \(best)")
        print("   - Completed days: \(dayIsComplete.filter { $0.value }.keys.sorted())")
    }
    
    /// Compute whether a day is complete based on the completion rule
    private func computeDayCompletion(for date: Date, allMeals: [MealInstance]) -> Bool {
        let normalizedDate = normalizeDate(date)
        let mealsForDate = allMeals.filter { normalizeDate($0.date) == normalizedDate }
        
        switch DAY_COMPLETION_RULE {
        case .anyMeal:
            // Day is complete if at least one meal has completion != .none
            return mealsForDate.contains { $0.completion != .none }
            
        case .allMeals:
            // Day is complete only if all meals for that date have completion != .none
            // For now, we'll assume 3 meals per day (breakfast, lunch, dinner)
            let expectedMealTypes = ["breakfast", "lunch", "dinner"]
            let completedMealTypes = mealsForDate.compactMap { meal in
                meal.completion != .none ? meal.mealType : nil
            }
            
            // Day is complete if all expected meal types are completed
            return expectedMealTypes.allSatisfy { mealType in
                completedMealTypes.contains(mealType)
            }
        }
    }
    
    /// Compute current and best streak from day completion states
    private func computeCurrentAndBestStreak(days: [DayStreakState]) -> (current: Int, best: Int) {
        let calendar = Calendar.current
        let today = Date()
        let sortedDays = days.sorted { $0.date < $1.date }
        
        print("   🔥 Computing streaks for \(sortedDays.count) days:")
        for day in sortedDays {
            print("     - \(day.date): \(day.isComplete ? "✅" : "❌")")
        }
        
        var currentStreak = 0
        var bestStreak = 0
        var runningStreak = 0
        var lastCompletedDate: Date?
        
        // Calculate streaks - only count consecutive days
        for dayState in sortedDays {
            if dayState.isComplete {
                if let lastDate = lastCompletedDate {
                    // Check if this day is consecutive to the last completed day
                    if areConsecutiveDays(lastDate, dayState.date) {
                        // Consecutive day - continue streak
                        runningStreak += 1
                        print("   🔥 Consecutive day: \(dayState.date) - streak continues: \(runningStreak)")
                    } else {
                        // Non-consecutive day - start new streak
                        runningStreak = 1
                        print("   🔥 Non-consecutive day: \(dayState.date) - new streak starts: \(runningStreak)")
                    }
                } else {
                    // First completed day - start streak
                    runningStreak = 1
                    print("   🔥 First completed day: \(dayState.date) - streak starts: \(runningStreak)")
                }
                
                lastCompletedDate = dayState.date
                bestStreak = max(bestStreak, runningStreak)
            } else {
                // Day not complete - reset streak
                runningStreak = 0
                lastCompletedDate = nil
                print("   🔥 Day not complete: \(dayState.date) - streak reset")
            }
        }
        
        // Current streak is the running streak if today is complete, otherwise 0
        if let todayState = sortedDays.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            currentStreak = todayState.isComplete ? runningStreak : 0
        }
        
        return (current: currentStreak, best: bestStreak)
    }
    
    // MARK: - Helper Methods
    
    /// Normalize a date to midnight in the user's local timezone
    private func normalizeDate(_ date: Date) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let normalized = calendar.date(from: components) ?? date
        print("📅 Normalizing date: \(date) -> \(normalized)")
        return normalized
    }
    
    /// Format date for database (YYYY-MM-DD)
    private func formatDateForDatabase(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        let result = formatter.string(from: date)
        print("📅 Formatting date \(date) to database format: \(result)")
        return result
    }
    
    /// Check if two dates are consecutive calendar days
    private func areConsecutiveDays(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: date1, to: date2)
        return components.day == 1
    }
}

// MARK: - Database Models
private struct DatabaseMealCompletion: Codable {
    let id: UUID
    let userId: String
    let date: String
    let mealType: String
    let completion: String
    let completedAt: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case mealType = "meal_type"
        case completion
        case completedAt = "completed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    func toMealInstance() -> MealInstance {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        
        let parsedDate = dateFormatter.date(from: date) ?? Date()
        let completionType = MealCompletionType(rawValue: completion) ?? .none
        let completionDate = completedAt.flatMap { ISO8601DateFormatter().date(from: $0) }
        
        print("📅 Parsing database date '\(date)' to Date: \(parsedDate)")
        print("   - Original string: '\(date)'")
        print("   - Parsed date: \(parsedDate)")
        print("   - Timezone: \(TimeZone.current.identifier)")
        
        return MealInstance(
            id: id,
            date: parsedDate,
            mealType: mealType,
            completion: completionType,
            completedAt: completionDate
        )
    }
}

// MARK: - Errors
enum StreakError: LocalizedError {
    case userNotAuthenticated
    case databaseError(String)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        case .databaseError(let message):
            return "Database error: \(message)"
        case .invalidData:
            return "Invalid data"
        }
    }
}