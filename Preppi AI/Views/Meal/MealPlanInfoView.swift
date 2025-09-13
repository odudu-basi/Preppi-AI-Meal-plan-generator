import SwiftUI

struct MealPlanInfoView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCuisines: [String] = []
    @State private var showingCuisinePicker = false
    @State private var isGenerating = false
    @State private var mealPreparationStyle: MealPreparationStyle = .newMealEveryTime
    @State private var selectedMealCount: Int = 3
    
    private let availableCuisines = [
        "American Classic",
        "Italian", 
        "Mexican",
        "Chinese",
        "Indian",
        "Japanese",
        "Mediterranean",
        "Thai",
        "French",
        "Korean",
        "Greek",
        "Soul Food / Southern"
    ]
    
    private let maxCuisines = 3
    
    enum MealPreparationStyle: String, CaseIterable {
        case newMealEveryTime = "New Meal Every Time"
        case multiplePortions = "Multiple Portions"
        
        var description: String {
            switch self {
            case .newMealEveryTime:
                return "Cook fresh meals daily with variety and new recipes"
            case .multiplePortions:
                return "Meal prep larger batches to save time and repeat meals"
            }
        }
        
        var icon: String {
            switch self {
            case .newMealEveryTime:
                return "sparkles"
            case .multiplePortions:
                return "square.stack.3d.up.fill"
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
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        headerSection
                        
                        // Cuisine Selection Section
                        cuisineSelectionSection
                        
                        // Selected Cuisines Display
                        if !selectedCuisines.isEmpty {
                            selectedCuisinesSection
                        }
                        
                        // Meal Preparation Style Section
                        mealPreparationSection
                        
                        Spacer(minLength: 100)
                        
                        // Create Meal Plan Button
                        createMealPlanButton
                        
                        // Bottom safe area spacing
                        Color.clear.frame(height: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Meal Plan Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showingCuisinePicker) {
            CuisinePickerView(
                availableCuisines: availableCuisines.filter { !selectedCuisines.contains($0) },
                onCuisineSelected: { cuisine in
                    selectedCuisines.append(cuisine)
                    showingCuisinePicker = false
                }
            )
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "globe.americas.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)
            
            Text("Customize Your Meal Plan")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Select up to 3 cuisines to personalize your weekly \(appState.currentMealTypeBeingCreated) plan")
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
    
    // MARK: - Cuisine Selection Section
    private var cuisineSelectionSection: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Select Your Cuisines")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(selectedCuisines.count)/\(maxCuisines)")
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.1))
                    )
            }
            
            Text("Choose cuisines that match your taste preferences. We'll create a diverse meal plan with recipes from your selected cuisines.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            // Add Cuisine Button
            if selectedCuisines.count < maxCuisines {
                Button {
                    showingCuisinePicker = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Cuisines")
                    }
                    .font(.headline)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.green.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 2)
                            )
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Selected Cuisines Section
    private var selectedCuisinesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Selected Cuisines")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(selectedCuisines, id: \.self) { cuisine in
                    CuisineTagView(
                        cuisine: cuisine,
                        onRemove: {
                            selectedCuisines.removeAll { $0 == cuisine }
                        }
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Meal Preparation Section
    private var mealPreparationSection: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Meal Preparation Style")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Text("Choose how you prefer to approach your weekly meal planning")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            VStack(spacing: 12) {
                ForEach(MealPreparationStyle.allCases, id: \.self) { style in
                    MealPreparationOptionView(
                        style: style,
                        isSelected: mealPreparationStyle == style,
                        selectedMealCount: $selectedMealCount,
                        onTap: {
                            withAnimation(.spring(response: 0.3)) {
                                mealPreparationStyle = style
                            }
                        }
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Create Meal Plan Button
    private var createMealPlanButton: some View {
        NavigationLink(destination: MealPlanningView(
            selectedCuisines: selectedCuisines,
            mealPreparationStyle: mealPreparationStyle,
            mealCount: mealPreparationStyle == .multiplePortions ? selectedMealCount : 7
        ).environmentObject(appState)) {
            HStack {
                if isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "sparkles")
                }
                Text(isGenerating ? "Creating..." : "Create Meal Plan")
                if !isGenerating {
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
                    colors: selectedCuisines.isEmpty ? [.gray.opacity(0.6), .gray.opacity(0.4)] : [.green, .mint],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(
                color: selectedCuisines.isEmpty ? .clear : .green.opacity(0.4), 
                radius: 12, 
                x: 0, 
                y: 6
            )
        }
        .disabled(selectedCuisines.isEmpty)
        .padding(.horizontal, 4)
    }
}

// MARK: - Supporting Views

struct MealPreparationOptionView: View {
    let style: MealPlanInfoView.MealPreparationStyle
    let isSelected: Bool
    @Binding var selectedMealCount: Int
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.green : Color(.systemGray5))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: style.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(isSelected ? .white : .secondary)
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(style.rawValue)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(style.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    // Selection indicator
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .green : .secondary)
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Meal count chips (only shown for multiple portions when selected)
            if style == .multiplePortions && isSelected {
                mealCountChips
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ? Color.green : Color(.systemGray4),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .shadow(
                    color: isSelected ? .green.opacity(0.2) : .black.opacity(0.05),
                    radius: isSelected ? 8 : 4,
                    x: 0,
                    y: isSelected ? 4 : 2
                )
        )
        .animation(.spring(response: 0.3), value: isSelected)
    }
    
    private var mealCountChips: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Number of unique meals:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                ForEach([3, 4], id: \.self) { count in
                    Button {
                        withAnimation(.spring(response: 0.2)) {
                            selectedMealCount = count
                        }
                    } label: {
                        Text("\(count) meals")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedMealCount == count ? .white : .green)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedMealCount == count ? Color.green : Color.green.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.green.opacity(0.3), lineWidth: selectedMealCount == count ? 0 : 1)
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!isSelected)
                    .opacity(isSelected ? 1.0 : 0.5)
                }
                
                Spacer()
            }
            
            Text("You'll cook \(selectedMealCount) unique meals in larger portions and repeat them throughout the week")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(.top, 8)
    }
}

struct CuisineTagView: View {
    let cuisine: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Text(cuisine)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.green)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.green.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct CuisinePickerView: View {
    let availableCuisines: [String]
    let onCuisineSelected: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Text("Choose a Cuisine")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Select from our available cuisine options")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                // Cuisine List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(availableCuisines, id: \.self) { cuisine in
                            Button {
                                onCuisineSelected(cuisine)
                            } label: {
                                HStack {
                                    Text(getCuisineEmoji(cuisine))
                                        .font(.title2)
                                    
                                    Text(cuisine)
                                        .font(.headline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "plus.circle")
                                        .font(.title3)
                                        .foregroundColor(.green)
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
                    }
                    .padding(.horizontal, 20)
                }
            }
            .background(Color(.systemGray6).opacity(0.3))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    private func getCuisineEmoji(_ cuisine: String) -> String {
        switch cuisine {
        case "American Classic": return "🇺🇸"
        case "Italian": return "🇮🇹"
        case "Mexican": return "🇲🇽"
        case "Chinese": return "🇨🇳"
        case "Indian": return "🇮🇳"
        case "Japanese": return "🇯🇵"
        case "Mediterranean": return "🫒"
        case "Thai": return "🇹🇭"
        case "French": return "🇫🇷"
        case "Korean": return "🇰🇷"
        case "Greek": return "🇬🇷"
        case "Soul Food / Southern": return "🍗"
        default: return "🍽️"
        }
    }
}

#Preview {
    MealPlanInfoView()
        .environmentObject(AppState())
}