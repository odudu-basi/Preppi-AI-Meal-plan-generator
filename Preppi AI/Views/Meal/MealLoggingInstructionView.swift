//
//  MealLoggingInstructionView.swift
//  Preppi AI
//
//  Created for meal logging instructions
//

import SwiftUI

struct MealLoggingInstructionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var animateContent = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color("AppBackground"),
                    Color(.systemGray6).opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Header Section
                VStack(spacing: 20) {
                    // Camera Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .scaleEffect(animateContent ? 1.0 : 0.8)
                            .opacity(animateContent ? 1.0 : 0.0)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.white)
                            .scaleEffect(animateContent ? 1.0 : 0.8)
                            .opacity(animateContent ? 1.0 : 0.0)
                    }
                    
                    // Title
                    Text("Log Your Meals")
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
                    
                    // Description
                    Text("You can log your meals by taking a picture of your food and adding any extra details to ensure accuracy.")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 30)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 20)
                }
                
                Spacer()
                
                // Continue Button
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 12) {
                        Text("Continue")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Image(systemName: "arrow.right")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .green.opacity(0.3), radius: 12, x: 0, y: 6)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 30)
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 30)
                
                Spacer(minLength: 50)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateContent = true
            }
        }
    }
}

#Preview {
    MealLoggingInstructionView()
}
