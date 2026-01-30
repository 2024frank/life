//
//  TodoWidget.swift
//  knowbestWidget
//
//  Created by Frank Kusi Appiah on 1/31/26.
//

import WidgetKit
import SwiftUI

struct TodoWidget: Widget {
    let kind: String = "TodoWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodoProvider()) { entry in
            TodoWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Todo Reminders")
        .description("View your upcoming todos and reminders")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct TodoProvider: TimelineProvider {
    private let storageKey = "SavedTodos"
    private let appGroupIdentifier = "group.Personal.knowbest"
    
    private var userDefaults: UserDefaults {
        if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            return sharedDefaults
        }
        return UserDefaults.standard
    }
    
    func placeholder(in context: Context) -> TodoEntry {
        TodoEntry(
            date: Date(),
            todos: [
                TodoItem(title: "Sample Todo 1", priority: .high, dueDate: Date()),
                TodoItem(title: "Sample Todo 2", priority: .medium, dueDate: Date().addingTimeInterval(3600))
            ]
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TodoEntry) -> Void) {
        let todos = loadTodos()
        let upcomingTodos = getUpcomingTodos(from: todos, within: 7)
        let entry = TodoEntry(date: Date(), todos: Array(upcomingTodos.prefix(5)))
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TodoEntry>) -> Void) {
        let todos = loadTodos()
        let upcomingTodos = getUpcomingTodos(from: todos, within: 7)
        let entry = TodoEntry(date: Date(), todos: Array(upcomingTodos.prefix(5)))
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadTodos() -> [TodoItem] {
        guard let data = userDefaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) else {
            return []
        }
        return decoded
    }
    
    private func getUpcomingTodos(from todos: [TodoItem], within days: Int) -> [TodoItem] {
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return todos.filter { todo in
            guard let dueDate = todo.dueDate else { return false }
            return !todo.isCompleted && dueDate <= futureDate && dueDate >= Date()
        }.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
    }
}

struct TodoEntry: TimelineEntry {
    let date: Date
    let todos: [TodoItem]
}

struct TodoWidgetEntryView: View {
    var entry: TodoProvider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checklist")
                    .font(.headline)
                    .foregroundColor(.blue)
                Text("Upcoming Todos")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if entry.todos.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    Text("All caught up!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ForEach(entry.todos.prefix(3)) { todo in
                    TodoWidgetRow(todo: todo)
                }
                
                if entry.todos.count > 3 {
                    Text("+ \(entry.todos.count - 3) more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
    }
}

struct TodoWidgetRow: View {
    let todo: TodoItem
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(todo.priority.color))
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(todo.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                if let dueDate = todo.dueDate {
                    Text(formatDate(dueDate))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.timeStyle = .short
            return "Today \(formatter.string(from: date))"
        } else if Calendar.current.isDateInTomorrow(date) {
            formatter.timeStyle = .short
            return "Tomorrow \(formatter.string(from: date))"
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}

#Preview(as: .systemSmall) {
    TodoWidget()
} timeline: {
    TodoEntry(
        date: Date(),
        todos: [
            TodoItem(title: "Buy groceries", priority: .high, dueDate: Date()),
            TodoItem(title: "Call dentist", priority: .medium, dueDate: Date().addingTimeInterval(3600))
        ]
    )
}
