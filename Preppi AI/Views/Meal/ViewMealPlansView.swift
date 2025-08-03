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
    
    @State private var showingDetails = false
    
    var body: some View {
        Button {
            showingDetails = true
        } label: {
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
        .sheet(isPresented: $showingDetails) {
            MealPlanDetailView(mealPlan: mealPlan)
        }
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.green)
                }
            }
        }
        .onAppear {
            loadMealPlanDetails()
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
                VStack(spacing: 8) {
                    Text(dayMeal.meal.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(dayMeal.meal.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 20) {
                        Label("\(dayMeal.meal.calories) cal", systemImage: "flame.fill")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                        
                        Label("\(dayMeal.meal.cookTime) min", systemImage: "clock.fill")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        
                        if let originalDay = dayMeal.meal.originalCookingDay {
                            Label("From \(originalDay)", systemImage: "arrow.clockwise")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
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
                if let fullMealPlan = try await databaseService.getMealPlanDetails(mealPlanId: mealPlanId) {
                    await MainActor.run {
                        dayMeals = fullMealPlan.dayMeals.sorted { $0.dayIndex < $1.dayIndex }
                        isLoading = false
                        selectedDayIndex = 0
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