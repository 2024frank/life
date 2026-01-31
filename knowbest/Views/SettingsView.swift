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
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var name: String = ""
    @State private var isRegistering = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var isLoggedIn: Bool {
        BackendService.shared.isLoggedIn
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.blue)
                        Text("KnowBest Assistant")
                            .font(.headline)
                    }
                }
                
                // Account Section - OPTIONAL for cloud sync only
                Section("Cloud Sync (Optional)") {
                    if isLoggedIn {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Cloud sync enabled")
                        }
                        
                        Text("Your todos sync across devices")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Log Out", role: .destructive) {
                            BackendService.shared.logout()
                        }
                    } else {
                        Text("Login is OPTIONAL - only needed if you want to sync todos across devices.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                        
                        if isRegistering {
                            TextField("Name", text: $name)
                                .textContentType(.name)
                        }
                        
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                        
                        SecureField("Password", text: $password)
                            .textContentType(isRegistering ? .newPassword : .password)
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        Button {
                            performAuth()
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                                Text(isRegistering ? "Create Account" : "Login")
                            }
                        }
                        .disabled(email.isEmpty || password.isEmpty || isLoading)
                        
                        Button(isRegistering ? "Already have an account? Login" : "Don't have an account? Register") {
                            isRegistering.toggle()
                            errorMessage = nil
                        }
                        .font(.caption)
                    }
                }
                
                Section("AI Features") {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        Text("Adam works perfectly without login!")
                            .font(.subheadline)
                    }
                    Text("All AI features work locally on your device. Login is only for cloud sync.")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
    
    private func performAuth() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                if isRegistering {
                    _ = try await BackendService.shared.register(email: email, password: password, name: name)
                } else {
                    _ = try await BackendService.shared.login(email: email, password: password)
                }
                
                await MainActor.run {
                    isLoading = false
                    email = ""
                    password = ""
                    name = ""
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
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
                            icon: "person.circle",
                            title: "Account Login",
                            description: "Create an account or login to enable AI features. Your requests are processed securely on our server using OpenAI.",
                            link: "https://knowbest-backend.onrender.com"
                        )
                        
                        InfoRow(
                            icon: "brain",
                            title: "AI Powered",
                            description: "When logged in, your voice commands are understood using GPT-4o-mini. No need for your own OpenAI key!",
                            link: "https://openai.com"
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
                    Text("• Voice commands are processed securely")
                    Text("• Eleven Labs key is stored only on your device")
                    
                    Divider()
                    
                    Text("Without Login")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("• Basic voice recognition still works")
                    Text("• Simple commands like 'Remind me to...' are parsed locally")
                    Text("• Login for better understanding of complex requests")
                    
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
