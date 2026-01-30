//
//  TodoStore.swift
//  knowbest
//
//  Created by Frank Kusi Appiah on 1/31/26.
//

import Foundation
import Combine
import WidgetKit

class TodoStore: ObservableObject {
    @Published var todos: [TodoItem] = []
    
    private let storageKey = "SavedTodos"
    private let appGroupIdentifier = "group.Personal.knowbest"
    
    private var userDefaults: UserDefaults {
        if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            return sharedDefaults
        }
        return UserDefaults.standard
    }
    
    init() {
        loadTodos()
    }
    
    func addTodo(_ todo: TodoItem) {
        todos.append(todo)
        saveTodos()
    }
    
    func updateTodo(_ todo: TodoItem) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index] = todo
            saveTodos()
        }
    }
    
    func deleteTodo(_ todo: TodoItem) {
        todos.removeAll { $0.id == todo.id }
        saveTodos()
    }
    
    func toggleComplete(_ todo: TodoItem) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index].isCompleted.toggle()
            saveTodos()
        }
    }
    
    func getTodosForCategory(_ category: String) -> [TodoItem] {
        todos.filter { $0.category == category }
    }
    
    func getUpcomingTodos(within days: Int = 7) -> [TodoItem] {
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return todos.filter { todo in
            guard let dueDate = todo.dueDate else { return false }
            return !todo.isCompleted && dueDate <= futureDate && dueDate >= Date()
        }.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
    }
    
    func getTodosWithReminders() -> [TodoItem] {
        todos.filter { todo in
            guard let reminderDate = todo.reminderDate else { return false }
            return !todo.isCompleted && reminderDate > Date()
        }
    }
    
    private func saveTodos() {
        if let encoded = try? JSONEncoder().encode(todos) {
            userDefaults.set(encoded, forKey: storageKey)
            // Also update widget timeline
            WidgetCenter.shared.reloadTimelines(ofKind: "TodoWidget")
        }
    }
    
    private func loadTodos() {
        if let data = userDefaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            todos = decoded
        }
    }
}
