//
//  TodoListView.swift
//  knowbest
//
//  Created by Frank Kusi Appiah on 1/31/26.
//

import SwiftUI

struct TodoListView: View {
    @StateObject private var store = TodoStore()
    @State private var showingAddTodo = false
    @State private var showingAIChat = false
    @State private var showingVoiceAssistant = false
    @State private var showingEveningPrompt = false
    @State private var selectedTodo: TodoItem?
    @State private var filterOption: FilterOption = .all
    @State private var searchText = ""
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case completed = "Completed"
        case upcoming = "Upcoming"
    }
    
    var filteredTodos: [TodoItem] {
        var todos = store.todos
        
        // Apply search filter
        if !searchText.isEmpty {
            todos = todos.filter { todo in
                todo.title.localizedCaseInsensitiveContains(searchText) ||
                todo.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply status filter
        switch filterOption {
        case .all:
            break
        case .active:
            todos = todos.filter { !$0.isCompleted }
        case .completed:
            todos = todos.filter { $0.isCompleted }
        case .upcoming:
            todos = store.getUpcomingTodos(within: 7)
        }
        
        // Sort by priority and due date
        return todos.sorted { first, second in
            if first.isCompleted != second.isCompleted {
                return !first.isCompleted
            }
            if let firstDate = first.dueDate, let secondDate = second.dueDate {
                return firstDate < secondDate
            }
            if first.dueDate != nil {
                return true
            }
            return priorityOrder(first.priority) > priorityOrder(second.priority)
        }
    }
    
    private func priorityOrder(_ priority: Priority) -> Int {
        switch priority {
        case .urgent: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Stats header
                    statsHeader
                    
                    // Filter and search
                    filterAndSearchSection
                    
                    // Todo list
                    if filteredTodos.isEmpty {
                        emptyStateView
                    } else {
                        todoList
                    }
                }
            }
            .navigationTitle("My Life Manager")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button {
                            showingVoiceAssistant = true
                        } label: {
                            Label("Voice Assistant", systemImage: "waveform")
                        }
                        
                        Button {
                            showingAIChat = true
                        } label: {
                            Label("Text Chat", systemImage: "sparkles")
                        }
                    } label: {
                        Image(systemName: "waveform")
                            .font(.title2)
                            .foregroundColor(.purple)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTodo = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddTodo) {
                AddEditTodoView(store: store)
            }
            .sheet(isPresented: $showingAIChat) {
                AIChatView(store: store)
            }
            .sheet(isPresented: $showingVoiceAssistant) {
                VoiceAssistantView(store: store)
            }
            .sheet(isPresented: $showingEveningPrompt) {
                EveningPromptView(store: store)
            }
            .sheet(item: $selectedTodo) { todo in
                AddEditTodoView(store: store, todo: todo)
            }
            .onAppear {
                checkEveningPrompt()
            }
        }
    }
    
    private var statsHeader: some View {
        HStack(spacing: 20) {
            StatCard(
                title: "Active",
                value: "\(store.todos.filter { !$0.isCompleted }.count)",
                color: .blue,
                icon: "checkmark.circle"
            )
            StatCard(
                title: "Completed",
                value: "\(store.todos.filter { $0.isCompleted }.count)",
                color: .green,
                icon: "checkmark.circle.fill"
            )
            StatCard(
                title: "Upcoming",
                value: "\(store.getUpcomingTodos(within: 7).count)",
                color: .orange,
                icon: "calendar"
            )
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var filterAndSearchSection: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search todos...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding()
            .background(Color.white.opacity(0.8))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(FilterOption.allCases, id: \.self) { option in
                        FilterChip(
                            title: option.rawValue,
                            isSelected: filterOption == option
                        ) {
                            filterOption = option
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var todoList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredTodos) { todo in
                    TodoRowView(todo: todo, store: store) {
                        selectedTodo = todo
                    }
                }
            }
            .padding()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checklist")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            Text("No todos yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
            Text("Tap the + button to add your first task")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.8))
            Button {
                showingAddTodo = true
            } label: {
                Label("Add Todo", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func checkEveningPrompt() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        
        // Show evening prompt between 7pm and 10pm if not shown today
        if hour >= 19 && hour < 22 {
            let lastPromptDate = UserDefaults.standard.object(forKey: "LastEveningPromptDate") as? Date
            let today = calendar.startOfDay(for: Date())
            let lastPromptDay = lastPromptDate != nil ? calendar.startOfDay(for: lastPromptDate!) : nil
            
            if lastPromptDay != today {
                showingEveningPrompt = true
                UserDefaults.standard.set(Date(), forKey: "LastEveningPromptDate")
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.white.opacity(0.8))
                .cornerRadius(20)
        }
    }
}

struct TodoRowView: View {
    let todo: TodoItem
    let store: TodoStore
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Checkbox
                Button {
                    store.toggleComplete(todo)
                    if todo.isCompleted {
                        NotificationManager.shared.cancelReminder(for: todo)
                    }
                } label: {
                    Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(todo.isCompleted ? .green : .gray)
                }
                .buttonStyle(.plain)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(todo.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .strikethrough(todo.isCompleted)
                    
                    if !todo.description.isEmpty {
                        Text(todo.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    HStack(spacing: 12) {
                        // Priority badge
                        Label(todo.priority.rawValue, systemImage: todo.priority.icon)
                            .font(.caption)
                            .foregroundColor(Color(todo.priority.color))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(todo.priority.color).opacity(0.2))
                            .cornerRadius(8)
                        
                        // Category
                        if !todo.category.isEmpty {
                            Text(todo.category)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        // Due date
                        if let dueDate = todo.dueDate {
                            Label(formatDate(dueDate), systemImage: "calendar")
                                .font(.caption)
                                .foregroundColor(dueDate < Date() && !todo.isCompleted ? .red : .secondary)
                        }
                        
                        // Reminder indicator
                        if let reminderDate = todo.reminderDate, reminderDate > Date() {
                            Label("Reminder", systemImage: "bell.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white.opacity(0.9))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                NotificationManager.shared.cancelReminder(for: todo)
                store.deleteTodo(todo)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

#Preview {
    TodoListView()
}
