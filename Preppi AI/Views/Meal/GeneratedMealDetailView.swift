import SwiftUI

struct GeneratedMealDetailView: View {
    let generatedMeal: DayMeal
    let mealType: String
    let onConfirmReplacement: () -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Meal Image
                    ZStack(alignment: .topLeading) {
                        if let imageUrl = generatedMeal.meal.imageUrl, let url = URL(string: imageUrl) {
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
                            Color.gray.opacity(0.3)
                        }

                        // Back button
                        Button(action: {
                            onCancel()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.gray)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color(.systemGray6)))
                        }
                        .padding(16)
                    }
                    .frame(height: 300)
                    .clipped()

                    // Meal Info
                    VStack(alignment: .leading, spacing: 20) {
                        // Name and meal type
                        VStack(alignment: .leading, spacing: 8) {
                            Text(generatedMeal.meal.name)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            Text("AI Generated \(mealType.capitalized)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        // Description
                        if !generatedMeal.meal.description.isEmpty {
                            Text(generatedMeal.meal.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                        }

                        Divider()

                        // Calories
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("\(generatedMeal.meal.calories) calories")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)

                            Spacer()

                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .foregroundColor(.secondary)
                                Text("\(generatedMeal.meal.cookTime) min")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Divider()

                        // Nutritional Breakdown
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Nutritional Breakdown")
                                .font(.headline)
                                .fontWeight(.bold)

                            if let macros = generatedMeal.meal.macros {
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
                        }

                        // Ingredients (if available)
                        if !generatedMeal.meal.ingredients.isEmpty {
                            Divider()

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Ingredients")
                                    .font(.headline)
                                    .fontWeight(.bold)

                                ForEach(generatedMeal.meal.ingredients, id: \.self) { ingredient in
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
                        }
                    }
                    .padding(.horizontal, 20)

                    // Confirm Replacement Button
                    Button(action: {
                        onConfirmReplacement()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                            Text("Confirm Replacement")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
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
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
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
}
