//
//  NutritionPlanDisplayView.swift
//  Preppi AI
//
//  Display custom nutrition plan with macros and health score
//

import SwiftUI

struct NutritionPlanDisplayView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var animateContent = false

    private var plan: NutritionPlan? {
        coordinator.userData.nutritionPlan
    }

    private var targetDate: Date {
        Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    }

    var body: some View {
        OnboardingContainer {
            VStack(spacing: 20) {
                // Navigation bar
                OnboardingNavigationBar(
                    currentStep: coordinator.currentStep.stepNumber,
                    totalSteps: OnboardingStep.totalSteps,
                    canGoBack: false, // Don't allow going back from here
                    onBackTapped: {}
                )

                // Scrollable content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header with predicted weight
                        headerSection

                        // Daily recommendation card
                        dailyRecommendationCard

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                }

                // Continue button
                VStack(spacing: 25) {
                    PremiumContinueButton(
                        isEnabled: true,
                        animateContent: animateContent,
                        action: {
                            coordinator.nextStep()
                        }
                    )
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 10)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateContent = true
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            Text("Your custom plan is ready!")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 20)

            if let plan = plan {
                // Weight prediction card
                VStack(spacing: 12) {
                    Text("You should \(plan.weightChange < 0 ? "lose" : "gain"):")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text("\(String(format: "%.1f", abs(plan.weightChange))) lb by \(formattedDate(targetDate))")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.15, green: 0.17, blue: 0.20),
                                    Color(red: 0.1, green: 0.12, blue: 0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 30)
            }
        }
    }

    // MARK: - Daily Recommendation Card

    private var dailyRecommendationCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Daily recommendation")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                Text("You can edit this anytime")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }

            if let plan = plan {
                // Macro cards grid
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        MacroCard(
                            icon: "flame.fill",
                            title: "Calories",
                            value: plan.dailyCalories,
                            unit: "",
                            color: .white,
                            progress: 0.75
                        )

                        MacroCard(
                            icon: "leaf.fill",
                            title: "Carbs",
                            value: plan.dailyCarbs,
                            unit: "g",
                            color: Color.orange,
                            progress: 0.65
                        )
                    }

                    HStack(spacing: 16) {
                        MacroCard(
                            icon: "drop.fill",
                            title: "Protein",
                            value: plan.dailyProtein,
                            unit: "g",
                            color: Color.pink,
                            progress: 0.55
                        )

                        MacroCard(
                            icon: "circle.fill",
                            title: "Fats",
                            value: plan.dailyFats,
                            unit: "g",
                            color: Color.blue,
                            progress: 0.45
                        )
                    }
                }

                // Health Score
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.pink)

                        Text("Health Score")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)

                        Spacer()

                        Text("\(plan.healthScore)/10")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 12)

                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: geometry.size.width * (Double(plan.healthScore) / 10.0),
                                    height: 12
                                )
                                .animation(.easeOut(duration: 1.0).delay(0.3), value: animateContent)
                        }
                    }
                    .frame(height: 12)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.08))
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.15, green: 0.17, blue: 0.20),
                            Color(red: 0.1, green: 0.12, blue: 0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .opacity(animateContent ? 1.0 : 0.0)
        .offset(y: animateContent ? 0 : 40)
    }

    // Helper to format date
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Macro Card Component

struct MacroCard: View {
    let icon: String
    let title: String
    let value: Int
    let unit: String
    let color: Color
    let progress: Double

    @State private var animateProgress = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()
            }

            // Circular progress
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: animateProgress ? progress : 0)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 1.0).delay(0.2), value: animateProgress)

                VStack(spacing: 4) {
                    Text("\(value)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    if !unit.isEmpty {
                        Text(unit)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
        )
        .onAppear {
            animateProgress = true
        }
    }
}

#if DEBUG
#Preview {
    NutritionPlanDisplayView(coordinator: {
        let coordinator = OnboardingCoordinator()
        coordinator.userData.nutritionPlan = NutritionPlan(
            dailyCalories: 1894,
            dailyCarbs: 187,
            dailyProtein: 167,
            dailyFats: 52,
            predictedWeightAfter3Months: 75.2,
            weightChange: -10.3,
            healthScore: 7,
            healthScoreReasoning: "Balanced plan with sustainable deficit",
            createdDate: Date()
        )
        return coordinator
    }())
}
#endif
