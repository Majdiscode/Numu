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

    // Habit type - positive (build) or negative (break)
    private var habitTypeRaw: String = "positive"  // Stored as string for CloudKit
    var habitType: HabitType {
        get { HabitType(rawValue: habitTypeRaw) ?? .positive }
        set { habitTypeRaw = newValue.rawValue }
    }

    // Frequency control - stored as separate properties for SwiftData compatibility
    private var frequencyType: String = "daily"  // "daily", "weekdays", "weekends", "specificDays", "weeklyTarget"
    private var frequencyDays: [Int] = []  // Used for specificDays case
    private var frequencyTargetTimes: Int = 0  // Used for weeklyTarget case (e.g., 3 = "3 times per week")

    var frequency: TaskFrequency {
        get {
            // 🛡️ DEFENSIVE: Handle corrupted data from V1 schema migration
            // If accessing frequencyDays causes issues, fallback to .daily
            do {
                switch frequencyType {
                case "daily":
                    return TaskFrequency.daily
                case "weekdays":
                    return TaskFrequency.weekdays
                case "weekends":
                    return TaskFrequency.weekends
                case "specificDays":
                    // Safely access frequencyDays - this may be corrupted from V1
                    let days = frequencyDays.isEmpty ? [] : frequencyDays
                    return TaskFrequency.specificDays(days)
                case "weeklyTarget":
                    let times = frequencyTargetTimes > 0 ? frequencyTargetTimes : 1
                    return TaskFrequency.weeklyTarget(times: times)
                default:
                    print("⚠️ [HabitTask] Unknown frequencyType '\(frequencyType)', defaulting to .daily")
                    return TaskFrequency.daily
                }
            } catch {
                print("❌ [HabitTask] Error accessing frequency data: \(error)")
                print("   Falling back to .daily frequency")
                return TaskFrequency.daily
            }
        }
        set {
            switch newValue {
            case .daily:
                frequencyType = "daily"
                frequencyDays = []
                frequencyTargetTimes = 0
            case .weekdays:
                frequencyType = "weekdays"
                frequencyDays = []
                frequencyTargetTimes = 0
            case .weekends:
                frequencyType = "weekends"
                frequencyDays = []
                frequencyTargetTimes = 0
            case .specificDays(let days):
                frequencyType = "specificDays"
                frequencyDays = days
                frequencyTargetTimes = 0
            case .weeklyTarget(let times):
                frequencyType = "weeklyTarget"
                frequencyDays = []
                frequencyTargetTimes = times
            }
        }
    }

    // Atomic Habits - The 4 Laws (optional)
    var cue: String?  // When/where does this happen?
    var cueTime: Date?  // Specific time of day
    var attractiveness: String?  // How to make it attractive
    var easeStrategy: String?  // 2-minute version
    var reward: String?  // Immediate satisfaction

    // Time-based limits for negative habits (gradual reduction)
    var hasTimeLimit: Bool = false  // Whether this habit uses time limits
    var baselineLimit: Int = 0  // Starting limit in minutes (e.g., 120 min)
    var targetLimit: Int = 0  // Goal limit in minutes (e.g., 15 min or 0)
    var currentWeekLimit: Int = 0  // Current week's limit in minutes
    var weekStartDate: Date?  // When current week started
    var reductionPercentage: Double = 0.17  // Default 17% reduction per week

    // HealthKit Integration (CloudKit-compatible backing storage)
    private var healthKitMetricRaw: String?  // HealthKitMetricType raw value (for specific activity)
    private var healthKitActivityGroupRaw: String?  // ActivityGroup raw value (for group tracking)
    var healthKitThreshold: Double = 0.0  // Threshold value (accessible to HealthKitService)
    private var healthKitComparisonRaw: String = "greaterThanOrEqual"  // ComparisonType
    var healthKitAutoCompleteEnabled: Bool = false  // Toggle auto-complete (accessible to HealthKitService)

    var healthKitMetric: HealthKitMetricType? {
        get {
            guard let raw = healthKitMetricRaw else { return nil }
            return HealthKitMetricType(rawValue: raw)
        }
        set { healthKitMetricRaw = newValue?.rawValue }
    }

    var healthKitActivityGroup: ActivityGroup? {
        get {
            guard let raw = healthKitActivityGroupRaw else { return nil }
            return ActivityGroup(rawValue: raw)
        }
        set { healthKitActivityGroupRaw = newValue?.rawValue }
    }

    var healthKitComparison: ComparisonType {
        get { ComparisonType(rawValue: healthKitComparisonRaw) ?? .greaterThanOrEqual }
        set { healthKitComparisonRaw = newValue.rawValue }
    }

    var hasHealthKitMapping: Bool {
        healthKitMetric != nil || healthKitActivityGroup != nil
    }

    /// Get all metrics to check (either single metric or group's metrics)
    var healthKitMetricsToCheck: [HealthKitMetricType] {
        if let group = healthKitActivityGroup {
            return group.includedActivities
        } else if let metric = healthKitMetric {
            return [metric]
        }
        return []
    }

    // Relationship to parent System
    var system: System?

    // Relationship to completion logs
    // CloudKit requires relationships to be optional
    @Relationship(deleteRule: .cascade, inverse: \HabitTaskLog.task)
    var logs: [HabitTaskLog]?

    init(
        name: String,
        description: String? = nil,
        frequency: TaskFrequency = .daily,
        habitType: HabitType = .positive,
        baselineLimit: Int? = nil,
        targetLimit: Int? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.name = name
        self.taskDescription = description
        self.habitTypeRaw = habitType.rawValue

        // Set up time limits for negative habits
        if let baseline = baselineLimit, let target = targetLimit {
            self.hasTimeLimit = true
            self.baselineLimit = baseline
            self.targetLimit = target
            self.currentWeekLimit = baseline
            self.weekStartDate = Date()
        }

        // Set frequency via the backing properties
        switch frequency {
        case .daily:
            self.frequencyType = "daily"
            self.frequencyDays = []
            self.frequencyTargetTimes = 0
        case .weekdays:
            self.frequencyType = "weekdays"
            self.frequencyDays = []
            self.frequencyTargetTimes = 0
        case .weekends:
            self.frequencyType = "weekends"
            self.frequencyDays = []
            self.frequencyTargetTimes = 0
        case .specificDays(let days):
            self.frequencyType = "specificDays"
            self.frequencyDays = days
            self.frequencyTargetTimes = 0
        case .weeklyTarget(let times):
            self.frequencyType = "weeklyTarget"
            self.frequencyDays = []
            self.frequencyTargetTimes = times
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

    /// Check if streak is "at risk" (one day already missed, next miss breaks it)
    var isStreakAtRisk: Bool {
        // For weekly tasks, check if we missed last week
        if case .weeklyTarget(let times) = frequency {
            let calendar = Calendar.current
            guard let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: Date()) else { return false }
            let lastWeekCompletions = completionsInWeek(containing: lastWeek)
            return lastWeekCompletions < times
        }

        // For daily tasks, check if we missed yesterday (and task was due)
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return false }
        let yesterdayStart = calendar.startOfDay(for: yesterday)

        // Only at risk if task was due yesterday and we missed it
        return shouldBeCompletedOn(date: yesterdayStart) && !wasCompletedOn(date: yesterdayStart)
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
        case .weeklyTarget:
            // Weekly tasks are NOT "due" on any specific day
            // They appear in "Weekly Goals" section instead of "Today's Tasks"
            // User chooses when to complete them within the week
            return false
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

    // MARK: - Weekly Frequency Helpers

    /// Count completions in the current calendar week
    func completionsThisWeek() -> Int {
        completionsInWeek(containing: Date())
    }

    /// Count completions in a specific calendar week
    func completionsInWeek(containing date: Date) -> Int {
        guard let logs = logs else { return 0 }

        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? date

        // Safely filter logs, catching any access errors
        return logs.compactMap { log -> HabitTaskLog? in
            // Try to access the log's date - if it fails, skip this log
            do {
                _ = log.date
                return log
            } catch {
                return nil
            }
        }.filter { log in
            log.date >= weekStart && log.date < weekEnd
        }.count
    }

    /// Check if weekly target has been met for current week
    func weeklyTargetMet() -> Bool {
        guard case .weeklyTarget(let times) = frequency else { return false }
        return completionsThisWeek() >= times
    }

    /// Check if task is over weekly target (for gray-out display)
    func isOverWeeklyTarget() -> Bool {
        guard case .weeklyTarget(let times) = frequency else { return false }
        return completionsThisWeek() > times  // Only over if EXCEEDS target, not meets it
    }

    /// Get weekly progress display (e.g., "2/3 this week")
    func weeklyProgressText() -> String? {
        guard case .weeklyTarget(let times) = frequency else { return nil }
        let completions = completionsThisWeek()
        return "\(completions)/\(times) this week"
    }

    private func calculateStreak() -> Int {
        guard let logs = logs else { return 0 }

        // For weekly targets, count consecutive weeks meeting the target
        if case .weeklyTarget(let times) = frequency {
            return calculateWeeklyStreak(targetTimes: times)
        }

        // For daily/specific day frequencies, apply "Never Miss Twice" rule
        // One missed day is allowed, but two consecutive missed days breaks the streak
        let calendar = Calendar.current
        var streak = 0
        var consecutiveMisses = 0
        var currentDate = calendar.startOfDay(for: Date())

        // Go backwards from today, checking only days when task was due
        while true {
            // Only check days where this task should have been completed
            if shouldBeCompletedOn(date: currentDate) {
                if wasCompletedOn(date: currentDate) {
                    // Completed: add to streak, reset miss counter
                    streak += 1
                    consecutiveMisses = 0
                } else {
                    // Missed: increment miss counter
                    consecutiveMisses += 1

                    // Break if we've missed twice in a row
                    if consecutiveMisses >= 2 {
                        break
                    }
                    // If only one miss, allow it and continue checking
                }
            }

            // Move to previous day
            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }

            // Stop if we've gone back before the task was created
            if previousDate < calendar.startOfDay(for: createdAt) {
                break
            }

            currentDate = previousDate
        }

        return streak
    }

    private func calculateWeeklyStreak(targetTimes: Int) -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = Date()

        // Count consecutive weeks where target was met
        while true {
            let completions = completionsInWeek(containing: checkDate)

            if completions >= targetTimes {
                streak += 1
                // Move to previous week
                guard let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: checkDate) else {
                    break
                }
                checkDate = previousWeek
            } else {
                break
            }
        }

        return streak
    }

    private func calculateLongestStreak() -> Int {
        guard let logs = logs else { return 0 }

        // For weekly targets, calculate longest streak of weeks meeting target
        if case .weeklyTarget(let times) = frequency {
            return calculateLongestWeeklyStreak(targetTimes: times)
        }

        // For daily/specific day frequencies, count longest consecutive days
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

    private func calculateLongestWeeklyStreak(targetTimes: Int) -> Int {
        guard let logs = logs, !logs.isEmpty else { return 0 }

        let calendar = Calendar.current
        var longest = 0
        var current = 0
        var lastWeekStart: Date?

        // Get earliest log to start from
        let sortedLogs = logs.sorted { $0.date < $1.date }
        guard let firstLog = sortedLogs.first else { return 0 }

        var checkDate = firstLog.date

        // Iterate through each week from first log to now
        while checkDate <= Date() {
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: checkDate)?.start ?? checkDate
            let completions = completionsInWeek(containing: checkDate)

            if completions >= targetTimes {
                // Check if this week is consecutive with last successful week
                if let last = lastWeekStart,
                   let weeksBetween = calendar.dateComponents([.weekOfYear], from: last, to: weekStart).weekOfYear,
                   weeksBetween == 1 {
                    current += 1
                } else {
                    longest = max(longest, current)
                    current = 1
                }
                lastWeekStart = weekStart
            } else if current > 0 {
                longest = max(longest, current)
                current = 0
                lastWeekStart = nil
            }

            // Move to next week
            guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: checkDate) else {
                break
            }
            checkDate = nextWeek
        }

        return max(longest, current)
    }

    // MARK: - Time Limit Management (Negative Habits)

    /// Get today's total time spent on this habit
    func todayTimeSpent() -> Int {
        guard let logs = logs else { return 0 }
        let today = Calendar.current.startOfDay(for: Date())
        return logs
            .filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
            .reduce(0) { $0 + ($1.minutesSpent ?? 0) }
    }

    /// Get remaining time allowance for today
    func remainingTimeToday() -> Int {
        guard hasTimeLimit else { return 0 }
        let spent = todayTimeSpent()
        return max(0, currentWeekLimit - spent)
    }

    /// Check if user stayed under limit today
    func isUnderLimitToday() -> Bool {
        guard hasTimeLimit else { return false }
        return todayTimeSpent() <= currentWeekLimit
    }

    /// Get performance zone for given time spent
    enum PerformanceZone {
        case excellent  // Under goal (green)
        case good       // Between goal and limit (yellow)
        case overLimit  // Over limit (red)

        var color: String {
            switch self {
            case .excellent: return "green"
            case .good: return "yellow"
            case .overLimit: return "red"
            }
        }

        var displayText: String {
            switch self {
            case .excellent: return "Excellent! Under goal"
            case .good: return "Good! Under limit"
            case .overLimit: return "Over limit"
            }
        }

        var emoji: String {
            switch self {
            case .excellent: return "🎉"
            case .good: return "✅"
            case .overLimit: return "⚠️"
            }
        }
    }

    /// Calculate performance zone based on minutes spent
    func getPerformanceZone(minutesSpent: Int) -> PerformanceZone {
        guard hasTimeLimit else { return .good }

        if minutesSpent <= targetLimit {
            return .excellent  // Beat the goal!
        } else if minutesSpent <= currentWeekLimit {
            return .good  // Under weekly limit
        } else {
            return .overLimit  // Over limit
        }
    }

    /// Check if it's time to evaluate weekly progress and adjust limit
    func shouldEvaluateWeek() -> Bool {
        guard let weekStart = weekStartDate else { return false }
        let daysSinceWeekStart = Calendar.current.dateComponents([.day], from: weekStart, to: Date()).day ?? 0
        return daysSinceWeekStart >= 7
    }

    /// Evaluate this week's performance and adjust limit for next week
    func evaluateAndAdjustWeeklyLimit() {
        guard hasTimeLimit, shouldEvaluateWeek() else { return }

        let successDays = countSuccessfulDaysThisWeek()
        let needsToSucceed = 4 // Need 4 out of 7 days

        if successDays >= needsToSucceed {
            // Success! Reduce the limit for next week
            let reduction = Double(currentWeekLimit) * reductionPercentage
            let newLimit = Int(Double(currentWeekLimit) - reduction)

            // Don't go below target
            currentWeekLimit = max(newLimit, targetLimit)
        }
        // If failed, keep same limit for another week

        // Reset week start date
        weekStartDate = Date()
    }

    /// Count how many days this week the user stayed under limit
    private func countSuccessfulDaysThisWeek() -> Int {
        guard let logs = logs, let weekStart = weekStartDate else { return 0 }

        var successCount = 0
        let calendar = Calendar.current

        // Check each of the last 7 days
        for dayOffset in 0..<7 {
            guard let checkDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }

            let dayStart = calendar.startOfDay(for: checkDate)
            let timeSpent = logs
                .filter { calendar.isDate($0.date, inSameDayAs: dayStart) }
                .reduce(0) { $0 + ($1.minutesSpent ?? 0) }

            if timeSpent <= currentWeekLimit {
                successCount += 1
            }
        }

        return successCount
    }

    /// Get progress percentage for current week (0.0 to 1.0+)
    func weekProgressPercentage() -> Double {
        guard hasTimeLimit, currentWeekLimit > 0 else { return 0.0 }
        let spent = todayTimeSpent()
        return Double(spent) / Double(currentWeekLimit)
    }

    /// Format minutes to hours and minutes string
    static func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours) hr"
            } else {
                return "\(hours) hr \(mins) min"
            }
        }
    }
}

// MARK: - Habit Type

enum HabitType: String, Codable {
    case positive  // Habits to build (e.g., "Run", "Read")
    case negative  // Habits to break/avoid (e.g., "Scroll social media", "Eat junk food")

    var displayName: String {
        switch self {
        case .positive: return "Build (Do More)"
        case .negative: return "Break (Do Less)"
        }
    }

    var completionVerb: String {
        switch self {
        case .positive: return "Completed"
        case .negative: return "Avoided"
        }
    }

    var icon: String {
        switch self {
        case .positive: return "checkmark.circle.fill"
        case .negative: return "xmark.circle.fill"
        }
    }
}

// MARK: - Task Frequency

enum TaskFrequency: Codable, Equatable, Hashable {
    case daily
    case weekdays
    case weekends
    case specificDays([Int])  // Array of weekday numbers (1 = Sunday, 2 = Monday, etc.)
    case weeklyTarget(times: Int)  // Flexible weekly goal (e.g., 3 = "3 times per week")

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
        case .weeklyTarget(let times):
            return "\(times)x per week"
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
        case times
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
        case "weeklyTarget":
            let times = try container.decode(Int.self, forKey: .times)
            self = .weeklyTarget(times: times)
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
        case .weeklyTarget(let times):
            try container.encode("weeklyTarget", forKey: .type)
            try container.encode(times, forKey: .times)
        }
    }
}
