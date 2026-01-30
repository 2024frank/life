//
//  OnboardingView.swift
//  knowbest
//
//  Created by Frank Kusi Appiah on 1/31/26.
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var permissionManager = PermissionManager.shared
    @Binding var isComplete: Bool
    @State private var currentPage = 0
    @State private var isRequesting = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)
                
                Text("Welcome to Adam")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your AI life assistant")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 60)
            .padding(.bottom, 40)
            
            // Permission cards
            ScrollView {
                VStack(spacing: 16) {
                    PermissionCard(
                        icon: "mic.fill",
                        title: "Microphone",
                        description: "Adam needs to hear your voice commands",
                        isGranted: permissionManager.microphoneGranted
                    )
                    
                    PermissionCard(
                        icon: "waveform",
                        title: "Speech Recognition",
                        description: "Adam uses speech to understand what you say",
                        isGranted: permissionManager.speechGranted
                    )
                    
                    PermissionCard(
                        icon: "bell.fill",
                        title: "Notifications",
                        description: "Get reminders for your tasks",
                        isGranted: permissionManager.notificationsGranted
                    )
                    
                    PermissionCard(
                        icon: "calendar",
                        title: "Calendar",
                        description: "Add tasks directly to your calendar",
                        isGranted: permissionManager.calendarGranted
                    )
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Action button
            VStack(spacing: 16) {
                if permissionManager.allPermissionsRequested {
                    Button {
                        isComplete = true
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(14)
                    }
                } else {
                    Button {
                        isRequesting = true
                        // Check current permissions first (safe - won't crash)
                        permissionManager.checkAllPermissions()
                        // Then request if needed
                        permissionManager.requestAllPermissions {
                            isRequesting = false
                        }
                    } label: {
                        HStack {
                            if isRequesting {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("Enable All Permissions")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(14)
                    }
                    .disabled(isRequesting)
                    
                    Button {
                        isComplete = true
                    } label: {
                        Text("Skip for now")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
    }
}

struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.purple)
                .frame(width: 44, height: 44)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: isGranted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(isGranted ? .green : .gray)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    OnboardingView(isComplete: .constant(false))
}
