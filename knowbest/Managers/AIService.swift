//
//  AIService.swift
//  knowbest
//
//  Created by Frank Kusi Appiah on 1/31/26.
//

import Foundation

struct ParsedTodo {
    let title: String
    let description: String
    let dueDate: Date?
    let reminderDate: Date?
    let priority: Priority
    let category: String
}

class AIService {
    static let shared = AIService()
    
    private init() {}
    
    func parseNaturalLanguage(_ text: String) async -> [ParsedTodo] {
        // For now, we'll use a simple rule-based parser
        // In production, you'd integrate with OpenAI API or similar
        
        var todos: [ParsedTodo] = []
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ",;\n"))
        
        for sentence in sentences {
            let trimmed = sentence.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            
            let parsed = parseSentence(trimmed)
            todos.append(parsed)
        }
        
        return todos
    }
    
    private func parseSentence(_ text: String) -> ParsedTodo {
        var title = text
        var description = ""
        var dueDate: Date? = nil
        var reminderDate: Date? = nil
        var priority: Priority = .medium
        var category = "General"
        
        // Extract priority keywords
        let lowerText = text.lowercased()
        if lowerText.contains("urgent") || lowerText.contains("asap") || lowerText.contains("immediately") {
            priority = .urgent
        } else if lowerText.contains("important") || lowerText.contains("high priority") {
            priority = .high
        } else if lowerText.contains("low priority") || lowerText.contains("whenever") {
            priority = .low
        }
        
        // Extract category keywords
        if lowerText.contains("work") || lowerText.contains("meeting") || lowerText.contains("office") {
            category = "Work"
        } else if lowerText.contains("health") || lowerText.contains("doctor") || lowerText.contains("gym") {
            category = "Health"
        } else if lowerText.contains("shopping") || lowerText.contains("buy") || lowerText.contains("grocery") {
            category = "Shopping"
        } else if lowerText.contains("family") {
            category = "Family"
        } else if lowerText.contains("bill") || lowerText.contains("pay") {
            category = "Bills"
        }
        
        // Extract dates and times
        let calendar = Calendar.current
        let datePatterns = [
            (#"today\s+at\s+(\d{1,2}):?(\d{2})?\s*(am|pm)"#, isToday: true),
            (#"tomorrow\s+at\s+(\d{1,2}):?(\d{2})?\s*(am|pm)"#, isToday: false),
            (#"(\d{1,2})/(\d{1,2})(?:\s+at\s+(\d{1,2}):?(\d{2})?\s*(am|pm))?"#, isToday: nil),
        ]
        
        for (pattern, isToday) in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
                
                var targetDate = Date()
                if let isToday = isToday {
                    if !isToday {
                        targetDate = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                    }
                }
                
                // Extract time components
                if match.numberOfRanges > 3 {
                    // Has time component
                    dueDate = extractDateTime(from: text, match: match, baseDate: targetDate)
                } else {
                    // Just date
                    var components = calendar.dateComponents([.year, .month, .day], from: targetDate)
                    components.hour = 9
                    components.minute = 0
                    dueDate = calendar.date(from: components)
                }
                
                // Set reminder 30 minutes before
                if let due = dueDate {
                    reminderDate = calendar.date(byAdding: .minute, value: -30, to: due)
                    if let reminder = reminderDate, reminder < Date() {
                        reminderDate = nil
                    }
                }
                
                // Remove date/time from title
                let dateRange = Range(match.range, in: text)!
                title = text.replacingCharacters(in: dateRange, with: "")
                    .trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: "at", with: "", options: .caseInsensitive)
                    .trimmingCharacters(in: .whitespaces)
                break
            }
        }
        
        // If no date found, check for relative times like "in 2 hours"
        if dueDate == nil {
            if let relativeDate = parseRelativeTime(text) {
                dueDate = relativeDate
                reminderDate = calendar.date(byAdding: .minute, value: -30, to: relativeDate)
            }
        }
        
        return ParsedTodo(
            title: title.isEmpty ? text : title,
            description: description,
            dueDate: dueDate,
            reminderDate: reminderDate,
            priority: priority,
            category: category
        )
    }
    
    private func extractDateTime(from text: String, match: NSTextCheckingResult, baseDate: Date) -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
        
        if match.numberOfRanges > 1, let hourRange = Range(match.range(at: 1), in: text) {
            if let hour = Int(text[hourRange]) {
                components.hour = hour
            }
        }
        
        if match.numberOfRanges > 2, let minuteRange = Range(match.range(at: 2), in: text) {
            if let minute = Int(text[minuteRange]) {
                components.minute = minute
            } else {
                components.minute = 0
            }
        }
        
        if match.numberOfRanges > 3, let amPmRange = Range(match.range(at: 3), in: text) {
            let amPm = String(text[amPmRange]).lowercased()
            if amPm == "pm" && components.hour ?? 0 < 12 {
                components.hour = (components.hour ?? 0) + 12
            } else if amPm == "am" && components.hour == 12 {
                components.hour = 0
            }
        }
        
        return calendar.date(from: components)
    }
    
    private func parseRelativeTime(_ text: String) -> Date? {
        let calendar = Calendar.current
        let lowerText = text.lowercased()
        
        // Patterns like "in 2 hours", "in 30 minutes"
        if let regex = try? NSRegularExpression(pattern: #"in\s+(\d+)\s+(hour|minute|day)s?"#, options: .caseInsensitive),
           let match = regex.firstMatch(in: lowerText, range: NSRange(lowerText.startIndex..., in: lowerText)) {
            
            if match.numberOfRanges > 1 {
                let amountRange = Range(match.range(at: 1), in: lowerText)!
                if let amount = Int(lowerText[amountRange]) {
                    let unitRange = Range(match.range(at: 2), in: lowerText)!
                    let unit = String(lowerText[unitRange])
                    
                    var dateComponent: Calendar.Component = .hour
                    if unit.contains("minute") {
                        dateComponent = .minute
                    } else if unit.contains("day") {
                        dateComponent = .day
                    }
                    
                    return calendar.date(byAdding: dateComponent, value: amount, to: Date())
                }
            }
        }
        
        return nil
    }
}
