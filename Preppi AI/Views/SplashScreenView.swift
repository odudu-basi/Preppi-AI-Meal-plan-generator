//
//  SplashScreenView.swift
//  Preppi AI
//
//  Created for session re-entry splash experience
//

import SwiftUI

struct SplashScreenView: View {
    @ObservedObject private var speechService = ElevenLabsSpeechService.shared
    @State private var mascotScale: CGFloat = 0.7
    @State private var mascotOpacity: Double = 0.0
    @State private var backgroundOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    @State private var hasSpoken: Bool = false

    let onComplete: () -> Void

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.green.opacity(0.8),
                    Color.green.opacity(0.6),
                    Color("AppBackground")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .opacity(backgroundOpacity)

            VStack(spacing: 40) {
                Spacer()

                // Animated Mascot - waving and talking
                AnimatedMascot(
                    animation: speechService.isSpeaking ? .talking : .waving,
                    size: 350
                )
                .scaleEffect(mascotScale)
                .opacity(mascotOpacity)

                // Welcome text
                VStack(spacing: 12) {
                    Text("Welcome!")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .primary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(textOpacity)

                    Text("Hi, I'm Preppi")
                        .font(.system(size: 26, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                        .opacity(textOpacity)
                }

                Spacer()
            }
            .padding()
        }
        .onAppear {
            startAnimation()
            playWelcomeMessage()
        }
    }

    private func startAnimation() {
        print("🎬 SplashScreen: Starting animation")

        // Initial background fade
        withAnimation(.easeOut(duration: 0.5)) {
            backgroundOpacity = 1.0
        }

        // Start mascot animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
            mascotScale = 1.0
            mascotOpacity = 1.0
        }

        // Show text
        withAnimation(.easeOut(duration: 0.6).delay(1.0)) {
            textOpacity = 1.0
        }

        // Complete splash screen after animation and audio (wave animation is about 2 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            print("🎬 SplashScreen: Fading out")
            withAnimation(.easeOut(duration: 0.5)) {
                mascotOpacity = 0.0
                textOpacity = 0.0
                backgroundOpacity = 0.0
            }

            // Call completion handler after fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("✅ SplashScreen: Completed")
                speechService.stop()
                onComplete()
            }
        }
    }

    private func playWelcomeMessage() {
        // Voice disabled for now
        // Play the speech after mascot appears and text is visible
        if !hasSpoken {
            print("🔊 SplashScreen: Voice disabled - skipping welcome message")
            // DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            //     print("🎯 SplashScreen: Playing welcome message")
            //     speechService.speak("Welcome! Hi, I'm Preppi")
            //     hasSpoken = true
            // }
            hasSpoken = true
        }
    }
}

#Preview {
    SplashScreenView {
        print("Splash screen completed")
    }
}