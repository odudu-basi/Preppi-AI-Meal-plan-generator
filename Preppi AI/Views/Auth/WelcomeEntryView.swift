//
//  WelcomeEntryView.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 10/25/25.
//

import SwiftUI

struct WelcomeEntryView: View {
    @EnvironmentObject var appState: AppState
    @State private var animateContent = false
    @State private var showSignIn = false

    var body: some View {
        ZStack {
            // Dark background with gradient
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.12, blue: 0.15),
                    Color(red: 0.15, green: 0.17, blue: 0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // iPhone mockup section
                phonePreviewSection
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(y: animateContent ? 0 : 50)

                Spacer()

                // Bottom section with title and buttons
                bottomSection
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(y: animateContent ? 0 : 30)
            }
        }
        .sheet(isPresented: $showSignIn) {
            SignInOnlyView(isPostOnboarding: false)
                .environmentObject(appState)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateContent = true
            }
        }
    }

    // MARK: - Phone Preview Section
    private var phonePreviewSection: some View {
        ZStack {
            // Glowing effect behind phone
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.green.opacity(0.3),
                            Color.green.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .blur(radius: 40)

            // Phone mockup
            VStack(spacing: 12) {
                // App Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [Color.green, Color.mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 90, height: 90)
                        .shadow(color: .green.opacity(0.5), radius: 20, x: 0, y: 10)

                    Image(systemName: "fork.knife")
                        .font(.system(size: 45, weight: .medium))
                        .foregroundColor(.white)
                }

                // App name
                VStack(spacing: 4) {
                    Text("PREPPI")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(2)

                    Text("AI")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                // Feature highlights
                VStack(spacing: 16) {
                    FeatureHighlight(
                        icon: "calendar.badge.checkmark",
                        text: "Smart Meal Planning",
                        color: .green
                    )

                    FeatureHighlight(
                        icon: "flame.fill",
                        text: "Calorie Tracking",
                        color: .orange
                    )

                    FeatureHighlight(
                        icon: "chart.line.uptrend.xyaxis",
                        text: "Progress Monitoring",
                        color: .blue
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
            .padding(.vertical, 40)
        }
    }

    // MARK: - Bottom Section
    private var bottomSection: some View {
        VStack(spacing: 24) {
            // Title and subtitle
            VStack(spacing: 12) {
                Text("Weight goals")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("made simple")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            // Action buttons
            VStack(spacing: 16) {
                // Get Started Button
                Button(action: {
                    // Start onboarding without authentication
                    appState.startGuestOnboarding()
                }) {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(red: 0.1, green: 0.12, blue: 0.15))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                        )
                }
                .buttonStyle(PlainButtonStyle())

                // Sign In Button
                Button(action: {
                    showSignIn = true
                }) {
                    HStack(spacing: 8) {
                        Text("Already have an account?")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))

                        Text("Sign In")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Feature Highlight Component
struct FeatureHighlight: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 24, height: 24)

            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

#Preview {
    WelcomeEntryView()
        .environmentObject(AppState())
}
