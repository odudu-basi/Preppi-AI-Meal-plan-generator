import SwiftUI

struct CookbooksListView: View {
    @Environment(\.dismiss) private var dismiss
    private let cookbookService = CookbookDatabaseService.shared
    @State private var showingCreateCookbook = false
    @State private var selectedCookbook: Cookbook?
    
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
                
                if cookbookService.isLoading {
                    // Loading state
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .green))
                            .scaleEffect(1.5)
                        
                        Text("Loading cookbooks...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if cookbookService.cookbooks.isEmpty {
                    // Empty state
                    VStack(spacing: 24) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        VStack(spacing: 12) {
                            Text("No Cookbooks Yet")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Create your first cookbook to start saving your favorite AI-generated recipes!")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        
                        Button {
                            showingCreateCookbook = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                
                                Text("Create Cookbook")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                            .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } else {
                    // Cookbooks list
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(cookbookService.cookbooks) { cookbook in
                                CookbookCard(cookbook: cookbook) {
                                    selectedCookbook = cookbook
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 100) // Space for floating button
                    }
                    
                    // Floating add button
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                showingCreateCookbook = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56)
                                    .background(
                                        LinearGradient(
                                            colors: [.green, .mint],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(Circle())
                                    .shadow(color: .green.opacity(0.4), radius: 12, x: 0, y: 6)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
                
                // Error message overlay
                if let errorMessage = cookbookService.errorMessage {
                    VStack {
                        Spacer()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    
                                    Text("Error")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                
                                Text(errorMessage)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Retry") {
                                Task {
                                    try? await cookbookService.fetchUserCookbooks()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("My Cookbooks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
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
            })
        }
        .sheet(isPresented: $showingCreateCookbook) {
            CreateCookbookFromListView { cookbook in
                // Refresh cookbooks after creation
                Task {
                    try? await cookbookService.fetchUserCookbooks()
                }
            }
        }
        .sheet(item: $selectedCookbook) { cookbook in
            CookbookDetailView(cookbook: cookbook)
        }
        .onAppear {
            Task {
                try? await cookbookService.fetchUserCookbooks()
            }
        }
    }
}

struct CookbookCard: View {
    let cookbook: Cookbook
    let onTap: () -> Void
    
    private var recipeText: String {
        let count = cookbook.recipeCount
        return count == 1 ? "1 recipe" : "\(count) recipes"
    }
    
    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(cookbook.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        if let description = cookbook.description, !description.isEmpty {
                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "book.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                }
                
                // Stats
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Text(recipeText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("Created \(formatDate(cookbook.createdAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        // Debug logging
        print("🕐 Formatting date: \(date)")
        print("🕐 Current time: \(now)")
        print("🕐 Time interval: \(timeInterval) seconds")
        
        // If the date is in the future or very recent (less than 60 seconds), handle specially
        if timeInterval < 60 {
            if timeInterval < 0 {
                return "just now" // Future date, probably a parsing issue
            } else {
                return "just now"
            }
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let result = formatter.localizedString(for: date, relativeTo: now)
        
        print("🕐 Formatted result: \(result)")
        return result
    }
}

struct CreateCookbookFromListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    let onCookbookCreated: (Cookbook) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color("AppBackground"),
                        Color(.systemGray6).opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .onTapGesture {
                    hideKeyboard()
                }
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "book.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.green)
                            
                            Text("Create New Cookbook")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        .padding(.top, 20)
                        
                        // Form
                        VStack(spacing: 20) {
                            // Name field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Cookbook Name")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                TextField("Enter cookbook name", text: $name)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.body)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray6))
                                    )
                            }
                            
                            // Description field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description (Optional)")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                TextField("Describe your cookbook", text: $description, axis: .vertical)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.body)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray6))
                                    )
                                    .lineLimit(3...6)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Create button
                        Button {
                            createCookbook()
                        } label: {
                            HStack {
                                if isCreating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.9)
                                    Text("Creating...")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                } else {
                                    Text("Create Cookbook")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? [.gray] : [.green, .mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .clear : .green.opacity(0.3), radius: 12, x: 0, y: 6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
                        .padding(.horizontal, 20)
                        
                        // Error message
                        if let errorMessage = errorMessage {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 24))
                                    .foregroundColor(.orange)
                                
                                Text("Creation Failed")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text(errorMessage)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            )
                            .padding(.horizontal, 20)
                        }
                        
                        // Bottom spacing
                        Color.clear.frame(height: 40)
                    }
                }
            }
            .navigationTitle("New Cookbook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func createCookbook() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        isCreating = true
        errorMessage = nil
        
        Task {
            do {
                let cookbook = try await CookbookDatabaseService.shared.createCookbook(
                    name: trimmedName,
                    description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                
                await MainActor.run {
                    onCookbookCreated(cookbook)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct CookbookDetailView: View {
    let cookbook: Cookbook
    @Environment(\.dismiss) private var dismiss
    private let cookbookService = CookbookDatabaseService.shared
    @State private var recipes: [SavedRecipe] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedRecipe: SavedRecipe?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color("AppBackground"),
                        Color(.systemGray6).opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .green))
                            .scaleEffect(1.5)
                        
                        Text("Loading recipes...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if recipes.isEmpty {
                    // Empty state
                    VStack(spacing: 24) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        VStack(spacing: 12) {
                            Text("No Recipes Yet")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Start adding AI-generated recipes to this cookbook!")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                    }
                } else {
                    // Recipes list
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(recipes) { recipe in
                                RecipeCard(recipe: recipe) {
                                    selectedRecipe = recipe
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle(cookbook.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(item: $selectedRecipe) { recipe in
            SavedRecipeDetailView(recipe: recipe) {
                // Refresh recipes when one is deleted
                loadRecipes()
            }
        }
        .onAppear {
            loadRecipes()
        }
    }
    
    private func loadRecipes() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedRecipes = try await cookbookService.fetchRecipes(for: cookbook.id)
                await MainActor.run {
                    self.recipes = fetchedRecipes
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

struct RecipeCard: View {
    let recipe: SavedRecipe
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(recipe.recipeName)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(recipe.recipeDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Difficulty rating
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= (recipe.difficultyRating / 2) ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundColor(index <= (recipe.difficultyRating / 2) ? .orange : .gray.opacity(0.3))
                    }
                }
            }
            
            // Stats
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Text(recipe.totalTime)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "person.2")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Text("\(recipe.servings) servings")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("Difficulty: \(recipe.difficultyRating)/10")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SavedRecipeDetailView: View {
    let recipe: SavedRecipe
    let onRecipeDeleted: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var showingImageFullscreen = false
    @State private var showingDeleteConfirmation = false
    @State private var isDeleting = false
    private let cookbookService = CookbookDatabaseService.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Recipe Image (if available)
                    if let imageUrl = recipe.imageUrl, !imageUrl.isEmpty {
                        RecipeImageView(imageUrl: imageUrl) {
                            showingImageFullscreen = true
                        }
                    } else {
                        // Placeholder image
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray5))
                            .frame(height: 250)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    Text("No Image")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            )
                    }
                    
                    // Recipe Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(recipe.recipeName)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(recipe.recipeDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // Time and Servings Info
                    HStack(spacing: 24) {
                        VStack(spacing: 4) {
                            Text("Prep Time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(recipe.prepTime)
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(spacing: 4) {
                            Text("Cook Time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(recipe.cookTime)
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(spacing: 4) {
                            Text("Total Time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(recipe.totalTime)
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(spacing: 4) {
                            Text("Servings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(recipe.servings)")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6).opacity(0.5))
                    )
                    .padding(.horizontal, 20)
                    
                    // Difficulty Rating
                    DifficultyRatingCard(difficulty: recipe.difficultyRating)
                        .padding(.horizontal, 20)
                    
                    // Nutrition Information
                    NutritionCard(nutrition: recipe.nutrition, servings: recipe.servings)
                        .padding(.horizontal, 20)
                    
                    // Ingredients
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Ingredients")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1).")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.green)
                                        .frame(minWidth: 24, alignment: .leading)
                                    
                                    Text("\(ingredient.amount) \(ingredient.unit) \(ingredient.item)")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                    .padding(.horizontal, 20)
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Instructions")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.body)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(Color.green))
                                    
                                    Text(instruction)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                    .padding(.horizontal, 20)
                    
                    // Shopping List
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Shopping List")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(recipe.shoppingList, id: \.self) { item in
                                HStack(spacing: 12) {
                                    Image(systemName: "circle")
                                        .font(.system(size: 12))
                                        .foregroundColor(.green)
                                    
                                    Text(item)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                    .padding(.horizontal, 20)
                    
                    // Notes (if any)
                    if let notes = recipe.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Notes")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(notes)
                                .font(.body)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    // Bottom spacing
                    Color.clear.frame(height: 40)
                }
                .padding(.top, 20)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color("AppBackground"),
                        Color(.systemGray6).opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingDeleteConfirmation = true
                    } label: {
                        if isDeleting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .red))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    .disabled(isDeleting)
                }
            }
        }
        .fullScreenCover(isPresented: $showingImageFullscreen) {
            if let imageUrl = recipe.imageUrl, !imageUrl.isEmpty {
                FullscreenRecipeImageView(imageUrl: imageUrl)
            }
        }
        .confirmationDialog(
            "Delete Recipe",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteRecipe()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \"\(recipe.recipeName)\"? This action cannot be undone.")
        }
    }
    
    // MARK: - Helper Methods
    
    private func deleteRecipe() {
        isDeleting = true
        
        Task {
            do {
                try await cookbookService.deleteRecipe(recipe)
                
                await MainActor.run {
                    MixpanelService.shared.track(
                        event: MixpanelService.Events.recipeDeletedFromCookbook,
                        properties: [
                            MixpanelService.Properties.recipeName: recipe.recipeName,
                            MixpanelService.Properties.recipeId: recipe.id.uuidString,
                            MixpanelService.Properties.cookbookId: recipe.cookbookId.uuidString
                        ]
                    )
                    
                    print("✅ Recipe deleted successfully")
                    onRecipeDeleted?() // Notify parent to refresh
                    dismiss() // Close the detail view
                }
                
            } catch {
                await MainActor.run {
                    isDeleting = false
                    print("❌ Failed to delete recipe: \(error)")
                    // TODO: Show error alert to user
                }
            }
        }
    }
}

struct FullscreenRecipeImageView: View {
    let imageUrl: String
    @Environment(\.dismiss) private var dismiss
    @State private var uiImage: UIImage?
    @State private var isLoading = true
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let uiImage = uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = max(1.0, min(value, 4.0))
                            }
                            .simultaneously(with:
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                            )
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring()) {
                            if scale > 1.0 {
                                scale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            } else {
                                scale = 2.0
                            }
                        }
                    }
            } else if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "photo")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("Image unavailable")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
            }
            
            // Close button
            VStack {
                HStack {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding()
                    Spacer()
                }
                Spacer()
            }
        }
        .onAppear {
            loadImage()
        }
        .onTapGesture {
            dismiss()
        }
    }
    
    private func loadImage() {
        Task {
            do {
                let image = try await loadImageFromUrl(imageUrl)
                await MainActor.run {
                    self.uiImage = image
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
                print("❌ Failed to load fullscreen recipe image: \(error)")
            }
        }
    }
    
    private func loadImageFromUrl(_ urlString: String) async throws -> UIImage {
        if urlString.hasPrefix("data:image/") {
            // Handle base64 data URL
            return try loadImageFromDataURL(urlString)
        } else {
            // Handle regular URL
            return try await loadImageFromRegularURL(urlString)
        }
    }
    
    private func loadImageFromDataURL(_ dataURL: String) throws -> UIImage {
        // Extract base64 part from data URL
        let components = dataURL.components(separatedBy: ",")
        guard components.count == 2,
              let base64String = components.last,
              let imageData = Data(base64Encoded: base64String),
              let image = UIImage(data: imageData) else {
            throw URLError(.badServerResponse)
        }
        return image
    }
    
    private func loadImageFromRegularURL(_ urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }
        return image
    }
}

struct RecipeImageView: View {
    let imageUrl: String
    let onTap: () -> Void
    @State private var uiImage: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let uiImage = uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .onTapGesture {
                        onTap()
                    }
            } else if isLoading {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray5))
                    .frame(height: 250)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                    )
            } else {
                // Error/fallback state
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray5))
                    .frame(height: 250)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("Image unavailable")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        Task {
            do {
                let image = try await loadImageFromUrl(imageUrl)
                await MainActor.run {
                    self.uiImage = image
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
                print("❌ Failed to load recipe image: \(error)")
            }
        }
    }
    
    private func loadImageFromUrl(_ urlString: String) async throws -> UIImage {
        if urlString.hasPrefix("data:image/") {
            // Handle base64 data URL
            return try loadImageFromDataURL(urlString)
        } else {
            // Handle regular URL
            return try await loadImageFromRegularURL(urlString)
        }
    }
    
    private func loadImageFromDataURL(_ dataURL: String) throws -> UIImage {
        // Extract base64 part from data URL
        let components = dataURL.components(separatedBy: ",")
        guard components.count == 2,
              let base64String = components.last,
              let imageData = Data(base64Encoded: base64String),
              let image = UIImage(data: imageData) else {
            throw URLError(.badServerResponse)
        }
        return image
    }
    
    private func loadImageFromRegularURL(_ urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }
        return image
    }
}

#Preview {
    CookbooksListView()
}
