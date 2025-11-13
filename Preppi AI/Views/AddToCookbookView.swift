import SwiftUI

struct AddToCookbookView: View {
    @Environment(\.dismiss) private var dismiss
    let recipe: RecipeAnalysis
    let image: UIImage
    let servings: Int
    let onRecipeSaved: (() -> Void)?
    
    @StateObject private var cookbookService = CookbookDatabaseService.shared
    @State private var showingCreateCookbook = false
    @State private var showingCookbookSelection = false
    @State private var newCookbookName = ""
    @State private var newCookbookDescription = ""
    @State private var showingSuccessMessage = false
    @State private var savedCookbookName = ""
    @State private var isSaving = false
    
    init(recipe: RecipeAnalysis, image: UIImage, servings: Int, onRecipeSaved: (() -> Void)? = nil) {
        self.recipe = recipe
        self.image = image
        self.servings = servings
        self.onRecipeSaved = onRecipeSaved
    }
    
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
                
                if cookbookService.isLoading {
                    VStack {
                        Spacer()
                        VStack(spacing: 8) {
                            ProgressView()
                            Text("Loading cookbooks...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                } else if cookbookService.cookbooks.isEmpty {
                    // Empty State
                    VStack(spacing: 40) {
                        Spacer()
                        
                        VStack(spacing: 24) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.6))
                            
                            Text("No cookbook exists, make one")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Spacer()
                        
                        Button {
                            MixpanelService.shared.track(event: MixpanelService.Events.createCookbookButtonTapped)
                            showingCreateCookbook = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .semibold))
                                
                                Text("Create Cookbook")
                                    .font(.headline)
                                    .fontWeight(.semibold)
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
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .green.opacity(0.3), radius: 12, x: 0, y: 6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 32)
                        .padding(.bottom, 40)
                    }
                } else {
                    // Show existing cookbooks
                    VStack(spacing: 20) {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(cookbookService.cookbooks) { cookbook in
                                    CookbookSelectionCard(cookbook: cookbook) {
                                        saveRecipeToCookbook(cookbook)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        }
                        
                        // Create New Cookbook Button
                        Button {
                            showingCreateCookbook = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .medium))
                                
                                Text("Create New Cookbook")
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.blue.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 32)
                        .padding(.bottom, 40)
                    }
                }
                
                // Success message overlay
                if showingSuccessMessage {
                    VStack {
                        Spacer()
                        
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.green)
                            
                            VStack(spacing: 8) {
                                Text("Recipe Saved!")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("Successfully added to \"\(savedCookbookName)\"")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
                        )
                        .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                    .background(Color.black.opacity(0.3))
                    .transition(.opacity.combined(with: .scale))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingSuccessMessage)
                }
                
                // Loading overlay
                if isSaving {
                    VStack {
                        Spacer()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .green))
                                .scaleEffect(1.5)
                            
                            Text("Saving recipe...")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
                        )
                        .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                    .background(Color.black.opacity(0.3))
                    .transition(.opacity.combined(with: .scale))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isSaving)
                }
            }
            .navigationTitle("Add to Cookbook")
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
        .sheet(isPresented: $showingCreateCookbook) {
            CreateCookbookView { name, description in
                Task {
                    await createCookbook(name: name, description: description)
                }
            }
        }
        .task {
            await loadCookbooks()
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadCookbooks() async {
        do {
            _ = try await cookbookService.fetchUserCookbooks()
        } catch {
            print("❌ Failed to load cookbooks: \(error)")
        }
    }
    
    private func createCookbook(name: String, description: String) async {
        do {
            let newCookbook = try await cookbookService.createCookbook(name: name, description: description)
            
            MixpanelService.shared.track(
                event: MixpanelService.Events.cookbookCreated,
                properties: [
                    MixpanelService.Properties.cookbookName: name,
                    MixpanelService.Properties.cookbookId: newCookbook.id.uuidString
                ]
            )
            
            showingCreateCookbook = false
            
            // Automatically save the recipe to the newly created cookbook
            saveRecipeToCookbook(newCookbook)
        } catch {
            print("❌ Failed to create cookbook: \(error)")
            // Handle error - could show alert
        }
    }
    
    private func saveRecipeToCookbook(_ cookbook: Cookbook) {
        isSaving = true
        
        Task {
            do {
                // Convert user's image to base64 data URL for storage
                let imageDataUrl = convertImageToDataURL(image)
                
                let savedRecipe = SavedRecipe(
                    from: recipe,
                    cookbookId: cookbook.id,
                    userId: cookbook.userId,
                    servings: servings, // Use actual servings from photo processing
                    imageUrl: imageDataUrl
                )
                
                try await cookbookService.saveRecipe(savedRecipe)
                
                await MainActor.run {
                    isSaving = false
                    savedCookbookName = cookbook.name
                    showingSuccessMessage = true
                }
                
                MixpanelService.shared.track(
                    event: MixpanelService.Events.recipeAddedToCookbook,
                    properties: [
                        MixpanelService.Properties.cookbookName: cookbook.name,
                        MixpanelService.Properties.cookbookId: cookbook.id.uuidString,
                        MixpanelService.Properties.recipeName: recipe.foodIdentification,
                        MixpanelService.Properties.servings: servings,
                        MixpanelService.Properties.difficultyRating: recipe.difficultyRating
                    ]
                )
                
                print("✅ Recipe saved to cookbook: \(cookbook.name)")
                
                // Auto dismiss after showing success message
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    onRecipeSaved?()
                }
                
            } catch {
                await MainActor.run {
                    isSaving = false
                }
                print("❌ Failed to save recipe: \(error)")
                // TODO: Show error alert to user
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func convertImageToDataURL(_ image: UIImage) -> String? {
        // Compress image to reasonable size for storage
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            print("❌ Failed to convert image to JPEG data")
            return nil
        }
        
        // Convert to base64 data URL
        let base64String = imageData.base64EncodedString()
        let dataURL = "data:image/jpeg;base64,\(base64String)"
        
        print("✅ Converted image to data URL (size: \(imageData.count) bytes)")
        return dataURL
    }
}

// MARK: - Supporting Views

struct CookbookSelectionCard: View {
    let cookbook: Cookbook
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Cookbook Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                
                // Cookbook Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(cookbook.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if let description = cookbook.description, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Text("\(cookbook.recipeCount) recipes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Selection Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CreateCookbookView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (String, String) -> Void
    
    @State private var name = ""
    @State private var description = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cookbook Name")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Enter cookbook name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description (Optional)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Enter description", text: $description, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...5)
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("New Cookbook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(name, description)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddToCookbookView(
        recipe: RecipeAnalysis(
            foodIdentification: "Chicken Stir Fry",
            description: "A delicious and healthy stir fry with fresh vegetables",
            recipe: RecipeDetails(
                ingredients: [
                    RecipeIngredient(item: "chicken breast", amount: "200", unit: "g")
                ],
                instructions: ["Heat oil in pan", "Add chicken and cook"],
                prepTime: "15 min",
                cookTime: "10 min",
                totalTime: "25 min"
            ),
            nutrition: NutritionInfo(calories: 350, protein: 30.0, carbs: 15.0, fat: 12.0, fiber: 3.0, sugar: 8.0),
            shoppingList: ["chicken breast", "bell peppers"],
            difficultyRating: 4
        ),
        image: UIImage(systemName: "photo") ?? UIImage(),
        servings: 2
    )
}
