//
//  MascotSpeechService.swift
//  Preppi AI
//
//  Text-to-speech service for mascot with Australian accent
//

import Foundation
import AVFoundation

class MascotSpeechService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = MascotSpeechService()

    @Published var isSpeaking = false
    @Published var currentWordRange: NSRange?

    private let synthesizer = AVSpeechSynthesizer()
    private var audioSession: AVAudioSession?

    override private init() {
        super.init()
        synthesizer.delegate = self
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            audioSession = AVAudioSession.sharedInstance()
            // Use .playback category to play even when device is in silent mode
            try audioSession?.setCategory(.playback, mode: .spokenAudio, options: [])
            try audioSession?.setActive(true, options: [])
            print("✅ MascotSpeech: Audio session configured successfully")
            print("📱 MascotSpeech: Category: \(audioSession?.category.rawValue ?? "unknown")")
        } catch {
            print("❌ MascotSpeech: Failed to setup audio session: \(error)")
        }
    }

    func speak(_ text: String, completion: (() -> Void)? = nil) {
        print("🗣️ MascotSpeech: Attempting to speak: \"\(text)\"")

        // Stop any ongoing speech
        if synthesizer.isSpeaking {
            print("⚠️ MascotSpeech: Stopping previous speech")
            synthesizer.stopSpeaking(at: .immediate)
        }

        // Ensure audio session is active
        do {
            try audioSession?.setActive(true, options: [])
        } catch {
            print("❌ MascotSpeech: Failed to activate audio session: \(error)")
        }

        let utterance = AVSpeechUtterance(string: text)

        // Debug: List all Australian voices
        print("📋 MascotSpeech: Searching for Australian voices...")
        let australianVoices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.contains("en-AU") }
        print("  Found \(australianVoices.count) Australian voices:")
        for voice in australianVoices {
            print("  - \(voice.name) (\(voice.language)) - Quality: \(voice.quality.rawValue)")
        }

        // Set Australian accent voice - prefer enhanced/premium quality
        // Try to find the best Australian English voice
        let selectedVoice: AVSpeechSynthesisVoice?

        // First try to find enhanced quality Australian voice
        if let enhancedAustralianVoice = AVSpeechSynthesisVoice.speechVoices().first(where: {
            $0.language == "en-AU" && $0.quality == .enhanced
        }) {
            selectedVoice = enhancedAustralianVoice
            print("✅ MascotSpeech: Using enhanced Australian voice: \(enhancedAustralianVoice.name)")
        }
        // Then try any Australian voice
        else if let australianVoice = AVSpeechSynthesisVoice.speechVoices().first(where: {
            $0.language == "en-AU"
        }) {
            selectedVoice = australianVoice
            print("✅ MascotSpeech: Using Australian voice: \(australianVoice.name)")
        }
        // Fallback to specific Australian voice identifiers
        else if let karenVoice = AVSpeechSynthesisVoice(identifier: "com.apple.voice.compact.en-AU.Karen") {
            selectedVoice = karenVoice
            print("✅ MascotSpeech: Using Karen (Australian) voice")
        }
        else if let leeVoice = AVSpeechSynthesisVoice(identifier: "com.apple.voice.compact.en-AU.Lee") {
            selectedVoice = leeVoice
            print("✅ MascotSpeech: Using Lee (Australian) voice")
        }
        // Last resort: UK English for similar accent
        else if let ukVoice = AVSpeechSynthesisVoice.speechVoices().first(where: {
            $0.language == "en-GB"
        }) {
            selectedVoice = ukVoice
            print("⚠️ MascotSpeech: Australian voice not available, using UK voice: \(ukVoice.name)")
        }
        // Final fallback
        else {
            selectedVoice = AVSpeechSynthesisVoice(language: "en-US")
            print("⚠️ MascotSpeech: Using fallback US voice")
        }

        utterance.voice = selectedVoice

        // Configure speech parameters for cartoonish child-like voice
        utterance.rate = 0.45 // Normal pace, not too fast
        utterance.pitchMultiplier = 1.35 // Much higher pitch for child-like voice
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0.0
        utterance.postUtteranceDelay = 0.0

        print("🎤 MascotSpeech: Speaking now with voice: \(selectedVoice?.name ?? "unknown")")
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            print("⏹️ MascotSpeech: Stopping speech")
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
        }
    }

    // MARK: - AVSpeechSynthesizerDelegate

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("🎬 MascotSpeech: Speech started")
        isSpeaking = true
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("✅ MascotSpeech: Speech finished")
        isSpeaking = false
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("⚠️ MascotSpeech: Speech cancelled")
        isSpeaking = false
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        currentWordRange = characterRange
    }
}
