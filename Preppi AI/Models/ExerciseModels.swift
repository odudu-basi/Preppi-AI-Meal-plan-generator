import Foundation

// MARK: - Exercise Analysis Result (from AI)
struct ExerciseAnalysisResult: Codable {
    let summary: String
    let caloriesBurned: Int
    let exercises: [ExerciseActivity]
}

// MARK: - Exercise Activity
struct ExerciseActivity: Codable {
    let name: String
    let duration: String
    let intensity: String
}

// MARK: - Logged Exercise
struct LoggedExercise: Identifiable, Codable {
    let id: UUID
    let userId: UUID?
    let summary: String
    let caloriesBurned: Int
    let exercises: [ExerciseActivity]
    let loggedAt: Date
    let createdAt: Date
    let updatedAt: Date

    init(from analysisResult: ExerciseAnalysisResult, userId: UUID? = nil, loggedDate: Date = Date()) {
        self.id = UUID()
        self.userId = userId
        self.summary = analysisResult.summary
        self.caloriesBurned = analysisResult.caloriesBurned
        self.exercises = analysisResult.exercises
        self.loggedAt = loggedDate
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // Database initializer
    init(id: UUID, userId: UUID?, summary: String, caloriesBurned: Int, exercises: [ExerciseActivity], loggedAt: Date, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.userId = userId
        self.summary = summary
        self.caloriesBurned = caloriesBurned
        self.exercises = exercises
        self.loggedAt = loggedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Database Logged Exercise Response
struct DatabaseLoggedExercise: Codable {
    let id: UUID
    let userId: UUID
    let summary: String
    let caloriesBurned: Int
    let exercises: String // JSON string
    let loggedAt: String // ISO8601 string from database
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case summary
        case caloriesBurned = "calories_burned"
        case exercises
        case loggedAt = "logged_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func toLoggedExercise() -> LoggedExercise {
        let dateFormatter = ISO8601DateFormatter()

        // Decode exercises JSON string
        var exerciseActivities: [ExerciseActivity] = []
        if let data = exercises.data(using: .utf8) {
            exerciseActivities = (try? JSONDecoder().decode([ExerciseActivity].self, from: data)) ?? []
        }

        return LoggedExercise(
            id: id,
            userId: userId,
            summary: summary,
            caloriesBurned: caloriesBurned,
            exercises: exerciseActivities,
            loggedAt: dateFormatter.date(from: loggedAt) ?? Date(),
            createdAt: dateFormatter.date(from: createdAt) ?? Date(),
            updatedAt: dateFormatter.date(from: updatedAt) ?? Date()
        )
    }
}

// MARK: - Exercise Insert Data (for database inserts)
struct ExerciseInsertData: Codable {
    let userId: String
    let summary: String
    let caloriesBurned: Int
    let exercises: String // JSON string
    let loggedAt: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case summary
        case caloriesBurned = "calories_burned"
        case exercises
        case loggedAt = "logged_at"
    }
}
