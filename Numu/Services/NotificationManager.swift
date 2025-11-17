//
//  NotificationManager.swift
//  Numu
//
//  Created by Claude Code
//

import Foundation
import UserNotifications
import SwiftData

@Observable
class NotificationManager {
    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()

    // MARK: - Initialization

    init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    /// Check current notification authorization status
    func checkAuthorizationStatus() {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    /// Request notification permissions from user
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])

            DispatchQueue.main.async {
                self.authorizationStatus = granted ? .authorized : .denied
            }

            return granted
        } catch {
            print("❌ Error requesting notification authorization: \(error)")
            return false
        }
    }

    // MARK: - Task Reminders

    /// Schedule a reminder for a task based on its cue time
    func scheduleTaskReminder(for task: HabitTask) {
        // Only schedule if task has a cue time
        guard let cueTime = task.cueTime else {
            print("⏭️ Skipping reminder for '\(task.name)' - no cue time set")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = task.habitType == .positive ? "Time to Build" : "Stay on Track"
        content.body = task.name
        content.sound = .default
        content.categoryIdentifier = "TASK_REMINDER"
        content.userInfo = [
            "taskId": task.id.uuidString,
            "taskName": task.name,
            "type": "task_reminder"
        ]

        // Add system name if available
        if let systemName = task.system?.name {
            content.subtitle = systemName
        }

        // Create date components from cue time
        let components = Calendar.current.dateComponents([.hour, .minute], from: cueTime)

        // Schedule based on task frequency
        switch task.frequency {
        case .daily:
            // Every day at cue time
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            scheduleNotification(identifier: "task-\(task.id)", content: content, trigger: trigger)

        case .weekdays:
            // Monday through Friday (2-6)
            for weekday in 2...6 {
                var dayComponents = components
                dayComponents.weekday = weekday

                let trigger = UNCalendarNotificationTrigger(dateMatching: dayComponents, repeats: true)
                scheduleNotification(identifier: "task-\(task.id)-\(weekday)", content: content, trigger: trigger)
            }

        case .weekends:
            // Saturday and Sunday (1, 7)
            for weekday in [1, 7] {
                var dayComponents = components
                dayComponents.weekday = weekday

                let trigger = UNCalendarNotificationTrigger(dateMatching: dayComponents, repeats: true)
                scheduleNotification(identifier: "task-\(task.id)-\(weekday)", content: content, trigger: trigger)
            }

        case .specificDays(let days):
            // On specific days of the week
            for day in days {
                var dayComponents = components
                dayComponents.weekday = day

                let trigger = UNCalendarNotificationTrigger(dateMatching: dayComponents, repeats: true)
                scheduleNotification(identifier: "task-\(task.id)-\(day)", content: content, trigger: trigger)
            }
        }

        print("✅ Scheduled reminder for '\(task.name)' at \(cueTime.formatted(date: .omitted, time: .shortened))")
    }

    /// Cancel a task reminder
    func cancelTaskReminder(for task: HabitTask) {
        let identifiers = getPendingIdentifiers(for: task)
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("🗑️ Cancelled \(identifiers.count) reminder(s) for '\(task.name)'")
    }

    private func getPendingIdentifiers(for task: HabitTask) -> [String] {
        var identifiers = ["task-\(task.id)"]

        // Add weekday-specific identifiers
        switch task.frequency {
        case .weekdays:
            for weekday in 2...6 {
                identifiers.append("task-\(task.id)-\(weekday)")
            }
        case .weekends:
            for weekday in [1, 7] {
                identifiers.append("task-\(task.id)-\(weekday)")
            }
        case .specificDays(let days):
            for day in days {
                identifiers.append("task-\(task.id)-\(day)")
            }
        case .daily:
            break // Already have the base identifier
        }

        return identifiers
    }

    // MARK: - Test Reminders

    /// Schedule a reminder for a performance test
    func scheduleTestReminder(for test: PerformanceTest) {
        guard let nextDue = test.nextDueDate() else {
            print("⏭️ Skipping test reminder for '\(test.name)' - no due date")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Time to Test"
        content.body = test.name
        content.sound = .default
        content.categoryIdentifier = "TEST_REMINDER"
        content.userInfo = [
            "testId": test.id.uuidString,
            "testName": test.name,
            "type": "test_reminder"
        ]

        // Add system name if available
        if let systemName = test.system?.name {
            content.subtitle = systemName
        }

        // Schedule for 9 AM on due date
        var components = Calendar.current.dateComponents([.year, .month, .day], from: nextDue)
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        scheduleNotification(identifier: "test-\(test.id)", content: content, trigger: trigger)

        print("✅ Scheduled test reminder for '\(test.name)' on \(nextDue.formatted(date: .abbreviated, time: .omitted))")
    }

    /// Cancel a test reminder
    func cancelTestReminder(for test: PerformanceTest) {
        center.removePendingNotificationRequests(withIdentifiers: ["test-\(test.id)"])
        print("🗑️ Cancelled reminder for test '\(test.name)'")
    }

    // MARK: - End of Day Summary

    /// Schedule daily end-of-day summary notification
    func scheduleEndOfDaySummary(at hour: Int = 21) {
        let content = UNMutableNotificationContent()
        content.title = "How did your systems go today?"
        content.body = "Review your progress and complete any remaining tasks"
        content.sound = .default
        content.categoryIdentifier = "EOD_SUMMARY"
        content.userInfo = ["type": "eod_summary"]

        var components = DateComponents()
        components.hour = hour
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        scheduleNotification(identifier: "eod-summary", content: content, trigger: trigger)

        print("✅ Scheduled end-of-day summary at \(hour):00")
    }

    /// Cancel end-of-day summary
    func cancelEndOfDaySummary() {
        center.removePendingNotificationRequests(withIdentifiers: ["eod-summary"])
        print("🗑️ Cancelled end-of-day summary")
    }

    // MARK: - Streak Alerts

    /// Schedule a streak protection alert for a task
    func scheduleStreakAlert(for task: HabitTask, at hour: Int = 20) {
        guard task.currentStreak >= 3 else {
            print("⏭️ Skipping streak alert for '\(task.name)' - streak too short (\(task.currentStreak) days)")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "🔥 Don't Break Your Streak!"
        content.body = "\(task.name) - \(task.currentStreak) day streak"
        content.sound = .default
        content.categoryIdentifier = "STREAK_ALERT"
        content.userInfo = [
            "taskId": task.id.uuidString,
            "taskName": task.name,
            "streak": task.currentStreak,
            "type": "streak_alert"
        ]

        var components = DateComponents()
        components.hour = hour
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        scheduleNotification(identifier: "streak-\(task.id)", content: content, trigger: trigger)

        print("✅ Scheduled streak alert for '\(task.name)' (\(task.currentStreak) days) at \(hour):00")
    }

    /// Cancel streak alert for a task
    func cancelStreakAlert(for task: HabitTask) {
        center.removePendingNotificationRequests(withIdentifiers: ["streak-\(task.id)"])
        print("🗑️ Cancelled streak alert for '\(task.name)'")
    }

    // MARK: - Helper Methods

    private func scheduleNotification(identifier: String, content: UNNotificationContent, trigger: UNNotificationTrigger) {
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification \(identifier): \(error)")
            }
        }
    }

    /// Remove all pending notifications
    func removeAllNotifications() {
        center.removeAllPendingNotificationRequests()
        print("🗑️ Removed all pending notifications")
    }

    /// Get count of pending notifications
    func getPendingNotificationCount() async -> Int {
        let requests = await center.pendingNotificationRequests()
        return requests.count
    }

    /// Debug: Print all pending notifications
    func printPendingNotifications() async {
        let requests = await center.pendingNotificationRequests()
        print("📬 Pending Notifications (\(requests.count)):")
        for request in requests {
            print("  - \(request.identifier): \(request.content.title)")
        }
    }
}
