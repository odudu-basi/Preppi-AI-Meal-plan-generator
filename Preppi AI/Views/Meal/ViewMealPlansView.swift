import SwiftUI

struct ViewMealPlansView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    private let databaseService = MealPlanDatabaseService.shared
    
    @State private var mealPlans: [DatabaseMealPlan] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingDeleteAlert = false
    @State private var mealPlanToDelete: DatabaseMealPlan?
    
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
                
                VStack(spacing: 0) {
                    if isLoading {
                        loadingView
                    } else if mealPlans.isEmpty {
                        emptyStateView
                    } else {
                        mealPlansList
                    }
                }
            }
            .navigationTitle("Your Meal Plans")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundColor(.green)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        loadMealPlans()
                    }
                    .foregroundColor(.green)
                }
            }
        }
        .onAppear {
            loadMealPlans()
        }
        .alert("Delete Meal Plan", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let mealPlan = mealPlanToDelete {
                    deleteMealPlan(mealPlan)
                }
            }
        } message: {
            Text("Are you sure you want to delete this meal plan? This action cannot be undone.")
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .green))
            
            Text("Loading your meal plans...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.green.opacity(0.6))
            
            VStack(spacing: 12) {
                Text("No Meal Plans Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Create your first meal plan to get started with your healthy eating journey!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button {
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Meal Plan")
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.green)
                )
                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Meal Plans List
    private var mealPlansList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(mealPlans, id: \.id) { mealPlan in
                    MealPlanCardView(
                        mealPlan: mealPlan,
                        onDelete: { 
                            mealPlanToDelete = mealPlan
                            showingDeleteAlert = true
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Helper Methods
    private func loadMealPlans() {
        Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
            
            do {
                let plans = try await databaseService.getUserMealPlans()
                await MainActor.run {
                    mealPlans = plans
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    print("❌ Error loading meal plans: \(error)")
                }
            }
        }
    }
    
    private func deleteMealPlan(_ mealPlan: DatabaseMealPlan) {
        guard let mealPlanId = mealPlan.id else { return }
        
        Task {
            do {
                try await databaseService.deleteMealPlan(mealPlanId: mealPlanId)
                await MainActor.run {
                    mealPlans.removeAll { $0.id == mealPlanId }
                    print("✅ Meal plan deleted successfully")
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    print("❌ Error deleting meal plan: \(error)")
                }
            }
        }
    }
}

// MARK: - Meal Plan Card View
struct MealPlanCardView: View {
    let mealPlan: DatabaseMealPlan
        let onDelete: () -> Void
    
    var body: some View {
        NavigationLink(destination: MealPlanDetailView(mealPlan: mealPlan)) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: mealPlan.mealPreparationStyle == "multiplePortions" ? "square.stack.3d.up.fill" : "sparkles")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(mealPlan.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text("Week of \(formatDate(mealPlan.weekStartDate))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Label("\(mealPlan.mealCount) meals", systemImage: "fork.knife")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        if mealPlan.isCompleted {
                            Label("Completed", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Label("Active", systemImage: "clock.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Spacer()
                
                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundColor(.red)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.1))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

// MARK: - Meal Plan Detail View
struct MealPlanDetailView: View {
    let mealPlan: DatabaseMealPlan
    @Environment(\.dismiss) private var dismiss
    
    private let databaseService = MealPlanDatabaseService.shared
    
    @State private var dayMeals: [DayMeal] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedDayIndex = 0
    @State private var generatingRecipeForMealId: UUID? = nil
    @EnvironmentObject var appState: AppState
    @StateObject private var openAIService = OpenAIService.shared
    
    private let weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    private let weekdayIcons = ["🌟", "⚡", "🔥", "💪", "🎯", "🌈", "✨"]
    
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
                
                VStack(spacing: 0) {
                    if isLoading {
                        loadingView
                    } else if dayMeals.isEmpty {
                        emptyView
                    } else {
                        mealPlanContent
                    }
                }
            }
            .navigationTitle(mealPlan.name)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            loadMealPlanDetails()
        }
        .alert("Recipe Generation Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .green))
            
            Text("Loading meal plan details...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Unable to load meal plan details")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("Try Again") {
                loadMealPlanDetails()
            }
            .foregroundColor(.green)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Meal Plan Content
    private var mealPlanContent: some View {
        VStack(spacing: 0) {
            // Meal Plan Info Header
            mealPlanInfoHeader
            
            // Day Selector
            daySelector
            
            // Meal Details
            if selectedDayIndex < dayMeals.count {
                mealDetailCard
            }
            
            Spacer()
        }
    }
    
    private var mealPlanInfoHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Week of \(formatDate(mealPlan.weekStartDate))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Label("\(mealPlan.mealCount) unique meals", systemImage: "fork.knife")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        Label(mealPlan.mealPreparationStyle == "multiplePortions" ? "Batch Cooking" : "Fresh Daily", 
                              systemImage: mealPlan.mealPreparationStyle == "multiplePortions" ? "square.stack.3d.up.fill" : "sparkles")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                VStack {
                    Image(systemName: mealPlan.isCompleted ? "checkmark.circle.fill" : "clock.fill")
                        .font(.title2)
                        .foregroundColor(mealPlan.isCompleted ? .green : .orange)
                    
                    Text(mealPlan.isCompleted ? "Completed" : "Active")
                        .font(.caption)
                        .foregroundColor(mealPlan.isCompleted ? .green : .orange)
                }
            }
            
            if !mealPlan.selectedCuisines.isEmpty {
                HStack {
                    Text("Cuisines: \(mealPlan.selectedCuisines.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    private var daySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<weekdays.count, id: \.self) { index in
                    DayButton(
                        day: weekdays[index],
                        icon: weekdayIcons[index],
                        isSelected: selectedDayIndex == index,
                        action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedDayIndex = index
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
    }
    
    private var mealDetailCard: some View {
        let dayMeal = dayMeals[selectedDayIndex]
        
        return ScrollView {
            VStack(spacing: 20) {
                // Meal header
                VStack(spacing: 16) {
                    Text(dayMeal.meal.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    // Show image if available, otherwise show description
                    if let imageUrl = dayMeal.meal.imageUrl, !imageUrl.isEmpty {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                                .cornerRadius(12)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                                .cornerRadius(12)
                                .overlay(
                                    ProgressView()
                                        .tint(.gray)
                                )
                        }
                    } else {
                        Text(dayMeal.meal.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Daily Calories Section
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "target")
                            .font(.title3)
                            .foregroundColor(.blue)
                        
                        Text("Daily Nutrition Goal")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Recommended calories before dinner")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 4) {
                                Text("\(dayMeal.meal.recommendedCaloriesBeforeDinner)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                
                                Text("calories")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Dinner calories")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 4) {
                                Text("\(dayMeal.meal.calories)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                                
                                Text("calories")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    
                    // Total daily calories
                    HStack {
                        Text("Total Daily Target:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Text("\(dayMeal.meal.recommendedCaloriesBeforeDinner + dayMeal.meal.calories)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            
                            Text("calories")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                )
                
                // Basic stats
                HStack(spacing: 20) {
                    Label("\(dayMeal.meal.cookTime) min", systemImage: "clock.fill")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    
                    if let originalDay = dayMeal.meal.originalCookingDay {
                        Label("From \(originalDay)", systemImage: "arrow.clockwise")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                }
                
                // View Recipes Button
                VStack(spacing: 12) {
                    let hasRecipe = hasDetailedRecipe(dayMeal.meal)
                    let _ = print("🔧 Button decision for \(dayMeal.meal.name) (ID: \(dayMeal.meal.id)): hasRecipe = \(hasRecipe), generating = \(generatingRecipeForMealId == dayMeal.meal.id)")
                    
                    if hasRecipe {
                        NavigationLink(destination: MealDetailedRecipeView(dayMeal: dayMeal)) {
                            HStack {
                                Image(systemName: "book.fill")
                                Text("View Recipes")
                            }
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    } else {
                        Button {
                            generateDetailedRecipe(for: dayMeal)
                        } label: {
                            HStack {
                                if generatingRecipeForMealId == dayMeal.meal.id {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text("Generating...")
                                } else {
                                    Image(systemName: "fork.knife")
                                    Text("View Recipes")
                                }
                            }
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(generatingRecipeForMealId == dayMeal.meal.id)
                    }
                }
                
                // Ingredients
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "list.bullet")
                            .foregroundColor(.green)
                        Text("Ingredients")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(dayMeal.meal.ingredients, id: \.self) { ingredient in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(.green)
                                    .fontWeight(.bold)
                                Text(ingredient)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6).opacity(0.5))
                )
                
                // Instructions
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "list.number")
                            .foregroundColor(.green)
                        Text("Instructions")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(dayMeal.meal.instructions.enumerated()), id: \.offset) { index, instruction in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Circle().fill(Color.green))
                                
                                Text(instruction)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6).opacity(0.5))
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Helper Methods
    private func loadMealPlanDetails() {
        guard let mealPlanId = mealPlan.id else {
            errorMessage = "Invalid meal plan ID"
            return
        }
        
        Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
            
            do {
                print("🔄 Loading meal plan details for ID: \(mealPlanId)")
                if let fullMealPlan = try await databaseService.getMealPlanDetails(mealPlanId: mealPlanId) {
                    await MainActor.run {
                        dayMeals = fullMealPlan.dayMeals.sorted { $0.dayIndex < $1.dayIndex }
                        isLoading = false
                        selectedDayIndex = 0
                        
                        // Debug: Print recipe data for each meal and check for duplicates
                        print("🔍 Loaded \(dayMeals.count) meals:")
                        
                        // Check for duplicate meal names
                        let mealNames = dayMeals.map { $0.meal.name }
                        let uniqueNames = Set(mealNames)
                        if mealNames.count != uniqueNames.count {
                            print("⚠️ WARNING: Found duplicate meal names!")
                        }
                        
                        for (index, dayMeal) in dayMeals.enumerated() {
                            print("📋 [\(index)] \(dayMeal.meal.name) (ID: \(dayMeal.meal.id))")
                            print("   - detailedIngredients: \(dayMeal.meal.detailedIngredients?.count ?? 0) items")
                            print("   - detailedInstructions: \(dayMeal.meal.detailedInstructions?.count ?? 0) items")
                            print("   - cookingTips: \(dayMeal.meal.cookingTips?.count ?? 0) items")
                            print("   - servingInfo: \(dayMeal.meal.servingInfo != nil ? "exists" : "nil")")
                            
                            // Check if this meal should have a recipe vs what we loaded
                            let shouldHaveRecipe = hasDetailedRecipe(dayMeal.meal)
                            print("   - hasRecipe calculated: \(shouldHaveRecipe)")
                            
                            if !shouldHaveRecipe && (dayMeal.meal.detailedIngredients?.count ?? 0) > 0 {
                                print("   ⚠️ ISSUE: Raw data shows \(dayMeal.meal.detailedIngredients?.count ?? 0) ingredients but hasDetailedRecipe returns false!")
                                print("   - Raw ingredients: \(dayMeal.meal.detailedIngredients ?? [])")
                                print("   - Raw instructions: \(dayMeal.meal.detailedInstructions ?? [])")
                            }
                            
                            // Check for duplicate names with different IDs
                            let duplicates = dayMeals.enumerated().filter { $0.element.meal.name == dayMeal.meal.name && $0.offset != index }
                            if !duplicates.isEmpty {
                                print("   🚨 DUPLICATE NAME FOUND: This meal name appears at indices: \(duplicates.map { $0.offset })")
                                for dup in duplicates {
                                    print("      Duplicate at [\(dup.offset)]: ID \(dup.element.meal.id)")
                                }
                            }
                        }
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "Meal plan not found"
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    print("❌ Error loading meal plan details: \(error)")
                }
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .long
            return displayFormatter.string(from: date)
        }
        return dateString
    }
    
    private func hasDetailedRecipe(_ meal: Meal) -> Bool {
        // Check if we have the essential detailed recipe components
        let hasIngredients = meal.detailedIngredients != nil && !meal.detailedIngredients!.isEmpty
        let hasInstructions = meal.detailedInstructions != nil && !meal.detailedInstructions!.isEmpty
        let hasTips = meal.cookingTips != nil && !meal.cookingTips!.isEmpty
        let hasServingInfo = meal.servingInfo != nil && !meal.servingInfo!.isEmpty
        
        let hasRecipe = hasIngredients && hasInstructions
        
        print("🔍 Checking recipe for \(meal.name) (ID: \(meal.id)):")
        print("   - detailedIngredients: \(meal.detailedIngredients?.count ?? 0) items (hasIngredients: \(hasIngredients))")
        print("   - detailedInstructions: \(meal.detailedInstructions?.count ?? 0) items (hasInstructions: \(hasInstructions))") 
        print("   - cookingTips: \(meal.cookingTips?.count ?? 0) items (hasTips: \(hasTips))")
        print("   - servingInfo: \(meal.servingInfo != nil ? "exists" : "nil") (hasServingInfo: \(hasServingInfo))")
        print("   - hasRecipe (ingredients + instructions): \(hasRecipe)")
        print("   - Currently generating for meal ID: \(generatingRecipeForMealId?.uuidString ?? "none")")
        
        // Note: Meal IDs now properly match database IDs, so recipes should persist correctly
        
        return hasRecipe
    }
    
    private func generateDetailedRecipe(for dayMeal: DayMeal) {
        Task {
            await MainActor.run {
                generatingRecipeForMealId = dayMeal.meal.id
                print("🔄 Starting recipe generation for: \(dayMeal.meal.name) (ID: \(dayMeal.meal.id))")
            }
            
            do {
                let detailedRecipe = try await openAIService.generateDetailedRecipe(
                    for: dayMeal,
                    userData: appState.userData
                )
                
                print("✅ Recipe generated successfully")
                print("📝 Ingredients: \(detailedRecipe.detailedIngredients.count)")
                print("📝 Instructions: \(detailedRecipe.instructions.count)")
                
                // Check if recipe columns exist before updating
                print("🔍 Checking if recipe columns exist in database...")
                let columnsExist = try await databaseService.checkRecipeColumnsExist()
                
                if !columnsExist {
                    throw NSError(domain: "RecipeError", code: 1, userInfo: [
                        NSLocalizedDescriptionKey: "Recipe columns not found in database. Please run the migration in Supabase first."
                    ])
                }
                
                // Update the meal in the database
                print("💾 Updating database for meal ID: \(dayMeal.meal.id)")
                try await databaseService.updateMealDetailedRecipe(
                    mealId: dayMeal.meal.id, 
                    detailedRecipe: detailedRecipe
                )
                print("✅ Database updated successfully")
                
                // Update local state for this specific meal
                await MainActor.run {
                    print("🔍 Looking for meal ID \(dayMeal.meal.id) in dayMeals array...")
                    for (i, dm) in dayMeals.enumerated() {
                        print("   [\(i)] \(dm.meal.name) - ID: \(dm.meal.id)")
                    }
                    
                    if let index = dayMeals.firstIndex(where: { $0.meal.id == dayMeal.meal.id }) {
                        print("✅ Found meal at index \(index)")
                        let updatedMeal = Meal(
                            id: dayMeal.meal.id, // CRITICAL: Preserve the original database ID
                            name: dayMeal.meal.name,
                            description: dayMeal.meal.description,
                            calories: dayMeal.meal.calories,
                            cookTime: dayMeal.meal.cookTime,
                            ingredients: dayMeal.meal.ingredients,
                            instructions: dayMeal.meal.instructions,
                            originalCookingDay: dayMeal.meal.originalCookingDay,
                            imageUrl: dayMeal.meal.imageUrl,
                            recommendedCaloriesBeforeDinner: dayMeal.meal.recommendedCaloriesBeforeDinner,
                            detailedIngredients: detailedRecipe.detailedIngredients,
                            detailedInstructions: detailedRecipe.instructions,
                            cookingTips: detailedRecipe.cookingTips,
                            servingInfo: detailedRecipe.servingInfo
                        )
                        
                        dayMeals[index] = DayMeal(day: dayMeal.day, meal: updatedMeal)
                        print("✅ Local state updated for meal: \(dayMeal.meal.name)")
                    } else {
                        print("❌ Could not find meal with ID \(dayMeal.meal.id) in dayMeals array")
                        print("❌ This means we're trying to update a meal that doesn't exist in our current data!")
                        print("❌ Possible causes:")
                        print("   1. Duplicate meals with different IDs")
                        print("   2. Meal IDs changing between loads")
                        print("   3. Stale meal reference")
                    }
                    generatingRecipeForMealId = nil
                }
                
                print("✅ Successfully generated and saved detailed recipe for \(dayMeal.meal.name)")
                
                // Verify the button state should change after successful generation
                await MainActor.run {
                    if let updatedMeal = dayMeals.first(where: { $0.meal.id == dayMeal.meal.id })?.meal {
                        let nowHasRecipe = hasDetailedRecipe(updatedMeal)
                        print("🔄 After generation - Button should now show: \(nowHasRecipe ? "book icon (View)" : "fork icon (Generate)")")
                    }
                }
                
            } catch {
                await MainActor.run {
                    generatingRecipeForMealId = nil
                    errorMessage = "Failed to generate recipe for \(dayMeal.meal.name): \(error.localizedDescription)"
                }
                print("❌ Error generating detailed recipe for \(dayMeal.meal.name): \(error)")
            }
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    ViewMealPlansView()
        .environmentObject(AppState())
}