import SwiftUI

struct ProgressTabView: View {

    // MARK: - TimeFrame Enum
    enum TimeFrame: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case threeMonths = "3 Months"
        
        var days: Int {
            switch self {
            case .week:
                return 7
            case .month:
                return 30
            case .threeMonths:
                return 90
            }
        }
    }
    @EnvironmentObject var appState: AppState
    @State private var showingNewCycleForm = false
    @State private var showingPaceEditor = false
    @State private var showResetConfirmation = false

    // Check if user has a start date
    private var hasStartDate: Bool {
        return appState.userData.progressStartDate != nil
    }

    // Calculate if 3 months have passed
    private var isThreeMonthsComplete: Bool {
        guard let startDate = appState.userData.progressStartDate else { return false }
        let threeMonthsLater = Calendar.current.date(byAdding: .day, value: 90, to: startDate) ?? startDate
        return Date() >= threeMonthsLater
    }
    
    // Calculate current week number (1-12)
    private var currentWeekNumber: Int {
        let startDate = effectiveStartDate
        let daysPassed = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return min(max((daysPassed / 7) + 1, 1), 12)
    }
    
    // Get the effective start date (progress start date only)
    private var effectiveStartDate: Date {
        if let progressStartDate = appState.userData.progressStartDate {
            print("📅 Using progress start date: \(progressStartDate)")
            return progressStartDate
        } else {
            print("⚠️ No progress start date found, using current date as fallback")
            return Date()
        }
    }
    
    // Calculate three month end date
    private var threeMonthEndDate: Date {
        let startDate = effectiveStartDate
        let endDate = Calendar.current.date(byAdding: .day, value: 90, to: startDate) ?? Date()
        print("📅 Progress dates - Start: \(startDate), End: \(endDate)")
        return endDate
    }
    
    // Calculate days remaining until goal end date
    private var daysRemaining: Int {
        let calendar = Calendar.current
        let today = Date()
        let endDate = threeMonthEndDate
        
        let components = calendar.dateComponents([.day], from: today, to: endDate)
        return max(components.day ?? 0, 0) // Don't show negative days
    }
    
    // Calculate weekly weight goal based on pace
    private var currentWeekWeightGoal: Double {
        guard let pace = appState.userData.weightLossSpeed else { 
            return appState.userData.weight 
        }
        
        let startingWeight = appState.userData.weight
        let isWeightLoss = appState.userData.healthGoals.contains(.loseWeight)
        let isWeightGain = appState.userData.healthGoals.contains(.gainWeight)
        
        if isWeightLoss {
            let weeklyLoss = pace.weeklyWeightLossLbs
            return startingWeight - (weeklyLoss * Double(currentWeekNumber))
        } else if isWeightGain {
            let weeklyGain = pace.weeklyWeightGainLbs
            return startingWeight + (weeklyGain * Double(currentWeekNumber))
        } else {
            // Maintain weight - use target range if available
            if let targetRange = appState.userData.targetWeightRange {
                return (targetRange.min + targetRange.max) / 2
            }
            return startingWeight
        }
    }
    
    // Get pace description
    private var paceDescription: String {
        guard let pace = appState.userData.weightLossSpeed else { return "No pace set" }
        
        let isWeightLoss = appState.userData.healthGoals.contains(.loseWeight)
        let isWeightGain = appState.userData.healthGoals.contains(.gainWeight)
        
        if isWeightLoss {
            return String(format: "%.1f lbs/week", pace.weeklyWeightLossLbs)
        } else if isWeightGain {
            return String(format: "%.1f lbs/week", pace.weeklyWeightGainLbs)
        } else {
            return "Maintain current weight"
        }
    }
    
    // Get target weight for display
    private var displayTargetWeight: Double {
        if let targetWeight = appState.userData.targetWeight {
            return targetWeight
        } else if let targetRange = appState.userData.targetWeightRange {
            return (targetRange.min + targetRange.max) / 2
        } else {
            return appState.userData.weight
        }
    }
    
    // Get 3-month predicted weight
    private var threeMonthPredictedWeight: Double {
        if let nutritionPlan = appState.userData.nutritionPlan {
            return nutritionPlan.predictedWeightAfter3Months
        } else {
            // Fallback calculation based on pace
            guard let pace = appState.userData.weightLossSpeed else { return appState.userData.weight }
            
            let startingWeight = appState.userData.weight
            let isWeightLoss = appState.userData.healthGoals.contains(.loseWeight)
            let isWeightGain = appState.userData.healthGoals.contains(.gainWeight)
            
            if isWeightLoss {
                return startingWeight - (pace.weeklyWeightLossLbs * 12) // 12 weeks = 3 months
            } else if isWeightGain {
                return startingWeight + (pace.weeklyWeightGainLbs * 12)
            } else {
                return startingWeight
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color("AppBackground"),
                        Color(.systemGray6).opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if isThreeMonthsComplete {
                    // Show congratulations overlay with restart button
                    congratulationsOverlay
                } else {
                    // Show normal progress content
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header
                            headerSection

                            // Weekly Target Card (only show if started)
                            if hasStartDate {
                                weeklyTargetCard
                            }

                            // 3-Month Overview Card with overlay if no start date
                            ZStack {
                                threeMonthOverviewCard
                                    .opacity(hasStartDate ? 1.0 : 0.3)

                                if !hasStartDate {
                                    startJourneyOverlay
                                }
                            }

                            // Reset Button (only show if started)
                            if hasStartDate {
                                resetProgressButton
                            }

                            // Bottom spacing
                            Color.clear.frame(height: 20)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingNewCycleForm) {
            NewCycleFormView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingPaceEditor) {
            PaceEditorView()
                .environmentObject(appState)
        }
        .alert("Reset Progress?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetProgressStartDate()
            }
        } message: {
            Text("This will reset your progress tracking start date. Your logged meals and other data will not be affected. Are you sure you want to restart?")
        }
    }

    // MARK: - Actions

    private func startProgressTracking() {
        print("🚀 Starting progress tracking...")
        var updatedUserData = appState.userData
        updatedUserData.progressStartDate = Date()

        Task {
            await appState.updateProfile(with: updatedUserData)
            print("✅ Progress tracking started on \(Date())")
        }
    }

    private func restartProgressTracking() {
        print("🔄 Restarting progress tracking after 3 months completion...")
        var updatedUserData = appState.userData
        updatedUserData.progressStartDate = Date()

        Task {
            await appState.updateProfile(with: updatedUserData)
            print("✅ Progress tracking restarted on \(Date())")
        }
    }

    private func resetProgressStartDate() {
        print("⚠️ Resetting progress start date...")
        var updatedUserData = appState.userData
        updatedUserData.progressStartDate = nil

        Task {
            await appState.updateProfile(with: updatedUserData)
            print("✅ Progress start date reset")
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your 3-Month Journey")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Track your progress towards your health goals")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var threeMonthOverviewCard: some View {
        VStack(spacing: 20) {
            // Card Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("3-Month Overview")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Started \(formatDate(effectiveStartDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Progress indicator
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(currentWeekNumber) / 12.0)
                        .stroke(
                            LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(currentWeekNumber)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            
            // Weight Information Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // Starting Weight
                weightInfoCard(
                    title: "Starting Weight",
                    value: String(format: "%.1f lbs", appState.userData.weight),
                    icon: "scalemass",
                    color: .blue
                )
                
                // Target Weight
                weightInfoCard(
                    title: "Target Weight",
                    value: String(format: "%.1f lbs", displayTargetWeight),
                    icon: "target",
                    color: .orange
                )
                
                // 3-Month Goal
                weightInfoCard(
                    title: "3-Month Goal",
                    value: String(format: "%.1f lbs", threeMonthPredictedWeight),
                    icon: "calendar",
                    color: .green
                )
                
                // Pace - Tappable
                Button(action: {
                    showingPaceEditor = true
                }) {
                    weightInfoCard(
                        title: "Your Pace",
                        value: paceDescription,
                        icon: "speedometer",
                        color: .purple
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // End Date - Make it more prominent
            VStack(spacing: 8) {
            HStack {
                    Image(systemName: "flag.checkered")
                        .foregroundColor(.green)
                        .font(.title2)
                    
                    Text("3-Month Goal Ends")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Target Date")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatGoalDate(threeMonthEndDate))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Days Remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
                        
                        Text("\(daysRemaining)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.1), Color.mint.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var weeklyTargetCard: some View {
        VStack(spacing: 16) {
            // Card Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Week \(currentWeekNumber) Target")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    
                    Text("Your goal for this week")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.green)
                    .font(.title2)
            }
            
            // Weekly Goal Display
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Target Weight")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(String(format: "%.1f lbs", currentWeekWeightGoal))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Week \(currentWeekNumber) of 12")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("\(Int((Double(currentWeekNumber) / 12.0) * 100))% Complete")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * (CGFloat(currentWeekNumber) / 12.0), height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6).opacity(0.5))
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Start Journey Overlay
    private var startJourneyOverlay: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.walk")
                .font(.system(size: 50))
                .foregroundColor(.green)

            Text("Start Your Journey")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text("Begin tracking your 3-month progress today!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: startProgressTracking) {
                Text("Start")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 180)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
        )
    }

    // MARK: - Congratulations Overlay
    private var congratulationsOverlay: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "party.popper")
                    .font(.system(size: 60))
                    .foregroundColor(.green)

                Text("Congratulations!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("You've completed your 3-month journey! Ready to start the next 3 months?")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button(action: restartProgressTracking) {
                Text("Restart for Next 3 Months")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Reset Button
    private var resetProgressButton: some View {
        Button(action: {
            showResetConfirmation = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .semibold))

                Text("Reset Progress Start Date")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Views
    
    private func weightInfoCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
    
    // MARK: - Helper Functions
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
    
    private func formatGoalDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - New Cycle Form View

struct NewCycleFormView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedGoal: HealthGoal = .maintainWeight
    @State private var currentWeight: String = ""
    @State private var targetWeight: String = ""
    @State private var selectedPace: WeightLossSpeed = .medium
    @State private var minWeight: Double = 0.0
    @State private var maxWeight: Double = 0.0
    @State private var isLoading = false
    
    private let weightGoals: [HealthGoal] = [.loseWeight, .gainWeight, .maintainWeight]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Set New Goals")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Configure your next 3-month journey")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Goal Selection
                    goalSelectionSection
                    
                    // Current Weight
                    currentWeightSection
                    
                    // Target Weight (conditional)
                    if selectedGoal != .maintainWeight {
                        targetWeightSection
                        paceSelectionSection
                    } else {
                        weightRangeSection
                    }
                    
                    // Start Button
                    Button(action: startNewCycle) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Start New Cycle")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .disabled(isLoading || !isFormValid)
                    .opacity(isFormValid ? 1.0 : 0.6)
                    
                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.green)
                }
            }
        }
        .onAppear {
            currentWeight = String(format: "%.1f", appState.userData.weight)
        }
    }
    
    // MARK: - Form Sections
    
    private var goalSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weight Goal")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(weightGoals, id: \.self) { goal in
                Button(action: {
                    selectedGoal = goal
                }) {
                    HStack {
                        Image(systemName: goal.icon)
                            .foregroundColor(selectedGoal == goal ? .white : goal == .loseWeight ? .blue : goal == .gainWeight ? .orange : .green)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(goal.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(selectedGoal == goal ? .white : .primary)
                            
                            Text(goal.description)
                                .font(.caption)
                                .foregroundColor(selectedGoal == goal ? .white.opacity(0.8) : .secondary)
                        }
                        
                        Spacer()
                        
                        if selectedGoal == goal {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedGoal == goal ? .green : Color(.systemGray6))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var currentWeightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Weight")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                TextField("Enter weight", text: $currentWeight)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Text("lbs")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
    }
}

    private var targetWeightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Target Weight")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                TextField("Enter target weight", text: $targetWeight)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Text("lbs")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var weightRangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weight Range")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Set your comfortable weight range for maintenance")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
            VStack(alignment: .leading, spacing: 4) {
                    Text("Min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Min", value: $minWeight, format: .number.precision(.fractionLength(1)))
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Text("-")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .padding(.top, 16)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Max")
                    .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Max", value: $maxWeight, format: .number.precision(.fractionLength(1)))
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Text("lbs")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 16)
            }
        }
    }
    
    private var paceSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pace")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(WeightLossSpeed.allCases, id: \.self) { pace in
                Button(action: {
                    selectedPace = pace
                }) {
                    HStack {
                        Image(systemName: pace.icon)
                            .foregroundColor(selectedPace == pace ? .white : .green)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pace.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(selectedPace == pace ? .white : .primary)
                            
                            Text(pace.description(isWeightLoss: selectedGoal == .loseWeight))
                                .font(.caption)
                                .foregroundColor(selectedPace == pace ? .white.opacity(0.8) : .secondary)
                        }
                        
                        Spacer()
                        
                        if selectedPace == pace {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                        }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                            .fill(selectedPace == pace ? .green : Color(.systemGray6))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Form Validation
    
    private var isFormValid: Bool {
        guard let currentWeightValue = Double(currentWeight), currentWeightValue > 0 else {
            return false
        }
        
        if selectedGoal == .maintainWeight {
            return minWeight > 0 && maxWeight > minWeight
        } else {
            guard let targetWeightValue = Double(targetWeight), targetWeightValue > 0 else {
                return false
            }
            return true
        }
    }
    
    // MARK: - Actions
    
    private func startNewCycle() {
        isLoading = true
        
        Task {
            // Update user data with new goals
            var updatedUserData = appState.userData
            updatedUserData.weight = Double(currentWeight) ?? appState.userData.weight
            updatedUserData.healthGoals = [selectedGoal]
            updatedUserData.weightLossSpeed = selectedGoal == .maintainWeight ? nil : selectedPace
            updatedUserData.onboardingCompletedAt = Date() // Reset the 3-month cycle
            
            if selectedGoal == .maintainWeight {
                updatedUserData.targetWeight = nil
                updatedUserData.targetWeightRange = WeightRange(min: minWeight, max: maxWeight)
            } else {
                updatedUserData.targetWeight = Double(targetWeight)
                updatedUserData.targetWeightRange = nil
            }
            
            // Update the app state
            await appState.updateProfile(with: updatedUserData)
            
            await MainActor.run {
                isLoading = false
                dismiss()
            }
        }
    }
}

// MARK: - Pace Editor View

struct PaceEditorView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPace: WeightLossSpeed = .medium
    @State private var isLoading = false
    
    private var isWeightLoss: Bool {
        appState.userData.healthGoals.contains(.loseWeight)
    }
    
    private var isWeightGain: Bool {
        appState.userData.healthGoals.contains(.gainWeight)
    }
    
    private var goalType: String {
        if isWeightLoss {
            return "Weight Loss"
        } else if isWeightGain {
            return "Weight Gain"
        } else {
            return "Weight Management"
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
        VStack(spacing: 8) {
                        Text("Update Your Pace")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Adjust your \(goalType.lowercased()) pace")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Current vs New Comparison
                    if let currentPace = appState.userData.weightLossSpeed {
                        VStack(spacing: 12) {
                            Text("Current Pace")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            paceComparisonCard(
                                pace: currentPace,
                                isSelected: false,
                                showAsCurrent: true
                            )
                        }
                        
                        if selectedPace != currentPace {
                            VStack(spacing: 12) {
                                Text("New Pace")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                
                                paceComparisonCard(
                                    pace: selectedPace,
                                    isSelected: true,
                                    showAsCurrent: false
                                )
                            }
                        }
                    }
                    
                    // Pace Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose Your Pace")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ForEach(WeightLossSpeed.allCases, id: \.self) { pace in
                            Button(action: {
                                selectedPace = pace
                            }) {
            HStack {
                                    Image(systemName: pace.icon)
                                        .foregroundColor(selectedPace == pace ? .white : .green)
                    .font(.title3)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(pace.title)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(selectedPace == pace ? .white : .primary)
                                        
                                        Text(pace.description(isWeightLoss: isWeightLoss))
                                            .font(.caption)
                                            .foregroundColor(selectedPace == pace ? .white.opacity(0.8) : .secondary)
                                    }
                
                Spacer()
                                    
                                    if selectedPace == pace {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedPace == pace ? .green : Color(.systemGray6))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    // Impact Summary
                    if let currentPace = appState.userData.weightLossSpeed, selectedPace != currentPace {
                        impactSummaryCard
                    }
                    
                    // Update Button
                    Button(action: updatePace) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Update Pace")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .disabled(isLoading)
                    .opacity(hasChanges ? 1.0 : 0.6)
                    
                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.green)
                }
            }
        }
        .onAppear {
            // Set the selected pace to current pace when view appears
            selectedPace = appState.userData.weightLossSpeed ?? .medium
        }
    }
    
    // MARK: - Helper Views
    
    private func paceComparisonCard(pace: WeightLossSpeed, isSelected: Bool, showAsCurrent: Bool) -> some View {
        HStack {
            Image(systemName: pace.icon)
                .foregroundColor(showAsCurrent ? .gray : .green)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(pace.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if isWeightLoss {
                    Text("\(pace.weeklyWeightLossLbs, specifier: "%.1f") lbs/week")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if isWeightGain {
                    Text("\(pace.weeklyWeightGainLbs, specifier: "%.1f") lbs/week")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if showAsCurrent {
                Text("Current")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(showAsCurrent ? Color(.systemGray6) : Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(showAsCurrent ? Color.clear : Color.green, lineWidth: 1)
                )
        )
    }
    
    private var impactSummaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text("Impact of Change")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text("Weekly Goal:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if isWeightLoss {
                        Text("\(selectedPace.weeklyWeightLossLbs, specifier: "%.1f") lbs/week")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    } else if isWeightGain {
                        Text("\(selectedPace.weeklyWeightGainLbs, specifier: "%.1f") lbs/week")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                }
                
                HStack {
                    Text("3-Month Goal:")
                        .font(.subheadline)
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    let newThreeMonthGoal = calculateNewThreeMonthGoal()
                    Text("\(newThreeMonthGoal, specifier: "%.1f") lbs")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
    }
    
    // MARK: - Computed Properties
    
    private var hasChanges: Bool {
        selectedPace != appState.userData.weightLossSpeed
    }
    
    // MARK: - Helper Functions
    
    private func calculateNewThreeMonthGoal() -> Double {
        let startingWeight = appState.userData.weight
        
        if isWeightLoss {
            return startingWeight - (selectedPace.weeklyWeightLossLbs * 12) // 12 weeks = 3 months
        } else if isWeightGain {
            return startingWeight + (selectedPace.weeklyWeightGainLbs * 12)
        } else {
            return startingWeight
        }
    }
    
    // MARK: - Actions
    
    private func updatePace() {
        guard hasChanges else { return }
        
        // Update user data with new pace and recalculate nutrition plan
        var updatedUserData = appState.userData
        updatedUserData.weightLossSpeed = selectedPace
        
        // Update nutrition plan to reflect new pace
        print("🔄 Pace changed, updating nutrition plan...")
        let updatedNutritionPlan = CalorieCalculationService.shared.updateNutritionPlan(for: updatedUserData)
        updatedUserData.nutritionPlan = updatedNutritionPlan
        print("✅ Nutrition plan updated: \(updatedNutritionPlan.dailyCalories) calories")
        
        // Update the app state immediately
        appState.userData = updatedUserData
        
        // Dismiss the sheet
        dismiss()
        
        // Update database in background after dismissing
        Task {
            do {
                let databaseService = LocalUserDataService.shared
                try await databaseService.updateUserProfile(updatedUserData)
                print("✅ Pace and nutrition plan updated successfully in database")
            } catch {
                print("❌ Failed to update pace in database: \(error)")
            }
        }
    }
}

#Preview {
    ProgressTabView()
        .environmentObject(AppState())
}