//
//  CalendarManager.swift
//  knowbest
//
//  Created by Frank Kusi Appiah on 1/31/26.
//

import Foundation
import EventKit

class CalendarManager {
    static let shared = CalendarManager()
    private let eventStore = EKEventStore()
    
    private init() {}
    
    func requestAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            return await eventStore.requestFullAccessToEvents()
        } else {
            return await eventStore.requestAccess(to: .event)
        }
    }
    
    func addTodoToCalendar(_ todo: TodoItem) async -> Bool {
        guard await requestAccess() else {
            print("Calendar access denied")
            return false
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = todo.title
        event.notes = todo.description
        event.startDate = todo.dueDate ?? Date()
        event.endDate = Calendar.current.date(byAdding: .minute, value: 30, to: event.startDate) ?? event.startDate
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
            return true
        } catch {
            print("Error saving event to calendar: \(error.localizedDescription)")
            return false
        }
    }
    
    func removeTodoFromCalendar(_ todo: TodoItem) async {
        // Note: This would require storing event identifiers, which is a more complex implementation
        // For now, we'll just log that removal would happen
        print("Would remove calendar event for todo: \(todo.title)")
    }
}
