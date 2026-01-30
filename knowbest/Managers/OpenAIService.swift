//
//  OpenAIService.swift
//  knowbest
//
//  Created by Frank Kusi Appiah on 1/31/26.
//

import Foundation

struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        
        struct Message: Codable {
            let content: String
        }
    }
}

struct ParsedTodoResponse: Codable {
    let todos: [ParsedTodoItem]
    let questions: [String]?
    let needsClarification: Bool
    let response: String?  // Natural language response for voice
    let emotion: String?   // happy, encouraging, calm, excited, understanding, neutral
    
    struct ParsedTodoItem: Codable {
        let title: String
        let description: String?
        let dueDate: String?
        let reminderDate: String?
        let priority: String?
        let category: String?
        let isRecurring: Bool?
        let recurrencePattern: String?
    }
    
    init(todos: [ParsedTodoItem], questions: [String]?, needsClarification: Bool, response: String? = nil, emotion: String? = nil) {
        self.todos = todos
        self.questions = questions
        self.needsClarification = needsClarification
        self.response = response
        self.emotion = emotion
    }
}

class OpenAIService {
    static let shared = OpenAIService()
    
    // Set your OpenAI API key here or via environment variable
    private var apiKey: String {
        // Check UserDefaults first, then environment variable
        if let key = UserDefaults.standard.string(forKey: "OpenAIAPIKey"), !key.isEmpty {
            return key
        }
        return ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    }
    
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    private init() {}
    
    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "OpenAIAPIKey")
    }
    
    func parseUserInput(_ text: String, conversationHistory: [String] = []) async throws -> ParsedTodoResponse {
        guard !apiKey.isEmpty else {
            // Fallback to local parsing if no API key
            return fallbackParse(text)
        }
        
        var messages: [[String: String]] = [
            [
                "role": "system",
                "content": """
                You are a helpful todo assistant. Parse user input and extract todos.
                Return a JSON object with this structure:
                {
                    "todos": [
                        {
                            "title": "Task title",
                            "description": "Optional description",
                            "dueDate": "ISO8601 date string or null",
                            "reminderDate": "ISO8601 date string (30min before dueDate) or null",
                            "priority": "low|medium|high|urgent or null",
                            "category": "Work|Personal|Health|Shopping|Bills|Family|General or null",
                            "isRecurring": true/false or null,
                            "recurrencePattern": "daily|weekly|monthly|yearly or null"
                        }
                    ],
                    "questions": ["Question 1", "Question 2"] or null,
                    "needsClarification": true/false
                }
                
                Ask questions if:
                - Task might be recurring (ask "Should this be a recurring task?")
                - Time is ambiguous (ask "What time should I remind you?")
                - Priority is unclear (ask "Is this urgent or can it wait?")
                
                Extract dates from natural language:
                - "tomorrow at 2pm" -> dueDate: tomorrow 14:00
                - "today at 5pm" -> dueDate: today 17:00
                - "next Monday" -> dueDate: next Monday
                - "in 2 hours" -> dueDate: now + 2 hours
                
                Always set reminderDate to 30 minutes before dueDate if dueDate exists.
                """
            ]
        ]
        
        // Add conversation history
        for (index, message) in conversationHistory.enumerated() {
            if index % 2 == 0 {
                messages.append(["role": "user", "content": message])
            } else {
                messages.append(["role": "assistant", "content": message])
            }
        }
        
        messages.append(["role": "user", "content": text])
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "temperature": 0.7,
            "response_format": ["type": "json_object"]
        ]
        
        guard let url = URL(string: baseURL) else {
            throw NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "OpenAIService", code: -2, userInfo: [NSLocalizedDescriptionKey: "API request failed"])
        }
        
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        let content = openAIResponse.choices.first?.message.content ?? "{}"
        
        guard let jsonData = content.data(using: .utf8) else {
            return fallbackParse(text)
        }
        
        let parsedResponse = try JSONDecoder().decode(ParsedTodoResponse.self, from: jsonData)
        return parsedResponse
    }
    
    private func fallbackParse(_ text: String) -> ParsedTodoResponse {
        // Use synchronous parsing for immediate response (Siri-like behavior)
        let lowerText = text.lowercased()
        var questions: [String]? = nil
        var needsClarification = false
        
        // Check if we can parse date/time
        let hasTime = lowerText.contains("at") && (lowerText.contains("am") || lowerText.contains("pm") || lowerText.contains(":") || lowerText.contains("hour") || lowerText.contains("minute"))
        let hasDate = lowerText.contains("today") || lowerText.contains("tomorrow") || lowerText.contains("monday") || lowerText.contains("tuesday") || lowerText.contains("wednesday") || lowerText.contains("thursday") || lowerText.contains("friday") || lowerText.contains("saturday") || lowerText.contains("sunday") || lowerText.contains("in ")
        
        // If user says "remind" but no time/date, ask for clarification
        if !hasTime && !hasDate && (lowerText.contains("remind") || lowerText.contains("todo") || lowerText.contains("task")) {
            questions = ["When would you like to be reminded about this?"]
            needsClarification = true
        }
        
        // Extract title - remove common command phrases
        var title = text
        title = title.replacingOccurrences(of: "remind me to", with: "", options: .caseInsensitive)
        title = title.replacingOccurrences(of: "remind me", with: "", options: .caseInsensitive)
        title = title.replacingOccurrences(of: "can you", with: "", options: .caseInsensitive)
        title = title.replacingOccurrences(of: "please", with: "", options: .caseInsensitive)
        title = title.replacingOccurrences(of: "hey assistant", with: "", options: .caseInsensitive)
        title = title.trimmingCharacters(in: .whitespaces)
        
        // Extract priority
        var priority: String? = nil
        if lowerText.contains("urgent") || lowerText.contains("asap") {
            priority = "urgent"
        } else if lowerText.contains("important") || lowerText.contains("high priority") {
            priority = "high"
        } else if lowerText.contains("low priority") {
            priority = "low"
        }
        
        // Extract category
        var category: String? = nil
        if lowerText.contains("work") || lowerText.contains("meeting") || lowerText.contains("office") {
            category = "Work"
        } else if lowerText.contains("shopping") || lowerText.contains("buy") || lowerText.contains("grocery") {
            category = "Shopping"
        } else if lowerText.contains("health") || lowerText.contains("doctor") || lowerText.contains("gym") {
            category = "Health"
        } else if lowerText.contains("family") {
            category = "Family"
        } else if lowerText.contains("bill") || lowerText.contains("pay") {
            category = "Bills"
        }
        
        // Try to parse date/time using simple patterns
        var dueDate: String? = nil
        var reminderDate: String? = nil
        
        // Pattern: "tomorrow at 2pm" or "today at 5pm"
        if let match = try? NSRegularExpression(pattern: #"(today|tomorrow)\s+at\s+(\d{1,2}):?(\d{2})?\s*(am|pm)"#, options: .caseInsensitive).firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            // Date/time found - will be parsed by AIService in async call
            // For now, just mark that we have it
        }
        
        let responseText = needsClarification ? questions?.first : "I'll add that to your todos."
        
        return ParsedTodoResponse(
            todos: [ParsedTodoResponse.ParsedTodoItem(
                title: title.isEmpty ? text : title,
                description: nil,
                dueDate: dueDate,
                reminderDate: reminderDate,
                priority: priority,
                category: category,
                isRecurring: nil,
                recurrencePattern: nil
            )],
            questions: questions,
            needsClarification: needsClarification,
            response: responseText
        )
    }
}

extension Date {
    func ISO8601Format() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}

extension String {
    func fromISO8601() -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: self) {
            return date
        }
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: self)
    }
}
