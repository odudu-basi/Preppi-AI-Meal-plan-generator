//
//  VoiceVisualizerView.swift
//  Preppi AI
//
//  Voice wave visualizer that responds to microphone amplitude
//

import SwiftUI
import AVFoundation

struct VoiceVisualizerView: View {
    @ObservedObject var speechService: SpeechRecognitionService
    @State private var waveAmplitudes: [CGFloat] = Array(repeating: 0.2, count: 5)
    @State private var animationTimer: Timer?
    
    let waveColor: Color
    let waveCount: Int
    let waveHeight: CGFloat
    let waveSpacing: CGFloat
    
    init(
        speechService: SpeechRecognitionService,
        waveColor: Color = .green,
        waveCount: Int = 5,
        waveHeight: CGFloat = 40,
        waveSpacing: CGFloat = 6
    ) {
        self.speechService = speechService
        self.waveColor = waveColor
        self.waveCount = waveCount
        self.waveHeight = waveHeight
        self.waveSpacing = waveSpacing
        self._waveAmplitudes = State(initialValue: Array(repeating: 0.2, count: waveCount))
    }
    
    var body: some View {
        HStack(spacing: waveSpacing) {
            ForEach(0..<waveCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [waveColor, waveColor.opacity(0.6)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(
                        width: 4,
                        height: max(4, waveAmplitudes[index] * waveHeight)
                    )
                    .animation(
                        .easeInOut(duration: 0.1 + Double(index) * 0.05),
                        value: waveAmplitudes[index]
                    )
            }
        }
        .onChange(of: speechService.isRecording) { isRecording in
            if isRecording {
                startWaveAnimation()
            } else {
                stopWaveAnimation()
            }
        }
        .onDisappear {
            stopWaveAnimation()
        }
    }
    
    private func startWaveAnimation() {
        // Start with a base animation
        animateWaves()
        
        // Create a timer for continuous animation
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            animateWaves()
        }
    }
    
    private func stopWaveAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        
        // Animate back to minimal state
        withAnimation(.easeOut(duration: 0.3)) {
            waveAmplitudes = Array(repeating: 0.2, count: waveCount)
        }
    }
    
    private func animateWaves() {
        withAnimation(.easeInOut(duration: 0.1)) {
            let audioLevel = CGFloat(speechService.audioLevel)
            
            for i in 0..<waveCount {
                // Use real audio level as base, with some variation per bar
                let baseAmplitude: CGFloat = max(0.2, audioLevel * 0.8)
                let randomVariation = CGFloat.random(in: 0.8...1.2)
                
                // Add some wave-like motion across the bars for visual appeal
                let wavePhase = sin(Double(i) * 0.8 + Date().timeIntervalSince1970 * 4) * 0.2 + 1.0
                
                waveAmplitudes[i] = baseAmplitude * randomVariation * CGFloat(wavePhase)
            }
        }
    }
}

// MARK: - Enhanced Voice Button with Visualizer
struct VoiceInputButton: View {
    @ObservedObject var speechService: SpeechRecognitionService
    @State private var pulseAnimation = false
    
    let title: String
    let subtitle: String
    let onTranscriptionReceived: (String) -> Void
    
    init(
        speechService: SpeechRecognitionService,
        title: String = "Tap to speak",
        subtitle: String = "Voice input",
        onTranscriptionReceived: @escaping (String) -> Void
    ) {
        self.speechService = speechService
        self.title = title
        self.subtitle = subtitle
        self.onTranscriptionReceived = onTranscriptionReceived
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                if speechService.isRecording {
                    speechService.stopRecording()
                } else {
                    speechService.startRecording()
                }
            }) {
                HStack(spacing: 16) {
                    // Microphone icon with pulse animation
                    ZStack {
                        if speechService.isRecording {
                            Circle()
                                .fill(Color.red.opacity(0.2))
                                .frame(width: 60, height: 60)
                                .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                                .opacity(pulseAnimation ? 0.0 : 1.0)
                        }

                        Image(systemName: speechService.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(speechService.isRecording ? .red : .green)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(speechService.isRecording ? "Recording..." : title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        if speechService.isRecording {
                            // Voice visualizer
                            VoiceVisualizerView(
                                speechService: speechService,
                                waveColor: .red,
                                waveCount: 7,
                                waveHeight: 20,
                                waveSpacing: 4
                            )
                        } else if speechService.isTranscribing {
                            HStack(spacing: 8) {
                                // Custom loading dots animation instead of ProgressView
                                LoadingDotsView()
                                Text("Processing...")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text(subtitle)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 8)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(speechService.isRecording ? Color.red : Color.green.opacity(0.3), lineWidth: speechService.isRecording ? 2 : 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(speechService.isTranscribing)
            
            // Error message
            if let errorMessage = speechService.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .onReceive(speechService.$extractedCountry) { extractedCountry in
            if let country = extractedCountry, !country.isEmpty {
                onTranscriptionReceived(country)
            }
        }
        .onAppear {
            startPulseAnimation()
        }
        .onChange(of: speechService.isRecording) { isRecording in
            if isRecording {
                startPulseAnimation()
            } else {
                pulseAnimation = false
            }
        }
    }
    
    private func startPulseAnimation() {
        guard speechService.isRecording else { return }
        
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
        
        // Continue pulsing while recording
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if speechService.isRecording {
                startPulseAnimation()
            }
        }
    }
}

// MARK: - Compact Voice Visualizer for smaller spaces
struct CompactVoiceVisualizerView: View {
    @ObservedObject var speechService: SpeechRecognitionService
    @State private var waveAmplitudes: [CGFloat] = Array(repeating: 0.3, count: 3)
    @State private var animationTimer: Timer?
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.green)
                    .frame(
                        width: 2,
                        height: max(2, waveAmplitudes[index] * 16)
                    )
                    .animation(
                        .easeInOut(duration: 0.15 + Double(index) * 0.05),
                        value: waveAmplitudes[index]
                    )
            }
        }
        .onChange(of: speechService.isRecording) { isRecording in
            if isRecording {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    private func startAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.08)) {
                let audioLevel = CGFloat(speechService.audioLevel)
                for i in 0..<3 {
                    let baseLevel = max(0.3, audioLevel * 0.9)
                    let variation = CGFloat.random(in: 0.8...1.2)
                    waveAmplitudes[i] = baseLevel * variation
                }
            }
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        
        withAnimation(.easeOut(duration: 0.2)) {
            waveAmplitudes = Array(repeating: 0.3, count: 3)
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        VoiceInputButton(
            speechService: SpeechRecognitionService.shared,
            title: "Tell us your country",
            subtitle: "Tap to speak"
        ) { text in
            print("Received: \(text)")
        }
        
        HStack {
            Text("Recording:")
            CompactVoiceVisualizerView(speechService: SpeechRecognitionService.shared)
        }
        
        VoiceVisualizerView(speechService: SpeechRecognitionService.shared)
    }
    .padding()
}

// MARK: - Loading Dots Animation
struct LoadingDotsView: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                    .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                    .opacity(animationPhase == index ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.4)
                        .repeatForever(autoreverses: false),
                        value: animationPhase
                    )
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            withAnimation {
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}
