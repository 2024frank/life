//
//  BackendService.swift
//  knowbest
//
//  Created by Frank Kusi Appiah on 1/31/26.
//

import Foundation

class BackendService {
    static let shared = BackendService()
    
    // Your Render backend URL
    private let baseURL = "https://knowbest-backend.onrender.com"
    
    private var authToken: String? {
        get { UserDefaults.standard.string(forKey: "BackendAuthToken") }
        set { UserDefaults.standard.set(newValue, forKey: "BackendAuthToken") }
    }
    
    private var userEmail: String? {
        get { UserDefaults.standard.string(forKey: "BackendUserEmail") }
        set { UserDefaults.standard.set(newValue, forKey: "BackendUserEmail") }
    }
    
    private init() {}
    
    var isLoggedIn: Bool {
        return authToken != nil && !authToken!.isEmpty
    }
    
    // MARK: - Auth
    
    func register(email: String, password: String, name: String) async throws -> Bool {
        let url = URL(string: "\(baseURL)/api/auth/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email": email, "password": password, "name": name]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }
        
        if httpResponse.statusCode == 201 || httpResponse.statusCode == 200 {
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            self.authToken = authResponse.token
            self.userEmail = email
            return true
        } else {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw BackendError.serverError(errorResponse?.error ?? "Registration failed")
        }
    }
    
    func login(email: String, password: String) async throws -> Bool {
        let url = URL(string: "\(baseURL)/api/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            self.authToken = authResponse.token
            self.userEmail = email
            return true
        } else {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw BackendError.serverError(errorResponse?.error ?? "Login failed")
        }
    }
    
    func logout() {
        authToken = nil
        userEmail = nil
    }
    
    // MARK: - AI Parse (uses backend OpenAI)
    
    func parseWithAI(_ text: String, conversationHistory: [String] = []) async throws -> ParsedTodoResponse {
        guard let token = authToken else {
            throw BackendError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/api/ai/parse")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "text": text,
            "conversationHistory": conversationHistory
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let parsed = try JSONDecoder().decode(BackendParsedResponse.self, from: data)
            // Convert to ParsedTodoResponse
            return ParsedTodoResponse(
                todos: parsed.todos.map { item in
                    ParsedTodoResponse.ParsedTodoItem(
                        title: item.title,
                        description: item.description,
                        dueDate: item.dueDate,
                        reminderDate: item.reminderDate,
                        priority: item.priority,
                        category: item.category,
                        isRecurring: item.isRecurring,
                        recurrencePattern: item.recurrencePattern
                    )
                },
                questions: parsed.questions,
                needsClarification: parsed.needsClarification,
                response: parsed.response
            )
        } else if httpResponse.statusCode == 401 {
            throw BackendError.notAuthenticated
        } else {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw BackendError.serverError(errorResponse?.error ?? "AI parsing failed")
        }
    }
    
    // MARK: - Todos Sync
    
    func syncTodos(_ todos: [TodoItem]) async throws -> [TodoItem] {
        guard let token = authToken else {
            throw BackendError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/api/todos/sync")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let syncData = todos.map { todo -> [String: Any?] in
            return [
                "id": todo.id.uuidString,
                "title": todo.title,
                "description": todo.description,
                "isCompleted": todo.isCompleted,
                "priority": todo.priority.rawValue,
                "dueDate": todo.dueDate?.ISO8601Format(),
                "reminderDate": todo.reminderDate?.ISO8601Format(),
                "category": todo.category,
                "createdAt": todo.createdAt.ISO8601Format(),
                "isRecurring": todo.isRecurring,
                "recurrencePattern": todo.recurrencePattern?.rawValue
            ]
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: ["todos": syncData])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw BackendError.syncFailed
        }
        
        // Parse response - server returns merged todos
        let syncResponse = try JSONDecoder().decode(SyncResponse.self, from: data)
        return syncResponse.todos.compactMap { item -> TodoItem? in
            guard let id = UUID(uuidString: item.id) else { return nil }
            return TodoItem(
                id: id,
                title: item.title,
                description: item.description ?? "",
                isCompleted: item.isCompleted,
                priority: Priority(rawValue: item.priority) ?? .medium,
                dueDate: item.dueDate?.fromISO8601(),
                reminderDate: item.reminderDate?.fromISO8601(),
                category: item.category,
                createdAt: item.createdAt?.fromISO8601() ?? Date(),
                isRecurring: item.isRecurring ?? false,
                recurrencePattern: item.recurrencePattern.flatMap { RecurrencePattern(rawValue: $0) }
            )
        }
    }
}

// MARK: - Response Models

struct AuthResponse: Codable {
    let message: String?
    let token: String
    let user: AuthUser?
    
    struct AuthUser: Codable {
        let id: String
        let email: String
    }
}

struct ErrorResponse: Codable {
    let error: String
}

struct BackendParsedResponse: Codable {
    let todos: [BackendParsedTodo]
    let questions: [String]?
    let needsClarification: Bool
    let response: String?
    
    struct BackendParsedTodo: Codable {
        let title: String
        let description: String?
        let dueDate: String?
        let reminderDate: String?
        let priority: String?
        let category: String?
        let isRecurring: Bool?
        let recurrencePattern: String?
    }
}

struct SyncResponse: Codable {
    let message: String
    let todos: [SyncTodoItem]
    
    struct SyncTodoItem: Codable {
        let id: String
        let title: String
        let description: String?
        let isCompleted: Bool
        let priority: String
        let dueDate: String?
        let reminderDate: String?
        let category: String
        let createdAt: String?
        let isRecurring: Bool?
        let recurrencePattern: String?
    }
}

enum BackendError: LocalizedError {
    case invalidResponse
    case notAuthenticated
    case serverError(String)
    case syncFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .notAuthenticated:
            return "Please log in to continue"
        case .serverError(let message):
            return message
        case .syncFailed:
            return "Failed to sync todos"
        }
    }
}
