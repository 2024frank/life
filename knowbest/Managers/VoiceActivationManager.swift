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
    @Published var permissionStatus: PermissionStatus = .notDetermined
    
    enum PermissionStatus {
        case notDetermined
        case authorized
        case denied
    }
    
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let wakeWord = "hey adam"  // Changed to "hey adam"
    
    private var isWaitingForWakeWord = true
    private var continuousText = ""
    
    override init() {
        super.init()
        // Don't auto-request - wait for user action
        checkPermissions()
    }
    
    func checkPermissions() {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        let micStatus = AVAudioSession.sharedInstance().recordPermission
        
        DispatchQueue.main.async {
            if speechStatus == .authorized && micStatus == .granted {
                self.permissionStatus = .authorized
            } else if speechStatus == .denied || micStatus == .denied {
                self.permissionStatus = .denied
            } else {
                self.permissionStatus = .notDetermined
            }
        }
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        var speechGranted = false
        var micGranted = false
        
        let group = DispatchGroup()
        
        group.enter()
        SFSpeechRecognizer.requestAuthorization { status in
            speechGranted = (status == .authorized)
            group.leave()
        }
        
        group.enter()
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            micGranted = granted
            group.leave()
        }
        
        group.notify(queue: .main) {
            let success = speechGranted && micGranted
            self.permissionStatus = success ? .authorized : .denied
            completion(success)
        }
    }
    
    func startListening() {
        guard !isListening else { return }
        guard permissionStatus == .authorized else {
            print("Permissions not granted")
            return
        }
        
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
                        // Check for "hey adam" or "hey assistant"
                        if text.contains(self.wakeWord) || text.contains("hey assistant") {
                            DispatchQueue.main.async {
                                self.isActivated = true
                                self.isWaitingForWakeWord = false
                                self.recognizedText = ""
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            // Remove wake words from recognized text
                            var cleanedText = text
                            cleanedText = cleanedText.replacingOccurrences(of: self.wakeWord, with: "", options: .caseInsensitive)
                            cleanedText = cleanedText.replacingOccurrences(of: "hey assistant", with: "", options: .caseInsensitive)
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
