//
//  ElevenLabsService.swift
//  knowbest
//
//  Created by Frank Kusi Appiah on 1/31/26.
//

import Foundation
import Combine
import AVFoundation

// Emotion types for voice modulation
enum VoiceEmotion: String {
    case happy = "happy"
    case encouraging = "encouraging"
    case calm = "calm"
    case excited = "excited"
    case understanding = "understanding"
    case neutral = "neutral"
    
    // Voice settings for each emotion - balanced pace
    var voiceSettings: [String: Any] {
        switch self {
        case .happy:
            return [
                "stability": 0.5,           // More stable = slower pace
                "similarity_boost": 0.8,
                "style": 0.6,               // Moderate expression
                "use_speaker_boost": true
            ]
        case .encouraging:
            return [
                "stability": 0.55,
                "similarity_boost": 0.8,
                "style": 0.5,
                "use_speaker_boost": true
            ]
        case .calm:
            return [
                "stability": 0.75,          // High stability = measured pace
                "similarity_boost": 0.85,
                "style": 0.3,
                "use_speaker_boost": true
            ]
        case .excited:
            return [
                "stability": 0.45,          // Slightly faster but controlled
                "similarity_boost": 0.75,
                "style": 0.7,
                "use_speaker_boost": true
            ]
        case .understanding:
            return [
                "stability": 0.65,          // Calm, measured
                "similarity_boost": 0.8,
                "style": 0.35,
                "use_speaker_boost": true
            ]
        case .neutral:
            return [
                "stability": 0.6,           // Balanced, natural pace
                "similarity_boost": 0.8,
                "style": 0.4,
                "use_speaker_boost": true
            ]
        }
    }
}

class ElevenLabsService: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = ElevenLabsService()
    
    @Published var isSpeaking = false
    
    private var audioPlayer: AVAudioPlayer?
    private var systemSynthesizer: AVSpeechSynthesizer?
    
    private var apiKey: String {
        // 1. Check UserDefaults (set in app)
        if let key = UserDefaults.standard.string(forKey: "ElevenLabsAPIKey"), !key.isEmpty {
            return key
        }
        // 2. Check environment variable (from build settings)
        if let key = ProcessInfo.processInfo.environment["ELEVENLABS_API_KEY"], !key.isEmpty {
            return key
        }
        // 3. Check Info.plist (from build settings)
        if let key = Bundle.main.object(forInfoDictionaryKey: "ELEVENLABS_API_KEY") as? String, !key.isEmpty {
            return key
        }
        return ""
    }
    
    private let baseURL = "https://api.elevenlabs.io/v1/text-to-speech"
    private let streamURL = "https://api.elevenlabs.io/v1/text-to-speech"
    private let voiceID = "pNInz6obpgDQGcFmaJgB" // Adam voice
    
    private override init() {
        super.init()
    }
    
    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "ElevenLabsAPIKey")
    }
    
    // Main speak function with emotion support
    func speak(_ text: String, emotion: VoiceEmotion = .neutral) async {
        guard !apiKey.isEmpty else {
            await speakWithSystemVoice(text, emotion: emotion)
            return
        }
        
        await MainActor.run {
            isSpeaking = true
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
                "voice_settings": emotion.voiceSettings
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("Eleven Labs API error")
                await speakWithSystemVoice(text, emotion: emotion)
                return
            }
            
            // Save to temporary file and play
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp3")
            try data.write(to: tempURL)
            
            await MainActor.run {
                do {
                    // Configure audio session for playback
                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                    try AVAudioSession.sharedInstance().setActive(true)
                    
                    audioPlayer = try AVAudioPlayer(contentsOf: tempURL)
                    audioPlayer?.delegate = self
                    audioPlayer?.play()
                } catch {
                    print("Error playing audio: \(error.localizedDescription)")
                    isSpeaking = false
                }
            }
            
        } catch {
            print("Error with Eleven Labs: \(error.localizedDescription)")
            await speakWithSystemVoice(text, emotion: emotion)
        }
    }
    
    // Convenience method for speaking with emotion string from API
    func speak(_ text: String, emotionString: String?) async {
        let emotion = VoiceEmotion(rawValue: emotionString ?? "neutral") ?? .neutral
        await speak(text, emotion: emotion)
    }
    
    private func speakWithSystemVoice(_ text: String, emotion: VoiceEmotion = .neutral) async {
        await MainActor.run {
            isSpeaking = true
            systemSynthesizer = AVSpeechSynthesizer()
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            
            // Adjust rate and pitch based on emotion
            switch emotion {
            case .happy, .excited:
                utterance.rate = 0.55
                utterance.pitchMultiplier = 1.1
            case .calm, .understanding:
                utterance.rate = 0.45
                utterance.pitchMultiplier = 0.95
            case .encouraging:
                utterance.rate = 0.5
                utterance.pitchMultiplier = 1.05
            case .neutral:
                utterance.rate = 0.5
                utterance.pitchMultiplier = 1.0
            }
            
            systemSynthesizer?.speak(utterance)
        }
    }
    
    func stopSpeaking() {
        audioPlayer?.stop()
        systemSynthesizer?.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
    
    // AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
}
