import Foundation
import Supabase

@MainActor
class ExerciseService: ObservableObject {
    static let shared = ExerciseService()

    @Published var loggedExercises: [LoggedExercise] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase = SupabaseService.shared.client
    private let openAIService = OpenAIService.shared

    private init() {
        // Load exercises on initialization
        Task {
            await loadExercises()
        }
    }

    // MARK: - Analyze Exercise
    func analyzeExercise(description: String) async throws -> ExerciseAnalysisResult {
        print("🏃 Analyzing exercise: \(description)")

        let prompt = """
        Analyze the following exercise description and provide:
        1. A brief summary of the workout
        2. Estimated total calories burned
        3. List of individual exercises with duration and intensity

        Exercise description: \(description)

        Respond in JSON format:
        {
            "summary": "Brief summary of the workout",
            "caloriesBurned": estimated_total_calories_as_integer,
            "exercises": [
                {
                    "name": "Exercise name",
                    "duration": "Duration (e.g., 30 minutes)",
                    "intensity": "low/moderate/high"
                }
            ]
        }
        """

        do {
            let response = try await openAIService.analyzeExerciseText(description)
            print("🤖 AI Response: \(response)")

            // Parse JSON response
            guard let data = response.data(using: .utf8) else {
                throw NSError(domain: "ExerciseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert response to data"])
            }

            let analysisResult = try JSONDecoder().decode(ExerciseAnalysisResult.self, from: data)
            print("✅ Exercise analyzed: \(analysisResult.caloriesBurned) calories")

            return analysisResult
        } catch {
            print("❌ Error analyzing exercise: \(error)")
            throw error
        }
    }

    // MARK: - Log Exercise
    func logExercise(from analysisResult: ExerciseAnalysisResult, loggedDate: Date = Date()) {
        Task {
            await saveExerciseToDatabase(from: analysisResult, loggedDate: loggedDate)
        }
    }

    // MARK: - Save to Database
    private func saveExerciseToDatabase(from analysisResult: ExerciseAnalysisResult, loggedDate: Date) async {
        isLoading = true
        errorMessage = nil

        do {
            // Get current user
            let user = try await supabase.auth.user()
            let userId = user.id

            // Encode exercises to JSON string
            let exercisesData = try JSONEncoder().encode(analysisResult.exercises)
            guard let exercisesJSON = String(data: exercisesData, encoding: .utf8) else {
                throw NSError(domain: "ExerciseService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to encode exercises"])
            }

            // Create exercise insert data
            let exerciseInsert = ExerciseInsertData(
                userId: userId.uuidString,
                summary: analysisResult.summary,
                caloriesBurned: analysisResult.caloriesBurned,
                exercises: exercisesJSON,
                loggedAt: ISO8601DateFormatter().string(from: loggedDate)
            )

            // Insert into database
            let response: DatabaseLoggedExercise = try await supabase
                .from("logged_exercises")
                .insert(exerciseInsert)
                .select()
                .single()
                .execute()
                .value

            // Add to local array
            let newLoggedExercise = response.toLoggedExercise()
            loggedExercises.insert(newLoggedExercise, at: 0)

            print("✅ Exercise logged to database: \(newLoggedExercise.summary)")
            
            // Post notification to refresh UI
            NotificationCenter.default.post(name: NSNotification.Name("ExerciseLogged"), object: nil)

        } catch {
            print("❌ Failed to save exercise: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Load Exercises
    func loadExercises() async {
        do {
            let user = try await supabase.auth.user()
            let userId = user.id

            let response: [DatabaseLoggedExercise] = try await supabase
                .from("logged_exercises")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("logged_at", ascending: false)
                .execute()
                .value

            loggedExercises = response.map { $0.toLoggedExercise() }
            print("✅ Loaded \(loggedExercises.count) exercises")

        } catch {
            print("❌ Failed to load exercises: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Refresh Exercises
    func refreshExercises() {
        Task {
            await loadExercises()
        }
    }

    // MARK: - Get Exercises for Date
    func getExercisesForDate(_ date: Date) -> [LoggedExercise] {
        let calendar = Calendar.current
        return loggedExercises.filter { exercise in
            calendar.isDate(exercise.loggedAt, inSameDayAs: date)
        }
    }

    // MARK: - Get Total Calories Burned for Date
    func getTotalCaloriesBurnedForDate(_ date: Date) -> Int {
        return getExercisesForDate(date).reduce(0) { $0 + $1.caloriesBurned }
    }

    // MARK: - Delete Exercise
    func deleteExercise(_ exercise: LoggedExercise) async {
        do {
            try await supabase
                .from("logged_exercises")
                .delete()
                .eq("id", value: exercise.id.uuidString)
                .execute()

            // Remove from local array
            loggedExercises.removeAll { $0.id == exercise.id }

            print("✅ Exercise deleted: \(exercise.summary)")

        } catch {
            print("❌ Failed to delete exercise: \(error)")
            errorMessage = error.localizedDescription
        }
    }
}
