//
//  SpeechRecognitionService.swift
//  Preppi AI
//
//  Service for recording audio and transcribing using OpenAI Whisper
//

import Foundation
import AVFoundation

class SpeechRecognitionService: NSObject, ObservableObject, AVAudioRecorderDelegate {
    static let shared = SpeechRecognitionService()

    @Published var isRecording = false
    @Published var isTranscribing = false
    @Published var errorMessage: String?
    @Published var transcribedText: String?
    @Published var extractedCountry: String?
    @Published var audioLevel: Float = 0.0

    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession?
    private var recordingURL: URL?
    private var levelTimer: Timer?

    private let apiKey = ConfigurationService.shared.openAIAPIKey
    private let whisperURL = "https://api.openai.com/v1/audio/transcriptions"

    override private init() {
        super.init()
        setupAudioSession()
    }

    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession?.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession?.setActive(true, options: [])
            print("✅ SpeechRecognition: Audio session configured")
        } catch {
            print("❌ SpeechRecognition: Failed to setup audio session: \(error)")
            errorMessage = "Failed to setup audio: \(error.localizedDescription)"
        }
    }

    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                print(granted ? "✅ SpeechRecognition: Microphone permission granted" : "❌ SpeechRecognition: Microphone permission denied")
                continuation.resume(returning: granted)
            }
        }
    }

    func startRecording() {
        Task { @MainActor in
            errorMessage = nil
            transcribedText = nil
            extractedCountry = nil
        }

        // Check microphone permission
        Task {
            let hasPermission = await requestMicrophonePermission()
            guard hasPermission else {
                await MainActor.run {
                    errorMessage = "Microphone permission is required to use voice input"
                }
                return
            }

            await MainActor.run {
                setupRecording()
            }
        }
    }

    private func setupRecording() {
        // Create a unique file URL for the recording
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
        recordingURL = tempDir.appendingPathComponent(fileName)

        guard let url = recordingURL else {
            errorMessage = "Failed to create recording file"
            return
        }

        // Configure recording settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000, // Whisper works well with 16kHz
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()

            let success = audioRecorder?.record() ?? false
            if success {
                isRecording = true
                startLevelMonitoring()
                print("🎤 SpeechRecognition: Recording started")
            } else {
                errorMessage = "Failed to start recording"
                print("❌ SpeechRecognition: Failed to start recording")
            }
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
            print("❌ SpeechRecognition: Recording error: \(error)")
        }
    }

    func stopRecording() {
        guard isRecording else { return }

        print("⏹️ SpeechRecognition: Stopping recording")
        stopLevelMonitoring()
        audioRecorder?.stop()
        isRecording = false

        // Transcribe the recording
        if let url = recordingURL {
            Task {
                await transcribeAudio(fileURL: url)
            }
        }
    }
    
    private func startLevelMonitoring() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            self.audioRecorder?.updateMeters()
            let averagePower = self.audioRecorder?.averagePower(forChannel: 0) ?? -160
            
            // Convert decibel to linear scale (0.0 to 1.0)
            // -160 dB is essentially silence, -40 dB is reasonable speaking volume
            let normalizedLevel = max(0.0, min(1.0, (averagePower + 160) / 120))
            
            DispatchQueue.main.async {
                self.audioLevel = Float(normalizedLevel)
            }
        }
    }
    
    private func stopLevelMonitoring() {
        levelTimer?.invalidate()
        levelTimer = nil
        audioLevel = 0.0
    }

    private func transcribeAudio(fileURL: URL) async {
        await MainActor.run {
            isTranscribing = true
            errorMessage = nil
        }

        defer {
            Task { @MainActor in
                isTranscribing = false
            }
        }

        do {
            print("🔄 SpeechRecognition: Starting transcription...")

            // Read the audio file
            let audioData = try Data(contentsOf: fileURL)

            // Create multipart form data
            let boundary = "Boundary-\(UUID().uuidString)"
            var body = Data()

            // Add model parameter
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
            body.append("whisper-1\r\n".data(using: .utf8)!)

            // Add file data
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: audio/mp4\r\n\r\n".data(using: .utf8)!)
            body.append(audioData)
            body.append("\r\n".data(using: .utf8)!)

            // Add language hint (optional, helps with accuracy)
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
            body.append("en\r\n".data(using: .utf8)!)

            // Close boundary
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)

            // Create request
            guard let url = URL(string: whisperURL) else {
                await MainActor.run {
                    errorMessage = "Invalid API URL"
                }
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.httpBody = body

            // Send request
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run {
                    errorMessage = "Invalid response from server"
                }
                return
            }

            guard httpResponse.statusCode == 200 else {
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorData["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    await MainActor.run {
                        errorMessage = "Transcription failed: \(message)"
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "Transcription failed with status code: \(httpResponse.statusCode)"
                    }
                }
                print("❌ SpeechRecognition: Transcription failed with status \(httpResponse.statusCode)")
                return
            }

            // Parse response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let text = json["text"] as? String {
                let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                await MainActor.run {
                    transcribedText = cleanedText
                }
                print("✅ SpeechRecognition: Transcription successful: \"\(cleanedText)\"")
                
                // Extract country using AI
                await extractCountryFromText(cleanedText)
            } else {
                await MainActor.run {
                    errorMessage = "Failed to parse transcription response"
                }
                print("❌ SpeechRecognition: Failed to parse response")
            }

            // Clean up temporary file
            try? FileManager.default.removeItem(at: fileURL)

        } catch {
            await MainActor.run {
                errorMessage = "Transcription error: \(error.localizedDescription)"
            }
            print("❌ SpeechRecognition: Transcription error: \(error)")
        }
    }

    // AVAudioRecorderDelegate
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            print("✅ SpeechRecognition: Recording finished successfully")
        } else {
            print("❌ SpeechRecognition: Recording finished with error")
            Task { @MainActor in
                errorMessage = "Recording failed"
            }
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("❌ SpeechRecognition: Encoding error: \(error?.localizedDescription ?? "unknown")")
        Task { @MainActor in
            errorMessage = "Recording error: \(error?.localizedDescription ?? "unknown error")"
            isRecording = false
        }
    }
    
    // MARK: - AI Country Extraction
    private func extractCountryFromText(_ text: String) async {
        do {
            print("🔄 SpeechRecognition: Extracting country from: \"\(text)\"")
            
            let prompt = """
            Extract the country name from the following text. The user is answering the question "What country are you from?" 
            
            Text: "\(text)"
            
            Rules:
            1. Return ONLY the country name in English
            2. Use the standard country name (e.g., "United States" not "USA" or "America")
            3. If no country is mentioned, return "Unknown"
            4. If multiple countries are mentioned, return the first one
            5. Handle common variations (e.g., "I'm from Nigeria" → "Nigeria")
            
            Country:
            """
            
            let requestBody: [String: Any] = [
                "model": "gpt-3.5-turbo",
                "messages": [
                    [
                        "role": "system",
                        "content": "You are a helpful assistant that extracts country names from user speech. Always respond with just the country name, nothing else."
                    ],
                    [
                        "role": "user",
                        "content": prompt
                    ]
                ],
                "max_tokens": 50,
                "temperature": 0.1
            ]
            
            guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
                await MainActor.run {
                    errorMessage = "Invalid OpenAI API URL"
                }
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run {
                    errorMessage = "Invalid response from OpenAI"
                }
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                print("❌ SpeechRecognition: Country extraction failed with status \(httpResponse.statusCode)")
                // Don't set error message for country extraction failure, just use original text
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                
                let extractedCountry = content.trimmingCharacters(in: .whitespacesAndNewlines)
                
                await MainActor.run {
                    if extractedCountry.lowercased() != "unknown" && !extractedCountry.isEmpty {
                        self.extractedCountry = extractedCountry
                        print("✅ SpeechRecognition: Country extracted: \"\(extractedCountry)\"")
                    } else {
                        // If AI couldn't extract country, use original transcribed text
                        self.extractedCountry = text
                        print("⚠️ SpeechRecognition: Could not extract country, using original text")
                    }
                }
            } else {
                await MainActor.run {
                    // If parsing fails, use original transcribed text
                    self.extractedCountry = text
                }
                print("⚠️ SpeechRecognition: Failed to parse country extraction response, using original text")
            }
            
        } catch {
            await MainActor.run {
                // If extraction fails, use original transcribed text
                self.extractedCountry = text
            }
            print("⚠️ SpeechRecognition: Country extraction error: \(error), using original text")
        }
    }
}
