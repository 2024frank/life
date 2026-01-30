//
//  TodoItem.swift
//  knowbest
//
//  Created by Frank Kusi Appiah on 1/31/26.
//

import Foundation

struct TodoItem: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var description: String
    var isCompleted: Bool
    var priority: Priority
    var dueDate: Date?
    var reminderDate: Date?
    var category: String
    var createdAt: Date
    var isRecurring: Bool
    var recurrencePattern: RecurrencePattern?
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        isCompleted: Bool = false,
        priority: Priority = .medium,
        dueDate: Date? = nil,
        reminderDate: Date? = nil,
        category: String = "General",
        createdAt: Date = Date(),
        isRecurring: Bool = false,
        recurrencePattern: RecurrencePattern? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
        self.priority = priority
        self.dueDate = dueDate
        self.reminderDate = reminderDate
        self.category = category
        self.createdAt = createdAt
        self.isRecurring = isRecurring
        self.recurrencePattern = recurrencePattern
    }
}

enum RecurrencePattern: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
    
    var calendarComponent: Calendar.Component {
        switch self {
        case .daily: return .day
        case .weekly: return .weekOfYear
        case .monthly: return .month
        case .yearly: return .year
        }
    }
    
    var interval: Int {
        switch self {
        case .daily: return 1
        case .weekly: return 1
        case .monthly: return 1
        case .yearly: return 1
        }
    }
}

enum Priority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
    
    var color: String {
        switch self {
        case .low: return "blue"
        case .medium: return "orange"
        case .high: return "red"
        case .urgent: return "purple"
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "arrow.down.circle"
        case .medium: return "minus.circle"
        case .high: return "arrow.up.circle"
        case .urgent: return "exclamationmark.triangle"
        }
    }
}
