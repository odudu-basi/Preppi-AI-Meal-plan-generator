import SwiftUI

struct AnalyzingFoodLoadingView: View {
    @State private var progress: Double = 0.0
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Circular Progress Ring with Percentage
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 8)
                        .frame(width: 140, height: 140)
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AngularGradient(
                                colors: [.green, .mint, .cyan, .green],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: progress)
                    
                    // Percentage text
                    VStack(spacing: 4) {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Complete")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                // Loading text and description
                VStack(spacing: 12) {
                    Text("Analyzing Food")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Our AI is identifying ingredients and nutritional information...")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Animated dots
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.white.opacity(0.6))
                            .frame(width: 8, height: 8)
                            .scaleEffect(isAnimating ? 1.2 : 0.8)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                                value: isAnimating
                            )
                    }
                }
            }
        }
        .onAppear {
            startProgressAnimation()
            isAnimating = true
        }
    }
    
    private func startProgressAnimation() {
        // Simulate realistic progress with varying speeds
        let progressSteps: [(Double, Double)] = [
            (0.15, 0.8),   // Quick initial progress
            (0.35, 1.2),   // Steady progress
            (0.55, 1.0),   // Consistent progress
            (0.75, 1.5),   // Slower analysis phase
            (0.90, 1.8),   // Final processing
            (1.0, 0.5)     // Complete
        ]
        
        var currentDelay: Double = 0.3
        
        for (targetProgress, duration) in progressSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + currentDelay) {
                withAnimation(.easeInOut(duration: duration)) {
                    progress = targetProgress
                }
            }
            currentDelay += duration
        }
    }
}

#Preview {
    AnalyzingFoodLoadingView()
}
