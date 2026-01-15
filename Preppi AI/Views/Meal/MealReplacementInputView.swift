import SwiftUI

struct MealReplacementInputView: View {
    let originalMeal: DayMeal
    let mealType: String
    let selectedDate: Date
    let onReplace: (DayMeal) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var userInput = ""
    @State private var showingSuggestions = false
    @State private var showingGeneratedMeal = false
    @State private var generatedMeal: DayMeal?
    @State private var isGenerating = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                            .padding(.top, 20)

                        Text("Replace \(originalMeal.meal.name)")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("What would you like to eat instead?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)

                    // Text editor
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Describe your ideal meal")
                            .font(.headline)
                            .foregroundColor(.primary)

                        ZStack(alignment: .topLeading) {
                            if userInput.isEmpty {
                                Text("e.g., Grilled salmon with roasted vegetables and quinoa")
                                    .foregroundColor(.secondary.opacity(0.5))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                            }

                            TextEditor(text: $userInput)
                                .focused($isTextFieldFocused)
                                .frame(minHeight: 150)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .scrollContentBackground(.hidden)
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    // Buttons
                    VStack(spacing: 12) {
                        // Continue button
                        Button(action: {
                            generateCustomMeal()
                        }) {
                            HStack {
                                if isGenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Continue")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(userInput.isEmpty || isGenerating ? Color.gray : Color.green)
                            )
                        }
                        .disabled(userInput.isEmpty || isGenerating)

                        // See Suggestions button
                        Button(action: {
                            showingSuggestions = true
                        }) {
                            HStack {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("See Suggestions")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.orange)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    isTextFieldFocused = false
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isTextFieldFocused = true
                    }
                }

                // Loading overlay
                if isGenerating {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)

                        Text("Generating your meal...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                    )
                }
            }
            .sheet(isPresented: $showingSuggestions) {
                MealSuggestionCardsView(
                    originalMeal: originalMeal,
                    mealType: mealType,
                    selectedDate: selectedDate,
                    onReplace: onReplace
                )
            }
            .fullScreenCover(isPresented: $showingGeneratedMeal) {
                if let meal = generatedMeal {
                    GeneratedMealDetailView(
                        generatedMeal: meal,
                        mealType: mealType,
                        onConfirmReplacement: {
                            onReplace(meal)
                            dismiss()
                        },
                        onCancel: {
                            showingGeneratedMeal = false
                            generatedMeal = nil
                        }
                    )
                }
            }
        }
    }

    // MARK: - Generate Custom Meal
    private func generateCustomMeal() {
        isGenerating = true

        Task {
            do {
                // Generate meal from user input
                let meal = try await MealGenerationService.shared.generateMealFromDescription(
                    description: userInput,
                    dayOfWeek: originalMeal.day
                )

                await MainActor.run {
                    generatedMeal = meal
                    showingGeneratedMeal = true
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    print("❌ Error generating meal: \(error)")
                    // TODO: Show error alert
                }
            }
        }
    }
}

#Preview {
    MealReplacementInputView(
        originalMeal: DayMeal(
            day: "Monday",
            meal: Meal(
                id: UUID(),
                name: "Chicken Salad",
                description: "Fresh mixed greens with grilled chicken",
                calories: 450,
                cookTime: 15,
                ingredients: ["Mixed greens", "Grilled chicken", "Cherry tomatoes"],
                instructions: ["Wash and prepare greens", "Grill chicken", "Toss together"],
                originalCookingDay: nil,
                imageUrl: nil,
                recommendedCaloriesBeforeDinner: 0,
                macros: Macros(protein: 35, carbohydrates: 20, fat: 25, fiber: 5, sugar: 3, sodium: 400),
                detailedIngredients: nil,
                detailedInstructions: nil,
                cookingTips: nil,
                servingInfo: nil
            )
        ),
        mealType: "lunch",
        selectedDate: Date(),
        onReplace: { _ in }
    )
}
