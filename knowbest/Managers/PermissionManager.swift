//
//  PermissionManager.swift
//  knowbest
//
//  Created by Frank Kusi Appiah on 1/31/26.
//

import Foundation
import Combine
import AVFoundation
import Speech
import UserNotifications
import EventKit

class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published var microphoneGranted = false
    @Published var speechGranted = false
    @Published var notificationsGranted = false
    @Published var calendarGranted = false
    @Published var allPermissionsRequested = false
    
    private let hasRequestedKey = "HasRequestedAllPermissions"
    
    var hasRequestedBefore: Bool {
        UserDefaults.standard.bool(forKey: hasRequestedKey)
    }
    
    var allGranted: Bool {
        microphoneGranted && speechGranted && notificationsGranted
    }
    
    private init() {
        checkAllPermissions()
    }
    
    func checkAllPermissions() {
        // Check microphone
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            microphoneGranted = true
        default:
            microphoneGranted = false
        }
        
        // Check speech recognition
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            speechGranted = true
        default:
            speechGranted = false
        }
        
        // Check notifications
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsGranted = settings.authorizationStatus == .authorized
            }
        }
        
        // Check calendar
        let status = EKEventStore.authorizationStatus(for: .event)
        calendarGranted = (status == .fullAccess || status == .authorized)
    }
    
    func requestAllPermissions(completion: @escaping () -> Void) {
        let group = DispatchGroup()
        
        // 1. Request Microphone
        group.enter()
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                self.microphoneGranted = granted
                group.leave()
            }
        }
        
        // 2. Request Speech Recognition
        group.enter()
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                self.speechGranted = (status == .authorized)
                group.leave()
            }
        }
        
        // 3. Request Notifications
        group.enter()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.notificationsGranted = granted
                group.leave()
            }
        }
        
        // 4. Request Calendar
        group.enter()
        let eventStore = EKEventStore()
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, _ in
                DispatchQueue.main.async {
                    self.calendarGranted = granted
                    group.leave()
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, _ in
                DispatchQueue.main.async {
                    self.calendarGranted = granted
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            UserDefaults.standard.set(true, forKey: self.hasRequestedKey)
            self.allPermissionsRequested = true
            completion()
        }
    }
}
