//
//  NutritionPlanLoadingView.swift
//  Preppi AI
//
//  Loading view with percentage counter for nutrition plan generation
//

import SwiftUI

struct NutritionPlanLoadingView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var progress: Double = 0.0
    @State private var animateGradient = false
    @State private var animateRings = false
    @State private var loadingMessage = "Analyzing your profile..."

    var body: some View {
        OnboardingContainer {
            VStack(spacing: 30) {
                Spacer()

                // Animated loading rings with percentage
                ZStack {
                    // Outer ring - rotating
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.green.opacity(0.3), .mint.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(animateRings ? 360 : 0))
                        .animation(
                            .linear(duration: 3).repeatForever(autoreverses: false),
                            value: animateRings
                        )

                    // Middle progress ring
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: progress)

                    // Inner glow circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.green.opacity(0.2),
                                    Color.green.opacity(0.05),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(animateGradient ? 1.1 : 0.9)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: animateGradient
                        )

                    // Percentage text
                    VStack(spacing: 8) {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Image(systemName: "sparkles")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                            .opacity(progress > 0.5 ? 1.0 : 0.5)
                    }
                }
                .padding(.vertical, 40)

                // Loading messages
                VStack(spacing: 16) {
                    Text("Customizing Your Plan")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)

                    Text(loadingMessage)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .transition(.opacity)
                        .id(loadingMessage) // Force view update when message changes
                }

                Spacer()

                // Fun facts or tips while loading
                if progress < 0.9 {
                    VStack(spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)

                        Text("Did you know?")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)

                        Text("Personalized nutrition plans are 3x more effective than generic diet plans")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal, 20)
                }

                Spacer()
            }
        }
        .onAppear {
            animateRings = true
            animateGradient = true
            generateNutritionPlan()
        }
    }

    private func generateNutritionPlan() {
        Task {
            do {
                let plan = try await OpenAIService.shared.generateNutritionPlan(
                    userData: coordinator.userData
                ) { progressValue in
                    Task { @MainActor in
                        withAnimation {
                            self.progress = progressValue
                        }

                        // Update loading messages based on progress
                        if progressValue < 0.3 {
                            loadingMessage = "Analyzing your profile..."
                        } else if progressValue < 0.6 {
                            loadingMessage = "Calculating optimal calories..."
                        } else if progressValue < 0.9 {
                            loadingMessage = "Determining macronutrient balance..."
                        } else {
                            loadingMessage = "Finalizing your custom plan..."
                        }
                    }
                }

                // Store the nutrition plan
                await MainActor.run {
                    coordinator.userData.nutritionPlan = plan
                }

                // Wait a moment to show 100% before moving on
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

                // Move to next step
                await MainActor.run {
                    coordinator.nextStep()
                }

            } catch {
                print("❌ Error generating nutrition plan: \(error.localizedDescription)")
                await MainActor.run {
                    // Show error and allow user to retry or skip
                    loadingMessage = "Error generating plan. Please try again."
                    // You could show a retry button here or skip to next step
                }
            }
        }
    }
}

#Preview {
    NutritionPlanLoadingView(coordinator: OnboardingCoordinator())
}
