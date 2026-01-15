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
        // App Icon only
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
            } else if !appState.isAuthenticated && !appState.isGuestOnboarding && !appState.needsSignUpAfterOnboarding {
                // NEW: Show welcome entry screen for non-authenticated users
                WelcomeEntryView()
                    .environmentObject(appState)
            } else if appState.isGuestOnboarding {
                // NEW: Show onboarding for guest users (not authenticated yet)
                OnboardingView()
                    .environmentObject(appState)
            } else if appState.needsSignUpAfterOnboarding && !appState.isAuthenticated {
                // NEW: Show signup screen after guest completes onboarding
                PostOnboardingSignUpView()
                    .environmentObject(appState)
            } else if appState.shouldShowLoading {
                // Show loading state for general app loading or checking entitlements
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .green))
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
                // Show RevenueCat paywall if authenticated and onboarded but no Pro access
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
                        .progressViewStyle(CircularProgressViewStyle(tint: .green))
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
            // Initialize app state
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .environmentObject(appState)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            MealPlanView()
                .environmentObject(appState)
                .tabItem {
                    Image(systemName: "fork.knife")
                    Text("Meal Plan")
                }
                .tag(1)

            ProgressTabView()
                .environmentObject(appState)
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Progress")
                }
                .tag(2)

            FeedbackView()
                .environmentObject(appState)
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Feedback")
                }
                .tag(3)

            SettingsView()
                .environmentObject(appState)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(4)
        }
        .accentColor(.green)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenHomeTab"))) { _ in
            print("🔔 MainTabView received notification tap - opening Home tab")
            selectedTab = 0
        }
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
    @StateObject private var streakService = StreakService.shared
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
    @State private var showingStreakDetails = false
    @State private var showingMealPlanOnboarding = false
    @State private var showingCameraForMeal = false
    @State private var showingImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var showingMealAnalysis = false
    @State private var selectedMealImage: UIImage?
    @State private var mealAnalysisResult: MealAnalysisResult?
    @State private var isAnalyzingMeal = false
    @StateObject private var loggedMealService = LoggedMealService.shared
    @StateObject private var exerciseService = ExerciseService.shared
    @State private var showingLoggedMealDetail = false
    @State private var selectedLoggedMeal: LoggedMeal?
    @State private var pendingMealType: String? // Track which meal type is being logged
    @State private var showingQuickActionPopup = false // For the plus button popup
    @State private var showingExerciseLogging = false // For exercise logging sheet
    @State private var exerciseDescription = "" // User's exercise description

    // Performance optimization: Cache meal plans to avoid repeated database calls
    @State private var cachedMealPlans: [DatabaseMealPlan] = []
    @State private var lastMealPlansUpdate: Date = Date.distantPast
    @State private var cachedMealPlanDetails: [UUID: MealPlan] = [:] // Cache for full meal plan details
    @State private var lastMealPlanDetailsUpdate: [UUID: Date] = [:] // Track when each was last updated
    

    
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
            mainContent
            .navigationBarHidden(true)
            .navigationDestination(for: String.self) { destination in
                navigationDestination(for: destination)
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
                streakService.loadStreakData()
                print("🔄 Refreshing logged meals on HomeView appear...")
                loggedMealService.refreshMeals()
                exerciseService.refreshExercises()

                // Debug: Print all logged meals after refresh
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    print("📊 Total logged meals: \(loggedMealService.loggedMeals.count)")
                    for meal in loggedMealService.loggedMeals {
                        print("📊 Meal: \(meal.mealName) - \(meal.loggedAt) - Type: \(meal.mealType ?? "extra")")
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                // Refresh streak data when app becomes active
                streakService.refreshStreakData()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("MealPlanUpdated"))) { _ in
                // Refresh meal plans when a meal is replaced
                print("🔄 HomeView received meal plan updated notification - refreshing data")
                lastMealPlansUpdate = Date.distantPast
                loadDailyNutrition()
                loadSelectedDayMeal()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("MealLogged"))) { _ in
                // Refresh UI when a meal is logged
                print("🔄 HomeView received meal logged notification - refreshing data")
                loadDailyNutrition()
                loggedMealService.refreshMeals()
                streakService.refreshStreakData()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ExerciseLogged"))) { _ in
                // Refresh UI when an exercise is logged
                print("🔄 HomeView received exercise logged notification - refreshing data")
                loadDailyNutrition()
                exerciseService.refreshExercises()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("MealCompletionUpdated"))) { _ in
                // Refresh UI when meal completions are updated
                print("🔄 HomeView received meal completion updated notification - refreshing data")
                streakService.refreshStreakData()
            }
            .onChange(of: selectedDate) { newDate in
                // Load data for the new date
                // These functions now use caching for instant updates
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
        .sheet(isPresented: $showingStreakDetails) {
            StreakDetailsView()
                .environmentObject(streakService)
        }
        .sheet(isPresented: $showingMealPlanOnboarding) {
            MealPlanOnboardingView()
                .environmentObject(appState)
        }
        .confirmationDialog("Select Photo", isPresented: $showingCameraForMeal, titleVisibility: .visible) {
            Button("Take Photo") {
                sourceType = .camera
                showingImagePicker = true
            }
            
            Button("Choose from Library") {
                sourceType = .photoLibrary
                showingImagePicker = true
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose how you'd like to add your photo")
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: sourceType) { image in
                print("📱 HomeView: Received image from picker for meal logging")
                selectedMealImage = image
                // Dismiss the picker immediately and start analysis
                showingImagePicker = false
                analyzeMealImage(image)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenDeviceCamera"))) { _ in
            print("📸 HomeView received open device camera notification")
            showingCameraForMeal = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DismissMealPlanOnboarding"))) { _ in
            print("📱 HomeView received dismiss meal plan onboarding notification")
            showingMealPlanOnboarding = false
        }
        .onChange(of: selectedDate) { newDate in
            // Update current preferences when date changes to handle week transitions
            appState.updateCurrentPreferences(for: newDate)
        }
        .fullScreenCover(isPresented: $showingMealAnalysis) {
            if let image = selectedMealImage, let result = mealAnalysisResult {
                MealAnalysisResultView(
                    mealImage: image,
                    analysisResult: result,
                    onDone: {
                        showingMealAnalysis = false
                        selectedMealImage = nil
                        mealAnalysisResult = nil
                    },
                    onAddDetails: {
                        // Sheet is handled internally in MealAnalysisResultView
                        print("Add details tapped")
                    },
                    onLogMeal: {
                        // Log the meal with meal type if specified, using the selected date
                        // Use the current mealAnalysisResult which may have been refined
                        if let currentResult = mealAnalysisResult {
                            loggedMealService.logMeal(from: currentResult, image: image, mealType: pendingMealType, loggedDate: selectedDate)

                            // Track in Mixpanel
                            MixpanelService.shared.track(
                                event: MixpanelService.Events.mealButtonTapped,
                                properties: [
                                    MixpanelService.Properties.mealName: currentResult.mealName,
                                    MixpanelService.Properties.calories: currentResult.calories,
                                    MixpanelService.Properties.mealType: "logged_meal"
                                ]
                            )
                        }

                        // Close the analysis view
                        showingMealAnalysis = false
                        selectedMealImage = nil
                        mealAnalysisResult = nil
                        pendingMealType = nil // Clear pending meal type
                    },
                    onRefinedAnalysis: { refinedResult in
                        // Update the meal analysis result with the refined version
                        mealAnalysisResult = refinedResult
                    }
                )
            }
        }
        .overlay {
            if isAnalyzingMeal {
                AnalyzingFoodLoadingView()
            }
        }
        .fullScreenCover(item: $selectedLoggedMeal, onDismiss: {
            selectedLoggedMeal = nil
        }) { meal in
            LoggedMealDetailView(loggedMeal: meal)
        }
        .sheet(isPresented: $showingExerciseLogging) {
            ExerciseLoggingSheet(
                exerciseDescription: $exerciseDescription,
                selectedDate: selectedDate,
                onSubmit: {
                    analyzeAndLogExercise()
                },
                onCancel: {
                    showingExerciseLogging = false
                    exerciseDescription = ""
                }
            )
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
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

                    // Bottom spacing
                    Color.clear.frame(height: 100)
                }
            }

            // Floating plus button
            floatingPlusButton

            // Quick action popup overlay
            if showingQuickActionPopup {
                quickActionPopup
            }
        }
    }
    
    // MARK: - Navigation Destination
    @ViewBuilder
    private func navigationDestination(for destination: String) -> some View {
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
                
                // Streak counter
                Button(action: {
                    showingStreakDetails = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("\(streakService.currentStreak)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                    )
                }

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
                            isComplete: streakService.dayIsComplete[date] ?? false,
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

            // Check if all meals are empty
            let hasNoMeals = selectedBreakfastMeal == nil && selectedLunchMeal == nil && selectedDayMeal == nil

            // Meal cards section
            VStack(spacing: 12) {
                // Show Start button if no weekly preference has been set for the current week
                if hasNoMeals && !appState.hasWeeklyMealPlanPreference(for: selectedDate) {
                    startButton
                    
                    // Logged meals section for NoView
                    VStack(spacing: 16) {
                        // Get completed meals from StreakService (meal_completions table)
                        let completedMealsForDate = streakService.getCompletedMealsForDate(selectedDate)
                        print("🏠 DEBUG: Home screen - Found \(completedMealsForDate.count) completed meals for \(selectedDate)")
                        
                        // Also get any logged meals from LoggedMealService (logged_meals table) as backup
                        let allLoggedMealsForDate = loggedMealService.getLoggedMealsForDate(selectedDate)
                        print("🏠 DEBUG: Home screen - Found \(allLoggedMealsForDate.count) logged meals for \(selectedDate)")
                        
                        // Display completed meals from meal plan
                        if !completedMealsForDate.isEmpty {
                            ForEach(completedMealsForDate) { mealInstance in
                                CompletedMealCard(
                                    mealInstance: mealInstance,
                                    selectedDate: selectedDate,
                                    selectedBreakfastMeal: selectedBreakfastMeal,
                                    selectedLunchMeal: selectedLunchMeal,
                                    selectedDinnerMeal: selectedDinnerMeal
                                )
                            }
                        }
                        
                        // Display logged meals from photo logging as backup
                        if !allLoggedMealsForDate.isEmpty {
                            ForEach(allLoggedMealsForDate) { loggedMeal in
                                LoggedMealCard(loggedMeal: loggedMeal) {
                                    print("📱 Tapping logged meal (NoView): \(loggedMeal.mealName)")
                                    print("📱 Setting selectedLoggedMeal to: \(loggedMeal.id)")

                                    // Ensure UI update happens on main thread
                                    DispatchQueue.main.async {
                                        selectedLoggedMeal = loggedMeal
                                        print("📱 NoView UI updated - selectedLoggedMeal set: \(String(describing: selectedLoggedMeal?.id))")
                                    }
                                }
                            }
                        }
                        } else {
                            // Placeholder when no meals are logged
                            VStack(spacing: 12) {
                                Image(systemName: "fork.knife.circle")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray.opacity(0.4))

                                Text("No meals logged today")
                                    .font(.headline)
                                    .foregroundColor(.gray)

                                Text("Press the + button to log meals or log meals directly from the meal plan")
                                    .font(.subheadline)
                                    .foregroundColor(.gray.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        }

                        // Exercise cards for the selected date
                        let exercisesForDate = exerciseService.getExercisesForDate(selectedDate)
                        if !exercisesForDate.isEmpty {
                            ForEach(exercisesForDate) { exercise in
                                exerciseCard(exercise: exercise)
                            }
                        }
                    }
                } else {
                    // Check if there are any logged meals for the selected date
                    // Get completed meals from StreakService (meal_completions table)
                    let completedMealsForDate = streakService.getCompletedMealsForDate(selectedDate)
                    print("🏠 DEBUG: YesView - Found \(completedMealsForDate.count) completed meals for \(selectedDate)")
                    
                    // Also get logged meals as backup
                    let loggedBreakfast = loggedMealService.getLoggedMealForDateAndType(selectedDate, mealType: "breakfast")
                    let loggedLunch = loggedMealService.getLoggedMealForDateAndType(selectedDate, mealType: "lunch")
                    let loggedDinner = loggedMealService.getLoggedMealForDateAndType(selectedDate, mealType: "dinner")
                    let extraLoggedMealsForDate = loggedMealService.getLoggedMealsForDate(selectedDate).filter { $0.mealType == nil }
                    let hasAnyLoggedMeals = loggedBreakfast != nil || loggedLunch != nil || loggedDinner != nil || !extraLoggedMealsForDate.isEmpty

                    if !completedMealsForDate.isEmpty || hasAnyLoggedMeals {
                        // Display completed meals from meal plan
                        ForEach(completedMealsForDate) { mealInstance in
                            CompletedMealCard(
                                mealInstance: mealInstance,
                                selectedDate: selectedDate,
                                selectedBreakfastMeal: selectedBreakfastMeal,
                                selectedLunchMeal: selectedLunchMeal,
                                selectedDinnerMeal: selectedDinnerMeal
                            )
                        }
                        
                        // Display logged meals from photo logging as backup
                        if let loggedBreakfast = loggedBreakfast {
                            LoggedMealCard(loggedMeal: loggedBreakfast) {
                                print("📱 Tapping logged breakfast (YesView): \(loggedBreakfast.mealName)")
                                DispatchQueue.main.async {
                                    selectedLoggedMeal = loggedBreakfast
                                    print("📱 Breakfast YesView UI updated - selectedLoggedMeal set: \(String(describing: selectedLoggedMeal?.id))")
                                }
                            }
                        }

                        if let loggedLunch = loggedLunch {
                            LoggedMealCard(loggedMeal: loggedLunch) {
                                print("📱 Tapping logged lunch (YesView): \(loggedLunch.mealName)")
                                DispatchQueue.main.async {
                                    selectedLoggedMeal = loggedLunch
                                    print("📱 Lunch YesView UI updated - selectedLoggedMeal set: \(String(describing: selectedLoggedMeal?.id))")
                                }
                            }
                        }

                        if let loggedDinner = loggedDinner {
                            LoggedMealCard(loggedMeal: loggedDinner) {
                                print("📱 Tapping logged dinner (YesView): \(loggedDinner.mealName)")
                                DispatchQueue.main.async {
                                    selectedLoggedMeal = loggedDinner
                                    print("📱 Dinner YesView UI updated - selectedLoggedMeal set: \(String(describing: selectedLoggedMeal?.id))")
                                }
                            }
                        }

                        // Extra logged meals for the selected date (only meals without specific meal types)
                        if !extraLoggedMealsForDate.isEmpty {
                            ForEach(extraLoggedMealsForDate) { loggedMeal in
                                LoggedMealCard(loggedMeal: loggedMeal) {
                                    print("📱 Tapping extra logged meal: \(loggedMeal.mealName)")
                                    print("📱 Setting selectedLoggedMeal to: \(loggedMeal.id)")

                                    // Ensure UI update happens on main thread
                                    DispatchQueue.main.async {
                                        selectedLoggedMeal = loggedMeal
                                        print("📱 UI updated - selectedLoggedMeal set: \(String(describing: selectedLoggedMeal?.id))")
                                    }
                                }
                            }
                        }
                    } else {
                        // Placeholder when no meals are logged
                        VStack(spacing: 12) {
                            Image(systemName: "fork.knife.circle")
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.4))

                            Text("No meals logged today")
                                .font(.headline)
                                .foregroundColor(.gray)

                            Text("Press the + button to log meals or log meals directly from the meal plan")
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }

                    // Exercise cards for the selected date
                    let exercisesForDate = exerciseService.getExercisesForDate(selectedDate)
                    if !exercisesForDate.isEmpty {
                        ForEach(exercisesForDate) { exercise in
                            exerciseCard(exercise: exercise)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Add Meal Button
    private func addMealButton(mealType: String, icon: String, color: Color) -> some View {
        Button(action: {
            // Check if we're in NoView (no meals and no weekly preference)
            let hasNoMeals = selectedBreakfastMeal == nil && selectedLunchMeal == nil && selectedDayMeal == nil
            let isNoView = hasNoMeals && !appState.hasWeeklyMealPlanPreference(for: selectedDate)

            // Determine if this is photo mode or meal plan mode
            let isPhotoMode = isNoView || (appState.getWeeklyMealPlanPreference(for: selectedDate) == false)

            // Track meal button tap in Mixpanel with specific event for photo mode
            if isPhotoMode {
                // Track with specific photo button events
                MixpanelService.shared.track(
                    event: "\(mealType.lowercased())_photo_pressed",
                    properties: [
                        "meal_type": mealType.lowercased(),
                        "source": "home_screen",
                        "mode": "photo_logging"
                    ]
                )
            } else {
                // Track regular meal plan button tap
                MixpanelService.shared.track(
                    event: MixpanelService.Events.mealButtonTapped,
                    properties: [
                        MixpanelService.Properties.mealType: mealType.lowercased(),
                        MixpanelService.Properties.source: "home_screen",
                        "mode": "meal_plan"
                    ]
                )
            }

            if isNoView {
                // NoView: Use camera flow for meal logging
                // Check if this meal type already exists for today
                if loggedMealService.hasLoggedMealForDateAndType(selectedDate, mealType: mealType.lowercased()) {
                    // Already have a meal of this type for today - do nothing
                    print("⚠️ Already have a \(mealType.lowercased()) logged for today")
                    return
                }

                // Set pending meal type and open camera
                pendingMealType = mealType.lowercased()
                showingCameraForMeal = true
            } else {
                // Regular view: Check weekly preference
                if let weeklyPreference = appState.getWeeklyMealPlanPreference(for: selectedDate) {
                    if !weeklyPreference {
                        // User chose "No" - photo logging
                        // Check if this meal type already exists for today
                        if loggedMealService.hasLoggedMealForDateAndType(selectedDate, mealType: mealType.lowercased()) {
                            // Already have a meal of this type for today - do nothing
                            print("⚠️ Already have a \(mealType.lowercased()) logged for today")
                            return
                        }

                        // Set pending meal type and open camera
                        pendingMealType = mealType.lowercased()
                        showingCameraForMeal = true
                    } else {
                        // User chose "Yes" - meal plan creation
                        if mealType == "Breakfast" {
                            checkAndCreateBreakfastMealPlan()
                        } else if mealType == "Lunch" {
                            checkAndCreateLunchMealPlan()
                        } else if mealType == "Dinner" {
                            checkAndCreateDinnerMealPlan()
                        }
                    }
                } else {
                    // No preference set - default to meal plan creation
                    if mealType == "Breakfast" {
                        checkAndCreateBreakfastMealPlan()
                    } else if mealType == "Lunch" {
                        checkAndCreateLunchMealPlan()
                    } else if mealType == "Dinner" {
                        checkAndCreateDinnerMealPlan()
                    }
                }
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
                    
                    Text(getButtonSubtitle(for: mealType))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                Image(systemName: getButtonIcon())
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
    
    // MARK: - Helper Methods for Add Meal Button
    private func getButtonSubtitle(for mealType: String) -> String {
        if let weeklyPreference = appState.getWeeklyMealPlanPreference(for: selectedDate) {
            if weeklyPreference {
                return "Tap to add \(mealType.lowercased()) to your day"
            } else {
                return "Tap to take a photo of your \(mealType.lowercased())"
            }
        }
        return "Tap to add \(mealType.lowercased()) to your day"
    }
    
    private func getButtonIcon() -> String {
        if let weeklyPreference = appState.getWeeklyMealPlanPreference(for: selectedDate) {
            return weeklyPreference ? "plus.circle" : "camera.fill"
        }
        return "plus.circle"
    }

    // MARK: - Floating Plus Button
    private var floatingPlusButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        showingQuickActionPopup.toggle()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 56, height: 56)
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)

                        Image(systemName: showingQuickActionPopup ? "xmark" : "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(showingQuickActionPopup ? 90 : 0))
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Quick Action Popup
    private var quickActionPopup: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        showingQuickActionPopup = false
                    }
                }

            // Popup content
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 16) {
                        // Log Exercise Button
                        Button(action: {
                            showingQuickActionPopup = false
                            showingExerciseLogging = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "figure.run")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Circle()
                                            .fill(Color.orange)
                                    )

                                Text("Log Exercise")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)

                                Spacer()
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            )
                        }

                        // Log Meal Button
                        Button(action: {
                            showingQuickActionPopup = false
                            showingCameraForMeal = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Circle()
                                            .fill(Color.blue)
                                    )

                                Text("Log Meal")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)

                                Spacer()
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            )
                        }
                    }
                    .frame(width: 250)
                    .padding(.trailing, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .transition(.opacity)
    }

    // MARK: - Extra Meal Card
    private var extraMealCard: some View {
        Button(action: {
            // Track extra meal logging in Mixpanel
            MixpanelService.shared.track(
                event: MixpanelService.Events.mealButtonTapped,
                properties: [
                    MixpanelService.Properties.mealType: "extra",
                    MixpanelService.Properties.source: "home_screen"
                ]
            )
            
            // Open camera for extra meal logging
            showingCameraForMeal = true
        }) {
            HStack(spacing: 16) {
                // Camera icon
                Image(systemName: "camera.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Log Extra Meal")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Take a photo to analyze")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.green)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Exercise Card
    private func exerciseCard(exercise: LoggedExercise) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Exercise icon
                Image(systemName: "figure.run")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.orange)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Exercise Logged")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(exercise.summary)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                // Calories burned
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(exercise.caloriesBurned)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)

                    Text("cal burned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Start Button
    private var startButton: some View {
        VStack(spacing: 20) {
            // Breakfast section - show LoggedMealCard if exists, otherwise meal button
            if let breakfastMeal = loggedMealService.getLoggedMealForDateAndType(selectedDate, mealType: "breakfast") {
                LoggedMealCard(loggedMeal: breakfastMeal) {
                    print("📱 Tapping logged breakfast: \(breakfastMeal.mealName)")
                    DispatchQueue.main.async {
                        selectedLoggedMeal = breakfastMeal
                        print("📱 Breakfast UI updated - selectedLoggedMeal set: \(String(describing: selectedLoggedMeal?.id))")
                    }
                }
            } else {
                addMealButton(mealType: "Breakfast", icon: "sunrise.fill", color: .orange)
            }

            // Start button in the middle
            Button(action: {
                showingMealPlanOnboarding = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "play.circle.fill")
                        .font(.title)
                        .foregroundColor(.white)

                    Text("Start")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .green.opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(PlainButtonStyle())

            // Lunch section - show LoggedMealCard if exists, otherwise meal button
            if let lunchMeal = loggedMealService.getLoggedMealForDateAndType(selectedDate, mealType: "lunch") {
                LoggedMealCard(loggedMeal: lunchMeal) {
                    print("📱 Tapping logged lunch: \(lunchMeal.mealName)")
                    DispatchQueue.main.async {
                        selectedLoggedMeal = lunchMeal
                        print("📱 Lunch UI updated - selectedLoggedMeal set: \(String(describing: selectedLoggedMeal?.id))") 
                    }
                }
            } else {
                addMealButton(mealType: "Lunch", icon: "sun.max.fill", color: .yellow)
            }

            // Dinner section - show LoggedMealCard if exists, otherwise meal button
            if let dinnerMeal = loggedMealService.getLoggedMealForDateAndType(selectedDate, mealType: "dinner") {
                LoggedMealCard(loggedMeal: dinnerMeal) {
                    print("📱 Tapping logged dinner: \(dinnerMeal.mealName)")
                    DispatchQueue.main.async {
                        selectedLoggedMeal = dinnerMeal
                        print("📱 Dinner UI updated - selectedLoggedMeal set: \(String(describing: selectedLoggedMeal?.id))")
                    }
                }
            } else {
                addMealButton(mealType: "Dinner", icon: "moon.fill", color: .purple)
            }
        }
    }

    // MARK: - Disabled Meal Button
    private func disabledMealButton(mealType: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color.opacity(0.3))
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text("Add \(mealType)")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary.opacity(0.3))

                Text("Tap to add \(mealType.lowercased()) to your day")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.3))
            }

            Spacer()

            Image(systemName: "plus.circle")
                .font(.title2)
                .foregroundColor(.gray.opacity(0.3))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                .foregroundColor(.gray.opacity(0.3))
        )
        .opacity(0.5)
    }

    private var caloriesCard: some View {
        SwipeableNutritionCard(
            totalCaloriesForSelectedDay: max(totalCaloriesForSelectedDay, 1200),
            remainingCaloriesForSelectedDay: max(remainingCaloriesForSelectedDay, 0),
            caloriesProgress: max(min(caloriesProgress, 1.0), 0.0),
            progressRingColor: progressRingColor,
            userData: appState.userData,
            dailyMicronutrientGoals: dailyMicronutrientGoals,
            consumedMicronutrients: consumedMicronutrients,
            remainingMicronutrients: remainingMicronutrients
        )
    }
    
    // MARK: - Helper Properties
    private var totalCaloriesForSelectedDay: Int {
        // Return the user's daily calorie goal based on their profile and goals
        // Add defensive programming to prevent crashes
        guard appState.userData.age > 0,
              appState.userData.weight > 0,
              appState.userData.height > 0 else {
            // Return a reasonable default if user data is incomplete
            return 2000
        }

        let baseCalories = CalorieCalculationService.shared.calculateDailyCalorieGoal(for: appState.userData)

        // Add exercise calories burned for the selected date
        let exerciseCalories = ExerciseService.shared.getTotalCaloriesBurnedForDate(selectedDate)

        return max(baseCalories + exerciseCalories, 1200) // Ensure minimum safe value
    }
    
    private var remainingCaloriesForSelectedDay: Int {
        let dailyGoal = totalCaloriesForSelectedDay
        var consumedCalories = 0
        
        // Get completed meals for the selected date
        let normalizedDate = normalizeDate(selectedDate)
        let mealsForDate = streakService.weekCompletions[normalizedDate] ?? []
        
        // Calculate consumed calories from completed meals
        for mealInstance in mealsForDate {
            if mealInstance.completion == .ateExact {
                // User ate the exact planned meal - use planned meal calories
                if let meal = getMealForType(mealInstance.mealType) {
                    consumedCalories += meal.calories
                }
            }
            // Note: If completion is .ateSimilar, calories will be counted from logged meals instead
        }

        // Add calories from logged meals (includes meals marked as .ateSimilar)
        consumedCalories += loggedMealService.getTotalCaloriesForDate(selectedDate)
        
        // Return remaining calories (daily goal - consumed)
        return max(0, dailyGoal - consumedCalories)
    }
    
    private var caloriesProgress: Double {
        let dailyGoal = Double(totalCaloriesForSelectedDay)
        let remainingCalories = Double(remainingCaloriesForSelectedDay)
        
        // Return progress as percentage of remaining calories (higher percentage means more calories remaining)
        return dailyGoal > 0 ? min(remainingCalories / dailyGoal, 1.0) : 0.0
    }
    
    private var progressRingColor: Color {
        let progress = caloriesProgress
        if progress > 0.7 {
            return .green // Lots of calories remaining
        } else if progress > 0.3 {
            return .orange // Moderate calories remaining
        } else {
            return .red // Few calories remaining
        }
    }

    // MARK: - Micronutrient Properties

    private var dailyMicronutrientGoals: (fiber: Double, sugar: Double, sodium: Double) {
        guard appState.userData.age > 0,
              appState.userData.weight > 0,
              appState.userData.height > 0 else {
            // Return reasonable defaults if user data is incomplete
            return (fiber: 25.0, sugar: 50.0, sodium: 2300.0)
        }
        return CalorieCalculationService.shared.calculateDailyMicronutrientGoals(for: appState.userData)
    }

    private var consumedMicronutrients: (fiber: Double, sugar: Double, sodium: Double) {
        var totalFiber = 0.0
        var totalSugar = 0.0
        var totalSodium = 0.0

        // Get completed meals for the selected date
        let normalizedDate = normalizeDate(selectedDate)
        let mealsForDate = streakService.weekCompletions[normalizedDate] ?? []

        // Calculate consumed micronutrients from completed planned meals
        for mealInstance in mealsForDate {
            if mealInstance.completion == .ateExact {
                // User ate the exact planned meal - use planned meal macros
                if let meal = getMealForType(mealInstance.mealType),
                   let macros = meal.macros {
                    totalFiber += macros.fiber
                    totalSugar += macros.sugar
                    totalSodium += macros.sodium
                }
            }
        }

        // Add micronutrients from logged meals
        let loggedMeals = loggedMealService.getLoggedMealsForDate(selectedDate)
        for loggedMeal in loggedMeals {
            totalFiber += loggedMeal.macros.fiber
            totalSugar += loggedMeal.macros.sugar
            totalSodium += loggedMeal.macros.sodium
        }

        return (fiber: totalFiber, sugar: totalSugar, sodium: totalSodium)
    }

    private var remainingMicronutrients: (fiber: Double, sugar: Double, sodium: Double) {
        let goals = dailyMicronutrientGoals
        let consumed = consumedMicronutrients

        return (
            fiber: max(0, goals.fiber - consumed.fiber),
            sugar: max(0, goals.sugar - consumed.sugar),
            sodium: max(0, goals.sodium - consumed.sodium)
        )
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
        HStack(spacing: 16) {
            // Meal info and completion check (left side)
            HStack(spacing: 12) {
                // Completion check button
                MealCompletionButton(
                    date: selectedDate,
                    mealType: mealType,
                    currentCompletion: getCurrentCompletion(for: selectedDate, mealType: mealType),
                    onMealReplacement: { replacementMealType in
                        // Handle meal replacement with camera flow
                        pendingMealType = replacementMealType
                        showingCameraForMeal = true
                    },
                    streakService: streakService
                )
                
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
            NavigationLink(destination: MealDetailView(dayMeal: dayMeal, mealType: mealType, selectedDate: selectedDate).environmentObject(appState)) {
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
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
        .overlay(
            // Completion overlay
            Group {
                if let completion = getCurrentCompletion(for: selectedDate, mealType: mealType),
                   completion != .none {
                    VStack {
                        HStack {
                            Spacer()
                            Text(completion == .ateExact ? "Exact" : "Similar")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(completion == .ateExact ? Color.green : Color.blue)
                                )
                        }
                        Spacer()
                    }
                    .padding(.top, 8)
                    .padding(.trailing, 8)
                }
            }
        )
        .opacity(getCurrentCompletion(for: selectedDate, mealType: mealType) != .none ? 0.7 : 1.0)
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

                        Text("(1 serving)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
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
    
    /// Get current completion status for a meal on a specific date
    private func getCurrentCompletion(for date: Date, mealType: String) -> MealCompletionType? {
        let normalizedDate = normalizeDate(date)
        let mealsForDate = streakService.weekCompletions[normalizedDate] ?? []
        let completion = mealsForDate.first { $0.mealType == mealType }?.completion
        
        // Getting completion for meal type
        // Checking meal completion data
        
        return completion
    }
    
    /// Normalize a date to midnight in the user's local timezone
    private func normalizeDate(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return calendar.date(from: components) ?? date
    }
    
    /// Get the meal for a specific meal type on the selected date
    private func getMealForType(_ mealType: String) -> Meal? {
        switch mealType.lowercased() {
        case "breakfast":
            return selectedBreakfastMeal?.meal
        case "lunch":
            return selectedLunchMeal?.meal
        case "dinner":
            return selectedDayMeal?.meal
        default:
            return nil
        }
    }
    

    
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

        // Note: Actual consumed nutrients are calculated in the main view from logged meals
        // This function just returns the goals/remaining values
        // The consumed calories are calculated separately in the view
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
                    // Using cached meal plans
                } else {
                    // Fetch fresh data and update cache
                    let freshMealPlans = try await databaseService.getUserMealPlans()
                    await MainActor.run {
                        cachedMealPlans = freshMealPlans
                        lastMealPlansUpdate = now
                    }
                    mealPlans = freshMealPlans
                    // Fetched fresh meal plans
                }
                
                // All meal plans loaded
                
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
                // Looking for meal plans for selected date
                
                let dinnerMealPlan = findDinnerMealPlanForWeek(mealPlans, weekOf: selectedDate)
                let breakfastMealPlan = findBreakfastMealPlanForWeek(mealPlans, weekOf: selectedDate)
                let lunchMealPlan = findLunchMealPlanForWeek(mealPlans, weekOf: selectedDate)
                
                // Found meal plans for breakfast, lunch, and dinner

                // Performance optimization: Use cached meal plan details or fetch if needed
                let fullDinnerMealPlan: MealPlan?
                let fullBreakfastMealPlan: MealPlan?
                let fullLunchMealPlan: MealPlan?

                // Helper function to get or fetch meal plan details with caching
                func getCachedOrFetchDetails(for mealPlan: DatabaseMealPlan?) async throws -> MealPlan? {
                    guard let mealPlan = mealPlan, let mealPlanId = mealPlan.id else { return nil }

                    // Check if we have a fresh cached version (valid for 5 minutes)
                    if let cachedDetails = await MainActor.run(body: { cachedMealPlanDetails[mealPlanId] }),
                       let lastUpdate = await MainActor.run(body: { lastMealPlanDetailsUpdate[mealPlanId] }),
                       now.timeIntervalSince(lastUpdate) < 300 {
                        // Using cached meal plan details for ID
                        return cachedDetails
                    }

                    // Fetch fresh details and cache them
                    let freshDetails = try await databaseService.getMealPlanDetails(mealPlanId: mealPlanId)
                    await MainActor.run {
                        cachedMealPlanDetails[mealPlanId] = freshDetails
                        lastMealPlanDetailsUpdate[mealPlanId] = now
                    }
                    // Fetched and cached fresh meal plan details
                    return freshDetails
                }

                // Fetch all meal plan details in parallel (using cache when available)
                async let dinnerDetails = try getCachedOrFetchDetails(for: dinnerMealPlan)
                async let breakfastDetails = try getCachedOrFetchDetails(for: breakfastMealPlan)
                async let lunchDetails = try getCachedOrFetchDetails(for: lunchMealPlan)

                // Wait for all parallel operations to complete
                (fullDinnerMealPlan, fullBreakfastMealPlan, fullLunchMealPlan) =
                    try await (dinnerDetails, breakfastDetails, lunchDetails)
                
                // Process dinner meal
                var dayMeal: DayMeal? = nil
                var dinnerPlanId: UUID? = nil
                if let dinnerPlan = fullDinnerMealPlan {
                    // Looking for dinner meal with expected day index
                    dayMeal = dinnerPlan.dayMeals.first { dayMealItem in
                        dayMealItem.dayIndex == expectedDayIndex
                    }
                    dinnerPlanId = dinnerMealPlan?.id
                    // Found dinner meal
                }
                
                // Process breakfast meal
                var breakfastMeal: DayMeal? = nil
                var breakfastPlanId: UUID? = nil
                if let breakfastPlan = fullBreakfastMealPlan {
                    // Looking for breakfast meal
                    breakfastMeal = breakfastPlan.dayMeals.first { dayMeal in
                        dayMeal.dayIndex == expectedDayIndex
                    }
                    breakfastPlanId = breakfastMealPlan?.id
                    // Found breakfast meal
                }
                
                // Process lunch meal
                var lunchMeal: DayMeal? = nil
                var lunchPlanId: UUID? = nil
                if let lunchPlan = fullLunchMealPlan {
                    // Looking for lunch meal
                    lunchMeal = lunchPlan.dayMeals.first { dayMeal in
                        dayMeal.dayIndex == expectedDayIndex
                    }
                    lunchPlanId = lunchMealPlan?.id
                    // Found lunch meal
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
        // Looking for breakfast meal plan for week
        
        let result = mealPlans.first { plan in
            // Check if this meal plan was created during the specified week AND is a breakfast meal plan
            let createdDuringWeek = mealPlanCreatedDuringWeek(plan, weekOf: date)
            let isBreakfast = plan.mealPlanType == "breakfast"
            
            // Checking meal plan
            print("    - Match: \(createdDuringWeek && isBreakfast)")
            
            return createdDuringWeek && isBreakfast
        }
        
        // Found breakfast meal plan result
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
        // Checking if meal plan was created during target week
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
            // No createdAt found for meal plan
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
            // Failed to parse createdAt for meal plan
            return false
        }
        
        let weekInterval = getWeekInterval(for: date)
        let isInWeek = finalCreatedAt >= weekInterval.start && finalCreatedAt <= weekInterval.end
        // Checking meal plan timing
        return isInWeek
    }
    
    /// Finds meal plan that was created during a specific week
    private func findMealPlanForWeek(_ mealPlans: [DatabaseMealPlan], weekOf date: Date) -> DatabaseMealPlan? {
        return mealPlans.first { mealPlan in
            mealPlanCreatedDuringWeek(mealPlan, weekOf: date)
        }
    }
    
    // MARK: - Meal Analysis
    private func analyzeMealImage(_ image: UIImage) {
        isAnalyzingMeal = true

        Task {
            do {
                let result = try await OpenAIService.shared.analyzeMealImage(image)

                await MainActor.run {
                    self.mealAnalysisResult = result
                    self.isAnalyzingMeal = false
                    self.showingMealAnalysis = true
                }
            } catch {
                await MainActor.run {
                    self.isAnalyzingMeal = false
                    print("❌ Error analyzing meal: \(error)")
                }
            }
        }
    }

    // MARK: - Analyze and Log Exercise
    private func analyzeAndLogExercise() {
        guard !exerciseDescription.isEmpty else { return }

        print("🏃 Starting exercise analysis...")

        Task {
            do {
                // Analyze the exercise description
                let analysisResult = try await ExerciseService.shared.analyzeExercise(description: exerciseDescription)

                await MainActor.run {
                    // Log the exercise
                    ExerciseService.shared.logExercise(from: analysisResult, loggedDate: selectedDate)

                    // Clear the description
                    exerciseDescription = ""

                    // Close the sheet
                    showingExerciseLogging = false

                    print("✅ Exercise logged successfully!")
                }

                // Wait a moment for the database operation to complete
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

                await MainActor.run {
                    // Refresh exercises to ensure UI updates
                    exerciseService.refreshExercises()

                    // Reload daily nutrition to include exercise calories
                    loadDailyNutrition()

                    print("✅ UI refreshed with new exercise data!")
                }
            } catch {
                await MainActor.run {
                    print("❌ Error analyzing exercise: \(error)")
                    // TODO: Show error alert to user
                }
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
    let isComplete: Bool
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
                            .stroke(
                                isComplete ? Color.orange : (isToday && !isSelected ? Color.green : Color.clear),
                                lineWidth: isComplete ? 2 : 1
                            )
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

struct MainAppMacroCard: View {
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

// MARK: - Meal Completion Button
struct MealCompletionButton: View {
    let date: Date
    let mealType: String
    let currentCompletion: MealCompletionType?
    let onMealReplacement: (String) -> Void
    
    @ObservedObject var streakService: StreakService
    @State private var showingCompletionSheet = false
    
    var body: some View {
        Button(action: {
            showingCompletionSheet = true
        }) {
            Image(systemName: currentCompletion?.icon ?? "circle")
                .font(.title3)
                .foregroundColor(currentCompletion?.color ?? .gray)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingCompletionSheet) {
            MealCompletionSheet(
                date: date,
                mealType: mealType,
                currentCompletion: currentCompletion ?? .none,
                streakService: streakService,
                onMealReplacement: onMealReplacement
            )
        }
    }
}

// MARK: - Meal Completion Sheet
struct MealCompletionSheet: View {
    let date: Date
    let mealType: String
    let currentCompletion: MealCompletionType
    let onMealReplacement: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var streakService: StreakService
    @State private var localCompletion: MealCompletionType
    @State private var isUpdating = false
    
    init(date: Date, mealType: String, currentCompletion: MealCompletionType, streakService: StreakService, onMealReplacement: @escaping (String) -> Void) {
        self.date = date
        self.mealType = mealType
        self.currentCompletion = currentCompletion
        self.onMealReplacement = onMealReplacement
        self.streakService = streakService
        self._localCompletion = State(initialValue: currentCompletion)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Mark \(mealType.capitalized) Complete")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Did you eat this meal today?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // Completion options
                VStack(spacing: 16) {
                    // Ate exact meal
                    exactMealButton
                    
                    // Ate similar meal
                    similarMealButton
                    
                    // Undo completion
                    if localCompletion != .none {
                        undoButton
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 32)
                
                // Save button
                if localCompletion != currentCompletion {
                    saveButton
                }
                
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
    
    // MARK: - Button Views
    
    private var exactMealButton: some View {
        Button(action: {
            updateCompletion(.ateExact)
        }) {
            HStack(spacing: 12) {
                Image(systemName: localCompletion == .ateExact ? "checkmark.circle.fill" : "checkmark.circle")
                    .font(.title2)
                    .foregroundColor(localCompletion == .ateExact ? .green : .gray)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("✅ I ate this meal")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Exactly as planned")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if localCompletion == .ateExact {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(exactMealButtonBackground)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isUpdating)
    }
    
    private var similarMealButton: some View {
        Button(action: {
            // Call the replacement callback and dismiss
            onMealReplacement(mealType.lowercased())
            dismiss()
        }) {
            HStack(spacing: 12) {
                Image(systemName: localCompletion == .ateSimilar ? "checkmark.circle.fill" : "checkmark.circle")
                    .font(.title2)
                    .foregroundColor(localCompletion == .ateSimilar ? .blue : .gray)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("📷 I ate something else")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Log a different meal with camera")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if localCompletion == .ateSimilar {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(similarMealButtonBackground)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isUpdating)
    }
    
    private var undoButton: some View {
        Button(action: {
            updateCompletion(.none)
        }) {
            HStack(spacing: 12) {
                Image(systemName: "xmark.circle")
                    .font(.title2)
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("❌ Undo completion")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Mark as not completed")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(undoButtonBackground)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isUpdating)
    }
    
    private var saveButton: some View {
        Button(action: {
            saveCompletion()
        }) {
            HStack {
                if isUpdating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                    Text("Saving...")
                } else {
                    Text("Save Changes")
                }
            }
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green)
            )
        }
        .disabled(isUpdating)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Background Views
    
    private var exactMealButtonBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(localCompletion == .ateExact ? Color.green.opacity(0.2) : Color.green.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(localCompletion == .ateExact ? Color.green : Color.green.opacity(0.3), lineWidth: localCompletion == .ateExact ? 2 : 1)
            )
    }
    
    private var similarMealButtonBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(localCompletion == .ateSimilar ? Color.blue.opacity(0.2) : Color.blue.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(localCompletion == .ateSimilar ? Color.blue : Color.blue.opacity(0.3), lineWidth: localCompletion == .ateSimilar ? 2 : 1)
            )
    }
    
    private var undoButtonBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.red.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
            )
    }
    
    // MARK: - Helper Methods
    
    private func updateCompletion(_ completion: MealCompletionType) {
        localCompletion = completion
    }
    
    private func saveCompletion() {
        guard localCompletion != currentCompletion else { return }
        
        isUpdating = true
        
        Task {
            do {
                try await streakService.markMeal(date: date, mealType: mealType, as: localCompletion)
                await MainActor.run {
                    isUpdating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isUpdating = false
                    print("❌ Error saving completion: \(error)")
                }
            }
        }
    }
}

// MARK: - Streak Details View
struct StreakDetailsView: View {
    @EnvironmentObject var streakService: StreakService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .font(.title)
                            .foregroundColor(.orange)
                        
                        Text("Your Streaks")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    Text("Track your meal completion consistency")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // Streak stats
                VStack(spacing: 20) {
                    // Current streak
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Streak")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("\(streakService.currentStreak) days")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "flame.fill")
                            .font(.title)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                    )
                    
                    // Best streak
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Best Streak")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("\(streakService.bestStreak) days")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "trophy.fill")
                            .font(.title)
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
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

// MARK: - Swipeable Nutrition Card Component
struct SwipeableNutritionCard: View {
    let totalCaloriesForSelectedDay: Int
    let remainingCaloriesForSelectedDay: Int
    let caloriesProgress: Double
    let progressRingColor: Color
    let userData: UserOnboardingData
    let dailyMicronutrientGoals: (fiber: Double, sugar: Double, sodium: Double)
    let consumedMicronutrients: (fiber: Double, sugar: Double, sodium: Double)
    let remainingMicronutrients: (fiber: Double, sugar: Double, sodium: Double)

    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Page 1: Calories
                caloriesView
                    .frame(width: geometry.size.width)

                // Page 2: Macros
                macrosView
                    .frame(width: geometry.size.width)

                // Page 3: Micronutrients
                micronutrientsView
                    .frame(width: geometry.size.width)
            }
            .offset(x: -CGFloat(currentPage) * geometry.size.width + dragOffset)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)
            .animation(.interactiveSpring(), value: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        let velocity = value.velocity.width

                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            if value.translation.width > threshold || velocity > 500 {
                                // Swipe right - go to previous page
                                currentPage = max(0, currentPage - 1)
                            } else if value.translation.width < -threshold || velocity < -500 {
                                // Swipe left - go to next page
                                currentPage = min(2, currentPage + 1)
                            }
                            dragOffset = 0
                        }
                    }
            )
        }
        .frame(minHeight: 220)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(currentPage == index ? Color.primary : Color.primary.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.bottom, 8),
            alignment: .bottom
        )
        .clipped()
    }
    
    // MARK: - Calories View (Page 1)
    private var caloriesView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(remainingCaloriesForSelectedDay)")
                    .font(.system(size: 48, weight: .bold, design: .default))
                    .foregroundColor(.primary)
                
                Text("Remaining calories")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if totalCaloriesForSelectedDay - remainingCaloriesForSelectedDay > 0 {
                    Text("Consumed: \(totalCaloriesForSelectedDay - remainingCaloriesForSelectedDay) cal")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Text("Goal: \(totalCaloriesForSelectedDay) cal")
                    .font(.caption)
                    .foregroundColor(Color.gray.opacity(0.6))
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
                        progressRingColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundColor(progressRingColor)
                    
                    Text("\(Int(caloriesProgress * 100))%")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(progressRingColor)
                }
            }
        }
        .padding(20)
    }
    
    // MARK: - Macros View (Page 2)
    private var macrosView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Daily Macros")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: "chart.pie.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            HStack(spacing: 12) {
                // Carbs
                CompactMacroCard(
                    value: "\(dailyCarbs)g",
                    label: "Carbs",
                    icon: "🌾",
                    color: .orange
                )
                
                // Protein
                CompactMacroCard(
                    value: "\(dailyProtein)g",
                    label: "Protein",
                    icon: "🥩",
                    color: .red
                )
                
                // Fats
                CompactMacroCard(
                    value: "\(dailyFats)g",
                    label: "Fats",
                    icon: "🥑",
                    color: .yellow
                )
            }
        }
        .padding(20)
    }
    
    // MARK: - Computed Properties for Macros (defensive)
    private var dailyCarbs: Int {
        guard let plan = userData.nutritionPlan else {
            let calories = max(totalCaloriesForSelectedDay, 1200)
            // 40% carbs, 4 cal/g - with extra safety checks
            guard calories > 0 else { return 120 } // Fallback: 120g carbs
            let carbCalories = Double(calories) * 0.4
            let carbGrams = carbCalories / 4.0
            return max(Int(carbGrams), 50) // Minimum 50g carbs
        }
        return max(plan.dailyCarbs, 50)
    }
    
    private var dailyProtein: Int {
        guard let plan = userData.nutritionPlan else {
            let calories = max(totalCaloriesForSelectedDay, 1200)
            // 30% protein, 4 cal/g - with extra safety checks
            guard calories > 0 else { return 90 } // Fallback: 90g protein
            let proteinCalories = Double(calories) * 0.3
            let proteinGrams = proteinCalories / 4.0
            return max(Int(proteinGrams), 50) // Minimum 50g protein
        }
        return max(plan.dailyProtein, 50)
    }
    
    private var dailyFats: Int {
        guard let plan = userData.nutritionPlan else {
            let calories = max(totalCaloriesForSelectedDay, 1200)
            // 30% fats, 9 cal/g - with extra safety checks
            guard calories > 0 else { return 40 } // Fallback: 40g fats
            let fatCalories = Double(calories) * 0.3
            let fatGrams = fatCalories / 9.0
            return max(Int(fatGrams), 25) // Minimum 25g fats
        }
        return max(plan.dailyFats, 25)
    }

    // MARK: - Micronutrients View (Page 3)
    private var micronutrientsView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Daily Micronutrients")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.purple)
            }

            VStack(spacing: 10) {
                // Fiber
                micronutrientRow(
                    icon: "leaf.circle.fill",
                    name: "Fiber",
                    remaining: remainingMicronutrients.fiber,
                    goal: dailyMicronutrientGoals.fiber,
                    unit: "g",
                    color: .green
                )

                Divider()

                // Sugar
                micronutrientRow(
                    icon: "cube.fill",
                    name: "Sugar",
                    remaining: remainingMicronutrients.sugar,
                    goal: dailyMicronutrientGoals.sugar,
                    unit: "g",
                    color: .pink
                )

                Divider()

                // Sodium
                micronutrientRow(
                    icon: "drop.triangle.fill",
                    name: "Sodium",
                    remaining: remainingMicronutrients.sodium,
                    goal: dailyMicronutrientGoals.sodium,
                    unit: "mg",
                    color: .cyan
                )
            }
        }
        .padding(20)
    }

    // MARK: - Micronutrient Row Component
    private func micronutrientRow(icon: String, name: String, remaining: Double, goal: Double, unit: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text("\(Int(remaining))/\(Int(goal)) \(unit) left")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Progress indicator
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 8)

                let progress = goal > 0 ? max(0, min(1.0, remaining / goal)) : 0
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: 60 * CGFloat(progress), height: 8)
            }
        }
    }
}

// MARK: - Compact Macro Card for Swipeable Card
struct CompactMacroCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.title2)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

#Preview {
    ContentView()
}
