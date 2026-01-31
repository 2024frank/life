//
//  SettingsView.swift
//  knowbest
//
//  Created by Frank Kusi Appiah on 1/31/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var elevenLabsKey: String = UserDefaults.standard.string(forKey: "ElevenLabsAPIKey") ?? ""
    @State private var showAPIKeyInfo = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        Text("Adam - Your Personal Assistant")
                            .font(.headline)
                    }
                }
                
                Section("Voice (Eleven Labs)") {
                    HStack {
                        TextField("API Key (optional)", text: $elevenLabsKey)
                            .textContentType(.password)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                        
                        if !elevenLabsKey.isEmpty {
                            Button {
                                elevenLabsKey = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    HStack {
                        Image(systemName: elevenLabsKey.isEmpty ? "exclamationmark.triangle" : "checkmark.circle.fill")
                            .foregroundColor(elevenLabsKey.isEmpty ? .orange : .green)
                        Text(elevenLabsKey.isEmpty ? "Using system voice" : "Using natural voice")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://elevenlabs.io/app/api-keys")!) {
                        HStack {
                            Image(systemName: "link")
                            Text("Get Eleven Labs API Key")
                        }
                    }
                }
                
                Section {
                    Button {
                        showAPIKeyInfo = true
                    } label: {
                        HStack {
                            Image(systemName: "info.circle")
                            Text("How It Works")
                        }
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com/2024frank/life")!) {
                        HStack {
                            Image(systemName: "link")
                            Text("GitHub Repository")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showAPIKeyInfo) {
                APIKeyInfoView()
            }
        }
    }
    
    private func saveSettings() {
        ElevenLabsService.shared.setAPIKey(elevenLabsKey)
        dismiss()
    }
}

struct APIKeyInfoView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("How It Works")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(
                            icon: "brain",
                            title: "AI Powered",
                            description: "Adam uses local AI to understand your voice commands. Everything works offline!",
                            link: ""
                        )
                        
                        InfoRow(
                            icon: "waveform",
                            title: "Natural Voice (Optional)",
                            description: "Add your own Eleven Labs key for natural voice responses. Free tier gives 10,000 chars/month.",
                            link: "https://elevenlabs.io/app/api-keys"
                        )
                    }
                    
                    Divider()
                    
                    Text("Privacy")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("• Your todos are stored locally on your device")
                    Text("• Voice commands are processed on your device")
                    Text("• Eleven Labs key is stored only on your device")
                    Text("• No data is sent to any server")
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("How It Works")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String
    let link: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Link(destination: URL(string: link)!) {
                HStack {
                    Text("Get API Key")
                        .font(.caption)
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                }
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    SettingsView()
}
