 import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    // Temporary state for editing - these won't affect the main app state until saved
    @State private var tempUserData: UserOnboardingData
    @State private var hasUnsavedChanges = false
    @State private var showingUnsavedAlert = false
    @State private var isSaving = false
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
    
    init(userData: UserOnboardingData) {
        _tempUserData = State(initialValue: userData)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    profileHeader
                    
                    // Name Section
                    nameSection
                    
                    // Cooking Preference Section
                    cookingPreferenceSection
                    
                    // Health Goals Section
                    healthGoalsSection
                    
                    // Physical Stats Section
                    physicalStatsSection
                    
                    // Dietary Restrictions Section
                    dietaryRestrictionsSection
                    
                    // Food Allergies Section
                    foodAllergiesSection
                    
                    // Budget Section
                    budgetSection
                    
                    // Save & Sign Out Buttons
                    signOutButtonSection
                    
                    // Delete Account Section
                    deleteAccountSection
                    
                    // Bottom safe area spacing
                    Color.clear.frame(height: 50)
                }
                .padding()
            }
        }
        .navigationTitle("Profile Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    handleCancel()
                }
                .foregroundColor(.blue)
            }
        }
        .onChange(of: tempUserData) {
            checkForChanges()
        }
        .alert("Unsaved Changes", isPresented: $showingUnsavedAlert) {
            Button("Discard Changes", role: .destructive) {
                dismiss()
            }
            Button("Keep Editing", role: .cancel) { }
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
        }
        .alert("Delete All Data", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Everything", role: .destructive) {
                deleteAllUserData()
            }
        } message: {
            Text("This will permanently delete all your profile data, preferences, and meal plans. This action cannot be undone.")
        }
        }
    }
    
    // MARK: - Header Section
    private var profileHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Edit Your Profile")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Update your preferences to get better meal recommendations")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Name Section
    private var nameSection: some View {
        ProfileSection(title: "Personal Information", icon: "person.fill") {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.headline)
                    
                    TextField("Enter your name", text: $tempUserData.name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                }
            }
        }
    }
    
    // MARK: - Cooking Preference Section
    private var cookingPreferenceSection: some View {
        ProfileSection(title: "Cooking Preference", icon: "fork.knife") {
            VStack(spacing: 12) {
                ForEach(CookingPreference.allCases) { preference in
                    HStack {
                        Text(preference.emoji)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(preference.rawValue)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        Image(systemName: tempUserData.cookingPreference == preference ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(tempUserData.cookingPreference == preference ? .blue : .gray)
                            .font(.title3)
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        tempUserData.cookingPreference = preference
                    }
                    
                    if preference != CookingPreference.allCases.last {
                        Divider()
                    }
                }
            }
        }
    }
    
    // MARK: - Health Goals Section
    private var healthGoalsSection: some View {
        ProfileSection(title: "Health Goals", icon: "heart.fill") {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                // Only show the 4 health goals from onboarding
                let onboardingHealthGoals: [HealthGoal] = [.loseWeight, .maintainWeight, .gainWeight, .improveHealth]
                ForEach(onboardingHealthGoals) { goal in
                    let isSelected = tempUserData.healthGoals.contains(goal)
                    
                    VStack(spacing: 8) {
                        Text(goal.emoji)
                            .font(.title2)
                        
                        Text(goal.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                            )
                    )
                    .onTapGesture {
                        if isSelected {
                            tempUserData.healthGoals.removeAll { $0 == goal }
                        } else {
                            tempUserData.healthGoals.append(goal)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Physical Stats Section
    private var physicalStatsSection: some View {
        ProfileSection(title: "Physical Stats", icon: "figure.walk") {
            VStack(spacing: 20) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Age")
                            .font(.headline)
                        
                        TextField("Age", value: $tempUserData.age, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight (lbs)")
                            .font(.headline)
                        
                        TextField("Weight", value: $tempUserData.weight, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Height (inches)")
                        .font(.headline)
                    
                    TextField("Height", value: $tempUserData.height, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Activity Level")
                        .font(.headline)
                    
                    ForEach(ActivityLevel.allCases) { level in
                        HStack {
                            Text(level.emoji)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(level.rawValue)
                                    .font(.body)
                                    .fontWeight(.medium)
                                
                                Text(level.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: tempUserData.activityLevel == level ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(tempUserData.activityLevel == level ? .blue : .gray)
                                .font(.title3)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            tempUserData.activityLevel = level
                        }
                        
                        if level != ActivityLevel.allCases.last {
                            Divider()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Dietary Restrictions Section
    private var dietaryRestrictionsSection: some View {
        ProfileSection(title: "Dietary Restrictions", icon: "leaf.fill") {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(DietaryRestriction.allCases) { restriction in
                    let isSelected = tempUserData.dietaryRestrictions.contains(restriction)
                    
                    VStack(spacing: 8) {
                        Text(restriction.emoji)
                            .font(.title2)
                        
                        Text(restriction.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.green.opacity(0.2) : Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
                            )
                    )
                    .onTapGesture {
                        if isSelected {
                            tempUserData.dietaryRestrictions.remove(restriction)
                        } else {
                            tempUserData.dietaryRestrictions.insert(restriction)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Food Allergies Section
    private var foodAllergiesSection: some View {
        ProfileSection(title: "Food Allergies", icon: "exclamationmark.triangle.fill") {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Allergy.allCases) { allergy in
                    let isSelected = tempUserData.foodAllergies.contains(allergy)
                    
                    VStack(spacing: 8) {
                        Text(allergy.emoji)
                            .font(.title2)
                        
                        Text(allergy.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.red.opacity(0.2) : Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSelected ? Color.red : Color.clear, lineWidth: 2)
                            )
                    )
                    .onTapGesture {
                        if isSelected {
                            tempUserData.foodAllergies.remove(allergy)
                        } else {
                            tempUserData.foodAllergies.insert(allergy)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Budget Section
    private var budgetSection: some View {
        ProfileSection(title: "Weekly Budget", icon: "dollarsign.circle.fill") {
            VStack(alignment: .leading, spacing: 12) {
                Text("How much do you want to spend on groceries per week?")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("$")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    TextField("0", value: $tempUserData.weeklyBudget, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .font(.title2)
                }
            }
        }
    }
    
    // MARK: - Sign Out Button Section
    private var signOutButtonSection: some View {
        VStack(spacing: 16) {
            if hasUnsavedChanges {
                Text("You have unsaved changes")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            Button {
                saveChanges()
            } label: {
                HStack {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    
                    Text(isSaving ? "Saving..." : "Save Changes")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(hasUnsavedChanges ? Color.blue : Color.gray)
                )
            }
            .disabled(!hasUnsavedChanges || isSaving)
            
            // Sign Out Button
            Button {
                appState.signOut()
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red)
                )
            }
        }
    }
    
    // MARK: - Delete Account Section
    private var deleteAccountSection: some View {
        VStack(spacing: 16) {
            Text("Danger Zone")
                .font(.headline)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button {
                showingDeleteAlert = true
            } label: {
                HStack {
                    if isDeleting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "trash.fill")
                    }
                    
                    Text(isDeleting ? "Deleting..." : "Delete All Data")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red)
                )
            }
            .disabled(isDeleting)
            
            Text("This will permanently delete all your data and reset the app")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Helper Functions
    private func checkForChanges() {
        hasUnsavedChanges = tempUserData != appState.userData
    }
    
    private func handleCancel() {
        if hasUnsavedChanges {
            showingUnsavedAlert = true
        } else {
            dismiss()
        }
    }
    
    private func saveChanges() {
        isSaving = true
        
        Task {
            do {
                print("💾 Saving profile changes to Supabase...")
                await appState.updateProfile(with: tempUserData)
                await MainActor.run {
                    hasUnsavedChanges = false
                    isSaving = false
                    print("✅ Profile changes saved successfully!")
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    print("❌ Failed to save profile changes: \(error)")
                    // You could add an alert here to show the error to the user
                    appState.errorMessage = "Failed to save changes: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func deleteAllUserData() {
        isDeleting = true
        
        Task {
            do {
                // Delete from local storage
                try await LocalUserDataService.shared.deleteUserProfile()
                
                // Clear all local storage data
                LocalUserDataService.shared.clearAllData()
                
                await MainActor.run {
                    // Reset app state
                    appState.resetUserData()
                    
                    isDeleting = false
                    dismiss()
                    
                    print("🗑️ All user data deleted successfully")
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    print("❌ Failed to delete user data: \(error)")
                    // Could add error handling UI here if needed
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct ProfileSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

#Preview {
    let sampleData = UserOnboardingData()
    return ProfileView(userData: sampleData)
        .environmentObject(AppState())
}