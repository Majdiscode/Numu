//
//  Task.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//
// NOTE: Class renamed to HabitTask to avoid conflict with Swift.Task

import Foundation
import SwiftData

/// A HabitTask represents a daily habit within a System
/// Example: "Run" within "Hybrid Athlete" system
@Model
final class HabitTask {
    // CloudKit requires: all properties must have default values or be optional
    var id: UUID = UUID()
    var createdAt: Date = Date()

    // Task details
    var name: String = ""  // e.g., "Run", "Read", "Meditate"
    var taskDescription: String?  // Optional description

    // Frequency control - stored as separate properties for SwiftData compatibility
    private var frequencyType: String = "daily"  // "daily", "weekdays", "weekends", "specificDays"
    private var frequencyDays: [Int] = []  // Used for specificDays case

    var frequency: TaskFrequency {
        get {
            switch frequencyType {
            case "daily":
                return TaskFrequency.daily
            case "weekdays":
                return TaskFrequency.weekdays
            case "weekends":
                return TaskFrequency.weekends
            case "specificDays":
                return TaskFrequency.specificDays(frequencyDays)
            default:
                return TaskFrequency.daily
            }
        }
        set {
            switch newValue {
            case .daily:
                frequencyType = "daily"
                frequencyDays = []
            case .weekdays:
                frequencyType = "weekdays"
                frequencyDays = []
            case .weekends:
                frequencyType = "weekends"
                frequencyDays = []
            case .specificDays(let days):
                frequencyType = "specificDays"
                frequencyDays = days
            }
        }
    }

    // Atomic Habits - The 4 Laws (optional)
    var cue: String?  // When/where does this happen?
    var cueTime: Date?  // Specific time of day
    var attractiveness: String?  // How to make it attractive
    var easeStrategy: String?  // 2-minute version
    var reward: String?  // Immediate satisfaction

    // Relationship to parent System
    var system: System?

    // Relationship to completion logs
    // CloudKit requires relationships to be optional
    @Relationship(deleteRule: .cascade, inverse: \HabitTaskLog.task)
    var logs: [HabitTaskLog]?

    init(
        name: String,
        description: String? = nil,
        frequency: TaskFrequency = .daily
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.name = name
        self.taskDescription = description

        // Set frequency via the backing properties
        switch frequency {
        case .daily:
            self.frequencyType = "daily"
            self.frequencyDays = []
        case .weekdays:
            self.frequencyType = "weekdays"
            self.frequencyDays = []
        case .weekends:
            self.frequencyType = "weekends"
            self.frequencyDays = []
        case .specificDays(let days):
            self.frequencyType = "specificDays"
            self.frequencyDays = days
        }
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

        return Double(logs?.count ?? 0) / Double(daysSinceCreation + 1)
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
        return logs?.contains { Calendar.current.isDate($0.date, inSameDayAs: targetDate) } ?? false
    }

    private func calculateStreak() -> Int {
        guard let logs = logs else { return 0 }

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
        guard let logs = logs else { return 0 }

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

    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case type
        case days
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "daily":
            self = .daily
        case "weekdays":
            self = .weekdays
        case "weekends":
            self = .weekends
        case "specificDays":
            let days = try container.decode([Int].self, forKey: .days)
            self = .specificDays(days)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown TaskFrequency type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .daily:
            try container.encode("daily", forKey: .type)
        case .weekdays:
            try container.encode("weekdays", forKey: .type)
        case .weekends:
            try container.encode("weekends", forKey: .type)
        case .specificDays(let days):
            try container.encode("specificDays", forKey: .type)
            try container.encode(days, forKey: .days)
        }
    }
}
