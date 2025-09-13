import SwiftUI

struct MealDetailedRecipeView: View {
    let dayMeal: DayMeal
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color("AppBackground"),
                    Color(.systemGray6).opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Recipe content sections
                    if let detailedIngredients = dayMeal.meal.detailedIngredients {
                        detailedIngredientsSection(ingredients: detailedIngredients)
                    }
                    
                    if let detailedInstructions = dayMeal.meal.detailedInstructions {
                        cookingInstructionsSection(instructions: detailedInstructions)
                    }
                    
                    if let cookingTips = dayMeal.meal.cookingTips {
                        cookingTipsSection(tips: cookingTips)
                    }
                    
                    if let servingInfo = dayMeal.meal.servingInfo {
                        servingInfoSection(info: servingInfo)
                    }
                    
                    // Bottom spacing
                    Color.clear.frame(height: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
        }
        .navigationTitle("Recipe Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dayMeal.day)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    Text("\(appState.currentMealTypeBeingCreated.capitalized) Recipe")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
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
    private func detailedIngredientsSection(ingredients: [String]) -> some View {
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
                
                Text("\(ingredients.count) items")
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
                ForEach(Array(ingredients.enumerated()), id: \.offset) { index, ingredient in
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
    private func cookingInstructionsSection(instructions: [String]) -> some View {
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
                ForEach(Array(instructions.enumerated()), id: \.offset) { index, instruction in
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
    private func cookingTipsSection(tips: [String]) -> some View {
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
                ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
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
    private func servingInfoSection(info: String) -> some View {
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
            
            Text(info)
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
}

// MARK: - Supporting Views
// Note: IngredientRowView, InstructionStepView, and CookingTipView are shared from RecipePage.swift

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
        detailedIngredients: [
            "2 boneless skinless chicken breasts (6 oz each)",
            "1 cup quinoa",
            "3 tbsp extra virgin olive oil",
            "1 large lemon (juiced and zested)"
        ],
        detailedInstructions: [
            "Preheat your oven to 425°F and line a large baking sheet with parchment paper.",
            "In a bowl, whisk together olive oil, lemon juice, and herbs to create the marinade."
        ],
        cookingTips: [
            "Pound chicken to even thickness for uniform cooking",
            "Let chicken rest before slicing to retain juices"
        ],
        servingInfo: "Serves 2-3 people as a main course. Pairs beautifully with a simple green salad."
    )
    
    let sampleDayMeal = DayMeal(day: "Monday", meal: sampleMeal)
    
    NavigationView {
        MealDetailedRecipeView(dayMeal: sampleDayMeal)
            .environmentObject(AppState())
    }
}