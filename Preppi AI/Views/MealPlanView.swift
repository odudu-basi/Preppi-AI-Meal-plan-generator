import SwiftUI

struct MealPlanView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedDate = Date()
    @State private var weekOffset = 0
    @Environment(\.colorScheme) var colorScheme

    // Meal plan state
    @State private var selectedBreakfastMeal: DayMeal?
    @State private var selectedLunchMeal: DayMeal?
    @State private var selectedDinnerMeal: DayMeal?
    @State private var isLoading = false
    @State private var showingMealPlanExistsAlert = false
    @State private var existingMealPlanWeek: String = ""
    @State private var existingMealPlanId: UUID?
    @State private var navigationPath = NavigationPath()

    // Shopping list and edit state
    @State private var showingShoppingList = false
    @State private var currentMealPlanId: UUID?
    @State private var breakfastMealPlanId: UUID?
    @State private var lunchMealPlanId: UUID?
    @State private var dinnerMealPlanId: UUID?
    @State private var showingMealEditPopup = false

    // Meal plan flow state
    @State private var showingMealPlanFlow = false
    @State private var mealPlanFlowData = MealPlanFlowData()
    @State private var currentFlowPage = 0 // 0: DayPicker, 1: Foods, 2: Specific Meals

    // Meal replacement state
    @State private var showingMealReplacement = false
    @State private var mealToReplace: DayMeal?
    @State private var mealTypeToReplace: String?

    // Performance optimization: Cache meal plans to avoid repeated database calls
    @State private var cachedMealPlans: [DatabaseMealPlan] = []
    @State private var lastMealPlansUpdate: Date = Date.distantPast
    @State private var cachedMealPlanDetails: [UUID: MealPlan] = [:] // Cache for full meal plan details
    @State private var lastMealPlanDetailsUpdate: [UUID: Date] = [:] // Track when each was last updated

    // Services
    private let databaseService = MealPlanDatabaseService.shared
    @StateObject private var loggedMealService = LoggedMealService.shared

    // Generate week days based on the current week offset
    private var weekDays: [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Sunday is first day

        let today = Date()
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today)!
        let weekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: weekInterval.start)!

        return (0..<7).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: weekStart)
        }
    }

    // Check if we can navigate to next week (prevent going beyond current week)
    private var canNavigateToNextWeek: Bool {
        let calendar = Calendar.current
        let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: Date())!.start
        let selectedWeekStart = calendar.dateInterval(of: .weekOfYear, for: weekDays[0])!.start

        return selectedWeekStart < currentWeekStart
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        Text("Meal Plan")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)

                        // Week navigation
                        HStack {
                            Button(action: {
                                weekOffset -= 1
                                // Update selected date to the same day of week in the previous week
                                let calendar = Calendar.current
                                if let newDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) {
                                    selectedDate = newDate
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                        .font(.caption)
                                    Text("Previous Week")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.primary)
                            }

                            Spacer()

                            Button(action: {
                                weekOffset += 1
                                // Update selected date to the same day of week in the next week
                                let calendar = Calendar.current
                                if let newDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) {
                                    selectedDate = newDate
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Text("Next Week")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                }
                                .foregroundColor(canNavigateToNextWeek ? .primary : .gray)
                            }
                            .disabled(!canNavigateToNextWeek)
                        }
                        .padding(.horizontal, 20)

                        // Simplified Day selector
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(weekDays, id: \.self) { date in
                                    SimpleDayCircle(
                                        date: date,
                                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                                        isToday: Calendar.current.isDate(date, inSameDayAs: Date()),
                                        action: {
                                            selectedDate = date
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .background(colorScheme == .dark ? Color.black : Color.white)

                    // Content area - Meal plans for selected date
                    ScrollView {
                        VStack(spacing: 20) {
                            // Meal plan sections
                            mealPlanContent

                            // Shopping list button
                            if currentMealPlanId != nil {
                                Button {
                                    showingShoppingList = true
                                } label: {
                                    HStack {
                                        Image(systemName: "cart.fill")
                                            .font(.title3)
                                        Text("View Shopping List")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.green)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.green, lineWidth: 2)
                                            .background(Color(.systemBackground))
                                    )
                                }
                                .padding(.top, 20)
                            }

                            // Bottom spacing for floating button
                            Color.clear.frame(height: 100)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    .background(colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground))
                }
                .background(colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground))

                // Floating edit button
                floatingEditButton
            }
            .navigationDestination(for: String.self) { destination in
                if destination == "MealPlanInfo" {
                    MealPlanInfoView()
                        .environmentObject(appState)
                }
            }
            .onChange(of: appState.shouldDismissMealPlanFlow) { oldValue, newValue in
                if newValue {
                    navigationPath = NavigationPath()
                    appState.shouldDismissMealPlanFlow = false
                    // Reset meal type to default
                    appState.currentMealTypeBeingCreated = "dinner"
                    appState.selectedMealTypes = ["dinner"]

                    // Invalidate cache when new meal plan is created
                    lastMealPlansUpdate = Date.distantPast

                    // Refresh the meal display after creating a new meal plan
                    loadMealPlans()
                }
            }
            .onChange(of: selectedDate) { oldValue, newValue in
                loadMealPlans()
                loggedMealService.refreshMeals()
            }
            .onAppear {
                loadMealPlans()
                loggedMealService.refreshMeals()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("MealPlanUpdated"))) { _ in
                // Refresh meal plans when a meal is replaced
                print("🔄 MealPlanView received meal plan updated notification - refreshing data")
                lastMealPlansUpdate = Date.distantPast
                loadMealPlans()
            }
            .alert("Meal Plan Already Exists", isPresented: $showingMealPlanExistsAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Replace", role: .destructive) {
                    replaceExistingMealPlan()
                }
            } message: {
                Text("You already have a meal plan created during the week of \(existingMealPlanWeek). Only one meal plan per week is allowed. Would you like to replace it with a new one?")
            }
            .sheet(isPresented: $showingShoppingList) {
                if let mealPlanId = currentMealPlanId {
                    ShoppingListView(mealPlanId: mealPlanId, weekIdentifier: getWeekIdentifier(for: selectedDate))
                }
            }
            .sheet(isPresented: $showingMealEditPopup) {
                MealEditPopupView(
                    onEditBreakfast: {
                        showingMealEditPopup = false
                        checkAndCreateBreakfastMealPlan()
                    },
                    onEditLunch: {
                        showingMealEditPopup = false
                        checkAndCreateLunchMealPlan()
                    },
                    onEditDinner: {
                        showingMealEditPopup = false
                        checkAndCreateDinnerMealPlan()
                    }
                )
            }
            .fullScreenCover(isPresented: $showingMealPlanFlow) {
                mealPlanFlowNavigation
            }
            .sheet(isPresented: $showingMealReplacement) {
                if let meal = mealToReplace, let type = mealTypeToReplace {
                    MealReplacementInputView(
                        originalMeal: meal,
                        mealType: type,
                        selectedDate: selectedDate,
                        onReplace: { newMeal in
                            replaceMeal(oldMeal: meal, newMeal: newMeal, mealType: type)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Meal Plan Flow Navigation
    @ViewBuilder
    private var mealPlanFlowNavigation: some View {
        NavigationStack {
            Group {
                switch currentFlowPage {
                case 0:
                    DayPickerView(flowData: $mealPlanFlowData) {
                        // Move to next page
                        currentFlowPage = 1
                    }
                case 1:
                    AvailableFoodsSelectionView(flowData: $mealPlanFlowData) {
                        // Move to next page
                        currentFlowPage = 2
                    }
                case 2:
                    SpecificMealsRequestView(flowData: $mealPlanFlowData) {
                        // Save the flow data and proceed to meal customization
                        saveMealPlanFlowData()
                        showingMealPlanFlow = false
                        currentFlowPage = 0

                        // Navigate to meal customization
                        navigationPath.append("MealPlanInfo")
                    }
                default:
                    EmptyView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if currentFlowPage > 0 {
                        Button(action: {
                            // Go back to previous page
                            currentFlowPage -= 1
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Back")
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingMealPlanFlow = false
                        currentFlowPage = 0
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }

    // MARK: - Floating Edit Button
    private var floatingEditButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    showingMealEditPopup = true
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 56, height: 56)
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)

                        Image(systemName: "pencil")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Helper Functions
    private func saveMealPlanFlowData() {
        // Save the flow data to AppState
        print("💾 DEBUG: About to save meal plan flow data:")
        print("   - Selected Days: \(mealPlanFlowData.selectedDays)")
        print("   - Selected Days Count: \(mealPlanFlowData.selectedDays.count)")
        
        appState.saveMealPlanFlowData(mealPlanFlowData)
        print("💾 DEBUG: Saved meal plan flow data - ready for AI prompt generation")
    }

    private func getWeekIdentifier(for date: Date) -> String {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Sunday is first day

        let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: weekStart)
    }

    // MARK: - Meal Plan Content
    private var mealPlanContent: some View {
        VStack(spacing: 12) {
            // Breakfast section
            if let breakfastMeal = selectedBreakfastMeal {
                simplifiedMealCard(dayMeal: breakfastMeal, mealType: "breakfast")
            } else {
                addMealButton(mealType: "Breakfast", icon: "sunrise.fill", color: .orange)
            }

            // Lunch section
            if let lunchMeal = selectedLunchMeal {
                simplifiedMealCard(dayMeal: lunchMeal, mealType: "lunch")
            } else {
                addMealButton(mealType: "Lunch", icon: "sun.max.fill", color: .yellow)
            }

            // Dinner section
            if let dinnerMeal = selectedDinnerMeal {
                simplifiedMealCard(dayMeal: dinnerMeal, mealType: "dinner")
            } else {
                addMealButton(mealType: "Dinner", icon: "moon.fill", color: .purple)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Add Meal Button
    private func addMealButton(mealType: String, icon: String, color: Color) -> some View {
        Button(action: {
            // Reset flow data for new meal plan
            mealPlanFlowData = MealPlanFlowData()
            currentFlowPage = 0

            // Set the meal type in app state
            appState.currentMealTypeBeingCreated = mealType.lowercased()
            appState.selectedMealTypes = [mealType.lowercased()]

            // Show the meal plan flow
            showingMealPlanFlow = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Add \(mealType)")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text("Create meal plan")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(color)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Meal Card View
    private func simplifiedMealCard(dayMeal: DayMeal, mealType: String) -> some View {
        // Check if meal is completed in StreakService (meal_completions table)
        let completedMeals = StreakService.shared.getCompletedMealsForDate(selectedDate)
        let isLogged = completedMeals.contains { $0.mealType.lowercased() == mealType.lowercased() }

        return VStack(spacing: 0) {
            // Main card content (tappable to navigate to detail)
            NavigationLink(destination: MealDetailView(dayMeal: dayMeal, mealType: mealType, selectedDate: selectedDate).environmentObject(appState)) {
                HStack(spacing: 16) {
                    // Meal image on the left
                    Group {
                        if let imageUrl = dayMeal.meal.imageUrl, let url = URL(string: imageUrl) {
                            // Remote image from database
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                    .scaleEffect(0.5)
                            }
                        } else {
                            // No image placeholder
                            Image(systemName: "fork.knife")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )

                    // Meal info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dayMeal.meal.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)

                        Text(mealType.capitalized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Calories (right side)
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(dayMeal.meal.calories)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)

                        Text("cal/serving")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Navigation arrow
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }

            // Divider
            Divider()
                .padding(.horizontal, 20)

            // Log Meal button (always visible)
            Button(action: {
                toggleMealLog(dayMeal: dayMeal, mealType: mealType)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: isLogged ? "xmark.circle.fill" : "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(isLogged ? .red : .green)

                    Text(isLogged ? "Cancel Log" : "Log Meal")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isLogged ? .red : .green)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isLogged ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Load Meal Plans
    private func loadMealPlans() {
        Task {
            isLoading = true
            do {
                // Performance optimization: Use cached meal plans if available and fresh
                let mealPlans: [DatabaseMealPlan]
                let now = Date()

                if now.timeIntervalSince(lastMealPlansUpdate) < 30 && !cachedMealPlans.isEmpty {
                    // Use cached data (cache is valid for 30 seconds)
                    mealPlans = cachedMealPlans
                    print("📦 Using cached meal plans")
                } else {
                    // Fetch fresh data and update cache
                    let freshMealPlans = try await databaseService.getUserMealPlans()
                    await MainActor.run {
                        cachedMealPlans = freshMealPlans
                        lastMealPlansUpdate = now
                    }
                    mealPlans = freshMealPlans
                    print("🔄 Fetched fresh meal plans")
                }

                // Find meal plans for the selected week
                let breakfastMealPlan = findBreakfastMealPlanForWeek(mealPlans, weekOf: selectedDate)
                let lunchMealPlan = findLunchMealPlanForWeek(mealPlans, weekOf: selectedDate)
                let dinnerMealPlan = findDinnerMealPlanForWeek(mealPlans, weekOf: selectedDate)

                // Helper function to get or fetch meal plan details with caching
                func getCachedOrFetchDetails(for mealPlan: DatabaseMealPlan?) async throws -> MealPlan? {
                    guard let mealPlan = mealPlan, let mealPlanId = mealPlan.id else { return nil }

                    // Check if we have a fresh cached version (valid for 5 minutes)
                    if let cachedDetails = await MainActor.run(body: { cachedMealPlanDetails[mealPlanId] }),
                       let lastUpdate = await MainActor.run(body: { lastMealPlanDetailsUpdate[mealPlanId] }),
                       now.timeIntervalSince(lastUpdate) < 300 {
                        print("📦 Using cached meal plan details for ID: \(mealPlanId)")
                        return cachedDetails
                    }

                    // Fetch fresh details and cache them
                    let freshDetails = try await databaseService.getMealPlanDetails(mealPlanId: mealPlanId)
                    await MainActor.run {
                        cachedMealPlanDetails[mealPlanId] = freshDetails
                        lastMealPlanDetailsUpdate[mealPlanId] = now
                    }
                    print("🔄 Fetched and cached fresh meal plan details for ID: \(mealPlanId)")
                    return freshDetails
                }

                // Fetch full meal plan details with caching
                let fullBreakfastMealPlan = try await getCachedOrFetchDetails(for: breakfastMealPlan)
                let fullLunchMealPlan = try await getCachedOrFetchDetails(for: lunchMealPlan)
                let fullDinnerMealPlan = try await getCachedOrFetchDetails(for: dinnerMealPlan)

                // Calculate day index for the selected date
                var calendar = Calendar.current
                calendar.firstWeekday = 1 // Sunday is first day
                let selectedWeekday = calendar.component(.weekday, from: selectedDate)
                let expectedDayIndex = selectedWeekday - 1 // Sunday=1 becomes index 0

                await MainActor.run {
                    // Get meals for the selected day
                    if let breakfastPlan = fullBreakfastMealPlan, expectedDayIndex < breakfastPlan.dayMeals.count {
                        selectedBreakfastMeal = breakfastPlan.dayMeals[expectedDayIndex]
                    } else {
                        selectedBreakfastMeal = nil
                    }

                    if let lunchPlan = fullLunchMealPlan, expectedDayIndex < lunchPlan.dayMeals.count {
                        selectedLunchMeal = lunchPlan.dayMeals[expectedDayIndex]
                    } else {
                        selectedLunchMeal = nil
                    }

                    if let dinnerPlan = fullDinnerMealPlan, expectedDayIndex < dinnerPlan.dayMeals.count {
                        selectedDinnerMeal = dinnerPlan.dayMeals[expectedDayIndex]
                    } else {
                        selectedDinnerMeal = nil
                    }

                    // Set meal plan IDs for shopping list and edit functionality
                    breakfastMealPlanId = breakfastMealPlan?.id
                    lunchMealPlanId = lunchMealPlan?.id
                    dinnerMealPlanId = dinnerMealPlan?.id

                    // Set currentMealPlanId to any available meal plan (prioritize dinner, then lunch, then breakfast)
                    currentMealPlanId = dinnerMealPlan?.id ?? lunchMealPlan?.id ?? breakfastMealPlan?.id

                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("❌ Error loading meal plans: \(error)")
                    selectedBreakfastMeal = nil
                    selectedLunchMeal = nil
                    selectedDinnerMeal = nil
                    isLoading = false
                }
            }
        }
    }

    // MARK: - Meal Plan Creation
    private func checkAndCreateBreakfastMealPlan() {
        Task {
            do {
                let mealPlans = try await databaseService.getUserMealPlans()
                let existingBreakfastPlan = findBreakfastMealPlanForWeek(mealPlans, weekOf: selectedDate)

                await MainActor.run {
                    appState.currentMealTypeBeingCreated = "breakfast"
                    appState.selectedMealTypes = ["breakfast"]

                    if let existingPlan = existingBreakfastPlan {
                        existingMealPlanId = existingPlan.id

                        var calendar = Calendar.current
                        calendar.firstWeekday = 1
                        let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
                        let formatter = DateFormatter()
                        formatter.dateFormat = "MMM d, yyyy"
                        existingMealPlanWeek = formatter.string(from: currentWeekStart)

                        showingMealPlanExistsAlert = true
                    } else {
                        navigationPath.append("MealPlanInfo")
                    }
                }
            } catch {
                await MainActor.run {
                    print("❌ Error checking existing breakfast meal plans: \(error)")
                    appState.currentMealTypeBeingCreated = "breakfast"
                    appState.selectedMealTypes = ["breakfast"]
                    navigationPath.append("MealPlanInfo")
                }
            }
        }
    }

    private func checkAndCreateLunchMealPlan() {
        Task {
            do {
                let mealPlans = try await databaseService.getUserMealPlans()
                let existingLunchPlan = findLunchMealPlanForWeek(mealPlans, weekOf: selectedDate)

                await MainActor.run {
                    appState.currentMealTypeBeingCreated = "lunch"
                    appState.selectedMealTypes = ["lunch"]

                    if let existingPlan = existingLunchPlan {
                        existingMealPlanId = existingPlan.id

                        var calendar = Calendar.current
                        calendar.firstWeekday = 1
                        let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
                        let formatter = DateFormatter()
                        formatter.dateFormat = "MMM d, yyyy"
                        existingMealPlanWeek = formatter.string(from: currentWeekStart)

                        showingMealPlanExistsAlert = true
                    } else {
                        navigationPath.append("MealPlanInfo")
                    }
                }
            } catch {
                await MainActor.run {
                    print("❌ Error checking existing lunch meal plans: \(error)")
                    appState.currentMealTypeBeingCreated = "lunch"
                    appState.selectedMealTypes = ["lunch"]
                    navigationPath.append("MealPlanInfo")
                }
            }
        }
    }

    private func checkAndCreateDinnerMealPlan() {
        Task {
            do {
                let mealPlans = try await databaseService.getUserMealPlans()
                let existingDinnerPlan = findDinnerMealPlanForWeek(mealPlans, weekOf: selectedDate)

                await MainActor.run {
                    appState.currentMealTypeBeingCreated = "dinner"
                    appState.selectedMealTypes = ["dinner"]

                    if let existingPlan = existingDinnerPlan {
                        existingMealPlanId = existingPlan.id

                        var calendar = Calendar.current
                        calendar.firstWeekday = 1
                        let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
                        let formatter = DateFormatter()
                        formatter.dateFormat = "MMM d, yyyy"
                        existingMealPlanWeek = formatter.string(from: currentWeekStart)

                        showingMealPlanExistsAlert = true
                    } else {
                        navigationPath.append("MealPlanInfo")
                    }
                }
            } catch {
                await MainActor.run {
                    print("❌ Error checking existing dinner meal plans: \(error)")
                    appState.currentMealTypeBeingCreated = "dinner"
                    appState.selectedMealTypes = ["dinner"]
                    navigationPath.append("MealPlanInfo")
                }
            }
        }
    }

    private func replaceExistingMealPlan() {
        Task {
            if let existingId = existingMealPlanId {
                do {
                    try await databaseService.deleteMealPlan(mealPlanId: existingId)
                    await MainActor.run {
                        // Invalidate cache after deleting meal plan
                        lastMealPlansUpdate = Date.distantPast

                        navigationPath.append("MealPlanInfo")
                        existingMealPlanId = nil
                    }
                } catch {
                    print("❌ Error deleting existing meal plan: \(error)")
                }
            }
        }
    }

    // MARK: - Helper Functions
    private func findBreakfastMealPlanForWeek(_ mealPlans: [DatabaseMealPlan], weekOf date: Date) -> DatabaseMealPlan? {
        return mealPlans.first { plan in
            mealPlanCreatedDuringWeek(plan, weekOf: date) && plan.mealPlanType == "breakfast"
        }
    }

    private func findLunchMealPlanForWeek(_ mealPlans: [DatabaseMealPlan], weekOf date: Date) -> DatabaseMealPlan? {
        return mealPlans.first { plan in
            mealPlanCreatedDuringWeek(plan, weekOf: date) && plan.mealPlanType == "lunch"
        }
    }

    private func findDinnerMealPlanForWeek(_ mealPlans: [DatabaseMealPlan], weekOf date: Date) -> DatabaseMealPlan? {
        return mealPlans.first { plan in
            mealPlanCreatedDuringWeek(plan, weekOf: date) && plan.mealPlanType == "dinner"
        }
    }

    private func mealPlanCreatedDuringWeek(_ mealPlan: DatabaseMealPlan, weekOf date: Date) -> Bool {
        guard mealPlan.isActive else { return false }

        // Parse the week_start_date string
        var mealPlanWeekStart: Date?

        // Try date-only format first (e.g., "2025-08-18")
        let dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
        dateOnlyFormatter.timeZone = TimeZone.current
        mealPlanWeekStart = dateOnlyFormatter.date(from: mealPlan.weekStartDate)

        // If that fails, try ISO8601 format
        if mealPlanWeekStart == nil {
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.timeZone = TimeZone.current
            mealPlanWeekStart = iso8601Formatter.date(from: mealPlan.weekStartDate)
        }

        guard let parsedWeekStart = mealPlanWeekStart else {
            print("⚠️ Could not parse week_start_date: \(mealPlan.weekStartDate)")
            return false
        }

        // Get the week start for the target date
        var calendar = Calendar.current
        calendar.firstWeekday = 1
        calendar.timeZone = TimeZone.current
        let targetWeekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date

        // Compare if they're in the same week
        return calendar.isDate(parsedWeekStart, inSameDayAs: targetWeekStart)
    }

    // MARK: - Toggle Meal Log
    private func toggleMealLog(dayMeal: DayMeal, mealType: String) {
        // Check if meal is already completed in StreakService
        let completedMeals = StreakService.shared.getCompletedMealsForDate(selectedDate)
        let isLogged = completedMeals.contains { $0.mealType.lowercased() == mealType.lowercased() }

        if isLogged {
            // Unlog the meal - remove from StreakService (meal_completions table)
            print("🗑️ DEBUG: Removing meal completion: \(dayMeal.meal.name) - \(mealType)")
            Task {
                do {
                    try await StreakService.shared.markMeal(date: selectedDate, mealType: mealType, as: .none)
                    print("✅ DEBUG: Removed meal completion from StreakService")
                } catch {
                    print("❌ DEBUG: Failed to remove meal completion from StreakService: \(error)")
                }
            }
        } else {
            // Log the meal - mark as completed in StreakService (meal_completions table)
            print("📝 DEBUG: toggleMealLog called - Logging meal from plan: \(dayMeal.meal.name) - \(mealType)")
            print("📝 DEBUG: Selected date: \(selectedDate)")
            
            Task {
                do {
                    try await StreakService.shared.markMeal(date: selectedDate, mealType: mealType, as: .ateExact)
                    print("✅ DEBUG: Marked meal as completed in StreakService")
                } catch {
                    print("❌ DEBUG: Failed to mark meal as completed: \(error)")
                }
            }
        }
    }

    // MARK: - Replace Meal
    private func replaceMeal(oldMeal: DayMeal, newMeal: DayMeal, mealType: String) {
        print("🔄 Replacing meal: \(oldMeal.meal.name) with \(newMeal.meal.name)")

        Task {
            do {
                // 1. Update the meal in the database
                try await databaseService.replaceMealInPlan(
                    date: selectedDate,
                    mealType: mealType,
                    newMeal: newMeal.meal
                )

                // 2. Update local state
                await MainActor.run {
                    switch mealType {
                    case "breakfast":
                        selectedBreakfastMeal = newMeal
                    case "lunch":
                        selectedLunchMeal = newMeal
                    case "dinner":
                        selectedDinnerMeal = newMeal
                    default:
                        break
                    }

                    // Close the replacement sheet
                    showingMealReplacement = false
                    mealToReplace = nil
                    mealTypeToReplace = nil
                }

                // 3. Update shopping list
                await updateShoppingListAfterReplacement(oldMeal: oldMeal, newMeal: newMeal)

                print("✅ Meal replaced successfully!")

            } catch {
                print("❌ Error replacing meal: \(error)")
                // TODO: Show error alert to user
            }
        }
    }

    // MARK: - Update Shopping List After Replacement
    private func updateShoppingListAfterReplacement(oldMeal: DayMeal, newMeal: DayMeal) async {
        print("🛒 Updating shopping list...")

        // Get old and new ingredients
        let oldIngredients = Set(oldMeal.meal.ingredients.map { $0.lowercased() })
        let newIngredients = Set(newMeal.meal.ingredients.map { $0.lowercased() })

        // Ingredients to remove (in old but not in new)
        let ingredientsToRemove = oldIngredients.subtracting(newIngredients)

        // Ingredients to add (in new but not in old)
        let ingredientsToAdd = newIngredients.subtracting(oldIngredients)

        print("📝 Removing \(ingredientsToRemove.count) ingredients, adding \(ingredientsToAdd.count) ingredients")

        // TODO: Implement actual shopping list update when shopping list service is available
        // For now, just log the changes
        if !ingredientsToRemove.isEmpty {
            print("🗑️ Remove from shopping list: \(ingredientsToRemove.joined(separator: ", "))")
        }
        if !ingredientsToAdd.isEmpty {
            print("➕ Add to shopping list: \(ingredientsToAdd.joined(separator: ", "))")
        }
    }
}

// Simplified day circle showing only first letter of day and date number
struct SimpleDayCircle: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let action: () -> Void

    // Get first letter of day name
    private var dayLetter: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE" // Single letter format
        return formatter.string(from: date).uppercased()
    }

    // Get day number
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dayLetter)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .secondary)

                Text(dayNumber)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 50, height: 70)
            .background(
                Circle()
                    .fill(isSelected ? Color.green : Color.clear)
                    .overlay(
                        Circle()
                            .stroke(
                                isToday && !isSelected ? Color.green : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MealPlanView()
        .environmentObject(AppState())
}
