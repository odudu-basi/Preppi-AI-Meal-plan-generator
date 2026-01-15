import SwiftUI

struct LoggedMealDetailView: View {
    let loggedMeal: LoggedMeal
    @Environment(\.dismiss) private var dismiss
    @StateObject private var loggedMealService = LoggedMealService.shared

    @State private var showingDeleteAlert = false
    @State private var animateContent = false
    @State private var animateImage = false
    @State private var showingShareSheet = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Navigation bar
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.gray)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color(.systemGray6)))
                        }

                        Spacer()

                        VStack(spacing: 2) {
                            Text(formatDate(loggedMeal.loggedAt))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            Text(formatTime(loggedMeal.loggedAt))
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.secondary.opacity(0.8))
                        }

                        Spacer()

                        Button(action: {
                            showingShareSheet = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.gray)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color(.systemGray6)))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                    // Meal name
                    Text(loggedMeal.mealName)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 20)

                    // Meal image
                    Group {
                        if let image = loggedMeal.image {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 300)
                                .clipped()
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
                        } else if let imageUrl = loggedMeal.imageUrl, let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 300)
                                    .clipped()
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
                            } placeholder: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color(.systemGray5))
                                        .frame(height: 300)

                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                }
                            }
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        LinearGradient(
                                            colors: [.green.opacity(0.3), .mint.opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(height: 300)

                                VStack(spacing: 12) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 40, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))

                                    Text("No Image")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
                        }
                    }
                    .scaleEffect(animateImage ? 1.0 : 0.98)
                    .opacity(animateImage ? 1.0 : 0.0)

                    // Edit button overlay on image (servings indicator)
                    HStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Text("1")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)

                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                        .padding(.trailing, 35)
                        .offset(y: -40)
                    }

                    // Description section
                    Text(loggedMeal.description)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 20)

                    // Calories section
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.orange)

                            Text("Calories")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }

                        Text("\(loggedMeal.calories)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(y: animateContent ? 0 : 20)

                    // Macros section
                    HStack(spacing: 12) {
                        // Protein
                        MacroColumn(
                            icon: "person.fill",
                            title: "Protein",
                            value: "\(Int(loggedMeal.macros.protein))g",
                            color: .red
                        )

                        // Carbs
                        MacroColumn(
                            icon: "leaf.fill",
                            title: "Carbs",
                            value: "\(Int(loggedMeal.macros.carbohydrates))g",
                            color: .blue
                        )

                        // Fats
                        MacroColumn(
                            icon: "drop.fill",
                            title: "Fats",
                            value: "\(Int(loggedMeal.macros.fat))g",
                            color: .orange
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(y: animateContent ? 0 : 30)

                    // Micronutrients section
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.purple)

                            Text("Micronutrients")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)

                            Spacer()
                        }

                        HStack(spacing: 12) {
                            // Fiber
                            MacroColumn(
                                icon: "leaf.circle.fill",
                                title: "Fiber",
                                value: "\(Int(loggedMeal.macros.fiber))g",
                                color: .green
                            )

                            // Sugar
                            MacroColumn(
                                icon: "cube.fill",
                                title: "Sugar",
                                value: "\(Int(loggedMeal.macros.sugar))g",
                                color: .pink
                            )

                            // Sodium
                            MacroColumn(
                                icon: "drop.triangle.fill",
                                title: "Sodium",
                                value: "\(Int(loggedMeal.macros.sodium))mg",
                                color: .cyan
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(y: animateContent ? 0 : 40)

                    // Health Score section
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.pink)

                            Text("Preppi Score")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)

                            Spacer()

                            Text("\(loggedMeal.healthScore)/10")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                        }

                        // Health score progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [.green, .mint],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * (Double(loggedMeal.healthScore) / 10.0), height: 8)
                                    .animation(.easeInOut(duration: 1.0), value: animateContent)
                            }
                        }
                        .frame(height: 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(y: animateContent ? 0 : 30)

                    // Bottom spacing before delete button
                    Spacer(minLength: 40)

                    // Delete button
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .medium))

                            Text("Delete Meal")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6))
                        )
                    }
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(y: animateContent ? 0 : 50)

                    // Bottom safe area spacing
                    Color.clear.frame(height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
            .background(Color(.systemBackground))
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animateImage = true
            }

            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateContent = true
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = loggedMeal.image {
                ShareSheet(items: [
                    generateShareText(),
                    image
                ])
            } else {
                ShareSheet(items: [generateShareText()])
            }
        }
        .alert("Delete Meal", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                loggedMealService.deleteMeal(withId: loggedMeal.id)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this logged meal? This action cannot be undone.")
        }
    }

    // MARK: - Helper Functions
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func generateShareText() -> String {
        let dateStr = formatDate(loggedMeal.loggedAt)
        let timeStr = formatTime(loggedMeal.loggedAt)

        var text = """
        🍽️ \(loggedMeal.mealName)

        📅 \(dateStr) at \(timeStr)
        🔥 \(loggedMeal.calories) calories

        Macros:
        💪 Protein: \(Int(loggedMeal.macros.protein))g
        🍞 Carbs: \(Int(loggedMeal.macros.carbohydrates))g
        🥑 Fats: \(Int(loggedMeal.macros.fat))g
        """

        if !loggedMeal.description.isEmpty {
            text += "\n\n📝 \(loggedMeal.description)"
        }

        text += "\n\n✨ Tracked with Preppi AI"

        return text
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    LoggedMealDetailView(
        loggedMeal: LoggedMeal(
            from: MealAnalysisResult(
                mealName: "Grilled Chicken Salad",
                description: "Fresh mixed greens with grilled chicken breast, cherry tomatoes, and balsamic dressing",
                macros: Macros(
                    protein: 35.0,
                    carbohydrates: 12.0,
                    fat: 8.0,
                    fiber: 4.0,
                    sugar: 6.0,
                    sodium: 450.0
                ),
                calories: 250,
                healthScore: 9
            ),
            image: nil
        )
    )
}
