//
//  MealAnalysisResultView.swift
//  Preppi AI
//
//  Created by AI Assistant on 10/26/25.
//

import SwiftUI

struct MealAnalysisResultView: View {
    let mealImage: UIImage
    let analysisResult: MealAnalysisResult
    let onDone: () -> Void
    let onAddDetails: () -> Void
    let onLogMeal: () -> Void
    let onRefinedAnalysis: (MealAnalysisResult) -> Void

    @State private var animateContent = false
    @State private var animateImage = false
    @State private var showingDetailsSheet = false
    @State private var isRefining = false
    @State private var currentAnalysis: MealAnalysisResult
    @State private var showingShareSheet = false

    init(mealImage: UIImage, analysisResult: MealAnalysisResult, onDone: @escaping () -> Void, onAddDetails: @escaping () -> Void, onLogMeal: @escaping () -> Void, onRefinedAnalysis: @escaping (MealAnalysisResult) -> Void) {
        self.mealImage = mealImage
        self.analysisResult = analysisResult
        self.onDone = onDone
        self.onAddDetails = onAddDetails
        self.onLogMeal = onLogMeal
        self.onRefinedAnalysis = onRefinedAnalysis
        self._currentAnalysis = State(initialValue: analysisResult)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Navigation bar
                    HStack {
                        Button(action: onDone) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.gray)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color(.systemGray6)))
                        }
                        
                        Spacer()
                        
                        Text("10:21pm")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                        
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
                    Text(currentAnalysis.mealName)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 20)
                    
                    // Meal image
                    Image(uiImage: mealImage)
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
                        .scaleEffect(animateImage ? 1.0 : 0.98)
                        .opacity(animateImage ? 1.0 : 0.0)
                    
                    // Edit button overlay on image
                    HStack {
                        Spacer()
                        Button(action: {
                            // Edit functionality placeholder
                        }) {
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
                        }
                        .padding(.trailing, 35)
                        .offset(y: -40)
                    }
                    
                    // Description section
                    Text(currentAnalysis.description)
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

                        Text("\(currentAnalysis.calories)")
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
                            value: "\(Int(currentAnalysis.macros.protein))g",
                            color: .red
                        )

                        // Carbs
                        MacroColumn(
                            icon: "leaf.fill",
                            title: "Carbs",
                            value: "\(Int(currentAnalysis.macros.carbohydrates))g",
                            color: .blue
                        )

                        // Fats
                        MacroColumn(
                            icon: "drop.fill",
                            title: "Fats",
                            value: "\(Int(currentAnalysis.macros.fat))g",
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
                                value: "\(Int(currentAnalysis.macros.fiber))g",
                                color: .green
                            )

                            // Sugar
                            MacroColumn(
                                icon: "cube.fill",
                                title: "Sugar",
                                value: "\(Int(currentAnalysis.macros.sugar))g",
                                color: .pink
                            )

                            // Sodium
                            MacroColumn(
                                icon: "drop.triangle.fill",
                                title: "Sodium",
                                value: "\(Int(currentAnalysis.macros.sodium))mg",
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

                            Text("\(currentAnalysis.healthScore)/10")
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
                                    .frame(width: geometry.size.width * (Double(currentAnalysis.healthScore) / 10.0), height: 8)
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
                    
                    // Bottom spacing before buttons
                    Spacer(minLength: 40)
                    
                    // Action buttons at bottom
                    VStack(spacing: 16) {
                        // Add Details button
                        Button(action: {
                            showingDetailsSheet = true
                            onAddDetails()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 16, weight: .medium))

                                Text("Add Details")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemGray6))
                            )
                        }
                        
                        HStack(spacing: 12) {
                            // Done button
                            Button(action: onDone) {
                                Text("Done")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color(.systemGray6))
                                    )
                            }
                            
                            // Log Meal button
                            Button(action: onLogMeal) {
                                Text("Log Meal")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(
                                        LinearGradient(
                                            colors: [.green, .mint],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
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
        .sheet(isPresented: $showingDetailsSheet) {
            MealDetailsInputView(
                mealImage: mealImage,
                currentAnalysis: currentAnalysis,
                onRefine: { additionalDetails in
                    Task {
                        isRefining = true
                        showingDetailsSheet = false

                        do {
                            let refinedAnalysis = try await OpenAIService.shared.refineMealAnalysis(
                                mealImage,
                                currentAnalysis: currentAnalysis,
                                additionalDetails: additionalDetails
                            )

                            await MainActor.run {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentAnalysis = refinedAnalysis
                                }
                                onRefinedAnalysis(refinedAnalysis)
                                isRefining = false
                            }
                        } catch {
                            print("❌ Error refining meal analysis: \(error)")
                            await MainActor.run {
                                isRefining = false
                            }
                        }
                    }
                },
                onCancel: {
                    showingDetailsSheet = false
                }
            )
        }
        .overlay {
            if isRefining {
                AnalyzingFoodLoadingView()
            }
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
            ShareSheet(items: [
                generateShareText(),
                mealImage
            ])
        }
    }

    // MARK: - Helper Functions
    private func generateShareText() -> String {
        var text = """
        🍽️ \(currentAnalysis.mealName)

        🔥 \(currentAnalysis.calories) calories

        Macros:
        💪 Protein: \(Int(currentAnalysis.macros.protein))g
        🍞 Carbs: \(Int(currentAnalysis.macros.carbohydrates))g
        🥑 Fats: \(Int(currentAnalysis.macros.fat))g
        """

        if !currentAnalysis.description.isEmpty {
            text += "\n\n📝 \(currentAnalysis.description)"
        }

        text += "\n\n✨ Analyzed with Preppi AI"

        return text
    }
}

// MARK: - Macro Column Component
struct MacroColumn: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    MealAnalysisResultView(
        mealImage: UIImage(systemName: "photo") ?? UIImage(),
        analysisResult: MealAnalysisResult(
            mealName: "Burger Bowl with Pickles, Red Onion, Cheese, Gro...",
            description: "Seared beef patty over greens with pickles, red onion, melted cheese, and tangy sauce.",
            macros: Macros(
                protein: 176.0,
                carbohydrates: 9.0,
                fat: 31.0,
                fiber: 5.0,
                sugar: 3.0,
                sodium: 890.0
            ),
            calories: 1151,
            healthScore: 8
        ),
        onDone: {},
        onAddDetails: {},
        onLogMeal: {},
        onRefinedAnalysis: { _ in }
    )
}
