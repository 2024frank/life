//
//  AIChatView.swift
//  knowbest
//
//  Created by Frank Kusi Appiah on 1/31/26.
//

import SwiftUI

struct AIChatView: View {
    @ObservedObject var store: TodoStore
    @Environment(\.dismiss) var dismiss
    @State private var messageText: String = ""
    @State private var messages: [ChatMessage] = []
    @State private var isProcessing: Bool = false
    
    struct ChatMessage: Identifiable {
        let id = UUID()
        let text: String
        let isUser: Bool
        let timestamp: Date
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages area
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            if messages.isEmpty {
                                welcomeMessage
                            } else {
                                ForEach(messages) { message in
                                    ChatBubble(message: message)
                                        .id(message.id)
                                }
                            }
                            
                            if isProcessing {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Processing...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _ in
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Input area
                HStack(spacing: 12) {
                    TextField("Type your tasks...", text: $messageText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)
                        .onSubmit {
                            sendMessage()
                        }
                    
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(messageText.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .blue)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty || isProcessing)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("AI Assistant")
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
    
    private var welcomeMessage: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            Text("AI Todo Assistant")
                .font(.title2)
                .fontWeight(.bold)
            Text("Tell me what you need to do, and I'll create todos for you!\n\nExamples:\n• \"Call dentist tomorrow at 2pm\"\n• \"Buy groceries today at 5pm\"\n• \"Finish project report urgent\"")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(text: text, isUser: true, timestamp: Date())
        messages.append(userMessage)
        messageText = ""
        isProcessing = true
        
        // Process with AI
        Task {
            let parsedTodos = await AIService.shared.parseNaturalLanguage(text)
            
            await MainActor.run {
                isProcessing = false
                
                if parsedTodos.isEmpty {
                    let response = ChatMessage(
                        text: "I couldn't parse any todos from that. Try something like 'Call dentist tomorrow at 2pm' or 'Buy groceries today'",
                        isUser: false,
                        timestamp: Date()
                    )
                    messages.append(response)
                } else {
                    var responseText = "I've created \(parsedTodos.count) todo(s) for you:\n\n"
                    for (index, todo) in parsedTodos.enumerated() {
                        responseText += "\(index + 1). \(todo.title)"
                        if let dueDate = todo.dueDate {
                            let formatter = DateFormatter()
                            formatter.dateStyle = .short
                            formatter.timeStyle = .short
                            responseText += " - \(formatter.string(from: dueDate))"
                        }
                        responseText += "\n"
                    }
                    
                    let response = ChatMessage(text: responseText, isUser: false, timestamp: Date())
                    messages.append(response)
                    
                    // Add todos to store
                    for parsedTodo in parsedTodos {
                        let todo = TodoItem(
                            title: parsedTodo.title,
                            description: parsedTodo.description,
                            isCompleted: false,
                            priority: parsedTodo.priority,
                            dueDate: parsedTodo.dueDate,
                            reminderDate: parsedTodo.reminderDate,
                            category: parsedTodo.category,
                            createdAt: Date()
                        )
                        
                        store.addTodo(todo)
                        
                        // Schedule notification
                        if let reminderDate = todo.reminderDate {
                            NotificationManager.shared.scheduleReminder(for: todo)
                        }
                        
                        // Add to calendar if due date exists
                        if let _ = todo.dueDate {
                            Task {
                                await CalendarManager.shared.addTodoToCalendar(todo)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ChatBubble: View {
    let message: AIChatView.ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(12)
                    .background(message.isUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(16)
                
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser {
                Spacer()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    AIChatView(store: TodoStore())
}
