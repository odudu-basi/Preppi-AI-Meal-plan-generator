 import SwiftUI

struct MealPlanningView: View {
    @StateObject private var openAIService = OpenAIService.shared
    private let databaseService = MealPlanDatabaseService.shared
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    let selectedCuisines: [String]
    let mealPreparationStyle: MealPlanInfoView.MealPreparationStyle
    let mealCount: Int
    
    @State private var selectedDayIndex = 0
    @State private var mealPlan: [DayMeal] = []
    @State private var selectedMeal: DayMeal?
    @State private var showingShoppingList = false
    @State private var isSavingMealPlan = false
    @State private var showingSaveSuccess = false
    @State private var saveError: String?
    
    // Default initializer for existing navigation
    init(selectedCuisines: [String] = [], mealPreparationStyle: MealPlanInfoView.MealPreparationStyle = .newMealEveryTime, mealCount: Int = 3) {
        self.selectedCuisines = selectedCuisines
        self.mealPreparationStyle = mealPreparationStyle
        self.mealCount = mealCount
    }

    
    private let weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    private let weekdayIcons = ["🌟", "⚡", "🔥", "💪", "🎯", "🌈", "✨"]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if openAIService.isGenerating {
                generatingView
            } else if mealPlan.isEmpty {
                emptyStateView
            } else {
                mealPlanContent
            }
        }
        .navigationTitle("Your Meal Plan")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button("Regenerate") {
                        generateMealPlan()
                    }
                    .foregroundColor(.blue)
                    .disabled(openAIService.isGenerating)
                    
                    Button {
                        showingShoppingList = true
                    } label: {
                        Image(systemName: "cart.fill")
                            .font(.title3)
                            .foregroundColor(.green)
                    }
                    .disabled(mealPlan.isEmpty)
                }
            }
        }
        .onAppear {
            if mealPlan.isEmpty {
                generateMealPlan()
            }
        }
        .sheet(item: $selectedMeal) { meal in
            NavigationView {
                RecipePage(dayMeal: meal)
                    .environmentObject(appState)
            }
        }
        .sheet(isPresented: $showingShoppingList) {
            NavigationView {
                ShoppingListView()
            }
        }
        .alert("Error", isPresented: .constant(openAIService.errorMessage != nil)) {
            Button("OK") {
                openAIService.errorMessage = nil
            }
            Button("Retry") {
                generateMealPlan()
            }
        } message: {
            Text(openAIService.errorMessage ?? "")
        }
    }
    
    // MARK: - Generating View
    private var generatingView: some View {
        VStack(spacing: 30) {
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 8)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        AngularGradient(
                            colors: [.blue, .purple, .blue],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(
                        .linear(duration: 2).repeatForever(autoreverses: false),
                        value: openAIService.isGenerating
                    )
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 12) {
                Text("Creating Your Perfect Meal Plan")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Our AI chef is crafting personalized dinners based on your preferences...")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 30) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 12) {
                Text("Ready to Create Your Meal Plan?")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Tap the button below to generate 7 personalized dinner recipes just for you!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button {
                generateMealPlan()
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Generate Meal Plan")
                    Image(systemName: "sparkles")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .scaleEffect(openAIService.isGenerating ? 0.95 : 1.0)
            .animation(.spring(response: 0.3), value: openAIService.isGenerating)
        }
        .padding()
    }
    
    // MARK: - Meal Plan Content
    private var mealPlanContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Section
                headerSection
                
                // Day Selector
                daySelector
                
                // Current Meal Display
                if selectedDayIndex < mealPlan.count {
                    currentMealCard
                }
                
                // Accept Meal Plan Button
                acceptMealPlanButton
                
                // Bottom safe area spacing
                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 50))
                .foregroundColor(.green)
            
            Text("Your Weekly Meal Plan")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Personalized dinners crafted just for you")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    private var daySelector: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Select Day")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(selectedDayIndex + 1)/7")
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.1))
                    )
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
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
                .padding(.horizontal, 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    private var currentMealCard: some View {
        let dayMeal = mealPlan[selectedDayIndex]
        
        return VStack(spacing: 0) {
            // Header Section
            VStack(spacing: 16) {
                // Day badge with leftover indicator
                HStack {
                    Text(weekdayIcons[selectedDayIndex])
                        .font(.title)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dayMeal.day)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        
                        Text("Dinner Plan")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Leftover badge if applicable
                    if let originalDay = dayMeal.meal.originalCookingDay,
                       originalDay != dayMeal.day {
                        VStack(alignment: .trailing, spacing: 2) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption2)
                                Text("Leftovers")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.orange)
                            )
                            
                            Text("from \(originalDay)")
                                .font(.caption2)
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // Meal name
                Text(dayMeal.meal.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 24)
            }
            
            // Description
            Text(dayMeal.meal.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 12)
            
            // Stats Section
            VStack(spacing: 20) {
                HStack(spacing: 0) {
                    StatView(
                        icon: "flame.fill",
                        value: "\(dayMeal.meal.calories)",
                        label: "Calories",
                        color: .orange
                    )
                    .frame(maxWidth: .infinity)
                    
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(width: 1, height: 40)
                    
                    StatView(
                        icon: "clock.fill",
                        value: "\(dayMeal.meal.cookTime)",
                        label: "Minutes",
                        color: .green
                    )
                    .frame(maxWidth: .infinity)
                    
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(width: 1, height: 40)
                    
                    StatView(
                        icon: "list.bullet",
                        value: "\(dayMeal.meal.ingredients.count)",
                        label: "Ingredients",
                        color: .purple
                    )
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // View Full Recipe Button
                Button {
                    selectedMeal = dayMeal
                } label: {
                    HStack {
                        Image(systemName: "book.fill")
                        Text("View Full Recipe")
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
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Accept Meal Plan Button
    private var acceptMealPlanButton: some View {
        VStack(spacing: 16) {
            // Accept button description
            Text("Ready to start cooking?")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Accept this meal plan to save it to your weekly schedule")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                acceptMealPlan()
            } label: {
                HStack {
                    if isSavingMealPlan {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else if showingSaveSuccess {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "heart.fill")
                    }
                    
                    Text(isSavingMealPlan ? "Saving..." : showingSaveSuccess ? "Saved!" : "Accept This Meal Plan")
                    
                    if !isSavingMealPlan && !showingSaveSuccess {
                        Image(systemName: "arrow.right")
                    }
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: showingSaveSuccess ? [.green, .green] : isSavingMealPlan ? [.gray.opacity(0.6), .gray.opacity(0.4)] : [.green, .mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(
                    color: showingSaveSuccess ? .green.opacity(0.6) : isSavingMealPlan ? .clear : .green.opacity(0.4), 
                    radius: 12, 
                    x: 0, 
                    y: 6
                )
                .scaleEffect(showingSaveSuccess ? 1.02 : 1.0)
                .animation(.spring(response: 0.3), value: showingSaveSuccess)
                .animation(.easeInOut(duration: 0.2), value: isSavingMealPlan)
            }
            .disabled(isSavingMealPlan)
            
            // Error message
            if let saveError = saveError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(saveError)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    private func acceptMealPlan() {
        Task {
            await MainActor.run {
                isSavingMealPlan = true
                saveError = nil
                showingSaveSuccess = false
            }
            
            do {
                let mealPlanId = try await databaseService.saveMealPlan(
                    dayMeals: mealPlan,
                    selectedCuisines: selectedCuisines,
                    mealPreparationStyle: mealPreparationStyle,
                    mealCount: mealCount
                )
                
                await MainActor.run {
                    isSavingMealPlan = false
                    showingSaveSuccess = true
                    print("✅ Meal plan saved successfully with ID: \(mealPlanId)")
                }
                
                // Auto-dismiss success message after 2 seconds, then navigate back
                try await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    showingSaveSuccess = false
                    // Trigger dismissal of entire meal plan flow
                    appState.shouldDismissMealPlanFlow = true
                }
                
            } catch {
                await MainActor.run {
                    isSavingMealPlan = false
                    saveError = error.localizedDescription
                    print("❌ Error saving meal plan: \(error)")
                }
            }
        }
    }
    
    private func generateMealPlan() {
        Task {
            do {
                let generatedMeals = try await openAIService.generateMealPlan(
                    for: appState.userData,
                    cuisines: selectedCuisines,
                    preparationStyle: mealPreparationStyle,
                    mealCount: mealCount
                )
                await MainActor.run {
                    mealPlan = generatedMeals
                    selectedDayIndex = 0
                }
            } catch {
                print("❌ Error generating meal plan: \(error)")
            }
        }
    }
}

// MARK: - Supporting Views
struct DayButton: View {
    let day: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(icon)
                    .font(.system(size: 24))
                
                Text(String(day.prefix(3)))
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .frame(width: 70, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.green : Color(.systemGray6))
                    .shadow(
                        color: isSelected ? .green.opacity(0.3) : .black.opacity(0.05),
                        radius: isSelected ? 8 : 4,
                        x: 0,
                        y: isSelected ? 4 : 2
                    )
            )
            .foregroundColor(isSelected ? .white : .primary)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatView: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    MealPlanningView(
        selectedCuisines: ["Italian", "Mexican"], 
        mealPreparationStyle: .multiplePortions
    )
    .environmentObject(AppState())
}