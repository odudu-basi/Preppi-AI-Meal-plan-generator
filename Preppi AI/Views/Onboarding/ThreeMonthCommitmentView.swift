//
//  ThreeMonthCommitmentView.swift
//  Preppi AI
//
//  3-month sprint commitment explanation with research
//

import SwiftUI

struct ThreeMonthCommitmentView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var animateContent = false
    @State private var showResearch = false

    var body: some View {
        OnboardingContainer {
            VStack(spacing: 20) {
                // Navigation bar with progress
                OnboardingNavigationBar(
                    currentStep: coordinator.currentStep.stepNumber,
                    totalSteps: OnboardingStep.totalSteps,
                    canGoBack: true,
                    onBackTapped: {
                        coordinator.previousStep()
                    }
                )

                // Scrollable content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        // Header Section
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.green.opacity(0.2), Color.green.opacity(0.1)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                    .scaleEffect(animateContent ? 1.0 : 0.8)
                                    .opacity(animateContent ? 1.0 : 0.0)

                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 50, weight: .medium))
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.green, Color.green.opacity(0.7)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .scaleEffect(animateContent ? 1.0 : 0.8)
                                    .opacity(animateContent ? 1.0 : 0.0)
                            }

                            VStack(spacing: 12) {
                                Text("The Preppi Approach")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.green, .mint],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .multilineTextAlignment(.center)
                                    .opacity(animateContent ? 1.0 : 0.0)
                                    .offset(y: animateContent ? 0 : 20)

                                Text("3-Month Sprints for Lasting Success")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                    .opacity(animateContent ? 1.0 : 0.0)
                                    .offset(y: animateContent ? 0 : 20)
                            }
                        }
                        .padding(.top, 20)

                        // Main Content Card
                        VStack(alignment: .leading, spacing: 24) {
                            // The Approach
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "target")
                                        .font(.system(size: 20))
                                        .foregroundColor(.green)
                                    Text("Our Philosophy")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.primary)
                                }

                                Text("Big goals can feel overwhelming. That's why at Preppi, we break your journey into focused 3-month sprints.")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text("Commit to just three months. See real, measurable progress. Then sprint again.")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.green.opacity(0.1))
                                    )
                            }

                            Divider()

                            // Why It Works
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(spacing: 8) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.orange)
                                    Text("Why 3 Months?")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.primary)
                                }

                                BenefitRow(
                                    icon: "checkmark.circle.fill",
                                    color: .green,
                                    text: "Short enough to stay motivated"
                                )

                                BenefitRow(
                                    icon: "chart.line.uptrend.xyaxis",
                                    color: .blue,
                                    text: "Long enough to see meaningful results"
                                )

                                BenefitRow(
                                    icon: "brain.head.profile",
                                    color: .purple,
                                    text: "Builds sustainable habits, not temporary fixes"
                                )

                                BenefitRow(
                                    icon: "arrow.triangle.2.circlepath",
                                    color: .mint,
                                    text: "Regular checkpoints to adjust and improve"
                                )
                            }

                            Divider()

                            // Science Button
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    showResearch.toggle()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "graduationcap.fill")
                                        .font(.system(size: 18))
                                    Text("The Science Behind It")
                                        .font(.system(size: 16, weight: .semibold))
                                    Spacer()
                                    Image(systemName: showResearch ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(.green)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.green.opacity(0.1))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())

                            // Research Content (Collapsible)
                            if showResearch {
                                VStack(alignment: .leading, spacing: 16) {
                                    ResearchCard(
                                        title: "Breaking Down Goals Works",
                                        stat: "7-8%",
                                        statDescription: "performance increase",
                                        description: "Research with 9,000+ participants found that breaking large goals into smaller subgoals significantly boosts achievement.",
                                        source: "Scientific American",
                                        url: "https://www.scientificamerican.com/article/the-secret-to-accomplishing-big-goals-lies-in-breaking-them-into-flexible-bite-size-chunks/"
                                    )

                                    ResearchCard(
                                        title: "Target Setting Drives Success",
                                        stat: "10.3x",
                                        statDescription: "more likely to succeed",
                                        description: "A study of 24,000+ participants showed those who set weight-loss targets were over 10 times more likely to achieve significant results.",
                                        source: "Journal of Human Nutrition and Dietetics",
                                        url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC5111772/"
                                    )
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
                        )
                        .padding(.horizontal)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 30)

                        Spacer(minLength: 20)
                    }
                }

                // Continue button
                VStack(spacing: 25) {
                    PremiumContinueButton(
                        isEnabled: true,
                        animateContent: animateContent
                    ) {
                        coordinator.nextStep()
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 10)
            }
        }
        .onAppear {
            // Animate content
            withAnimation(.easeOut(duration: 0.8)) {
                animateContent = true
            }
        }
    }
}

// MARK: - Benefit Row
struct BenefitRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 24, height: 24)

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

// MARK: - Research Card
struct ResearchCard: View {
    let title: String
    let stat: String
    let statDescription: String
    let description: String
    let source: String
    let url: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)

            // Big Stat
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(stat)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text(statDescription)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }

            // Description
            Text(description)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Source Link
            Link(destination: URL(string: url)!) {
                HStack(spacing: 6) {
                    Text("Source: \(source)")
                        .font(.system(size: 13, weight: .medium))
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 12))
                }
                .foregroundColor(.green)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    ThreeMonthCommitmentView(coordinator: OnboardingCoordinator())
}
