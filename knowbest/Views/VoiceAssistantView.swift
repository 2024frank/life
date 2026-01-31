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
    @State private var showLoginSheet = false
    @State private var isRequestingPermission = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Check permission status first
                if voiceManager.permissionStatus == .notDetermined {
                    permissionRequestView
                } else if voiceManager.permissionStatus == .denied {
                    permissionDeniedView
                } else {
                    // Normal voice assistant UI
                    voiceAssistantContent
                }
            }
            .navigationTitle("Adam")
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
                AccountSettingsView()
            }
            .sheet(isPresented: $showLoginSheet) {
                AccountSettingsView()
            }
        }
    }
    
    // MARK: - Permission Views
    
    private var permissionRequestView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.purple)
            
            Text("Adam needs permission")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("To hear your voice commands, Adam needs access to your microphone and speech recognition.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                isRequestingPermission = true
                voiceManager.requestAuthorization { success in
                    isRequestingPermission = false
                    if success {
                        voiceManager.startListening()
                    }
                }
            } label: {
                HStack {
                    if isRequestingPermission {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "mic.fill")
                    }
                    Text("Enable Voice")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .cornerRadius(14)
            }
            .disabled(isRequestingPermission)
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    private var permissionDeniedView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "mic.slash.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)
            
            Text("Microphone Access Denied")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Adam can't hear you without microphone access. Please enable it in Settings.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Image(systemName: "gearshape.fill")
                    Text("Open Settings")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(14)
            }
            .padding(.horizontal, 40)
            
            Button("Try Again") {
                voiceManager.checkPermissions()
            }
            .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    // MARK: - Main Voice Assistant Content
    
    private var voiceAssistantContent: some View {
        return VStack(spacing: 0) {
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
        .onAppear {
            if voiceManager.permissionStatus == .authorized {
                voiceManager.startListening()
            }
        }
        .onDisappear {
            voiceManager.stopListening()
        }
        .onChange(of: voiceManager.isActivated) { activated in
            if activated {
                Task {
                    await elevenLabs.speak("Hey! What can I help you with?", emotionString: "happy")
                }
            }
        }
        .onChange(of: voiceManager.recognizedText) { text in
            if voiceManager.isActivated && !text.isEmpty {
                handleUserInput(text)
            }
        }
    }
    
    private var statusHeader: some View {
        HStack {
            Circle()
                .fill(voiceManager.isListening ? (voiceManager.isActivated ? Color.green : Color.purple) : Color.gray)
                .frame(width: 12, height: 12)
            
            Text(voiceManager.isListening ? (voiceManager.isActivated ? "Adam is listening..." : "Say 'Hey Adam'") : "Tap to start")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if !voiceManager.isListening {
                Button {
                    voiceManager.startListening()
                } label: {
                    Image(systemName: "mic.fill")
                        .foregroundColor(.purple)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private var welcomeMessage: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform")
                .font(.system(size: 50))
                .foregroundColor(.purple)
            Text("Adam is Ready")
                .font(.title2)
                .fontWeight(.bold)
            Text("Say 'Hey Adam' to start, then tell me what you need!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var waitingState: some View {
        VStack(spacing: 12) {
            Image(systemName: "mic.fill")
                .font(.system(size: 40))
                .foregroundColor(.purple)
            Text("Say 'Hey Adam'...")
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
                // Try Backend AI first (uses OpenAI on server), fallback to local AIService
                let response: ParsedTodoResponse
                if BackendService.shared.isLoggedIn {
                    // Use backend API - OpenAI key is secure on server
                    response = try await BackendService.shared.parseWithAI(text, conversationHistory: conversationHistory)
                } else {
                    // Use AIService for rule-based parsing (Siri-like fallback)
                    let parsedTodos = await AIService.shared.parseNaturalLanguage(text)
                    let todoItems = parsedTodos.map { todo in
                        ParsedTodoResponse.ParsedTodoItem(
                            title: todo.title,
                            description: todo.description.isEmpty ? nil : todo.description,
                            dueDate: todo.dueDate?.ISO8601Format(),
                            reminderDate: todo.reminderDate?.ISO8601Format(),
                            priority: todo.priority.rawValue.lowercased(),
                            category: todo.category,
                            isRecurring: nil,
                            recurrencePattern: nil
                        )
                    }
                    
                    // Check if we need clarification
                    var questions: [String]? = nil
                    let needsClarification = todoItems.isEmpty || (todoItems.first?.dueDate == nil && text.lowercased().contains("remind"))
                    
                    if needsClarification {
                        if todoItems.isEmpty {
                            questions = ["I didn't catch that. Could you say it again? For example, 'Remind me to call the dentist tomorrow at 2pm'."]
                        } else if todoItems.first?.dueDate == nil {
                            questions = ["When would you like to be reminded about this?"]
                        }
                    }
                    
                    response = ParsedTodoResponse(
                        todos: todoItems,
                        questions: questions,
                        needsClarification: needsClarification
                    )
                }
                
                await MainActor.run {
                    isProcessing = false
                    
                    // Handle questions
                    if let questions = response.questions, !questions.isEmpty {
                        currentQuestion = questions.first
                        let questionText = questions.first!
                        conversationHistory.append(questionText)
                        
                        Task {
                            // Use calm emotion for questions
                            await elevenLabs.speak(questionText, emotionString: "calm")
                        }
                    } else {
                        currentQuestion = nil
                        
                        // Process todos
                        if !response.todos.isEmpty {
                            // Use response from AI if available, otherwise generate our own
                            let responseText = response.response ?? "I've created \(response.todos.count) todo\(response.todos.count > 1 ? "s" : "") for you."
                            let emotion = response.emotion ?? "encouraging"
                            
                            for todoData in response.todos {
                                let todo = createTodo(from: todoData)
                                store.addTodo(todo)
                                
                                if todo.reminderDate != nil {
                                    NotificationManager.shared.scheduleReminder(for: todo)
                                }
                                
                                if todo.dueDate != nil {
                                    Task {
                                        await CalendarManager.shared.addTodoToCalendar(todo)
                                    }
                                }
                            }
                            
                            conversationHistory.append(responseText)
                            assistantResponse = responseText
                            
                            Task {
                                // Use emotion from AI response
                                await elevenLabs.speak(responseText, emotionString: emotion)
                            }
                        } else {
                            let noTodoResponse = "I couldn't understand that. Could you try again? For example, say 'Remind me to call the dentist tomorrow at 2pm'."
                            conversationHistory.append(noTodoResponse)
                            
                            Task {
                                // Use understanding emotion for errors
                                await elevenLabs.speak(noTodoResponse, emotionString: "understanding")
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
                        // Use calm, understanding emotion for errors
                        await elevenLabs.speak(errorResponse, emotionString: "understanding")
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

struct AccountSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var name: String = ""
    @State private var isRegistering = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var elevenLabsKey: String = UserDefaults.standard.string(forKey: "ElevenLabsAPIKey") ?? ""
    
    var isLoggedIn: Bool {
        BackendService.shared.isLoggedIn
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if isLoggedIn {
                    // Logged in state
                    Section("Account") {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Logged in")
                        }
                        
                        Button("Log Out", role: .destructive) {
                            BackendService.shared.logout()
                        }
                    }
                    
                    Section("Cloud Sync") {
                        Text("Your todos sync across devices")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    // Login/Register form - OPTIONAL
                    Section("Cloud Sync (Optional)") {
                        Text("Login is OPTIONAL - only for syncing todos across devices. Adam works perfectly without it!")
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
                            if isLoading {
                                ProgressView()
                            } else {
                                Text(isRegistering ? "Create Account" : "Login")
                            }
                        }
                        .disabled(email.isEmpty || password.isEmpty || isLoading)
                    }
                    
                    Section {
                        Button(isRegistering ? "Already have an account? Login" : "Don't have an account? Register") {
                            isRegistering.toggle()
                            errorMessage = nil
                        }
                    }
                }
                
                Section("AI Features") {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        Text("Adam works perfectly without login!")
                            .font(.subheadline)
                    }
                    Text("All AI features work locally. Login is only for cloud sync.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Voice Settings") {
                    TextField("Eleven Labs API Key (optional)", text: $elevenLabsKey)
                        .textContentType(.password)
                    Text("For natural voice. Falls back to system voice if not provided.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Link("Get Eleven Labs Key", destination: URL(string: "https://elevenlabs.io/app/api-keys")!)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        ElevenLabsService.shared.setAPIKey(elevenLabsKey)
                        dismiss()
                    }
                }
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
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// Keep old name for backwards compatibility
typealias APIKeySettingsView = AccountSettingsView

#Preview {
    VoiceAssistantView(store: TodoStore())
}
