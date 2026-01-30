//
//  AdamIntents.swift
//  knowbest
//
//  Created by Frank Kusi Appiah on 1/31/26.
//

import Foundation
import Intents
import AppIntents

// MARK: - App Intent for iOS 16+
@available(iOS 16.0, *)
struct AskAdamIntent: AppIntent {
    static var title: LocalizedStringResource = "Ask Adam"
    static var description = IntentDescription("Talk to Adam, your personal assistant")
    
    // This makes it available to Siri
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "What do you need?")
    var request: String?
    
    func perform() async throws -> some IntentResult & OpensIntent {
        // Open the app to the voice assistant
        return .result(opensIntent: OpenVoiceAssistantIntent())
    }
}

@available(iOS 16.0, *)
struct OpenVoiceAssistantIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Adam"
    static var description = IntentDescription("Open Adam voice assistant")
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        // Post notification to open voice assistant
        await MainActor.run {
            NotificationCenter.default.post(name: .openVoiceAssistant, object: nil)
        }
        return .result()
    }
}

// MARK: - App Shortcuts Provider
@available(iOS 16.0, *)
struct AdamShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenVoiceAssistantIntent(),
            phrases: [
                "Open \(.applicationName)",
                "Talk to Adam",
                "Hey Adam",
                "Ask Adam",
                "Open Adam",
                "Adam",
                "\(.applicationName)"
            ],
            shortTitle: "Adam",
            systemImageName: "waveform"
        )
    }
}

// MARK: - Notification for opening voice assistant
extension Notification.Name {
    static let openVoiceAssistant = Notification.Name("openVoiceAssistant")
}
