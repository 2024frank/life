//
//  ContentView.swift
//  knowbest
//
//  Created by Frank Kusi Appiah on 1/31/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("HasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var permissionManager = PermissionManager.shared
    
    var body: some View {
        if hasCompletedOnboarding {
            TodoListView()
        } else {
            OnboardingView(isComplete: $hasCompletedOnboarding)
        }
    }
}

#Preview {
    ContentView()
}
