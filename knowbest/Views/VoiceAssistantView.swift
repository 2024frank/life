//
//  VoiceAssistantView.swift
//  knowbest
//
//  Created by Frank Kusi Appiah on 1/31/26.
//

import SwiftUI

struct VoiceAssistantView: View {
    @ObservedObject var store: TodoStore
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var voiceManager = VoiceActivationManager.shared
    @ObservedObject private var elevenLabs = ElevenLabsService.shared
    
    @State private var conversationHistory: [String] = []
    @State private var currentQuestion: String?
    @State private var isProcessing = false
    @State private var assistantResponse = ""
    @State private var showAPIKeySettings = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Status indicator
                statusHeader
                
                // Conversation area
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if conversationHistory.isEmpty {
                                welcomeMessage
                            } else {
                                ForEach(Array(conversationHistory.enumerated()), id: \.offset) { index, message in
                                    if index % 2 == 0 {
                                        UserMessage(text: message)
                                    } else {
                                        AssistantMessage(text: message)
                                    }
                                }
                                
                                if let question = currentQuestion {
                                    AssistantMessage(text: question, isQuestion: true)
                                }
                                
                                if isProcessing {
                                    HStack {
                                        ProgressView()
                                        Text("Processing...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                }
                            }
                        }
                        .padding()
                    }
                    .onChange(of: conversationHistory.count) { _ in
                        if let lastIndex = conversationHistory.indices.last {
                            withAnimation {
                                proxy.scrollTo(lastIndex, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Voice activation area
                VStack(spacing: 16) {
                    if voiceManager.isActivated {
                        activatedState
                    } else {
                        waitingState
                    }
                    
                    // Recognized text display
                    if !voiceManager.recognizedText.isEmpty {
                        Text("\"\(voiceManager.recognizedText)\"")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                            .padding(.horizontal)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
            }
            .navigationTitle("Voice Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showAPIKeySettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        voiceManager.stopListening()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showAPIKeySettings) {
                APIKeySettingsView()
            }
            .onAppear {
                voiceManager.startListening()
            }
            .onDisappear {
                voiceManager.stopListening()
            }
            .onChange(of: voiceManager.isActivated) { activated in
                if activated {
                    Task {
                        await elevenLabs.speak("Yes, how can I help you?")
                    }
                }
            }
            .onChange(of: voiceManager.recognizedText) { text in
                if voiceManager.isActivated && !text.isEmpty {
                    handleUserInput(text)
                }
            }
        }
    }
    
    private var statusHeader: some View {
        HStack {
            Circle()
                .fill(voiceManager.isListening ? (voiceManager.isActivated ? Color.green : Color.orange) : Color.gray)
                .frame(width: 12, height: 12)
            
            Text(voiceManager.isListening ? (voiceManager.isActivated ? "Listening..." : "Say 'Hey Assistant'") : "Not Listening")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private var welcomeMessage: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            Text("Voice Assistant Ready")
                .font(.title2)
                .fontWeight(.bold)
            Text("Say 'Hey Assistant' to start, then tell me what you need to do!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var waitingState: some View {
        VStack(spacing: 12) {
            Image(systemName: "mic.slash")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text("Waiting for 'Hey Assistant'...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
    
    private var activatedState: some View {
        VStack(spacing: 12) {
            Image(systemName: "mic.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)
                .symbolEffect(.pulse)
            Text("Listening...")
                .font(.headline)
                .foregroundColor(.green)
            Text("Tell me what you need to do")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func handleUserInput(_ text: String) {
        guard !isProcessing else { return }
        isProcessing = true
        
        conversationHistory.append(text)
        voiceManager.reset()
        
        Task {
            do {
                let response = try await OpenAIService.shared.parseUserInput(text, conversationHistory: conversationHistory)
                
                await MainActor.run {
                    isProcessing = false
                    
                    // Handle questions
                    if let questions = response.questions, !questions.isEmpty {
                        currentQuestion = questions.first
                        let questionText = questions.first!
                        conversationHistory.append(questionText)
                        
                        Task {
                            await elevenLabs.speak(questionText)
                        }
                    } else {
                        currentQuestion = nil
                        
                        // Process todos
                        if !response.todos.isEmpty {
                            var responseText = "I've created \(response.todos.count) todo"
                            if response.todos.count > 1 {
                                responseText += "s"
                            }
                            responseText += " for you."
                            
                            for (index, todoData) in response.todos.enumerated() {
                                let todo = createTodo(from: todoData)
                                store.addTodo(todo)
                                
                                if let reminderDate = todo.reminderDate {
                                    NotificationManager.shared.scheduleReminder(for: todo)
                                }
                                
                                if let _ = todo.dueDate {
                                    Task {
                                        await CalendarManager.shared.addTodoToCalendar(todo)
                                    }
                                }
                                
                                responseText += " \(index + 1). \(todo.title)"
                                if let dueDate = todo.dueDate {
                                    let formatter = DateFormatter()
                                    formatter.dateStyle = .short
                                    formatter.timeStyle = .short
                                    responseText += " scheduled for \(formatter.string(from: dueDate))"
                                }
                                responseText += "."
                            }
                            
                            conversationHistory.append(responseText)
                            assistantResponse = responseText
                            
                            Task {
                                await elevenLabs.speak(responseText)
                            }
                        } else {
                            let noTodoResponse = "I couldn't understand that. Could you try again? For example, say 'Remind me to call the dentist tomorrow at 2pm'."
                            conversationHistory.append(noTodoResponse)
                            
                            Task {
                                await elevenLabs.speak(noTodoResponse)
                            }
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    let errorResponse = "Sorry, I'm having trouble understanding. Please try again."
                    conversationHistory.append(errorResponse)
                    
                    Task {
                        await elevenLabs.speak(errorResponse)
                    }
                }
            }
        }
    }
    
    private func createTodo(from data: ParsedTodoResponse.ParsedTodoItem) -> TodoItem {
        let dueDate = data.dueDate?.fromISO8601()
        let reminderDate = data.reminderDate?.fromISO8601()
        
        var priority: Priority = .medium
        if let priorityStr = data.priority {
            switch priorityStr.lowercased() {
            case "urgent": priority = .urgent
            case "high": priority = .high
            case "low": priority = .low
            default: priority = .medium
            }
        }
        
        var recurrencePattern: RecurrencePattern? = nil
        if let patternStr = data.recurrencePattern {
            recurrencePattern = RecurrencePattern(rawValue: patternStr.capitalized)
        }
        
        return TodoItem(
            title: data.title,
            description: data.description ?? "",
            priority: priority,
            dueDate: dueDate,
            reminderDate: reminderDate,
            category: data.category ?? "General",
            isRecurring: data.isRecurring ?? false,
            recurrencePattern: recurrencePattern
        )
    }
}

struct UserMessage: View {
    let text: String
    
    var body: some View {
        HStack {
            Spacer()
            Text(text)
                .padding(12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(16)
        }
    }
}

struct AssistantMessage: View {
    let text: String
    var isQuestion: Bool = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(text)
                    .padding(12)
                    .background(isQuestion ? Color.orange.opacity(0.2) : Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(16)
                
                if isQuestion {
                    Text("Please respond with your answer")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.leading, 12)
                }
            }
            Spacer()
        }
    }
}

struct APIKeySettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var openAIKey: String = UserDefaults.standard.string(forKey: "OpenAIAPIKey") ?? ""
    @State private var elevenLabsKey: String = UserDefaults.standard.string(forKey: "ElevenLabsAPIKey") ?? ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("OpenAI API Key") {
                    TextField("sk-...", text: $openAIKey)
                        .textContentType(.password)
                    Text("Required for advanced natural language understanding")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Eleven Labs API Key") {
                    TextField("...", text: $elevenLabsKey)
                        .textContentType(.password)
                    Text("Required for natural voice synthesis. Falls back to system voice if not provided")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Link("Get OpenAI API Key", destination: URL(string: "https://platform.openai.com/api-keys")!)
                    Link("Get Eleven Labs API Key", destination: URL(string: "https://elevenlabs.io/app/api-keys")!)
                }
            }
            .navigationTitle("API Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        OpenAIService.shared.setAPIKey(openAIKey)
                        ElevenLabsService.shared.setAPIKey(elevenLabsKey)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    VoiceAssistantView(store: TodoStore())
}
