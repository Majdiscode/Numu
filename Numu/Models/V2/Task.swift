//
//  Task.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//

import Foundation
import SwiftData

/// A Task represents a daily habit within a System
/// Example: "Run" within "Hybrid Athlete" system
@Model
final class Task {
    var id: UUID
    var createdAt: Date

    // Task details
    var name: String  // e.g., "Run", "Read", "Meditate"
    var taskDescription: String?  // Optional description

    // Frequency control
    var frequency: TaskFrequency

    // Atomic Habits - The 4 Laws (optional)
    var cue: String?  // When/where does this happen?
    var cueTime: Date?  // Specific time of day
    var attractiveness: String?  // How to make it attractive
    var easeStrategy: String?  // 2-minute version
    var reward: String?  // Immediate satisfaction

    // Relationship to parent System
    var system: System?

    // Relationship to completion logs
    @Relationship(deleteRule: .cascade, inverse: \TaskLog.task)
    var logs: [TaskLog] = []

    init(
        name: String,
        description: String? = nil,
        frequency: TaskFrequency = .daily
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.name = name
        self.taskDescription = description
        self.frequency = frequency
    }

    // MARK: - Computed Properties

    /// Current streak for this specific task
    var currentStreak: Int {
        calculateStreak()
    }

    /// Longest streak for this task
    var longestStreak: Int {
        calculateLongestStreak()
    }

    /// Overall completion rate since creation
    var completionRate: Double {
        let daysSinceCreation = Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
        guard daysSinceCreation > 0 else { return 0.0 }

        return Double(logs.count) / Double(daysSinceCreation + 1)
    }

    // MARK: - Helper Methods

    /// Check if this task is due today based on frequency
    func isDueToday() -> Bool {
        shouldBeCompletedOn(date: Date())
    }

    /// Check if this task should be completed on a specific date
    func shouldBeCompletedOn(date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)

        switch frequency {
        case .daily:
            return true
        case .weekdays:
            return weekday >= 2 && weekday <= 6 // Monday to Friday
        case .weekends:
            return weekday == 1 || weekday == 7 // Saturday or Sunday
        case .specificDays(let days):
            return days.contains(weekday)
        }
    }

    /// Check if task was completed today
    func isCompletedToday() -> Bool {
        wasCompletedOn(date: Date())
    }

    /// Check if task was completed on a specific date
    func wasCompletedOn(date: Date) -> Bool {
        let targetDate = Calendar.current.startOfDay(for: date)
        return logs.contains { Calendar.current.isDate($0.date, inSameDayAs: targetDate) }
    }

    private func calculateStreak() -> Int {
        let sortedLogs = logs.sorted { $0.date > $1.date }
        var streak = 0
        var currentDate = Calendar.current.startOfDay(for: Date())

        for log in sortedLogs {
            let logDate = Calendar.current.startOfDay(for: log.date)
            if logDate == currentDate {
                streak += 1
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }

        return streak
    }

    private func calculateLongestStreak() -> Int {
        let sortedLogs = logs.sorted { $0.date < $1.date }
        var longest = 0
        var current = 0
        var lastDate: Date?

        for log in sortedLogs {
            let logDate = Calendar.current.startOfDay(for: log.date)

            if let last = lastDate {
                let daysBetween = Calendar.current.dateComponents([.day], from: last, to: logDate).day ?? 0
                if daysBetween == 1 {
                    current += 1
                } else {
                    longest = max(longest, current)
                    current = 1
                }
            } else {
                current = 1
            }

            lastDate = logDate
        }

        return max(longest, current)
    }
}

// MARK: - Task Frequency

enum TaskFrequency: Codable, Equatable, Hashable {
    case daily
    case weekdays
    case weekends
    case specificDays([Int])  // Array of weekday numbers (1 = Sunday, 2 = Monday, etc.)

    var displayText: String {
        switch self {
        case .daily:
            return "Every day"
        case .weekdays:
            return "Weekdays"
        case .weekends:
            return "Weekends"
        case .specificDays(let days):
            let dayNames = days.map { weekdayName(for: $0) }
            return dayNames.joined(separator: ", ")
        }
    }

    private func weekdayName(for weekday: Int) -> String {
        let formatter = DateFormatter()
        let names = formatter.shortWeekdaySymbols!
        let index = (weekday - 1) % 7
        return names[index]
    }
}
