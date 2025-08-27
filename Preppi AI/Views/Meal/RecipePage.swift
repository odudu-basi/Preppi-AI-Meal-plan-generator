import SwiftUI

struct RecipePage: View {
    let dayMeal: DayMeal
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var openAIService = OpenAIService.shared
    @State private var detailedRecipe: DetailedRecipe?
    @State private var isLoading = false
    @State private var hasError = false
    
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
            
            if detailedRecipe == nil && !isLoading && !hasError {
                // Initial state - Show generate button
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Meal Name Header
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text(dayMeal.meal.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 30)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 8)
                    )
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Generate Recipes Button
                    Button {
                        generateDetailedRecipe()
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Generate Recipes")
                            Image(systemName: "sparkles")
                        }
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .green.opacity(0.4), radius: 15, x: 0, y: 8)
                    }
                    .padding(.horizontal, 20)
                    .disabled(isLoading)
                    
                    Spacer()
                }
            } else if isLoading {
                // Loading state
                loadingView
            } else if hasError {
                // Error state
                errorView
            } else if let recipe = detailedRecipe {
                // Recipe content
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Recipe content sections
                        detailedIngredientsSection(recipe: recipe)
                        cookingInstructionsSection(recipe: recipe)
                        cookingTipsSection(recipe: recipe)
                        servingInfoSection(recipe: recipe)
                        
                        // Bottom spacing
                        Color.clear.frame(height: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
        }
        .navigationTitle("Recipe Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                }
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 30) {
            ZStack {
                Circle()
                    .stroke(Color.green.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        AngularGradient(
                            colors: [.green, .mint, .green],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(
                        .linear(duration: 2).repeatForever(autoreverses: false),
                        value: isLoading
                    )
                
                                                    Image(systemName: "book.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 12) {
                Text("Creating Your Recipe")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Our AI chef is crafting detailed instructions for \(dayMeal.meal.name)...")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("AppBackground").ignoresSafeArea())
    }
    
    // MARK: - Error View
    private var errorView: some View {
        VStack(spacing: 30) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)
            
            VStack(spacing: 12) {
                Text("Recipe Generation Failed")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("We couldn't generate the recipe. Please try again.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button("Try Again") {
                generateDetailedRecipe()
            }
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.green, .mint],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("AppBackground").ignoresSafeArea())
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.green)
                
                Text(dayMeal.day)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                
                Spacer()
                
                // Recipe generated badge
                HStack {
                    Image(systemName: "sparkles")
                        .font(.caption)
                    Text("AI Generated")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.green)
                )
            }
            
            Text(dayMeal.meal.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
            
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
                .padding(.horizontal, 4)
            } else {
                Text(dayMeal.meal.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Detailed Ingredients Section
    private func detailedIngredientsSection(recipe: DetailedRecipe) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "cart.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text("Shopping List")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(recipe.detailedIngredients.count) items")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
            }
            
            VStack(spacing: 12) {
                ForEach(Array(recipe.detailedIngredients.enumerated()), id: \.offset) { index, ingredient in
                    IngredientRowView(
                        ingredient: ingredient,
                        index: index + 1
                    )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Cooking Instructions Section
    private func cookingInstructionsSection(recipe: DetailedRecipe) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "list.number")
                    .font(.title3)
                    .foregroundColor(.green)
                
                Text("Cooking Instructions")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                    InstructionStepView(
                        stepNumber: index + 1,
                        instruction: instruction
                    )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Cooking Tips Section
    private func cookingTipsSection(recipe: DetailedRecipe) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.title3)
                    .foregroundColor(.yellow)
                
                Text("Chef's Tips")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(Array(recipe.cookingTips.enumerated()), id: \.offset) { index, tip in
                    CookingTipView(
                        tipNumber: index + 1,
                        tip: tip
                    )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Serving Info Section
    private func servingInfoSection(recipe: DetailedRecipe) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "hand.raised.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
                
                Text("Serving & Presentation")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Text(recipe.servingInfo)
                .font(.body)
                .foregroundColor(.primary)
                .lineSpacing(2)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Helper Functions
    private func generateDetailedRecipe() {
        Task { @MainActor in
            isLoading = true
            hasError = false
            detailedRecipe = nil
            
            do {
                let recipe = try await openAIService.generateDetailedRecipe(
                    for: dayMeal,
                    userData: appState.userData
                )
                self.detailedRecipe = recipe
                self.isLoading = false
            } catch {
                print("❌ Error generating detailed recipe: \(error)")
                self.hasError = true
                self.isLoading = false
            }
        }
    }
}

// MARK: - Supporting Views

struct IngredientRowView: View {
    let ingredient: String
    let index: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Number badge
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Text("\(index)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            // Ingredient text
            Text(ingredient)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct InstructionStepView: View {
    let stepNumber: Int
    let instruction: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Step number
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 32, height: 32)
                
                Text("\(stepNumber)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Instruction text
            Text(instruction)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineSpacing(2)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct CookingTipView: View {
    let tipNumber: Int
    let tip: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Tip icon
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
            
            // Tip text
            Text(tip)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineSpacing(2)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let sampleMeal = Meal(
        id: UUID(),
        name: "Mediterranean Grilled Chicken",
        description: "Tender grilled chicken breast marinated in Mediterranean herbs and olive oil.",
        calories: 520,
        cookTime: 35,
        ingredients: [
            "chicken breasts",
            "quinoa", 
            "olive oil",
            "lemon",
            "garlic",
            "oregano",
            "bell pepper",
            "zucchini"
        ],
        instructions: [],
        originalCookingDay: "Monday",
        imageUrl: nil,
        recommendedCaloriesBeforeDinner: 1400,
        macros: Macros(
            protein: 45.5,
            carbohydrates: 25.2,
            fat: 18.7,
            fiber: 8.3,
            sugar: 12.1,
            sodium: 590.5
        ),
        detailedIngredients: nil,
        detailedInstructions: nil,
        cookingTips: nil,
        servingInfo: nil
    )
    
    let sampleDayMeal = DayMeal(day: "Monday", meal: sampleMeal)
    
    NavigationView {
        RecipePage(dayMeal: sampleDayMeal)
            .environmentObject(AppState())
    }
}