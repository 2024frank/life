//
//  SettingsView.swift
//  knowbest
//
//  Created by Frank Kusi Appiah on 1/31/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var openAIKey: String = UserDefaults.standard.string(forKey: "OpenAIAPIKey") ?? ""
    @State private var elevenLabsKey: String = UserDefaults.standard.string(forKey: "ElevenLabsAPIKey") ?? ""
    @State private var showAPIKeyInfo = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.blue)
                        Text("Voice Assistant")
                            .font(.headline)
                    }
                }
                
                Section("OpenAI API Key") {
                    HStack {
                        TextField("sk-...", text: $openAIKey)
                            .textContentType(.password)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                        
                        if !openAIKey.isEmpty {
                            Button {
                                openAIKey = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    HStack {
                        Image(systemName: openAIKey.isEmpty ? "exclamationmark.triangle" : "checkmark.circle.fill")
                            .foregroundColor(openAIKey.isEmpty ? .orange : .green)
                        Text(openAIKey.isEmpty ? "Not configured - using basic parsing" : "Configured - using GPT-4o-mini")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://platform.openai.com/api-keys")!) {
                        HStack {
                            Image(systemName: "link")
                            Text("Get OpenAI API Key")
                        }
                    }
                }
                
                Section("Eleven Labs API Key") {
                    HStack {
                        TextField("...", text: $elevenLabsKey)
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
                        Text(elevenLabsKey.isEmpty ? "Not configured - using system voice" : "Configured - using natural voice")
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
                            Text("How to Get API Keys")
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
                        saveKeys()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showAPIKeyInfo) {
                APIKeyInfoView()
            }
        }
    }
    
    private func saveKeys() {
        OpenAIService.shared.setAPIKey(openAIKey)
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
                    Text("Why API Keys?")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("API keys enable advanced features:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(
                            icon: "brain",
                            title: "OpenAI API Key",
                            description: "Enables advanced natural language understanding. Makes the assistant understand complex requests better.",
                            link: "https://platform.openai.com/api-keys"
                        )
                        
                        InfoRow(
                            icon: "waveform",
                            title: "Eleven Labs API Key",
                            description: "Provides natural, human-like voice responses instead of robotic system voice.",
                            link: "https://elevenlabs.io/app/api-keys"
                        )
                    }
                    
                    Divider()
                    
                    Text("Cost")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("• OpenAI: Very affordable (~$1-5/month for personal use)")
                    Text("• Eleven Labs: Free tier available (10,000 chars/month)")
                    
                    Divider()
                    
                    Text("Security")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("• Keys are stored securely on your device")
                    Text("• Never shared with third parties")
                    Text("• You can remove them anytime")
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("API Keys Info")
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
