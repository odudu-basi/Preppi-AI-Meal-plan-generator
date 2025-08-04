//
//  SplashScreenView.swift
//  Preppi AI
//
//  Created for session re-entry splash experience
//

import SwiftUI

struct SplashScreenView: View {
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    @State private var backgroundOpacity: Double = 0.0
    @State private var showPulse: Bool = false
    
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.green.opacity(0.8),
                    Color.green.opacity(0.6),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .opacity(backgroundOpacity)
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo with animated effects
                ZStack {
                    // Pulse effect background
                    if showPulse {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 200, height: 200)
                            .scaleEffect(showPulse ? 1.2 : 0.8)
                            .opacity(showPulse ? 0.0 : 1.0)
                            .animation(
                                .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: false),
                                value: showPulse
                            )
                    }
                    
                    // Main logo
                    PreppiLogo()
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }
                
                // App title with animated text
                VStack(spacing: 8) {
                    Text("PREPPI AI")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .primary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(logoOpacity)
                    
                    Text("Your AI-powered meal companion")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .opacity(logoOpacity * 0.8)
                }
                
                Spacer()
                
                // Loading indicator
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .green))
                        .scaleEffect(1.2)
                        .opacity(logoOpacity)
                    
                    Text("Loading your meal plans...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .opacity(logoOpacity * 0.7)
                }
                .padding(.bottom, 60)
            }
            .padding()
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Initial background fade
        withAnimation(.easeOut(duration: 0.5)) {
            backgroundOpacity = 1.0
        }
        
        // Logo scale and fade in
        withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Start pulse effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            showPulse = true
        }
        
        // Complete splash screen after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                logoOpacity = 0.0
                backgroundOpacity = 0.0
            }
            
            // Call completion handler after fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onComplete()
            }
        }
    }
}

#Preview {
    SplashScreenView {
        print("Splash screen completed")
    }
}