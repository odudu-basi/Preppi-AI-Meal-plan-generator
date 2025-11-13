//
//  AnimatedMascot.swift
//  Preppi AI
//
//  Animated mascot component with various animations
//

import SwiftUI

enum MascotAnimation {
    case idle
    case waving
    case talking
    case walking
}

struct AnimatedMascot: View {
    let animation: MascotAnimation
    let size: CGFloat
    @State private var waveRotation: Double = 0
    @State private var talkScale: CGFloat = 1.0
    @State private var walkOffset: CGFloat = 0
    @State private var bounceOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Mascot image without background
            Image("PreppiMascot")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .modifier(AnimationModifier(animation: animation, waveRotation: waveRotation, talkScale: talkScale, walkOffset: walkOffset, bounceOffset: bounceOffset))
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        switch animation {
        case .idle:
            // Gentle breathing/bobbing animation
            withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                bounceOffset = 5
            }

        case .waving:
            // Waving animation - rotate the whole mascot slightly to simulate arm waving
            withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                waveRotation = 8
            }
            // Add a gentle bounce
            withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                bounceOffset = 8
            }

        case .talking:
            // Talking animation - scale pulse to simulate mouth movement
            withAnimation(Animation.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                talkScale = 1.02
            }
            // Add slight bounce
            withAnimation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                bounceOffset = 3
            }

        case .walking:
            // Walking animation - side to side movement with bounce
            withAnimation(Animation.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                walkOffset = 15
            }
            withAnimation(Animation.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                bounceOffset = 10
            }
        }
    }
}

struct AnimationModifier: ViewModifier {
    let animation: MascotAnimation
    let waveRotation: Double
    let talkScale: CGFloat
    let walkOffset: CGFloat
    let bounceOffset: CGFloat

    func body(content: Content) -> some View {
        switch animation {
        case .idle:
            content
                .offset(y: bounceOffset)

        case .waving:
            content
                .rotationEffect(.degrees(waveRotation))
                .offset(y: bounceOffset)

        case .talking:
            content
                .scaleEffect(talkScale)
                .offset(y: bounceOffset)

        case .walking:
            content
                .offset(x: walkOffset, y: bounceOffset)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        AnimatedMascot(animation: .waving, size: 200)
        Text("Waving Animation")
    }
}
