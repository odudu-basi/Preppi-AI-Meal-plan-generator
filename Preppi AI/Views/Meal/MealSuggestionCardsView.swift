import SwiftUI

struct MealSuggestionCardsView: View {
    let originalMeal: DayMeal
    let mealType: String
    let selectedDate: Date
    let onReplace: (DayMeal) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var suggestions: [DayMeal] = []
    @State private var currentIndex = 0
    @State private var isLoading = true
    @State private var dragOffset: CGFloat = 0
    @State private var showingMealDetail = false
    @State private var selectedSuggestion: DayMeal?

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .green))
                            .scaleEffect(1.5)

                        Text("Finding similar meals...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else if suggestions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)

                        Text("No suggestions found")
                            .font(.headline)

                        Button("Go Back") {
                            dismiss()
                        }
                        .foregroundColor(.blue)
                    }
                } else {
                    VStack(spacing: 0) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Similar Meals")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("\(currentIndex + 1) of \(suggestions.count)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 16)

                        // Swipeable cards
                        ZStack {
                            ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                                if index == currentIndex {
                                    suggestionCard(for: suggestion)
                                        .offset(x: dragOffset)
                                        .gesture(
                                            DragGesture()
                                                .onChanged { value in
                                                    dragOffset = value.translation.width
                                                }
                                                .onEnded { value in
                                                    withAnimation(.spring(response: 0.3)) {
                                                        if value.translation.width < -100 && currentIndex < suggestions.count - 1 {
                                                            // Swipe left - next card
                                                            currentIndex += 1
                                                        } else if value.translation.width > 100 && currentIndex > 0 {
                                                            // Swipe right - previous card
                                                            currentIndex -= 1
                                                        }
                                                        dragOffset = 0
                                                    }
                                                }
                                        )
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .trailing),
                                            removal: .move(edge: .leading)
                                        ))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, 20)

                        // Navigation arrows
                        HStack(spacing: 40) {
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    if currentIndex > 0 {
                                        currentIndex -= 1
                                    }
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(currentIndex > 0 ? .green : .gray)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        Circle()
                                            .fill(Color(.systemBackground))
                                            .shadow(color: .black.opacity(0.1), radius: 4)
                                    )
                            }
                            .disabled(currentIndex == 0)

                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    if currentIndex < suggestions.count - 1 {
                                        currentIndex += 1
                                    }
                                }
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(currentIndex < suggestions.count - 1 ? .green : .gray)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        Circle()
                                            .fill(Color(.systemBackground))
                                            .shadow(color: .black.opacity(0.1), radius: 4)
                                    )
                            }
                            .disabled(currentIndex == suggestions.count - 1)
                        }
                        .padding(.vertical, 20)

                        // Add Meal button
                        Button(action: {
                            onReplace(suggestions[currentIndex])
                            dismiss()
                        }) {
                            Text("Add Meal")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.green)
                                )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
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
                loadSuggestions()
            }
            .fullScreenCover(isPresented: $showingMealDetail) {
                if let meal = selectedSuggestion {
                    MealDetailView(dayMeal: meal, mealType: mealType, selectedDate: selectedDate)
                }
            }
        }
    }

    // MARK: - Suggestion Card
    private func suggestionCard(for suggestion: DayMeal) -> some View {
        VStack(spacing: 0) {
            // Meal Image
            ZStack {
                if let imageUrl = suggestion.meal.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                } else {
                    Color.gray.opacity(0.3)
                }

                // Tap to view details overlay
                VStack {
                    Spacer()
                    Button(action: {
                        selectedSuggestion = suggestion
                        showingMealDetail = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                            Text("Tap for details")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.6))
                        )
                    }
                    .padding(.bottom, 16)
                }
            }
            .frame(height: 300)
            .clipped()

            // Meal Info
            VStack(alignment: .leading, spacing: 16) {
                // Name
                Text(suggestion.meal.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                // Calories
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(suggestion.meal.calories) kcal")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }

                // Macros
                VStack(spacing: 12) {
                    macroRow(label: "Protein", value: suggestion.meal.macros?.protein ?? 0, unit: "g", color: .red)
                    macroRow(label: "Carbs", value: suggestion.meal.macros?.carbohydrates ?? 0, unit: "g", color: .blue)
                    macroRow(label: "Fat", value: suggestion.meal.macros?.fat ?? 0, unit: "g", color: .orange)
                    macroRow(label: "Fiber", value: suggestion.meal.macros?.fiber ?? 0, unit: "g", color: .brown)
                    macroRow(label: "Sugar", value: suggestion.meal.macros?.sugar ?? 0, unit: "g", color: .pink)
                    macroRow(label: "Sodium", value: suggestion.meal.macros?.sodium ?? 0, unit: "mg", color: .purple)
                }
            }
            .padding(20)
        }
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    // MARK: - Macro Row
    private func macroRow(label: String, value: Double, unit: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text("\(Int(value))\(unit)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }

    // MARK: - Load Suggestions
    private func loadSuggestions() {
        Task {
            do {
                let meals = try await MealGenerationService.shared.generateSimilarMeals(
                    to: originalMeal,
                    count: 5
                )

                await MainActor.run {
                    suggestions = meals
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("❌ Error loading suggestions: \(error)")
                }
            }
        }
    }
}
