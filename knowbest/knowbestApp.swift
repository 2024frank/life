//
//  knowbestApp.swift
//  knowbest
//
//  Created by Frank Kusi Appiah on 1/31/26.
//

import SwiftUI

@main
struct knowbestApp: App {
    init() {
        // Request notification permissions on app launch
        NotificationManager.shared.requestAuthorization()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
