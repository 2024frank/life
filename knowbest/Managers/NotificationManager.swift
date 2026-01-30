//
//  NotificationManager.swift
//  knowbest
//
//  Created by Frank Kusi Appiah on 1/31/26.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    init() {
        requestAuthorization()
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleReminder(for todo: TodoItem) {
        guard let reminderDate = todo.reminderDate,
              reminderDate > Date() else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Reminder: \(todo.title)"
        content.body = todo.description.isEmpty ? "Don't forget to complete this task!" : todo.description
        content.sound = .default
        content.badge = 1
        content.userInfo = ["todoId": todo.id.uuidString]
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: todo.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled for \(reminderDate)")
            }
        }
    }
    
    func cancelReminder(for todo: TodoItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [todo.id.uuidString])
    }
    
    func updateReminder(for todo: TodoItem) {
        cancelReminder(for: todo)
        scheduleReminder(for: todo)
    }
    
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
