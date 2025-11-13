//
//  MealLoggingInfoView.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 10/26/25.
//

import SwiftUI

struct MealLoggingInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var animateHeader = false
    @State private var animateContent = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Navigation bar
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color(.systemGray6)))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
                
                // Header Section with Icon
                VStack(spacing: 25) {
                    // Animated icon with gradient background
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.1), .cyan.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .scaleEffect(animateHeader ? 1.0 : 0.8)
                            .opacity(animateHeader ? 1.0 : 0.0)

                        Image(systemName: "camera.fill")
                            .font(.system(size: 45))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(animateHeader ? 1.0 : 0.8)
                    }

                    // Main message
                    VStack(spacing: 15) {
                        Text("Log your meals by taking a picture")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.primary, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(nil)
                            .padding(.horizontal, 20)
                            .opacity(animateHeader ? 1.0 : 0.0)
                            .offset(y: animateHeader ? 0 : 20)

                        Text("Add any extra details to ensure accuracy")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 20)
                            .opacity(animateHeader ? 1.0 : 0.0)
                            .offset(y: animateHeader ? 0 : 20)
                    }
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Continue Button
                Button(action: {
                    // Mark that user has completed meal logging info flow
                    appState.completeMealLoggingInfo()
                    // Dismiss this view and the parent meal plan onboarding view
                    dismiss()
                    // Post notification to dismiss the meal plan onboarding view as well
                    NotificationCenter.default.post(name: NSNotification.Name("DismissMealPlanOnboarding"), object: nil)
                }) {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .blue.opacity(0.4), radius: 12, x: 0, y: 6)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 30)
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateHeader = true
            }
            
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                animateContent = true
            }
        }
    }
}

#Preview {
    MealLoggingInfoView()
}
