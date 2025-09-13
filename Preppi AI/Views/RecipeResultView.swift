import SwiftUI

struct RecipeResultView: View {
    @Environment(\.dismiss) private var dismiss
    let recipeAnalysis: RecipeAnalysis
    let originalImage: UIImage
    let servings: Int
    @State private var showingImageFullscreen = false
    @State private var showingAddToCookbook = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient matching app theme
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
                        // Food Identification Header
                        VStack(spacing: 12) {
                            Image(uiImage: originalImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                .onTapGesture {
                                    showingImageFullscreen = true
                                }
                            
                            Text(recipeAnalysis.foodIdentification)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(recipeAnalysis.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .padding(.horizontal, 20)
                        
                        // Recipe Time Info and Difficulty
                        VStack(spacing: 16) {
                            HStack(spacing: 20) {
                                TimeInfoCard(title: "Prep", time: recipeAnalysis.recipe.prepTime)
                                TimeInfoCard(title: "Cook", time: recipeAnalysis.recipe.cookTime)
                                TimeInfoCard(title: "Total", time: recipeAnalysis.recipe.totalTime)
                            }
                            
                            // Difficulty Rating
                            DifficultyRatingCard(difficulty: recipeAnalysis.difficultyRating)
                        }
                        .padding(.horizontal, 20)
                        
                        // Nutrition Information
                        NutritionCard(nutrition: recipeAnalysis.nutrition, servings: servings)
                            .padding(.horizontal, 20)
                        
                        // Ingredients Section
                        IngredientsCard(ingredients: recipeAnalysis.recipe.ingredients, servings: servings)
                            .padding(.horizontal, 20)
                        
                        // Instructions Section
                        InstructionsCard(instructions: recipeAnalysis.recipe.instructions)
                            .padding(.horizontal, 20)
                        
                        // Shopping List Section
                        ShoppingListCard(items: recipeAnalysis.shoppingList)
                            .padding(.horizontal, 20)
                        
                        // Add to Cookbook Button
                    Button {
                        MixpanelService.shared.track(
                            event: MixpanelService.Events.addToCookbookButtonTapped,
                            properties: [
                                MixpanelService.Properties.recipeName: recipeAnalysis.foodIdentification,
                                MixpanelService.Properties.servings: servings,
                                MixpanelService.Properties.difficultyRating: recipeAnalysis.difficultyRating
                            ]
                        )
                        showingAddToCookbook = true
                    } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "book.closed")
                                    .font(.system(size: 18, weight: .medium))
                                
                                Text("Add to Cookbook")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 20)
                        
                        // Bottom spacing
                        Color.clear.frame(height: 40)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Back")
                                .font(.body)
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingImageFullscreen) {
            FullscreenImageView(image: originalImage)
        }
        .sheet(isPresented: $showingAddToCookbook) {
            AddToCookbookView(recipe: recipeAnalysis, image: originalImage, servings: servings) {
                // Dismiss all the way back to the main camera screen
                dismiss() // This will close the recipe result view and return to camera home screen
            }
        }
    }
}

// MARK: - Fullscreen Image View
struct FullscreenImageView: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            // Image with zoom and pan
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    SimultaneousGesture(
                        // Magnification gesture for zooming
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScale
                                lastScale = value
                                scale = min(max(scale * delta, 0.5), 4.0)
                            }
                            .onEnded { _ in
                                lastScale = 1.0
                                if scale < 1.0 {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        scale = 1.0
                                        offset = .zero
                                    }
                                }
                            },
                        
                        // Drag gesture for panning
                        DragGesture()
                            .onChanged { value in
                                let newOffset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                                offset = newOffset
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                )
                .onTapGesture(count: 2) {
                    // Double tap to zoom
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if scale > 1.0 {
                            scale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        } else {
                            scale = 2.0
                        }
                    }
                }
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                    }
                    .padding(.top, 50)
                    .padding(.trailing, 20)
                }
                Spacer()
            }
        }
    }
}

// MARK: - Supporting Views
struct TimeInfoCard: View {
    let title: String
    let time: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text(time)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }
}

struct NutritionCard: View {
    let nutrition: NutritionInfo
    let servings: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition (per serving)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                NutritionItem(label: "Calories", value: "\(nutrition.calories)")
                NutritionItem(label: "Protein", value: "\(String(format: "%.1f", nutrition.protein))g")
                NutritionItem(label: "Carbs", value: "\(String(format: "%.1f", nutrition.carbs))g")
                NutritionItem(label: "Fat", value: "\(String(format: "%.1f", nutrition.fat))g")
                NutritionItem(label: "Fiber", value: "\(String(format: "%.1f", nutrition.fiber))g")
                NutritionItem(label: "Sugar", value: "\(String(format: "%.1f", nutrition.sugar))g")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.3))
        )
    }
}

struct NutritionItem: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}

struct IngredientsCard: View {
    let ingredients: [RecipeIngredient]
    let servings: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Ingredients")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("(\(servings) serving\(servings == 1 ? "" : "s"))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(ingredients.indices, id: \.self) { index in
                    let ingredient = ingredients[index]
                    HStack(alignment: .top, spacing: 12) {
                        Text("•")
                            .font(.body)
                            .foregroundColor(.green)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(ingredient.amount) \(ingredient.unit) \(ingredient.item)")
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.3))
        )
    }
}

struct InstructionsCard: View {
    let instructions: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Instructions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 16) {
                ForEach(instructions.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.green))
                        
                        Text(instructions[index])
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.3))
        )
    }
}

struct ShoppingListCard: View {
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Shopping List")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(items.indices, id: \.self) { index in
                    HStack(spacing: 12) {
                        Image(systemName: "cart")
                            .font(.body)
                            .foregroundColor(.green)
                        
                        Text(items[index])
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.3))
        )
    }
}

struct DifficultyRatingCard: View {
    let difficulty: Int
    
    private var difficultyText: String {
        switch difficulty {
        case 1...2: return "Very Easy"
        case 3...4: return "Easy"
        case 5...6: return "Moderate"
        case 7...8: return "Hard"
        case 9...10: return "Expert"
        default: return "Unknown"
        }
    }
    
    private var difficultyColor: Color {
        switch difficulty {
        case 1...2: return .green
        case 3...4: return .mint
        case 5...6: return .orange
        case 7...8: return .red
        case 9...10: return .purple
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Difficulty Stars
            HStack(spacing: 4) {
                ForEach(1...10, id: \.self) { index in
                    Image(systemName: index <= difficulty ? "star.fill" : "star")
                        .font(.system(size: 14))
                        .foregroundColor(index <= difficulty ? difficultyColor : .gray.opacity(0.3))
                }
            }
            
            Spacer()
            
            // Difficulty Text and Rating
            VStack(alignment: .trailing, spacing: 2) {
                Text("Difficulty")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Text(difficultyText)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(difficultyColor)
                    
                    Text("(\(difficulty)/10)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(difficultyColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(difficultyColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    RecipeResultView(
        recipeAnalysis: RecipeAnalysis(
            foodIdentification: "Chicken Stir Fry",
            description: "A delicious and healthy stir fry with fresh vegetables",
            recipe: RecipeDetails(
                ingredients: [
                    RecipeIngredient(item: "chicken breast", amount: "200", unit: "g"),
                    RecipeIngredient(item: "bell peppers", amount: "1", unit: "cup")
                ],
                instructions: ["Heat oil in pan", "Add chicken and cook"],
                prepTime: "15 min",
                cookTime: "10 min",
                totalTime: "25 min"
            ),
            nutrition: NutritionInfo(calories: 350, protein: 30.0, carbs: 15.0, fat: 12.0, fiber: 3.0, sugar: 8.0),
            shoppingList: ["chicken breast", "bell peppers", "soy sauce"],
            difficultyRating: 4
        ),
        originalImage: UIImage(systemName: "photo") ?? UIImage(),
        servings: 2
    )
}
