//
//  VoiceActivationManager.swift
//  knowbest
//
//  Created by Frank Kusi Appiah on 1/31/26.
//

import Foundation
import Combine
import Speech
import AVFoundation

class VoiceActivationManager: NSObject, ObservableObject {
    static let shared = VoiceActivationManager()
    
    @Published var isListening = false
    @Published var isActivated = false
    @Published var recognizedText = ""
    
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let wakeWord = "hey assistant"
    
    private var isWaitingForWakeWord = true
    private var continuousText = ""
    
    override init() {
        super.init()
        requestAuthorization()
    }
    
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("Speech recognition authorized")
                case .denied, .restricted, .notDetermined:
                    print("Speech recognition not authorized")
                @unknown default:
                    break
                }
            }
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                print("Microphone permission granted")
            } else {
                print("Microphone permission denied")
            }
        }
    }
    
    func startListening() {
        guard !isListening else { return }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                return
            }
            
            recognitionRequest.shouldReportPartialResults = true
            recognitionRequest.taskHint = .dictation
            
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            isListening = true
            isWaitingForWakeWord = true
            continuousText = ""
            
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let result = result {
                    let text = result.bestTranscription.formattedString.lowercased()
                    self.continuousText = text
                    
                    if self.isWaitingForWakeWord {
                        if text.contains(self.wakeWord) {
                            DispatchQueue.main.async {
                                self.isActivated = true
                                self.isWaitingForWakeWord = false
                                self.recognizedText = ""
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            // Remove wake word from recognized text
                            let cleanedText = text.replacingOccurrences(of: self.wakeWord, with: "", options: .caseInsensitive)
                            self.recognizedText = cleanedText.trimmingCharacters(in: .whitespaces)
                        }
                    }
                }
                
                if error != nil || result?.isFinal == true {
                    self.stopListening()
                }
            }
        } catch {
            print("Error starting speech recognition: \(error.localizedDescription)")
        }
    }
    
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isListening = false
        isActivated = false
        isWaitingForWakeWord = true
        continuousText = ""
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Error deactivating audio session: \(error.localizedDescription)")
        }
    }
    
    func reset() {
        isActivated = false
        isWaitingForWakeWord = true
        recognizedText = ""
        continuousText = ""
    }
}
