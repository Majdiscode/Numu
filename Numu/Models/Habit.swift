//
//  Habit.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//

import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID
    var createdAt: Date

    // Identity-based (not goal-based)
    var identity: String  // "I am a person who..."
    var actionName: String  // e.g., "reads", "works out", "meditates"

    // Atomic Habits - The 4 Laws
    var cue: String?  // When/where does this happen?
    var cueTime: Date?  // Specific time of day
    var attractiveness: String?  // How to make it attractive
    var easeStrategy: String?  // 2-minute version
    var reward: String?  // Immediate satisfaction

    // Habit Stacking
    var stackAfterHabit: UUID?  // "After [existing habit], I will [this habit]"

    // System metrics
    var frequency: HabitFrequency  // Daily, specific days, etc.
    var category: HabitCategory

    // Visual
    var color: String  // Hex color
    var icon: String  // SF Symbol name

    // Outcome Metrics (Optional)
    var metricConfigData: Data?  // Stores MetricConfig as JSON

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \HabitLog.habit)
    var logs: [HabitLog] = []

    @Relationship(deleteRule: .cascade, inverse: \MetricEntry.habit)
    var metricEntries: [MetricEntry] = []

    init(
        identity: String,
        actionName: String,
        frequency: HabitFrequency = .daily,
        category: HabitCategory,
        color: String = "#007AFF",
        icon: String = "star.fill"
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.identity = identity
        self.actionName = actionName
        self.frequency = frequency
        self.category = category
        self.color = color
        self.icon = icon
    }

    // Computed properties
    var currentStreak: Int {
        calculateStreak()
    }

    var longestStreak: Int {
        calculateLongestStreak()
    }

    var completionRate: Double {
        calculateCompletionRate()
    }

    // MARK: - Helper Methods

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

    private func calculateCompletionRate() -> Double {
        guard !logs.isEmpty else { return 0.0 }

        let daysSinceCreation = Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
        guard daysSinceCreation > 0 else { return 0.0 }

        return Double(logs.count) / Double(daysSinceCreation + 1)
    }

    func isCompletedToday() -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return logs.contains { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    // MARK: - Metric Tracking

    var metricConfig: MetricConfig? {
        get {
            guard let data = metricConfigData else { return nil }
            return try? JSONDecoder().decode(MetricConfig.self, from: data)
        }
        set {
            metricConfigData = try? JSONEncoder().encode(newValue)
        }
    }

    var hasMetricTracking: Bool {
        metricConfig?.isEnabled ?? false
    }

    func isMetricDue() -> Bool {
        guard let config = metricConfig, config.isEnabled else { return false }

        // If no entries yet, it's due
        guard let lastEntry = metricEntries.sorted(by: { $0.date > $1.date }).first else {
            return true
        }

        let daysSinceLastEntry = Calendar.current.dateComponents([.day], from: lastEntry.date, to: Date()).day ?? 0
        return daysSinceLastEntry >= config.trackingFrequency.daysInterval
    }

    func nextMetricDueDate() -> Date? {
        guard let config = metricConfig, config.isEnabled else { return nil }
        guard let lastEntry = metricEntries.sorted(by: { $0.date > $1.date }).first else {
            return Date()  // Due now
        }

        return Calendar.current.date(byAdding: .day, value: config.trackingFrequency.daysInterval, to: lastEntry.date)
    }

    func getMetricAnalytics() -> MetricAnalytics {
        // Calculate consistency rate over the metric tracking period
        let sortedEntries = metricEntries.sorted { $0.date < $1.date }
        guard let firstEntry = sortedEntries.first else {
            return MetricAnalytics(entries: [], consistencyRate: completionRate)
        }

        let daysSinceFirst = Calendar.current.dateComponents([.day], from: firstEntry.date, to: Date()).day ?? 0
        guard daysSinceFirst > 0 else {
            return MetricAnalytics(entries: metricEntries, consistencyRate: completionRate)
        }

        // Count logs in the metric tracking period
        let logsInPeriod = logs.filter { $0.date >= firstEntry.date }
        let consistencyRate = Double(logsInPeriod.count) / Double(daysSinceFirst + 1)

        return MetricAnalytics(entries: metricEntries, consistencyRate: consistencyRate)
    }
}

// MARK: - Supporting Types

enum HabitFrequency: String, Codable {
    case daily
    case weekdays
    case weekends
    case custom  // For specific days of the week
}

enum HabitCategory: String, Codable, CaseIterable {
    case health = "Health"
    case mind = "Mind"
    case work = "Work"
    case relationships = "Relationships"
    case creativity = "Creativity"
    case learning = "Learning"
    case environment = "Environment"

    var systemIcon: String {
        switch self {
        case .health: return "heart.fill"
        case .mind: return "brain.head.profile"
        case .work: return "briefcase.fill"
        case .relationships: return "person.2.fill"
        case .creativity: return "paintbrush.fill"
        case .learning: return "book.fill"
        case .environment: return "house.fill"
        }
    }

    var defaultColor: String {
        switch self {
        case .health: return "#FF3B30"
        case .mind: return "#5856D6"
        case .work: return "#007AFF"
        case .relationships: return "#FF2D55"
        case .creativity: return "#FF9500"
        case .learning: return "#34C759"
        case .environment: return "#00C7BE"
        }
    }
}
