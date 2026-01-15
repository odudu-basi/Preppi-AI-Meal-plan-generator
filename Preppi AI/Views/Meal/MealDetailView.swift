import SwiftUI

struct MealDetailView: View {
    let dayMeal: DayMeal
    let mealType: String
    let selectedDate: Date
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    // State for meal replacement
    @State private var showingMealReplacement = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Meal Image
                ZStack(alignment: .topTrailing) {
                    Group {
                        if let imageUrl = dayMeal.meal.imageUrl, let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                ZStack {
                                    Color.gray.opacity(0.3)
                                    ProgressView()
                                }
                            }
                        } else {
                            ZStack {
                                Color.gray.opacity(0.3)
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .frame(height: 300)
                    .clipped()

                    // Replace Meal Button (top right)
                    Button(action: {
                        showingMealReplacement = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Replace")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.green)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 2)
                    }
                    .padding(16)
                }

                // Meal Info
                VStack(alignment: .leading, spacing: 20) {
                    // Name and meal type
                    VStack(alignment: .leading, spacing: 8) {
                        Text(dayMeal.meal.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text(mealType.capitalized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Description
                    if !dayMeal.meal.description.isEmpty {
                        Text(dayMeal.meal.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }

                    Divider()

                    // Calories and Cook Time
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(dayMeal.meal.calories)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                                Text("calories")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        HStack(spacing: 8) {
                            Image(systemName: "clock")
                                .foregroundColor(.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(dayMeal.meal.cookTime)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                Text("minutes")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Divider()

                    // Nutritional Breakdown
                    if let macros = dayMeal.meal.macros {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Nutritional Breakdown")
                                .font(.headline)
                                .fontWeight(.bold)

                            VStack(spacing: 12) {
                                nutritionRow(
                                    label: "Protein",
                                    value: macros.protein,
                                    unit: "g",
                                    color: .red,
                                    icon: "figure.strengthtraining.traditional"
                                )

                                nutritionRow(
                                    label: "Carbohydrates",
                                    value: macros.carbohydrates,
                                    unit: "g",
                                    color: .blue,
                                    icon: "leaf.fill"
                                )

                                nutritionRow(
                                    label: "Fat",
                                    value: macros.fat,
                                    unit: "g",
                                    color: .orange,
                                    icon: "drop.fill"
                                )

                                nutritionRow(
                                    label: "Fiber",
                                    value: macros.fiber,
                                    unit: "g",
                                    color: .brown,
                                    icon: "chart.bar.fill"
                                )

                                nutritionRow(
                                    label: "Sugar",
                                    value: macros.sugar,
                                    unit: "g",
                                    color: .pink,
                                    icon: "cube.fill"
                                )

                                nutritionRow(
                                    label: "Sodium",
                                    value: macros.sodium,
                                    unit: "mg",
                                    color: .purple,
                                    icon: "circle.fill"
                                )
                            }
                        }

                        Divider()
                    }

                    // Ingredients
                    if !dayMeal.meal.ingredients.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Ingredients")
                                .font(.headline)
                                .fontWeight(.bold)

                            ForEach(dayMeal.meal.ingredients, id: \.self) { ingredient in
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 6, height: 6)

                                    Text(ingredient)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                            }
                        }

                        Divider()
                    }

                    // Log Meal Button
                    Button(action: {
                        toggleMealLog()
                    }) {
                        HStack(spacing: 12) {
                            let completedMeals = StreakService.shared.getCompletedMealsForDate(selectedDate)
                            let isLogged = completedMeals.contains { $0.mealType.lowercased() == mealType.lowercased() }
                            
                            Image(systemName: isLogged ? "xmark.circle.fill" : "checkmark.circle.fill")
                                .font(.system(size: 20))
                            Text(isLogged ? "Cancel Log" : "Log Meal")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isLogged ? Color.red : Color.green)
                        )
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .background(colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingMealReplacement) {
            MealReplacementInputView(
                originalMeal: dayMeal,
                mealType: mealType,
                selectedDate: selectedDate,
                onReplace: { newMeal in
                    // Handle meal replacement
                    replaceMeal(newMeal: newMeal)
                }
            )
        }
    }

    // MARK: - Nutrition Row
    private func nutritionRow(label: String, value: Double, unit: String, color: Color, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()

            Text("\(Int(value))\(unit)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Toggle Meal Log
    private func toggleMealLog() {
        // Check if meal is already completed
        let completedMeals = StreakService.shared.getCompletedMealsForDate(selectedDate)
        let isLogged = completedMeals.contains { $0.mealType.lowercased() == mealType.lowercased() }
        
        if isLogged {
            // Unlog the meal
            print("🗑️ DEBUG: Removing meal completion: \(dayMeal.meal.name) - \(mealType)")
            Task {
                do {
                    try await StreakService.shared.markMeal(date: selectedDate, mealType: mealType, as: .none)
                    print("✅ DEBUG: Removed meal completion from StreakService")
                    
                    await MainActor.run {
                        dismiss()
                    }
                } catch {
                    print("❌ DEBUG: Failed to remove meal completion: \(error)")
                    await MainActor.run {
                        dismiss()
                    }
                }
            }
        } else {
            // Log the meal
            print("📝 DEBUG: Logging meal from plan: \(dayMeal.meal.name) - \(mealType)")
            Task {
                do {
                    try await StreakService.shared.markMeal(date: selectedDate, mealType: mealType, as: .ateExact)
                    print("✅ DEBUG: Marked meal as completed in StreakService")
                    
                    await MainActor.run {
                        dismiss()
                    }
                } catch {
                    print("❌ DEBUG: Failed to mark meal as completed: \(error)")
                    await MainActor.run {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Replace Meal
    private func replaceMeal(newMeal: DayMeal) {
        print("🔄 Replacing meal: \(dayMeal.meal.name) with \(newMeal.meal.name)")

        Task {
            do {
                // Update the meal in the database
                try await MealPlanDatabaseService.shared.replaceMealInPlan(
                    date: selectedDate,
                    mealType: mealType,
                    newMeal: newMeal.meal
                )

                print("✅ Meal replaced successfully!")

                // Post notification to refresh home view
                await MainActor.run {
                    NotificationCenter.default.post(name: NSNotification.Name("MealPlanUpdated"), object: nil)
                }

                // Close the sheet and dismiss the view
                await MainActor.run {
                    showingMealReplacement = false
                    dismiss()
                }
            } catch {
                print("❌ Error replacing meal: \(error)")
            }
        }
    }
}
