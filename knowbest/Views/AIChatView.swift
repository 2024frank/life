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
    @State private var pendingTodos: [PendingTodo] = []
    @State private var showingPreview: Bool = false
    
    struct ChatMessage: Identifiable {
        let id = UUID()
        let text: String
        let isUser: Bool
        let timestamp: Date
        var isPreview: Bool = false
    }
    
    struct PendingTodo: Identifiable {
        let id = UUID()
        var title: String
        var description: String
        var dueDate: Date?
        var reminderDate: Date?
        var priority: Priority
        var category: String
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
                                    Text("Adam is thinking...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            }
                            
                            // Preview card for pending todos
                            if !pendingTodos.isEmpty {
                                todoPreviewCard
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
                    TextField("Tell Adam what you need to do...", text: $messageText, axis: .vertical)
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
            .navigationTitle("Chat with Adam")
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
                .foregroundColor(.purple)
            Text("Chat with Adam")
                .font(.title2)
                .fontWeight(.bold)
            Text("Just type what you need to do - I'll clean it up and show you a preview before adding!\n\nExamples:\n• \"rmind me call mom tmrw 3pm\"\n• \"buy milk urgent\"\n• \"meeting with john next monday at 10\"")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var todoPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("Here's what I understood:")
                    .font(.headline)
                Spacer()
            }
            
            ForEach($pendingTodos) { $todo in
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Task", text: $todo.title)
                        .font(.body.bold())
                        .textFieldStyle(.roundedBorder)
                    
                    HStack {
                        if let dueDate = todo.dueDate {
                            Label(formatDate(dueDate), systemImage: "calendar")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        Label(todo.priority.rawValue, systemImage: "flag.fill")
                            .font(.caption)
                            .foregroundColor(priorityColor(todo.priority))
                        
                        Label(todo.category, systemImage: "folder")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            HStack(spacing: 12) {
                Button {
                    pendingTodos.removeAll()
                    let response = ChatMessage(text: "No problem! What else can I help you with?", isUser: false, timestamp: Date())
                    messages.append(response)
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
                
                Button {
                    confirmTodos()
                } label: {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Add \(pendingTodos.count) Task\(pendingTodos.count > 1 ? "s" : "")")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
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
            do {
                let response: ParsedTodoResponse
                
                // Use local AI parsing
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
                let response = ParsedTodoResponse(
                    todos: todoItems,
                    questions: nil,
                    needsClarification: false,
                    response: nil
                )
                
                await MainActor.run {
                    isProcessing = false
                    
                    if response.todos.isEmpty {
                        let aiResponse = ChatMessage(
                            text: response.response ?? "I couldn't understand that. Try something like 'Call mom tomorrow at 3pm'",
                            isUser: false,
                            timestamp: Date()
                        )
                        messages.append(aiResponse)
                    } else {
                        // Convert to pending todos for preview
                        pendingTodos = response.todos.map { item in
                            PendingTodo(
                                title: cleanupTitle(item.title),
                                description: item.description ?? "",
                                dueDate: item.dueDate?.fromISO8601(),
                                reminderDate: item.reminderDate?.fromISO8601(),
                                priority: parsePriority(item.priority),
                                category: item.category ?? "General"
                            )
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    let errorMessage = ChatMessage(
                        text: "Sorry, I had trouble understanding that. Try again?",
                        isUser: false,
                        timestamp: Date()
                    )
                    messages.append(errorMessage)
                }
            }
        }
    }
    
    private func confirmTodos() {
        var addedTitles: [String] = []
        
        for pending in pendingTodos {
            let todo = TodoItem(
                title: pending.title,
                description: pending.description,
                isCompleted: false,
                priority: pending.priority,
                dueDate: pending.dueDate,
                reminderDate: pending.reminderDate,
                category: pending.category,
                createdAt: Date()
            )
            
            store.addTodo(todo)
            addedTitles.append(pending.title)
            
            // Schedule notification
            if todo.reminderDate != nil {
                NotificationManager.shared.scheduleReminder(for: todo)
            }
            
            // Add to calendar
            if todo.dueDate != nil {
                Task {
                    await CalendarManager.shared.addTodoToCalendar(todo)
                }
            }
        }
        
        // Confirmation message
        let confirmText = addedTitles.count == 1 
            ? "Done! I've added \"\(addedTitles[0])\" to your list."
            : "Done! I've added \(addedTitles.count) tasks to your list."
        
        let confirmMessage = ChatMessage(text: confirmText, isUser: false, timestamp: Date())
        messages.append(confirmMessage)
        
        pendingTodos.removeAll()
    }
    
    private func cleanupTitle(_ title: String) -> String {
        // Capitalize first letter, clean up common issues
        var cleaned = title.trimmingCharacters(in: .whitespaces)
        if let first = cleaned.first {
            cleaned = first.uppercased() + cleaned.dropFirst()
        }
        return cleaned
    }
    
    private func parsePriority(_ priority: String?) -> Priority {
        guard let p = priority?.lowercased() else { return .medium }
        switch p {
        case "urgent": return .urgent
        case "high": return .high
        case "low": return .low
        default: return .medium
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .urgent: return .red
        case .high: return .orange
        case .medium: return .blue
        case .low: return .gray
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
