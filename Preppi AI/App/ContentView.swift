//
//  ContentView.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 7/25/25.
//

import SwiftUI
import RevenueCat
import RevenueCatUI

struct PreppiLogo: View {
    var body: some View {
        VStack(spacing: 20) {
            // App Icon
            ZStack {
                // Shadow background
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.black.opacity(0.1))
                    .frame(width: 124, height: 124)
                    .offset(x: 2, y: 2)
                
                // App icon with rounded corners
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            
            // PREPPI text
            Text("PREPPI")
                .font(.system(size: 36, weight: .heavy, design: .default))
                .foregroundColor(.green)
                .tracking(4)
        }
    }
}

struct ContentView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        Group {
            if appState.showSplashScreen {
                // Show splash screen only on initial app launch
                SplashScreenView {
                    appState.showSplashScreen = false
                }
            } else if appState.shouldShowGetStarted {
                // Show get started page for new users
                GetStartedView()
                    .environmentObject(appState)
            } else if appState.shouldShowAuth {
                // Show authentication if not signed in
                SignInSignUpView()
                    .environmentObject(appState)
            } else if appState.shouldShowLoading {
                // Show loading state for general app loading or checking entitlements
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text(appState.isCheckingEntitlements ? "Verifying subscription..." : "Loading...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color("AppBackground"))
            } else if appState.shouldShowOnboarding {
                // Show onboarding if authenticated but not onboarded
                OnboardingView()
                    .environmentObject(appState)
            } else if appState.shouldShowPaywall {
                // Show paywall if authenticated and onboarded but no Pro access
                PaywallRequiredView()
                    .environmentObject(appState)
            } else if appState.canAccessMainApp {
                // Show main app if authenticated, onboarded, and has Pro access
                MainTabView()
                    .environmentObject(appState)
            } else {
                // Fallback loading state
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color("AppBackground"))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.4), value: appState.isOnboardingComplete)
        .animation(.easeInOut(duration: 0.4), value: appState.hasProAccess)
        .animation(.easeInOut(duration: 0.4), value: appState.isCheckingEntitlements)
        .onAppear {
            // Debug: Print current user info
            appState.printUserInfo()
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView {
            HomeView()
                .environmentObject(appState)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            SettingsView()
                .environmentObject(appState)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .accentColor(.green)
    }
}

// MARK: - Home View
struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingFounderUpdates = false
    @State private var navigationPath = NavigationPath()
    @State private var selectedDate = Date()
    @State private var weekOffset = 0
    @Environment(\.colorScheme) var colorScheme
    
    private let databaseService = MealPlanDatabaseService.shared
    @State private var dailyNutrition: DailyNutritionSummary?
    @State private var isLoading = false
    @State private var selectedDayMeal: DayMeal? // Dinner meal
    @State private var selectedBreakfastMeal: DayMeal? // Breakfast meal
    @State private var selectedLunchMeal: DayMeal? // Lunch meal
    @State private var showingMealPlanExistsAlert = false
    @State private var existingMealPlanWeek: String = ""
    @State private var existingMealPlanId: UUID? // ID of existing meal plan to be replaced
    @State private var showingShoppingList = false
    @State private var currentMealPlanId: UUID? // For shopping list (can be any meal plan)
    @State private var breakfastMealPlanId: UUID?
    @State private var lunchMealPlanId: UUID?
    @State private var dinnerMealPlanId: UUID?
    @State private var showingMealEditPopup = false
    
    // Performance optimization: Cache meal plans to avoid repeated database calls
    @State private var cachedMealPlans: [DatabaseMealPlan] = []
    @State private var lastMealPlansUpdate: Date = Date.distantPast
    
    // MARK: - Helper Functions
    
    /// Generate a week identifier from a given date (format: yyyy-MM-dd for week start)
    private func getWeekIdentifier(for date: Date) -> String {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Sunday is first day
        
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: weekStart)
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Subtle vertical gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("AppBackground"),
                        Color(.systemGray6).opacity(0.3)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Top section with logo
                        topSection
                        
                        // Week day selector
                        weekDaySelector
                        
                        // Daily plan summary
                        dailyPlanSummary
                        
                        // Action buttons
                        actionButtons
                        
                        // Bottom spacing
                        Color.clear.frame(height: 100)
                    }
                }
                
                // Floating pencil icon at bottom right
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
            .navigationBarHidden(true)
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "MealPlanInfo":
                    MealPlanInfoView()
                        .environmentObject(appState)
                case "ViewMealPlans":
                    ViewMealPlansView()
                        .environmentObject(appState)
                default:
                    EmptyView()
                }
            }

            .onChange(of: appState.shouldDismissMealPlanFlow) { shouldDismiss in
                if shouldDismiss {
                    navigationPath = NavigationPath()
                    appState.shouldDismissMealPlanFlow = false
                    // Reset meal type to default
                    appState.currentMealTypeBeingCreated = "dinner"
                    appState.selectedMealTypes = ["dinner"]
                    
                    // Invalidate cache when new meal plan is created
                    lastMealPlansUpdate = Date.distantPast
                    
                    // Refresh the meal display after creating a new meal plan
                    loadDailyNutrition()
                    loadSelectedDayMeal()
                }
            }
            .onAppear {
                loadDailyNutrition()
                loadSelectedDayMeal()
            }
            .onChange(of: selectedDate) { _ in
                loadDailyNutrition()
                loadSelectedDayMeal()
            }
        }
        .sheet(isPresented: $showingFounderUpdates) {
            FounderUpdatesView()
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
    }
    
    // MARK: - Top Section
    private var topSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: {
                    showingFounderUpdates = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                    Spacer()
                    
                // Centered PREPPI logo
                Text("PREPPI")
                    .font(.system(size: 28, weight: .heavy, design: .default))
                    .foregroundColor(.primary)
                    .tracking(2)
                
                Spacer()
                
                // Empty space for balance
                Image(systemName: "info.circle")
                    .font(.title2)
                    .foregroundColor(.clear)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }
    
    // MARK: - Week Day Selector
    private var weekDaySelector: some View {
        VStack(spacing: 12) {
            // Week navigation header
            HStack {
                Button(action: {
                    navigateToPreviousWeek()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.caption)
                        Text("Previous")
                            .font(.caption)
                    }
                    .foregroundColor(canNavigateToPreviousWeek ? .primary : .gray)
                }
                .disabled(!canNavigateToPreviousWeek)
                    
                    Spacer()
                    
                Text(weekRangeText)
                        .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    navigateToNextWeek()
                }) {
                    HStack(spacing: 4) {
                        Text("Next")
                            .font(.caption)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(canNavigateToNextWeek ? .primary : .gray)
                }
                .disabled(!canNavigateToNextWeek)
            }
            .padding(.horizontal, 20)
            
            // Day selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(weekDays, id: \.self) { date in
                        DayCircle(
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
            .padding(.bottom, 8)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Daily Plan Summary
    private var dailyPlanSummary: some View {
                    VStack(spacing: 20) {
            // Calories left card
            caloriesCard
            
            // Meal cards section
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
                if let dinnerMeal = selectedDayMeal {
                    simplifiedMealCard(dayMeal: dinnerMeal, mealType: "dinner")
                } else {
                    addMealButton(mealType: "Dinner", icon: "moon.fill", color: .purple)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Add Meal Button
    private func addMealButton(mealType: String, icon: String, color: Color) -> some View {
        Button(action: {
            // Track meal button tap in Mixpanel
            MixpanelService.shared.track(
                event: MixpanelService.Events.mealButtonTapped,
                properties: [
                    MixpanelService.Properties.mealType: mealType.lowercased(),
                    MixpanelService.Properties.source: "home_screen"
                ]
            )
            
            if mealType == "Breakfast" {
                checkAndCreateBreakfastMealPlan()
            } else if mealType == "Lunch" {
                checkAndCreateLunchMealPlan()
            } else if mealType == "Dinner" {
                checkAndCreateDinnerMealPlan()
            }
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
                    
                    Text("Tap to add \(mealType.lowercased()) to your day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                Image(systemName: "plus.circle")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                    .foregroundColor(.gray.opacity(0.6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    
    private var caloriesCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(totalCaloriesForSelectedDay)")
                    .font(.system(size: 48, weight: .bold, design: .default))
                    .foregroundColor(.primary)
                
                Text("Total calories")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Circular progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: CGFloat(caloriesProgress))
                    .stroke(
                        Color.orange,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Shopping list button (only show if there's a current meal plan)
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
                            .background(Color("AppBackground"))
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Helper Properties
    private var totalCaloriesForSelectedDay: Int {
        // Return the user's daily calorie goal based on their profile and goals
        return CalorieCalculationService.shared.calculateDailyCalorieGoal(for: appState.userData)
    }
    
    private var caloriesProgress: Double {
        let dailyGoal = Double(totalCaloriesForSelectedDay)
        var plannedCalories = 0.0
        
        // Add up calories from planned meals
        if let breakfastMeal = selectedBreakfastMeal {
            plannedCalories += Double(breakfastMeal.meal.calories)
        }
        
        if let lunchMeal = selectedLunchMeal {
            plannedCalories += Double(lunchMeal.meal.calories)
        }
        
        if let dinnerMeal = selectedDayMeal {
            plannedCalories += Double(dinnerMeal.meal.calories)
        }
        
        // Return progress as percentage of daily goal
        return dailyGoal > 0 ? min(plannedCalories / dailyGoal, 1.0) : 0.0
    }
    
    private var weekDays: [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Ensure Sunday is the first day (1 = Sunday)
        
        let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let selectedWeekStart = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        
        // Only allow current week or previous weeks
        let adjustedStart = selectedWeekStart <= currentWeekStart ? selectedWeekStart : currentWeekStart
        
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: adjustedStart)
        }
    }
    
    private var weekRangeText: String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start,
              let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else {
            return ""
        }
        
        let startString = formatter.string(from: startOfWeek)
        let endString = formatter.string(from: endOfWeek)
        
        return "\(startString) - \(endString)"
    }
    
    private var canNavigateToPreviousWeek: Bool {
        // Allow navigation to any previous week
        return true
    }
    
    private var canNavigateToNextWeek: Bool {
        let calendar = Calendar.current
        let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let selectedWeekStart = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        
        // Only allow navigation to current week, not future weeks
        return selectedWeekStart < currentWeekStart
    }
    
    // MARK: - Meal Card Views
    private func simplifiedMealCard(dayMeal: DayMeal, mealType: String) -> some View {
        NavigationLink(destination: MealDetailView(dayMeal: dayMeal, mealType: mealType).environmentObject(appState)) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dayMeal.meal.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(mealType.capitalized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(dayMeal.meal.calories)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text("calories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
    
    private func selectedDayMealCard(dayMeal: DayMeal, mealType: String = "dinner") -> some View {
        VStack(spacing: 20) {
            // Meal Header
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dayMeal.meal.name)
                                    .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Today's \(mealType.capitalized)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(dayMeal.meal.calories) cal")
                            .font(.headline)
                                    .fontWeight(.semibold)
                            .foregroundColor(.orange)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                            Text("\(dayMeal.meal.cookTime) min")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                // Meal image if available
                if let imageUrl = dayMeal.meal.imageUrl, !imageUrl.isEmpty {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 180)
                            .clipped()
                            .cornerRadius(12)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 180)
                            .cornerRadius(12)
                            .overlay(
                                ProgressView()
                                    .tint(.gray)
                            )
                    }
                }
                
                // Description
                Text(dayMeal.meal.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
            }
            
            // Daily Nutritional Breakdown
            if let macros = dayMeal.meal.macros {
                VStack(spacing: 12) {
                    HStack {
                        Text("Daily Nutritional Breakdown")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    HStack(spacing: 12) {
                        NutritionPillCard(
                            value: "\(dailyNutrition?.proteinLeft ?? 149)g",
                            label: "Protein left",
                            color: .red
                        )
                        
                        NutritionPillCard(
                            value: "\(dailyNutrition?.carbsLeft ?? 200)g",
                            label: "Carbs left",
                            color: .orange
                        )
                        
                        NutritionPillCard(
                            value: "\(dailyNutrition?.fatLeft ?? 51)g",
                            label: "Fat left",
                            color: .blue
                        )
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            
            // View recipe button
            NavigationLink(destination: MealDetailedRecipeView(dayMeal: dayMeal)) {
                HStack {
                    Image(systemName: "book.fill")
                        .font(.subheadline)
                    Text("View Recipe")
                        .font(.subheadline)
                        .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                .frame(height: 44)
                            .background(
                    RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.green)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    
    // MARK: - Helper Methods
    private func loadDailyNutrition() {
        isLoading = true
        
        Task {
            do {
                let nutrition = try await calculateDailyNutrition(for: selectedDate)
                await MainActor.run {
                    dailyNutrition = nutrition
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    dailyNutrition = DailyNutritionSummary.placeholder
                    isLoading = false
                    print("❌ Error loading daily nutrition: \(error)")
                }
            }
        }
    }
    
    private func calculateDailyNutrition(for date: Date) async throws -> DailyNutritionSummary {
        // Calculate user's daily calorie goal based on their stats
        let dailyCalorieGoal = calculateDailyCalorieGoal(userData: appState.userData)
        
        // Get meal plans for the selected date
        let mealPlans = try await databaseService.getUserMealPlans()
        
        // Find meals for the selected date
        var consumedCalories = 0
        var consumedProtein = 0.0
        var consumedCarbs = 0.0
        var consumedFat = 0.0
        
        // Calculate consumed nutrients (this would be from logged meals in a real app)
        // For now, we'll use placeholder logic
        
        let caloriesLeft = max(0, dailyCalorieGoal - consumedCalories)
        let proteinLeft = max(0.0, Double(dailyCalorieGoal) * 0.3 / 4 - consumedProtein) // 30% of calories from protein
        let carbsLeft = max(0.0, Double(dailyCalorieGoal) * 0.4 / 4 - consumedCarbs) // 40% from carbs
        let fatLeft = max(0.0, Double(dailyCalorieGoal) * 0.3 / 9 - consumedFat) // 30% from fat
        
        let progress = Double(consumedCalories) / Double(dailyCalorieGoal)
        
        return DailyNutritionSummary(
            caloriesLeft: caloriesLeft,
            proteinLeft: Int(proteinLeft),
            carbsLeft: Int(carbsLeft),
            fatLeft: Int(fatLeft),
            caloriesProgress: min(1.0, progress)
        )
    }
    
    // Calculate daily calorie goal using Mifflin-St Jeor Equation
    private func calculateDailyCalorieGoal(userData: UserOnboardingData) -> Int {
        // If user data is incomplete, return a default value
        guard userData.weight > 0, userData.height > 0, userData.age > 0 else {
            return 2000 // Default calorie goal
        }
        
        // Mifflin-St Jeor Equation for BMR
        // For males: BMR = (10 × weight in kg) + (6.25 × height in cm) - (5 × age in years) + 5
        // For females: BMR = (10 × weight in kg) + (6.25 × height in cm) - (5 × age in years) - 161
        // Note: We'll assume male for now since gender isn't in the model
        
        let weightInKg = userData.weight
        let heightInCm = Double(userData.height)
        let age = Double(userData.age)
        
        // Using male formula as default (can be updated when gender is added to model)
        let bmr = (10 * weightInKg) + (6.25 * heightInCm) - (5 * age) + 5
        
        // Apply activity level multiplier
        let activityMultiplier: Double = {
            switch userData.activityLevel {
            case .sedentary: return 1.2
            case .lightlyActive: return 1.375
            case .moderatelyActive: return 1.55
            case .veryActive: return 1.725
            case .extremelyActive: return 1.9
            }
        }()
        
        let dailyCalories = bmr * activityMultiplier
        
        // Adjust based on health goals
        let adjustedCalories: Double = {
            if userData.healthGoals.contains(.loseWeight) {
                return dailyCalories - 500 // 500 calorie deficit for weight loss
            } else if userData.healthGoals.contains(.gainWeight) {
                return dailyCalories + 500 // 500 calorie surplus for weight gain
            } else {
                return dailyCalories // Maintenance calories
            }
        }()
        
        return Int(adjustedCalories)
    }
    
    private func loadSelectedDayMeal() {
        Task {
            do {
                // Performance optimization: Use cached meal plans if available and fresh
                let mealPlans: [DatabaseMealPlan]
                let now = Date()
                
                if now.timeIntervalSince(lastMealPlansUpdate) < 30 && !cachedMealPlans.isEmpty {
                    // Use cached data (cache is valid for 30 seconds)
                    mealPlans = cachedMealPlans
                    print("🔄 Using cached meal plans (\(mealPlans.count) plans)")
                } else {
                    // Fetch fresh data and update cache
                    let freshMealPlans = try await databaseService.getUserMealPlans()
                    await MainActor.run {
                        cachedMealPlans = freshMealPlans
                        lastMealPlansUpdate = now
                    }
                    mealPlans = freshMealPlans
                    print("🔄 Fetched fresh meal plans (\(mealPlans.count) plans)")
                }
                
                // DEBUG: Print all meal plans with their types
                print("📋 DEBUG: All meal plans loaded:")
                for (index, plan) in mealPlans.enumerated() {
                    print("  [\(index)] \(plan.name) - Type: '\(plan.mealPlanType)' - Week: \(plan.weekStartDate) - ID: \(plan.id?.uuidString ?? "nil")")
                }
                
                // Find meal plan that was created during the week of the selected date
                let weekInterval = getWeekInterval(for: selectedDate)
                
                let selectedMealPlan = findMealPlanForWeek(mealPlans, weekOf: selectedDate)
                let mealPlanId = selectedMealPlan?.id
                
                // Calculate day index for both dinner and breakfast
                var calendar = Calendar.current
                calendar.firstWeekday = 1 // Ensure Sunday is the first day
                let selectedWeekday = calendar.component(.weekday, from: selectedDate)
                let expectedDayIndex = selectedWeekday - 1 // Sunday=1 becomes index 0, Monday=2 becomes index 1, etc.
                
                // Find meal plans for the same week
                print("🔍 DEBUG: Looking for meal plans for selected date: \(selectedDate)")
                print("🔍 DEBUG: Week interval: \(getWeekInterval(for: selectedDate))")
                
                let dinnerMealPlan = findDinnerMealPlanForWeek(mealPlans, weekOf: selectedDate)
                let breakfastMealPlan = findBreakfastMealPlanForWeek(mealPlans, weekOf: selectedDate)
                let lunchMealPlan = findLunchMealPlanForWeek(mealPlans, weekOf: selectedDate)
                
                print("🍽️ DEBUG: Found meal plans:")
                print("  - Breakfast: \(breakfastMealPlan?.name ?? "nil") (ID: \(breakfastMealPlan?.id?.uuidString ?? "nil"))")
                print("  - Lunch: \(lunchMealPlan?.name ?? "nil") (ID: \(lunchMealPlan?.id?.uuidString ?? "nil"))")
                print("  - Dinner: \(dinnerMealPlan?.name ?? "nil") (ID: \(dinnerMealPlan?.id?.uuidString ?? "nil"))")
                
                // Performance optimization: Fetch meal plan details in parallel
                async let dinnerDetails = dinnerMealPlan?.id != nil ? 
                    databaseService.getMealPlanDetails(mealPlanId: dinnerMealPlan!.id!) : nil
                async let breakfastDetails = breakfastMealPlan?.id != nil ? 
                    databaseService.getMealPlanDetails(mealPlanId: breakfastMealPlan!.id!) : nil
                async let lunchDetails = lunchMealPlan?.id != nil ? 
                    databaseService.getMealPlanDetails(mealPlanId: lunchMealPlan!.id!) : nil
                
                // Wait for all parallel operations to complete
                let (fullDinnerMealPlan, fullBreakfastMealPlan, fullLunchMealPlan) = 
                    try await (dinnerDetails, breakfastDetails, lunchDetails)
                
                // Process dinner meal
                var dayMeal: DayMeal? = nil
                var dinnerPlanId: UUID? = nil
                if let dinnerPlan = fullDinnerMealPlan {
                    print("🔍 DEBUG: Looking for dinner meal with expectedDayIndex: \(expectedDayIndex)")
                    for (index, dayMealItem) in dinnerPlan.dayMeals.enumerated() {
                        print("  📋 Meal \(index): day='\(dayMealItem.day)', dayIndex=\(dayMealItem.dayIndex), matches=\(dayMealItem.dayIndex == expectedDayIndex)")
                    }
                    dayMeal = dinnerPlan.dayMeals.first { dayMealItem in
                        dayMealItem.dayIndex == expectedDayIndex
                    }
                    dinnerPlanId = dinnerMealPlan?.id
                    print("🔍 DEBUG: Found dinner meal: \(dayMeal?.meal.name ?? "nil")")
                }
                
                // Process breakfast meal
                var breakfastMeal: DayMeal? = nil
                var breakfastPlanId: UUID? = nil
                if let breakfastPlan = fullBreakfastMealPlan {
                    print("🔍 DEBUG: Looking for breakfast meal with expectedDayIndex: \(expectedDayIndex)")
                    breakfastMeal = breakfastPlan.dayMeals.first { dayMeal in
                        dayMeal.dayIndex == expectedDayIndex
                    }
                    breakfastPlanId = breakfastMealPlan?.id
                    print("🔍 DEBUG: Found breakfast meal: \(breakfastMeal?.meal.name ?? "nil")")
                }
                
                // Process lunch meal
                var lunchMeal: DayMeal? = nil
                var lunchPlanId: UUID? = nil
                if let lunchPlan = fullLunchMealPlan {
                    print("🔍 DEBUG: Looking for lunch meal with expectedDayIndex: \(expectedDayIndex)")
                    lunchMeal = lunchPlan.dayMeals.first { dayMeal in
                        dayMeal.dayIndex == expectedDayIndex
                    }
                    lunchPlanId = lunchMealPlan?.id
                    print("🔍 DEBUG: Found lunch meal: \(lunchMeal?.meal.name ?? "nil")")
                }
                
                await MainActor.run {
                    selectedDayMeal = dayMeal
                    selectedBreakfastMeal = breakfastMeal
                    selectedLunchMeal = lunchMeal
                    breakfastMealPlanId = breakfastPlanId
                    lunchMealPlanId = lunchPlanId
                    dinnerMealPlanId = dinnerPlanId
                    
                    // Set currentMealPlanId for shopping list (prefer dinner, then lunch, then breakfast)
                    currentMealPlanId = dinnerPlanId ?? lunchPlanId ?? breakfastPlanId
                }
                
            } catch {
                await MainActor.run {
                    selectedDayMeal = nil
                    selectedBreakfastMeal = nil
                    selectedLunchMeal = nil
                    breakfastMealPlanId = nil
                    lunchMealPlanId = nil
                    dinnerMealPlanId = nil
                    currentMealPlanId = nil
                }
            }
        }
    }

    
    private func checkAndCreateBreakfastMealPlan() {
        Task {
            do {
                let mealPlans = try await databaseService.getUserMealPlans()
                
                // Check if there's already a breakfast meal plan created during the current week
                let existingBreakfastPlan = findBreakfastMealPlanForWeek(mealPlans, weekOf: Date())
                
                await MainActor.run {
                    // Set the meal type being created
                    appState.currentMealTypeBeingCreated = "breakfast"
                    appState.selectedMealTypes = ["breakfast"]
                    
                    if let existingPlan = existingBreakfastPlan {
                        // Store the existing meal plan ID for deletion
                        existingMealPlanId = existingPlan.id
                        
                        // Show confirmation dialog
                        var calendar = Calendar.current
                        calendar.firstWeekday = 1 // Ensure Sunday is the first day
                        let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
                        let formatter = DateFormatter()
                        formatter.dateStyle = .medium
                        existingMealPlanWeek = formatter.string(from: currentWeekStart)
                        showingMealPlanExistsAlert = true
                    } else {
                        // No existing breakfast plan, proceed to create new one
                        navigationPath.append("MealPlanInfo")
                    }
                }
                
            } catch {
                await MainActor.run {
                    print("❌ Error checking existing breakfast meal plans: \(error)")
                    // If there's an error, allow the user to proceed
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
                
                // Check if there's already a lunch meal plan created during the current week
                let existingLunchPlan = findLunchMealPlanForWeek(mealPlans, weekOf: Date())
                
                await MainActor.run {
                    // Set the meal type being created
                    appState.currentMealTypeBeingCreated = "lunch"
                    appState.selectedMealTypes = ["lunch"]
                    
                    if let existingPlan = existingLunchPlan {
                        // Store the existing meal plan ID for deletion
                        existingMealPlanId = existingPlan.id
                        
                        // Show confirmation dialog
                        var calendar = Calendar.current
                        calendar.firstWeekday = 1 // Ensure Sunday is the first day
                        let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
                        let formatter = DateFormatter()
                        formatter.dateStyle = .medium
                        existingMealPlanWeek = formatter.string(from: currentWeekStart)
                        showingMealPlanExistsAlert = true
                    } else {
                        // No existing lunch plan, proceed to create new one
                        navigationPath.append("MealPlanInfo")
                    }
                }
                
            } catch {
                await MainActor.run {
                    print("❌ Error checking existing lunch meal plans: \(error)")
                    // If there's an error, allow the user to proceed
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
                
                // Check if there's already a dinner meal plan created during the current week
                let existingDinnerPlan = findDinnerMealPlanForWeek(mealPlans, weekOf: Date())
                
                await MainActor.run {
                    // Set the meal type being created
                    appState.currentMealTypeBeingCreated = "dinner"
                    appState.selectedMealTypes = ["dinner"]
                    
                    if let existingPlan = existingDinnerPlan {
                        // Store the existing meal plan ID for deletion
                        existingMealPlanId = existingPlan.id
                        
                        // Show confirmation dialog
                        var calendar = Calendar.current
                        calendar.firstWeekday = 1 // Ensure Sunday is the first day
                        let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
                        let formatter = DateFormatter()
                        formatter.dateStyle = .medium
                        existingMealPlanWeek = formatter.string(from: currentWeekStart)
                        showingMealPlanExistsAlert = true
                    } else {
                        // No existing dinner plan, proceed to create new one
                        navigationPath.append("MealPlanInfo")
                    }
                }
                
            } catch {
                await MainActor.run {
                    print("❌ Error checking existing dinner meal plans: \(error)")
                    // If there's an error, allow the user to proceed
                    appState.currentMealTypeBeingCreated = "dinner"
                    appState.selectedMealTypes = ["dinner"]
                    navigationPath.append("MealPlanInfo")
                }
            }
        }
    }
    
    private func replaceExistingMealPlan() {
        Task {
            do {
                // Delete the existing meal plan if we have its ID
                if let existingId = existingMealPlanId {
                    print("🗑️ Deleting existing meal plan: \(existingId)")
                    try await databaseService.deleteMealPlan(mealPlanId: existingId)
                    print("✅ Successfully deleted existing meal plan")
                }
                
                // Navigate to create new meal plan
                await MainActor.run {
                    existingMealPlanId = nil // Clear the stored ID
                    navigationPath.append("MealPlanInfo")
                }
                
            } catch {
                await MainActor.run {
                    print("❌ Error deleting existing meal plan: \(error)")
                    // Even if deletion fails, allow user to proceed with new meal plan
                    existingMealPlanId = nil
                    navigationPath.append("MealPlanInfo")
                }
            }
        }
    }
    
    private func navigateToPreviousWeek() {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Ensure Sunday is the first day
        if let newDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func navigateToNextWeek() {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Ensure Sunday is the first day
        let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        
        if let newDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate),
           let newWeekStart = calendar.dateInterval(of: .weekOfYear, for: newDate)?.start,
           newWeekStart <= currentWeekStart {
            selectedDate = newDate
        }
    }
    
    // MARK: - Helper Functions for Week Detection
    
    /// Finds a breakfast meal plan for a specific week
    private func findBreakfastMealPlanForWeek(_ mealPlans: [DatabaseMealPlan], weekOf date: Date) -> DatabaseMealPlan? {
        print("🔍 DEBUG findBreakfastMealPlanForWeek: Looking for breakfast meal plan for week of \(date)")
        print("🔍 DEBUG: Today's date: \(date)")
        print("🔍 DEBUG: Today's week interval: \(getWeekInterval(for: date))")
        
        let result = mealPlans.first { plan in
            // Check if this meal plan was created during the specified week AND is a breakfast meal plan
            let createdDuringWeek = mealPlanCreatedDuringWeek(plan, weekOf: date)
            let isBreakfast = plan.mealPlanType == "breakfast"
            
            print("  📋 Checking plan: \(plan.name) (ID: \(plan.id?.uuidString ?? "nil"))")
            print("    - Type: '\(plan.mealPlanType)' (isBreakfast: \(isBreakfast))")
            print("    - Week: \(plan.weekStartDate)")
            print("    - IsActive: \(plan.isActive)")
            print("    - CreatedDuringWeek: \(createdDuringWeek)")
            print("    - Match: \(createdDuringWeek && isBreakfast)")
            
            return createdDuringWeek && isBreakfast
        }
        
        print("🔍 DEBUG: findBreakfastMealPlanForWeek result: \(result?.name ?? "nil")")
        return result
    }
    
    /// Finds a lunch meal plan for a specific week
    private func findLunchMealPlanForWeek(_ mealPlans: [DatabaseMealPlan], weekOf date: Date) -> DatabaseMealPlan? {
        return mealPlans.first { plan in
            // Check if this meal plan was created during the specified week AND is a lunch meal plan
            guard mealPlanCreatedDuringWeek(plan, weekOf: date) else {
                return false
            }
            
            // Check if this meal plan is specifically for lunch using the identifier
            return plan.mealPlanType == "lunch"
        }
    }
    
    /// Finds a dinner meal plan for a specific week
    private func findDinnerMealPlanForWeek(_ mealPlans: [DatabaseMealPlan], weekOf date: Date) -> DatabaseMealPlan? {
        return mealPlans.first { plan in
            // Check if this meal plan was created during the specified week AND is a dinner meal plan
            guard mealPlanCreatedDuringWeek(plan, weekOf: date) else {
                return false
            }
            
            // Check if this meal plan is specifically for dinner using the identifier
            return plan.mealPlanType == "dinner"
        }
    }
    
    /// Gets the start and end dates for a given week
    private func getWeekInterval(for date: Date) -> (start: Date, end: Date) {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Ensure Sunday is the first day
        calendar.timeZone = TimeZone.current // Use local timezone for consistent week calculations
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? date
        return (start: weekStart, end: weekEnd)
    }
    
    /// Checks if a meal plan was created during a specific week
    private func mealPlanCreatedDuringWeek(_ mealPlan: DatabaseMealPlan, weekOf date: Date) -> Bool {
        print("🔍 DEBUG mealPlanCreatedDuringWeek: Checking meal plan \(mealPlan.name)")
        print("  - Target date: \(date)")
        print("  - Target week interval: \(getWeekInterval(for: date))")
        print("  - Meal plan week_start_date: '\(mealPlan.weekStartDate)'")
        print("  - Meal plan created_at: \(mealPlan.createdAt ?? "nil")")
        print("  - Meal plan is_active: \(mealPlan.isActive)")
        
        // IMPORTANT: We should match by week_start_date, not creation timestamp!
        // Let's check both methods and see which one works
        
        // Method 1: Check by week_start_date (recommended)
        let weekStartResult = checkByWeekStartDate(mealPlan, weekOf: date)
        print("  - Week start method result: \(weekStartResult)")
        
        // Method 2: Check by creation timestamp (current logic)
        let creationTimestampResult = checkByCreationTimestamp(mealPlan, weekOf: date)
        print("  - Creation timestamp method result: \(creationTimestampResult)")
        
        // For now, let's use the week_start_date method as it's more logical
        return weekStartResult
    }
    
    private func checkByWeekStartDate(_ mealPlan: DatabaseMealPlan, weekOf date: Date) -> Bool {
        // Parse the week_start_date string - it might be date-only format
        var mealPlanWeekStart: Date?
        
        // Try date-only format first (what we're seeing: "2025-08-18")
        let dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
        dateOnlyFormatter.timeZone = TimeZone.current // Use local timezone for consistency
        mealPlanWeekStart = dateOnlyFormatter.date(from: mealPlan.weekStartDate)
        
        // If that fails, try ISO8601 format
        if mealPlanWeekStart == nil {
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            mealPlanWeekStart = iso8601Formatter.date(from: mealPlan.weekStartDate)
        }
        
        guard let validMealPlanWeekStart = mealPlanWeekStart else {
            print("  ❌ Failed to parse week_start_date: \(mealPlan.weekStartDate)")
            return false
        }
        
        print("  ✅ Parsed meal plan week start: \(validMealPlanWeekStart)")
        
        // Get the week interval for the target date
        let targetWeekInterval = getWeekInterval(for: date)
        let mealPlanWeekInterval = getWeekInterval(for: validMealPlanWeekStart)
        
        // Check if they're the same week (exact match)
        let exactMatch = targetWeekInterval.start == mealPlanWeekInterval.start
        
        // Also check if the meal plan week start falls within the target week
        // This handles boundary cases where week calculations might differ
        let mealPlanDateInTargetWeek = validMealPlanWeekStart >= targetWeekInterval.start && 
                                      validMealPlanWeekStart <= targetWeekInterval.end
        
        // Also check if target date falls within meal plan week
        let targetDateInMealPlanWeek = date >= mealPlanWeekInterval.start && 
                                      date <= mealPlanWeekInterval.end
        
        let isSameWeek = exactMatch || mealPlanDateInTargetWeek || targetDateInMealPlanWeek
        
        print("  📅 Week comparison:")
        print("    - Target week: \(targetWeekInterval.start) to \(targetWeekInterval.end)")
        print("    - Meal plan week: \(mealPlanWeekInterval.start) to \(mealPlanWeekInterval.end)")
        print("    - Exact match: \(exactMatch)")
        print("    - Meal plan date in target week: \(mealPlanDateInTargetWeek)")
        print("    - Target date in meal plan week: \(targetDateInMealPlanWeek)")
        print("    - Final result: \(isSameWeek)")
        
        return isSameWeek
    }
    
    private func checkByCreationTimestamp(_ mealPlan: DatabaseMealPlan, weekOf date: Date) -> Bool {
        guard let createdAtString = mealPlan.createdAt else {
            print("🔍 No createdAt found for meal plan \(mealPlan.id?.uuidString ?? "nil")")
            return false
        }
        
        // Try multiple date formatters to handle different formats
        var createdAt: Date?
        
        // Try ISO8601 first
        let iso8601Formatter = ISO8601DateFormatter()
        createdAt = iso8601Formatter.date(from: createdAtString)
        
        // If that fails, try with fractional seconds
        if createdAt == nil {
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            createdAt = iso8601Formatter.date(from: createdAtString)
        }
        
        // If that fails, try standard date formatter
        if createdAt == nil {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
            createdAt = dateFormatter.date(from: createdAtString)
        }
        
        // If that fails, try without microseconds
        if createdAt == nil {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            createdAt = dateFormatter.date(from: createdAtString)
        }
        
        guard let finalCreatedAt = createdAt else {
            print("🔍 Failed to parse createdAt '\(createdAtString)' for meal plan \(mealPlan.id?.uuidString ?? "nil")")
            return false
        }
        
        let weekInterval = getWeekInterval(for: date)
        let isInWeek = finalCreatedAt >= weekInterval.start && finalCreatedAt <= weekInterval.end
        print("🔍 Checking meal plan \(mealPlan.id?.uuidString ?? "nil"): createdAt=\(finalCreatedAt), weekStart=\(weekInterval.start), weekEnd=\(weekInterval.end), isInWeek=\(isInWeek)")
        return isInWeek
    }
    
    /// Finds meal plan that was created during a specific week
    private func findMealPlanForWeek(_ mealPlans: [DatabaseMealPlan], weekOf date: Date) -> DatabaseMealPlan? {
        return mealPlans.first { mealPlan in
            mealPlanCreatedDuringWeek(mealPlan, weekOf: date)
        }
    }
    

}

// MARK: - Meal Detail View
struct MealDetailView: View {
    @State private var currentDayMeal: DayMeal
    private let mealType: String
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    private let databaseService = MealPlanDatabaseService.shared
    @State private var dailyNutrition: DailyNutritionSummary?
    @State private var isLoading = false
    @State private var generatingRecipeForMealId: UUID? = nil
    @State private var generatingImageForMealId: UUID? = nil
    @StateObject private var openAIService = OpenAIService.shared
    
    init(dayMeal: DayMeal, mealType: String = "dinner") {
        self._currentDayMeal = State(initialValue: dayMeal)
        self.mealType = mealType
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Meal Header
                mealHeader
                
                // Daily Nutrition Goal Section  
                dailyNutritionSection
                
                // Meal Image Section
                mealImageSection
                
                // Basic Stats
                basicStatsSection
                
                // View Recipes Button
                viewRecipesSection
                
                // Ingredients Section
                ingredientsSection
                
                // Bottom spacing
                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, 20)
        }
        .navigationTitle(currentDayMeal.meal.name)
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(false)
        .onAppear {
            loadDailyNutrition()
        }
    }
    
    // MARK: - Meal Header
    private var mealHeader: some View {
        VStack(spacing: 16) {
                            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentDayMeal.meal.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Today's \(mealType.capitalized)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(currentDayMeal.meal.calories) cal")
                                    .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                        Text("\(currentDayMeal.meal.cookTime) min")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            Text(currentDayMeal.meal.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Daily Nutrition Section
    private var dailyNutritionSection: some View {
        Group {
            // Daily Nutritional Breakdown
            if let macros = currentDayMeal.meal.macros {
                VStack(spacing: 12) {
                    HStack {
                        Text("Daily Nutritional Breakdown")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    CompactMacrosView(macros: macros)
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
            }
        }
    }
    
    // MARK: - Meal Image Section
    private var mealImageSection: some View {
        VStack(spacing: 16) {
            if let imageUrl = currentDayMeal.meal.imageUrl, !imageUrl.isEmpty {
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
                // View Image Button (only show when no image exists)
                Button {
                    generateMealImage(for: currentDayMeal)
                } label: {
                    HStack {
                        if generatingImageForMealId == currentDayMeal.meal.id {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                            Text("Generating...")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        } else {
                            Image(systemName: "photo.fill")
                                .font(.subheadline)
                            Text("View Image")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue)
                    )
                }
                .disabled(generatingImageForMealId == currentDayMeal.meal.id)
                .padding(.top, 12)
            }
        }
    }
    
    // MARK: - Basic Stats Section
    private var basicStatsSection: some View {
        HStack(spacing: 20) {
            Label("\(currentDayMeal.meal.cookTime) min", systemImage: "clock.fill")
                .font(.subheadline)
                .foregroundColor(.blue)
            
            if let originalDay = currentDayMeal.meal.originalCookingDay {
                Label("From \(originalDay)", systemImage: "arrow.clockwise")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
                    
                    Spacer()
        }
    }
                    
    // MARK: - View Recipes Section
    private var viewRecipesSection: some View {
                    VStack(spacing: 12) {
            let hasRecipe = hasDetailedRecipe(currentDayMeal.meal)
            
            if hasRecipe {
                NavigationLink(destination: MealDetailedRecipeView(dayMeal: currentDayMeal)) {
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
                    generateDetailedRecipe(for: currentDayMeal)
                } label: {
                    HStack {
                        if generatingRecipeForMealId == currentDayMeal.meal.id {
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
                .disabled(generatingRecipeForMealId == currentDayMeal.meal.id)
            }
        }
    }
    
    // MARK: - Ingredients Section
    private var ingredientsSection: some View {
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
                ForEach(currentDayMeal.meal.ingredients, id: \.self) { ingredient in
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
    }
    
    // MARK: - Helper Methods
    private func loadDailyNutrition() {
        isLoading = true
        
        Task {
            do {
                let nutrition = try await calculateDailyNutrition()
                await MainActor.run {
                    dailyNutrition = nutrition
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    dailyNutrition = DailyNutritionSummary.placeholder
                    isLoading = false
                    print("❌ Error loading daily nutrition: \(error)")
                }
            }
        }
    }
    
    private func calculateDailyNutrition() async throws -> DailyNutritionSummary {
        // Calculate user's daily calorie goal based on their stats
        let dailyCalorieGoal = calculateDailyCalorieGoal(userData: appState.userData)
        
        // For now, we'll use placeholder logic for consumed calories
        var consumedCalories = 0
        var consumedProtein = 0.0
        var consumedCarbs = 0.0
        var consumedFat = 0.0
        
        let caloriesLeft = max(0, dailyCalorieGoal - consumedCalories)
        let proteinLeft = max(0.0, Double(dailyCalorieGoal) * 0.3 / 4 - consumedProtein) // 30% of calories from protein
        let carbsLeft = max(0.0, Double(dailyCalorieGoal) * 0.4 / 4 - consumedCarbs) // 40% from carbs
        let fatLeft = max(0.0, Double(dailyCalorieGoal) * 0.3 / 9 - consumedFat) // 30% from fat
        
        let progress = Double(consumedCalories) / Double(dailyCalorieGoal)
        
        return DailyNutritionSummary(
            caloriesLeft: caloriesLeft,
            proteinLeft: Int(proteinLeft),
            carbsLeft: Int(carbsLeft),
            fatLeft: Int(fatLeft),
            caloriesProgress: min(1.0, progress)
        )
    }
    
    // Calculate daily calorie goal using Mifflin-St Jeor Equation
    private func calculateDailyCalorieGoal(userData: UserOnboardingData) -> Int {
        // If user data is incomplete, return a default value
        guard userData.weight > 0, userData.height > 0, userData.age > 0 else {
            return 2000 // Default calorie goal
        }
        
        let weightInKg = userData.weight
        let heightInCm = Double(userData.height)
        let age = Double(userData.age)
        
        // Using male formula as default (can be updated when gender is added to model)
        let bmr = (10 * weightInKg) + (6.25 * heightInCm) - (5 * age) + 5
        
        // Apply activity level multiplier
        let activityMultiplier: Double = {
            switch userData.activityLevel {
            case .sedentary: return 1.2
            case .lightlyActive: return 1.375
            case .moderatelyActive: return 1.55
            case .veryActive: return 1.725
            case .extremelyActive: return 1.9
            }
        }()
        
        let dailyCalories = bmr * activityMultiplier
        
        // Adjust based on health goals
        let adjustedCalories: Double = {
            if userData.healthGoals.contains(.loseWeight) {
                return dailyCalories - 500 // 500 calorie deficit for weight loss
            } else if userData.healthGoals.contains(.gainWeight) {
                return dailyCalories + 500 // 500 calorie surplus for weight gain
            } else {
                return dailyCalories // Maintenance calories
            }
        }()
        
        return Int(adjustedCalories)
    }
    
    private func hasDetailedRecipe(_ meal: Meal) -> Bool {
        // Check if we have the essential detailed recipe components
        let hasIngredients = meal.detailedIngredients != nil && !meal.detailedIngredients!.isEmpty
        let hasInstructions = meal.detailedInstructions != nil && !meal.detailedInstructions!.isEmpty
        
        return hasIngredients && hasInstructions
    }
    
    private func generateDetailedRecipe(for dayMeal: DayMeal) {
        Task {
            await MainActor.run {
                generatingRecipeForMealId = dayMeal.meal.id
            }
            
            do {
                let detailedRecipe = try await openAIService.generateDetailedRecipe(
                    for: dayMeal,
                    userData: appState.userData
                )
                
                // Update the meal in the database
                try await databaseService.updateMealDetailedRecipe(
                    mealId: dayMeal.meal.id, 
                    detailedRecipe: detailedRecipe
                )
                
                await MainActor.run {
                    // Update local state with the new recipe data
                    let updatedMeal = Meal(
                        id: currentDayMeal.meal.id,
                        name: currentDayMeal.meal.name,
                        description: currentDayMeal.meal.description,
                        calories: currentDayMeal.meal.calories,
                        cookTime: currentDayMeal.meal.cookTime,
                        ingredients: currentDayMeal.meal.ingredients,
                        instructions: currentDayMeal.meal.instructions,
                        originalCookingDay: currentDayMeal.meal.originalCookingDay,
                        imageUrl: currentDayMeal.meal.imageUrl,
                        recommendedCaloriesBeforeDinner: currentDayMeal.meal.recommendedCaloriesBeforeDinner,
                        macros: currentDayMeal.meal.macros,
                        detailedIngredients: detailedRecipe.detailedIngredients, // New detailed recipe
                        detailedInstructions: detailedRecipe.instructions, // New detailed recipe
                        cookingTips: detailedRecipe.cookingTips, // New detailed recipe
                        servingInfo: detailedRecipe.servingInfo // New detailed recipe
                    )
                    
                    currentDayMeal = DayMeal(day: currentDayMeal.day, meal: updatedMeal)
                    generatingRecipeForMealId = nil
                    print("✅ Local state updated with new detailed recipe")
                }
                
            } catch {
                await MainActor.run {
                    generatingRecipeForMealId = nil
                }
                print("❌ Error generating detailed recipe: \(error)")
            }
        }
    }
    
    private func generateMealImage(for dayMeal: DayMeal) {
        Task {
            await MainActor.run {
                generatingImageForMealId = dayMeal.meal.id
            }
            
            do {
                let imageUrl = try await openAIService.generateMealImage(for: dayMeal.meal)
                
                // Update the meal in the database
                try await databaseService.updateMealImage(mealId: dayMeal.meal.id, imageUrl: imageUrl)
                
                await MainActor.run {
                    // Update local state with the new image URL
                    let updatedMeal = Meal(
                        id: currentDayMeal.meal.id,
                        name: currentDayMeal.meal.name,
                        description: currentDayMeal.meal.description,
                        calories: currentDayMeal.meal.calories,
                        cookTime: currentDayMeal.meal.cookTime,
                        ingredients: currentDayMeal.meal.ingredients,
                        instructions: currentDayMeal.meal.instructions,
                        originalCookingDay: currentDayMeal.meal.originalCookingDay,
                        imageUrl: imageUrl, // New image URL
                        recommendedCaloriesBeforeDinner: currentDayMeal.meal.recommendedCaloriesBeforeDinner,
                        macros: currentDayMeal.meal.macros,
                        detailedIngredients: currentDayMeal.meal.detailedIngredients,
                        detailedInstructions: currentDayMeal.meal.detailedInstructions,
                        cookingTips: currentDayMeal.meal.cookingTips,
                        servingInfo: currentDayMeal.meal.servingInfo
                    )
                    
                    currentDayMeal = DayMeal(day: currentDayMeal.day, meal: updatedMeal)
                    generatingImageForMealId = nil
                    print("✅ Local state updated with new image URL")
                }
                
            } catch {
                await MainActor.run {
                    generatingImageForMealId = nil
                }
                print("❌ Error generating meal image: \(error)")
            }
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            ProfileMenuView()
                .environmentObject(appState)
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Founder Updates View
struct FounderUpdatesView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 24) {
                // Header section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "megaphone.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                        
                        Text("Updates from the founder")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    Text("Stay up to date with the latest features and improvements")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // Content section
                VStack(alignment: .leading, spacing: 16) {
                    UpdateMessageCard(
                        icon: "lightbulb.fill",
                        title: "Feature Requests",
                        message: "To request features, go to feature requests on your profile menu",
                        iconColor: .orange
                    )
                    
                    UpdateMessageCard(
                        icon: "slider.horizontal.3",
                        title: "Daily Meal Customization",
                        message: "Daily meal customization coming soon, stay tuned!",
                        iconColor: .purple
                    )
                    
                    UpdateMessageCard(
                        icon: "flame.fill",
                        title: "Streaks",
                        message: "Streaks are coming soon, stay tuned!",
                        iconColor: .orange
                    )
                    
                    UpdateMessageCard(
                        icon: "heart.fill",
                        title: "Thank You",
                        message: "Thank you for using Preppi AI! Your feedback helps us improve.",
                        iconColor: .red
                    )
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                }
            }
        }
    }
}

// MARK: - Update Message Card Component
struct UpdateMessageCard: View {
    let icon: String
    let title: String
    let message: String
    let iconColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [iconColor, iconColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Supporting Models
struct DailyNutritionSummary {
    let caloriesLeft: Int
    let proteinLeft: Int
    let carbsLeft: Int
    let fatLeft: Int
    let caloriesProgress: Double
    
    static let placeholder = DailyNutritionSummary(
        caloriesLeft: 1865,
        proteinLeft: 149,
        carbsLeft: 200,
        fatLeft: 51,
        caloriesProgress: 0.3
    )
}

// MARK: - Supporting Views
struct DayCircle: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let action: () -> Void
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }
    
    private var dayNumberFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dayFormatter.string(from: date).uppercased())
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .secondary)
                
                Text(dayNumberFormatter.string(from: date))
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
                            .stroke(isToday && !isSelected ? Color.green : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NutritionPillCard: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct MacroCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Text(icon)
                    .font(.title3)
            }
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Meal Edit Popup View
struct MealEditPopupView: View {
    let onEditBreakfast: () -> Void
    let onEditLunch: () -> Void
    let onEditDinner: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Text("Edit Meals")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Choose which meal you'd like to edit")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)
                .padding(.horizontal, 20)
                
                // Meal editing buttons
                VStack(spacing: 16) {
                    // Edit Breakfast
                    Button(action: onEditBreakfast) {
                        HStack(spacing: 16) {
                            Image(systemName: "sunrise.fill")
                                .font(.title2)
                                .foregroundColor(.orange)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Edit Breakfast")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text("Update your morning meal plan")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Edit Lunch
                    Button(action: onEditLunch) {
                        HStack(spacing: 16) {
                            Image(systemName: "sun.max.fill")
                                .font(.title2)
                                .foregroundColor(.yellow)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Edit Lunch")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text("Update your midday meal plan")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Edit Dinner
                    Button(action: onEditDinner) {
                        HStack(spacing: 16) {
                            Image(systemName: "moon.fill")
                                .font(.title2)
                                .foregroundColor(.purple)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Edit Dinner")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text("Update your evening meal plan")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 32)
                
                Spacer()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    ContentView()
}
