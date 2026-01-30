//
//  ElevenLabsService.swift
//  knowbest
//
//  Created by Frank Kusi Appiah on 1/31/26.
//

import Foundation
import Combine
import AVFoundation

class ElevenLabsService: NSObject, ObservableObject {
    static let shared = ElevenLabsService()
    
    @Published var isSpeaking = false
    
    private var audioPlayer: AVAudioPlayer?
    private var apiKey: String {
        if let key = UserDefaults.standard.string(forKey: "ElevenLabsAPIKey"), !key.isEmpty {
            return key
        }
        return ProcessInfo.processInfo.environment["ELEVENLABS_API_KEY"] ?? ""
    }
    
    private let baseURL = "https://api.elevenlabs.io/v1/text-to-speech"
    private let voiceID = "pNInz6obpgDQGcFmaJgB" // Adam voice
    
    private override init() {
        super.init()
    }
    
    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "ElevenLabsAPIKey")
    }
    
    func speak(_ text: String) async {
        guard !apiKey.isEmpty else {
            // Fallback to AVSpeechSynthesizer if no API key
            await speakWithSystemVoice(text)
            return
        }
        
        do {
            let url = URL(string: "\(baseURL)/\(voiceID)")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let requestBody: [String: Any] = [
                "text": text,
                "model_id": "eleven_turbo_v2_5",
                "voice_settings": [
                    "stability": 0.5,
                    "similarity_boost": 0.75
                ]
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("Eleven Labs API error")
                await speakWithSystemVoice(text)
                return
            }
            
            // Save to temporary file and play
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp3")
            try data.write(to: tempURL)
            
            await MainActor.run {
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: tempURL)
                    isSpeaking = true
                    audioPlayer?.play()
                } catch {
                    print("Error playing audio: \(error.localizedDescription)")
                    isSpeaking = false
                }
            }
            
        } catch {
            print("Error with Eleven Labs: \(error.localizedDescription)")
            await speakWithSystemVoice(text)
        }
    }
    
    private func speakWithSystemVoice(_ text: String) async {
        await MainActor.run {
            let synthesizer = AVSpeechSynthesizer()
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = 0.5
            synthesizer.speak(utterance)
        }
    }
    
    func stopSpeaking() {
        audioPlayer?.stop()
        isSpeaking = false
    }
}
