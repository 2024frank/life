//
//  AddEditTodoView.swift
//  knowbest
//
//  Created by Frank Kusi Appiah on 1/31/26.
//

import SwiftUI

struct AddEditTodoView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store: TodoStore
    
    let todo: TodoItem?
    
    @State private var title: String
    @State private var description: String
    @State private var priority: Priority
    @State private var category: String
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var hasReminder: Bool
    @State private var reminderDate: Date
    
    private let categories = ["General", "Work", "Personal", "Health", "Shopping", "Bills", "Family", "Other"]
    
    init(store: TodoStore, todo: TodoItem? = nil) {
        self.store = store
        self.todo = todo
        
        _title = State(initialValue: todo?.title ?? "")
        _description = State(initialValue: todo?.description ?? "")
        _priority = State(initialValue: todo?.priority ?? .medium)
        _category = State(initialValue: todo?.category ?? "General")
        _hasDueDate = State(initialValue: todo?.dueDate != nil)
        _dueDate = State(initialValue: todo?.dueDate ?? Date())
        _hasReminder = State(initialValue: todo?.reminderDate != nil)
        _reminderDate = State(initialValue: todo?.reminderDate ?? Date().addingTimeInterval(3600))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)
                        .font(.headline)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { priority in
                            HStack {
                                Image(systemName: priority.icon)
                                Text(priority.rawValue)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                }
                
                Section("Due Date") {
                    Toggle("Set due date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section("Reminder") {
                    Toggle("Set reminder", isOn: $hasReminder)
                    
                    if hasReminder {
                        DatePicker("Reminder Time", selection: $reminderDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle(todo == nil ? "New Todo" : "Edit Todo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTodo()
                    }
                    .disabled(title.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveTodo() {
        let calendar = Calendar.current
        var finalReminderDate: Date? = nil
        
        // Auto-set 30min reminder if due date exists and no explicit reminder set
        if hasDueDate && !hasReminder {
            if let reminder = calendar.date(byAdding: .minute, value: -30, to: dueDate) {
                // Only set if reminder is in the future
                if reminder > Date() {
                    finalReminderDate = reminder
                }
            }
        } else if hasReminder {
            finalReminderDate = reminderDate
        }
        
        let updatedTodo = TodoItem(
            id: todo?.id ?? UUID(),
            title: title,
            description: description,
            isCompleted: todo?.isCompleted ?? false,
            priority: priority,
            dueDate: hasDueDate ? dueDate : nil,
            reminderDate: finalReminderDate,
            category: category,
            createdAt: todo?.createdAt ?? Date()
        )
        
        if todo == nil {
            store.addTodo(updatedTodo)
            if let reminderDate = updatedTodo.reminderDate {
                NotificationManager.shared.scheduleReminder(for: updatedTodo)
            }
            
            // Add to calendar if due date exists
            if let _ = updatedTodo.dueDate {
                Task {
                    await CalendarManager.shared.addTodoToCalendar(updatedTodo)
                }
            }
        } else {
            let oldReminderDate = todo?.reminderDate
            store.updateTodo(updatedTodo)
            
            // Update notification if reminder changed
            if let reminderDate = updatedTodo.reminderDate {
                if oldReminderDate != reminderDate {
                    NotificationManager.shared.updateReminder(for: updatedTodo)
                }
            } else {
                NotificationManager.shared.cancelReminder(for: updatedTodo)
            }
        }
        
        dismiss()
    }
}

#Preview {
    AddEditTodoView(store: TodoStore())
}
