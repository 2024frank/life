//
//  EveningPromptView.swift
//  knowbest
//
//  Created by Frank Kusi Appiah on 1/31/26.
//

import SwiftUI

struct EveningPromptView: View {
    @ObservedObject var store: TodoStore
    @Environment(\.dismiss) var dismiss
    @State private var todoText: String = ""
    @State private var todos: [QuickTodo] = []
    
    struct QuickTodo: Identifiable {
        let id = UUID()
        var title: String
        var time: Date
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.purple)
                    Text("Plan Your Tomorrow")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("What do you want to accomplish tomorrow?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Input area
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add tasks for tomorrow:")
                        .font(.headline)
                    
                    TextField("e.g., Call dentist at 2pm, Buy groceries at 10am", text: $todoText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                        .onSubmit {
                            addQuickTodos()
                        }
                    
                    Button {
                        addQuickTodos()
                    } label: {
                        Label("Add Tasks", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(todoText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                
                // Preview of added todos
                if !todos.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tomorrow's Plan:")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(todos) { todo in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(todo.title)
                                                .font(.body)
                                            Text(formatTime(todo.time))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Button {
                                            todos.removeAll { $0.id == todo.id }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Skip")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                    
                    Button {
                        saveTodos()
                    } label: {
                        Text("Save & Done")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(todos.isEmpty ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(todos.isEmpty)
                }
                .padding()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveTodos()
                    }
                    .disabled(todos.isEmpty)
                }
            }
        }
    }
    
    private func addQuickTodos() {
        let text = todoText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        
        // Parse the text to extract todos with times
        let parsedTodos = parseTodosFromText(text)
        todos.append(contentsOf: parsedTodos)
        todoText = ""
    }
    
    private func parseTodosFromText(_ text: String) -> [QuickTodo] {
        // Simple parsing: look for patterns like "task at time" or "task at Xpm"
        var results: [QuickTodo] = []
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ",;\n"))
        
        for sentence in sentences {
            let trimmed = sentence.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            
            // Try to extract time
            let timePatterns = [
                (pattern: #"at\s+(\d{1,2})\s*(am|pm)"#, format: "h a"),
                (pattern: #"at\s+(\d{1,2}):(\d{2})\s*(am|pm)"#, format: "h:mm a"),
                (pattern: #"at\s+(\d{1,2})\s*(am|pm)"#, format: "h a"),
            ]
            
            var foundTime: Date?
            var taskTitle = trimmed
            
            for pattern in timePatterns {
                if let regex = try? NSRegularExpression(pattern: pattern.pattern, options: .caseInsensitive),
                   let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) {
                    
                    let timeString = String(trimmed[Range(match.range, in: trimmed)!])
                    foundTime = parseTimeString(timeString)
                    
                    // Remove time from title
                    taskTitle = trimmed.replacingOccurrences(of: timeString, with: "", options: .caseInsensitive)
                        .trimmingCharacters(in: .whitespaces)
                        .replacingOccurrences(of: "at", with: "", options: .caseInsensitive)
                        .trimmingCharacters(in: .whitespaces)
                    break
                }
            }
            
            // Default to 9am if no time specified
            let taskTime = foundTime ?? defaultTimeForTomorrow()
            
            results.append(QuickTodo(title: taskTitle.isEmpty ? trimmed : taskTitle, time: taskTime))
        }
        
        return results
    }
    
    private func parseTimeString(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.defaultDate = defaultTimeForTomorrow()
        
        // Try different formats
        let formats = ["h a", "h:mm a", "HH:mm"]
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: timeString.replacingOccurrences(of: "at ", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespaces)) {
                return date
            }
        }
        
        return nil
    }
    
    private func defaultTimeForTomorrow() -> Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        components.hour = 9
        components.minute = 0
        return calendar.date(from: components) ?? tomorrow
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func saveTodos() {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        
        for quickTodo in todos {
            var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: quickTodo.time)
            components.hour = timeComponents.hour
            components.minute = timeComponents.minute
            
            let dueDate = calendar.date(from: components) ?? quickTodo.time
            let reminderDate = calendar.date(byAdding: .minute, value: -30, to: dueDate) ?? dueDate
            
            let todo = TodoItem(
                title: quickTodo.title,
                description: "",
                isCompleted: false,
                priority: .medium,
                dueDate: dueDate,
                reminderDate: reminderDate > Date() ? reminderDate : nil,
                category: "Personal",
                createdAt: Date()
            )
            
            store.addTodo(todo)
            if let reminderDate = todo.reminderDate {
                NotificationManager.shared.scheduleReminder(for: todo)
            }
        }
        
        dismiss()
    }
}

#Preview {
    EveningPromptView(store: TodoStore())
}
