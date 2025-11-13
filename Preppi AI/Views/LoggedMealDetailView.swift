import SwiftUI

struct LoggedMealDetailView: View {
    let loggedMeal: LoggedMeal
    @Environment(\.dismiss) private var dismiss
    @StateObject private var loggedMealService = LoggedMealService.shared
    
    @State private var showingDeleteAlert = false
    @State private var animateContent = false
    
    var body: some View {
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
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero Image Section
                    heroImageSection
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : -30)

                    // Content Card
                    VStack(spacing: 24) {
                        // Header with meal name and time
                        headerSection
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)

                        // Description
                        if !loggedMeal.description.isEmpty {
                            descriptionSection
                                .opacity(animateContent ? 1.0 : 0.0)
                                .offset(y: animateContent ? 0 : 20)
                        }

                        // Stats Grid
                        statsGrid
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)

                        // Preppi Score Section
                        preppiScoreSection
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)

                        // Delete button
                        deleteButton
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, -30)
                    .padding(.bottom, 60)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color("AppBackground"))
                            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -10)
                    )
                }
                .padding(.horizontal, 0)
            }
            .ignoresSafeArea(edges: .top)
            
            // Custom Navigation Bar
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Spacer()
                    
                    // Share button
                    Button(action: { /* Share functionality */ }) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
            }
        }
        .onAppear {
            print("🔍 LoggedMealDetailView onAppear - Meal: \(loggedMeal.mealName)")
            
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                animateContent = true
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
    
    // MARK: - Hero Image Section
    private var heroImageSection: some View {
        ZStack(alignment: .bottom) {
            Group {
                if let image = loggedMeal.image {
                    // Local image
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if let imageUrl = loggedMeal.imageUrl, let url = URL(string: imageUrl) {
                    // Remote image
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ZStack {
                            LinearGradient(
                                colors: [.green.opacity(0.3), .mint.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                        }
                    }
                } else {
                    // Placeholder with gradient
                    ZStack {
                        LinearGradient(
                            colors: [.green.opacity(0.6), .mint.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        VStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text("No Image")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
            }
            .frame(height: 400)
            .clipped()
            
            // Gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 400)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text(loggedMeal.mealName)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
            
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(formatDateTime(loggedMeal.loggedAt))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color(.systemGray6))
            )
            
            // Meal type badge if available
            if let mealType = loggedMeal.mealType {
                Text(mealType.capitalized)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
        }
    }
    
    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.green)

                Text("Description")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()
            }

            Text(loggedMeal.description)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.secondary)
                .lineLimit(nil)
                .lineSpacing(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Stats Grid
    private var statsGrid: some View {
        VStack(spacing: 16) {
            // Calories - Featured
            caloriesCard
            
            // Macros Grid
            macrosGrid
        }
    }
    
    private var caloriesCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.orange)
                
                Text("Total Calories")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack {
                Text("\(loggedMeal.calories)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                
                Text("kcal")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.orange.opacity(0.7))
                    .offset(y: 8)
                
                Spacer()
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [.orange.opacity(0.1), .orange.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var macrosGrid: some View {
        HStack(spacing: 12) {
            DetailMacroCard(
                icon: "figure.strengthtraining.traditional",
                title: "Protein",
                value: Int(loggedMeal.macros.protein),
                unit: "g",
                color: .red,
                gradient: [.red.opacity(0.1), .red.opacity(0.05)]
            )
            
            DetailMacroCard(
                icon: "leaf.fill",
                title: "Carbs",
                value: Int(loggedMeal.macros.carbohydrates),
                unit: "g",
                color: .blue,
                gradient: [.blue.opacity(0.1), .blue.opacity(0.05)]
            )
            
            DetailMacroCard(
                icon: "drop.fill",
                title: "Fats",
                value: Int(loggedMeal.macros.fat),
                unit: "g",
                color: .purple,
                gradient: [.purple.opacity(0.1), .purple.opacity(0.05)]
            )
        }
    }
    
    // MARK: - Preppi Score Section
    private var preppiScoreSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.green)
                
                Text("Preppi Score")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                // Score display
                HStack {
                    Text("\(loggedMeal.healthScore)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                    
                    Text("/10")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.green.opacity(0.7))
                        .offset(y: 8)
                    
                    Spacer()
                }
                
                // Score visualization
                HStack(spacing: 6) {
                    ForEach(1...10, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(index <= loggedMeal.healthScore ? 
                                  LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing) :
                                  LinearGradient(colors: [.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(height: 8)
                            .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.05), value: animateContent)
                    }
                }
                
                // Score description
                Text(scoreDescription)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [.green.opacity(0.1), .mint.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Delete Button
    private var deleteButton: some View {
        Button(action: {
            showingDeleteAlert = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 16, weight: .medium))
                
                Text("Delete Meal")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.red.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Properties
    private var scoreDescription: String {
        switch loggedMeal.healthScore {
        case 9...10: return "Excellent choice! This meal is very nutritious."
        case 7...8: return "Great meal with good nutritional balance."
        case 5...6: return "Decent meal, could be improved."
        case 3...4: return "Consider healthier alternatives."
        default: return "This meal could be much healthier."
        }
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Detail Macro Card Component
struct DetailMacroCard: View {
    let icon: String
    let title: String
    let value: Int
    let unit: String
    let color: Color
    let gradient: [Color]
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text("\(value)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color.opacity(0.7))
            }
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
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
