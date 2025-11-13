//
//  ElevenLabsSpeechService.swift
//  Preppi AI
//
//  Text-to-speech service using ElevenLabs API
//

import Foundation
import AVFoundation

class ElevenLabsSpeechService: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = ElevenLabsSpeechService()
    
    @Published var isSpeaking = false
    @Published var errorMessage: String?
    
    private var audioPlayer: AVAudioPlayer?
    private var audioSession: AVAudioSession?
    
    // ElevenLabs API configuration
    private let apiKey = "81d07c0a0a1a21be201b904e20e67adfb5eca5cefea411cdee05b0fa10730be0"
    private let baseURL = "https://api.elevenlabs.io/v1"
    
    // Voice ID - you can change this to use different ElevenLabs voices
    // This is a default voice ID, you may want to customize it
    private let voiceID = "21m00Tcm4TlvDq8ikWAM" // Rachel voice (default)
    
    override private init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            audioSession = AVAudioSession.sharedInstance()
            // Use .playback category to play even when device is in silent mode
            try audioSession?.setCategory(.playback, mode: .spokenAudio, options: [])
            try audioSession?.setActive(true, options: [])
            print("✅ ElevenLabsSpeech: Audio session configured successfully")
        } catch {
            print("❌ ElevenLabsSpeech: Failed to setup audio session: \(error)")
            errorMessage = "Failed to setup audio: \(error.localizedDescription)"
        }
    }
    
    func speak(_ text: String, completion: (() -> Void)? = nil) {
        print("🗣️ ElevenLabsSpeech: Attempting to speak: \"\(text)\"")
        
        // Stop any ongoing speech
        stop()
        
        // Clear previous errors
        errorMessage = nil
        
        Task {
            await generateAndPlaySpeech(text: text, completion: completion)
        }
    }
    
    private func generateAndPlaySpeech(text: String, completion: (() -> Void)? = nil) async {
        do {
            // Update UI on main thread
            await MainActor.run {
                isSpeaking = true
            }
            
            // Generate speech using ElevenLabs API
            let audioData = try await generateSpeech(text: text)
            
            // Play the audio
            await playAudio(data: audioData, completion: completion)
            
        } catch {
            print("❌ ElevenLabsSpeech: Failed to generate/play speech: \(error)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isSpeaking = false
            }
            completion?()
        }
    }
    
    private func generateSpeech(text: String) async throws -> Data {
        guard let url = URL(string: "\(baseURL)/text-to-speech/\(voiceID)") else {
            throw ElevenLabsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        
        // Request body with voice settings for a friendly, child-like voice
        let requestBody: [String: Any] = [
            "text": text,
            "model_id": "eleven_monolingual_v1", // Fast, good quality model
            "voice_settings": [
                "stability": 0.5,        // Medium stability for natural variation
                "similarity_boost": 0.8, // High similarity to maintain voice character
                "style": 0.3,           // Light style for friendliness
                "use_speaker_boost": true
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("🌐 ElevenLabsSpeech: Sending request to ElevenLabs API...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ElevenLabsError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ ElevenLabsSpeech: API returned status code: \(httpResponse.statusCode)")
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ ElevenLabsSpeech: Error response: \(errorString)")
            }
            throw ElevenLabsError.apiError(httpResponse.statusCode)
        }
        
        print("✅ ElevenLabsSpeech: Successfully generated speech audio (\(data.count) bytes)")
        return data
    }
    
    private func playAudio(data: Data, completion: (() -> Void)? = nil) async {
        do {
            // Ensure audio session is active
            try audioSession?.setActive(true, options: [])
            
            // Create audio player
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            // Store completion for delegate callback
            self.playbackCompletion = completion
            
            // Play audio
            let success = audioPlayer?.play() ?? false
            
            if success {
                print("🎵 ElevenLabsSpeech: Started playing audio")
            } else {
                print("❌ ElevenLabsSpeech: Failed to start audio playback")
                await MainActor.run {
                    self.isSpeaking = false
                    self.errorMessage = "Failed to play audio"
                }
                completion?()
            }
            
        } catch {
            print("❌ ElevenLabsSpeech: Failed to create audio player: \(error)")
            await MainActor.run {
                self.isSpeaking = false
                self.errorMessage = "Failed to play audio: \(error.localizedDescription)"
            }
            completion?()
        }
    }
    
    func stop() {
        if let player = audioPlayer, player.isPlaying {
            print("⏹️ ElevenLabsSpeech: Stopping audio playback")
            player.stop()
        }
        audioPlayer = nil
        playbackCompletion = nil
        isSpeaking = false
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    private var playbackCompletion: (() -> Void)?
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("✅ ElevenLabsSpeech: Audio playback finished successfully: \(flag)")
        
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
        
        playbackCompletion?()
        playbackCompletion = nil
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("❌ ElevenLabsSpeech: Audio decode error: \(error?.localizedDescription ?? "unknown")")
        
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.errorMessage = "Audio decode error: \(error?.localizedDescription ?? "unknown")"
        }
        
        playbackCompletion?()
        playbackCompletion = nil
    }
}

// MARK: - Error Types

enum ElevenLabsError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid ElevenLabs API URL"
        case .invalidResponse:
            return "Invalid response from ElevenLabs API"
        case .apiError(let statusCode):
            return "ElevenLabs API error (status: \(statusCode))"
        }
    }
}
