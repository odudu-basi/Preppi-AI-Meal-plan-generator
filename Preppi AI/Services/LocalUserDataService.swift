//
//  LocalUserDataService.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 7/25/25.
//

import Foundation
import Combine
import PostgREST
import Auth

class LocalUserDataService: ObservableObject {
    static let shared = LocalUserDataService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseService.shared
    private let userProfileKey = "user_profile_data" // Keeping for potential local backup
    
    private init() {}
    
    // MARK: - User Profile Operations
    
    func createUserProfile(_ userData: UserOnboardingData) async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            let profileData = UserProfileData(
                id: "local_user",
                userData: userData,
                createdAt: Date(),
                updatedAt: Date(),
                onboardingCompleted: true
            )
            
            let encodedData = try encoder.encode(profileData)
            UserDefaults.standard.set(encodedData, forKey: userProfileKey)
            
            print("✅ User profile successfully saved locally")
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to create user profile: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    func updateUserProfile(_ userData: UserOnboardingData) async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            // Get current user session
            let session = try await supabase.auth.session
            
            let userId = session.user.id
            let userEmail = session.user.email ?? ""
            
            // Create an encodable struct for database upsert
            let dbUpdates = UserProfileUpdate(
                userId: userId.uuidString,
                email: userEmail,
                name: userData.name,
                sex: userData.sex?.rawValue,
                age: userData.age,
                weight: userData.weight,
                height: userData.height,
                likesToCook: userData.likesToCook,
                cookingPreference: userData.cookingPreference?.rawValue,
                activityLevel: userData.activityLevel.rawValue,
                marketingSource: userData.marketingSource?.rawValue,
                motivations: Array(userData.motivations.map { $0.rawValue }),
                motivationOther: userData.motivationOther,
                challenges: Array(userData.challenges.map { $0.rawValue }),
                healthGoals: userData.healthGoals.map { $0.rawValue },
                dietaryRestrictions: Array(userData.dietaryRestrictions.map { $0.rawValue }),
                foodAllergies: Array(userData.foodAllergies.map { $0.rawValue }),
                weeklyBudget: userData.weeklyBudget,
                onboardingCompleted: true,
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
            
            // Use upsert with explicit conflict resolution on user_id column
            try await supabase.database
                .from("user_profiles")
                .upsert(dbUpdates, onConflict: "user_id")
                .execute()
            
            print("✅ User profile successfully saved to Supabase (upsert operation)")
            
            // Also update local backup
            await saveToLocalBackup(userData: userData, userId: userId.uuidString)
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to update user profile: \(error.localizedDescription)"
            }
            print("❌ Failed to update profile in Supabase: \(error)")
            throw error
        }
    }
    
    func fetchUserProfileData() async throws -> UserProfileData? {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            guard let data = UserDefaults.standard.data(forKey: userProfileKey) else {
                return nil
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let profileData = try decoder.decode(UserProfileData.self, from: data)
            
            print("✅ User profile data successfully loaded from local storage")
            return profileData
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to fetch user profile: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    func fetchUserProfile() async throws -> UserOnboardingData? {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            guard let data = UserDefaults.standard.data(forKey: userProfileKey) else {
                return nil
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let profileData = try decoder.decode(UserProfileData.self, from: data)
            
            // Profile found in local storage
            
            print("✅ User profile successfully loaded from local storage")
            return profileData.userData
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to fetch user profile: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    func deleteUserProfile() async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        UserDefaults.standard.removeObject(forKey: userProfileKey)
        print("✅ User profile successfully deleted from local storage")
    }
    
    // MARK: - Supabase Profile Checking
    
    func checkProfileExistsInSupabase() async throws -> UserOnboardingData? {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            // Get current user session
            let session = try await supabase.auth.session
            let userId = session.user.id
            
            print("🔍 Checking if profile exists in Supabase for user: \(userId.uuidString)")
            
            // Query Supabase for existing profile
            let response: [UserProfileSupabaseResponse] = try await supabase.database
                .from("user_profiles")
                .select("*")
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            
            if let profileData = response.first {
                print("✅ Found existing profile in Supabase")
                let userData = try convertSupabaseToUserData(profileData)
                
                // Also save to local backup for faster future access
                await saveToLocalBackup(userData: userData, userId: userId.uuidString)
                
                return userData
            } else {
                print("📝 No profile found in Supabase - user needs onboarding")
                return nil
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to check profile in Supabase: \(error.localizedDescription)"
            }
            print("❌ Failed to check profile in Supabase: \(error)")
            throw error
        }
    }
    
    // MARK: - Helper Methods
    
    func clearAllData() {
        UserDefaults.standard.removeObject(forKey: userProfileKey)
        print("🗑️ All local user data cleared")
    }
    
    // MARK: - Data Synchronization
    
    func syncProfileData() async throws -> UserOnboardingData {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            print("🔄 Starting profile data synchronization...")
            
            // Get data from both sources
            let supabaseData = try await checkProfileExistsInSupabase()
            let localData = try await fetchUserProfileData()
            
            switch (supabaseData, localData) {
            case (let supabase?, let local?):
                // Both exist - check for conflicts and resolve
                return try await resolveDataConflict(supabaseData: supabase, localData: local.userData)
                
            case (let supabase?, nil):
                // Only Supabase data exists - save locally
                print("📥 Supabase data found, no local data - syncing down")
                await saveToLocalBackup(userData: supabase, userId: try await getCurrentUserId())
                return supabase
                
            case (nil, let local?):
                // Only local data exists - upload to Supabase
                print("📤 Local data found, no Supabase data - syncing up")
                try await updateUserProfile(local.userData)
                return local.userData
                
            case (nil, nil):
                // No data anywhere - return empty state
                print("📝 No data found in either location")
                throw NSError(domain: "SyncError", code: 404, userInfo: [NSLocalizedDescriptionKey: "No profile data found"])
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to sync profile data: \(error.localizedDescription)"
            }
            print("❌ Profile sync failed: \(error)")
            throw error
        }
    }
    
    private func resolveDataConflict(supabaseData: UserOnboardingData, localData: UserOnboardingData) async throws -> UserOnboardingData {
        print("⚖️ Resolving data conflict between Supabase and local storage")
        
        // For now, prioritize Supabase as source of truth (can be enhanced later)
        // In future: could compare timestamps, ask user, or merge intelligently
        
        print("✅ Using Supabase data as authoritative source")
        
        // Update local storage with Supabase data
        await saveToLocalBackup(userData: supabaseData, userId: try await getCurrentUserId())
        
        return supabaseData
    }
    
    private func getCurrentUserId() async throws -> String {
        let session = try await supabase.auth.session
        return session.user.id.uuidString
    }
    
    func validateDataConsistency() async -> Bool {
        do {
            print("🔍 Validating data consistency between local and remote")
            
            let supabaseData = try await checkProfileExistsInSupabase()
            let localData = try await fetchUserProfileData()
            
            switch (supabaseData, localData) {
            case (let supabase?, let local?):
                // Compare key fields for consistency
                let isConsistent = supabase.name == local.userData.name &&
                                 supabase.age == local.userData.age &&
                                 supabase.weight == local.userData.weight &&
                                 supabase.height == local.userData.height
                
                print(isConsistent ? "✅ Data is consistent" : "⚠️ Data inconsistency detected")
                return isConsistent
                
            case (nil, nil):
                print("✅ No data in either location - consistent empty state")
                return true
                
            default:
                print("⚠️ Data exists in only one location - inconsistent")
                return false
            }
            
        } catch {
            print("❌ Failed to validate data consistency: \(error)")
            return false
        }
    }
    
    private func saveToLocalBackup(userData: UserOnboardingData, userId: String) async {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            let profileData = UserProfileData(
                id: userId,
                userData: userData,
                createdAt: Date(),
                updatedAt: Date(),
                onboardingCompleted: true
            )
            
            let encodedData = try encoder.encode(profileData)
            UserDefaults.standard.set(encodedData, forKey: userProfileKey)
            print("✅ Local backup saved")
        } catch {
            print("⚠️ Failed to save local backup: \(error)")
        }
    }
    
    private func fetchFromLocalBackup() async throws -> UserProfileData? {
        guard let data = UserDefaults.standard.data(forKey: userProfileKey) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let profileData = try decoder.decode(UserProfileData.self, from: data)
        print("✅ Loaded from local backup")
        return profileData
    }
    
    private func convertSupabaseToUserData(_ response: UserProfileSupabaseResponse) throws -> UserOnboardingData {
        var userData = UserOnboardingData()
        
        userData.name = response.name
        userData.age = response.age
        userData.weight = response.weight
        userData.height = response.height
        userData.likesToCook = response.likesToCook
        userData.motivationOther = response.motivationOther
        userData.weeklyBudget = response.weeklyBudget
        
        // Convert enum strings back to enums
        if let cookingPref = response.cookingPreference {
            userData.cookingPreference = CookingPreference(rawValue: cookingPref)
        }
        
        userData.activityLevel = ActivityLevel(rawValue: response.activityLevel) ?? .sedentary
        
        if let marketingSource = response.marketingSource {
            userData.marketingSource = MarketingSource(rawValue: marketingSource)
        }
        
        // Convert string arrays back to Sets/Arrays
        userData.motivations = Set(response.motivations.compactMap { Motivation(rawValue: $0) })
        userData.challenges = Set(response.challenges.compactMap { Challenge(rawValue: $0) })
        userData.healthGoals = response.healthGoals.compactMap { HealthGoal(rawValue: $0) }
        userData.dietaryRestrictions = Set(response.dietaryRestrictions.compactMap { DietaryRestriction(rawValue: $0) })
        userData.foodAllergies = Set(response.foodAllergies.compactMap { Allergy(rawValue: $0) })
        
        return userData
    }

    private func convertDatabaseToUserData(_ dict: [String: Any]) throws -> UserOnboardingData {
        var userData = UserOnboardingData()
        
        userData.name = dict["name"] as? String ?? ""
        userData.age = dict["age"] as? Int ?? 0
        userData.weight = dict["weight"] as? Double ?? 0.0
        userData.height = dict["height"] as? Int ?? 0
        userData.likesToCook = dict["likes_to_cook"] as? Bool
        userData.motivationOther = dict["motivation_other"] as? String ?? ""
        userData.weeklyBudget = dict["weekly_budget"] as? Double
        
        // Convert enum strings back to enums
        if let cookingPrefString = dict["cooking_preference"] as? String {
            userData.cookingPreference = CookingPreference(rawValue: cookingPrefString)
        }
        
        if let activityLevelString = dict["activity_level"] as? String {
            userData.activityLevel = ActivityLevel(rawValue: activityLevelString) ?? .sedentary
        }
        
        if let marketingSourceString = dict["marketing_source"] as? String {
            userData.marketingSource = MarketingSource(rawValue: marketingSourceString)
        }
        
        // Convert JSONB arrays back to Sets/Arrays
        if let motivationsArray = dict["motivations"] as? [String] {
            userData.motivations = Set(motivationsArray.compactMap { Motivation(rawValue: $0) })
        }
        
        if let challengesArray = dict["challenges"] as? [String] {
            userData.challenges = Set(challengesArray.compactMap { Challenge(rawValue: $0) })
        }
        
        if let healthGoalsArray = dict["health_goals"] as? [String] {
            userData.healthGoals = healthGoalsArray.compactMap { HealthGoal(rawValue: $0) }
        }
        
        if let dietaryRestrictionsArray = dict["dietary_restrictions"] as? [String] {
            userData.dietaryRestrictions = Set(dietaryRestrictionsArray.compactMap { DietaryRestriction(rawValue: $0) })
        }
        
        if let foodAllergiesArray = dict["food_allergies"] as? [String] {
            userData.foodAllergies = Set(foodAllergiesArray.compactMap { Allergy(rawValue: $0) })
        }
        
        return userData
    }
    
    private func parseDate(_ dateString: Any?) -> Date? {
        guard let dateStr = dateString as? String else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateStr)
    }
}

// MARK: - Local Storage Models

struct UserProfileData: Codable {
    let id: String
    let userData: UserOnboardingData
    let createdAt: Date
    let updatedAt: Date
    let onboardingCompleted: Bool
}

extension UserOnboardingData: Codable {
    enum CodingKeys: String, CodingKey {
        case name
        case sex
        case likesToCook
        case cookingPreference
        case marketingSource
        case motivations
        case motivationOther
        case challenges
        case healthGoals
        case age
        case weight
        case height
        case activityLevel
        case dietaryRestrictions
        case foodAllergies
        case weeklyBudget
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        sex = try container.decodeIfPresent(Sex.self, forKey: .sex)
        likesToCook = try container.decodeIfPresent(Bool.self, forKey: .likesToCook)
        cookingPreference = try container.decodeIfPresent(CookingPreference.self, forKey: .cookingPreference)
        marketingSource = try container.decodeIfPresent(MarketingSource.self, forKey: .marketingSource)
        motivations = Set(try container.decodeIfPresent([Motivation].self, forKey: .motivations) ?? [])
        motivationOther = try container.decodeIfPresent(String.self, forKey: .motivationOther) ?? ""
        challenges = Set(try container.decodeIfPresent([Challenge].self, forKey: .challenges) ?? [])
        healthGoals = try container.decode([HealthGoal].self, forKey: .healthGoals)
        age = try container.decode(Int.self, forKey: .age)
        weight = try container.decode(Double.self, forKey: .weight)
        height = try container.decode(Int.self, forKey: .height)
        activityLevel = try container.decode(ActivityLevel.self, forKey: .activityLevel)
        dietaryRestrictions = Set(try container.decode([DietaryRestriction].self, forKey: .dietaryRestrictions))
        foodAllergies = Set(try container.decode([Allergy].self, forKey: .foodAllergies))
        weeklyBudget = try container.decodeIfPresent(Double.self, forKey: .weeklyBudget)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(sex, forKey: .sex)
        try container.encodeIfPresent(likesToCook, forKey: .likesToCook)
        try container.encodeIfPresent(cookingPreference, forKey: .cookingPreference)
        try container.encodeIfPresent(marketingSource, forKey: .marketingSource)
        try container.encode(Array(motivations), forKey: .motivations)
        try container.encode(motivationOther, forKey: .motivationOther)
        try container.encode(Array(challenges), forKey: .challenges)
        try container.encode(healthGoals, forKey: .healthGoals)
        try container.encode(age, forKey: .age)
        try container.encode(weight, forKey: .weight)
        try container.encode(height, forKey: .height)
        try container.encode(activityLevel, forKey: .activityLevel)
        try container.encode(Array(dietaryRestrictions), forKey: .dietaryRestrictions)
        try container.encode(Array(foodAllergies), forKey: .foodAllergies)
        try container.encodeIfPresent(weeklyBudget, forKey: .weeklyBudget)
    }
}

// MARK: - Database Models

struct UserProfileSupabaseResponse: Codable {
    let id: String
    let userId: String
    let email: String
    let name: String
    let age: Int
    let weight: Double
    let height: Int
    let likesToCook: Bool?
    let cookingPreference: String?
    let activityLevel: String
    let marketingSource: String?
    let motivations: [String]
    let motivationOther: String
    let challenges: [String]
    let healthGoals: [String]
    let dietaryRestrictions: [String]
    let foodAllergies: [String]
    let weeklyBudget: Double?
    let onboardingCompleted: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case email
        case name
        case age
        case weight
        case height
        case likesToCook = "likes_to_cook"
        case cookingPreference = "cooking_preference"
        case activityLevel = "activity_level"
        case marketingSource = "marketing_source"
        case motivations
        case motivationOther = "motivation_other"
        case challenges
        case healthGoals = "health_goals"
        case dietaryRestrictions = "dietary_restrictions"
        case foodAllergies = "food_allergies"
        case weeklyBudget = "weekly_budget"
        case onboardingCompleted = "onboarding_completed"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct UserProfileUpdate: Codable {
    let userId: String
    let email: String
    let name: String
    let sex: String?
    let age: Int
    let weight: Double
    let height: Int
    let likesToCook: Bool?
    let cookingPreference: String?
    let activityLevel: String
    let marketingSource: String?
    let motivations: [String]
    let motivationOther: String
    let challenges: [String]
    let healthGoals: [String]
    let dietaryRestrictions: [String]
    let foodAllergies: [String]
    let weeklyBudget: Double?
    let onboardingCompleted: Bool
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case name
        case sex
        case age
        case weight
        case height
        case likesToCook = "likes_to_cook"
        case cookingPreference = "cooking_preference"
        case activityLevel = "activity_level"
        case marketingSource = "marketing_source"
        case motivations
        case motivationOther = "motivation_other"
        case challenges
        case healthGoals = "health_goals"
        case dietaryRestrictions = "dietary_restrictions"
        case foodAllergies = "food_allergies"
        case weeklyBudget = "weekly_budget"
        case onboardingCompleted = "onboarding_completed"
        case updatedAt = "updated_at"
    }
}