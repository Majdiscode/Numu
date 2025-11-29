//
//  System.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//

import Foundation
import SwiftData

/// A System represents an overarching identity-based goal
/// Example: "Hybrid Athlete", "Knowledge Worker", "Creative"
@Model
final class System {
    // CloudKit requires: all properties must have default values or be optional
    var id: UUID = UUID()
    var createdAt: Date = Date()

    // Identity-based (Atomic Habits principle)
    var name: String = ""  // e.g., "Hybrid Athlete", "Consistent Reader"
    var systemDescription: String?  // Optional description of the system

    // Category for organization
    var category: SystemCategory = SystemCategory.athletics

    // Visual customization
    var color: String = "#FF6B35"  // Hex color
    var icon: String = "figure.run"  // SF Symbol name

    // Performance optimization: cache expensive calculations
    private var cachedConsistency: Double?
    private var consistencyCacheDate: Date?
    private let consistencyCacheDuration: TimeInterval = 300 // 5 minutes

    // Relationships (using cascade delete for data integrity)
    // CloudKit requires relationships to be optional
    @Relationship(deleteRule: .cascade, inverse: \HabitTask.system)
    var tasks: [HabitTask]?

    @Relationship(deleteRule: .cascade, inverse: \PerformanceTest.system)
    var tests: [PerformanceTest]?

    init(
        name: String,
        category: SystemCategory,
        description: String? = nil,
        color: String? = nil,
        icon: String? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.name = name
        self.systemDescription = description
        self.category = category
        self.color = color ?? category.defaultColor
        self.icon = icon ?? category.systemIcon
    }

    // MARK: - Computed Properties

    /// Tasks that should be completed today based on their frequency
    var todaysTasks: [HabitTask] {
        tasks?.filter { $0.isDueToday() } ?? []
    }

    /// Weekly frequency tasks (not tied to specific days)
    var weeklyTasks: [HabitTask] {
        guard let tasks = tasks else { return [] }
        return tasks.filter { task in
            if case .weeklyTarget = task.frequency {
                return true
            }
            return false
        }
    }

    /// Number of today's tasks that are completed
    var completedTodayCount: Int {
        todaysTasks.filter { $0.isCompletedToday() }.count
    }

    /// System completion rate for today (0.0 to 1.0)
    var todayCompletionRate: Double {
        guard !todaysTasks.isEmpty else { return 0.0 }
        return Double(completedTodayCount) / Double(todaysTasks.count)
    }

    /// Number of weekly tasks that have met their target this week
    var completedWeeklyCount: Int {
        guard let tasks = tasks else { return 0 }
        return tasks.filter { task in
            if case .weeklyTarget = task.frequency {
                return task.weeklyTargetMet()
            }
            return false
        }.count
    }

    /// Weekly goals completion rate (0.0 to 1.0)
    var weeklyCompletionRate: Double {
        let weekly = weeklyTasks
        guard !weekly.isEmpty else { return 0.0 }
        return Double(completedWeeklyCount) / Double(weekly.count)
    }

    /// Total completions for all weekly tasks this week (capped at target)
    var totalWeeklyCompletions: Int {
        weeklyTasks.reduce(0) { total, task in
            if case .weeklyTarget(let times) = task.frequency {
                // Cap completions at target to prevent over-completion from inflating progress
                return total + min(task.completionsThisWeek(), times)
            }
            return total
        }
    }

    /// Total target for all weekly tasks this week
    var totalWeeklyTarget: Int {
        weeklyTasks.reduce(0) { total, task in
            if case .weeklyTarget(let times) = task.frequency {
                return total + times
            }
            return total
        }
    }

    /// Overall system consistency since creation (CACHED for performance)
    var overallConsistency: Double {
        // Check cache validity
        if let cached = cachedConsistency,
           let cacheDate = consistencyCacheDate,
           Date().timeIntervalSince(cacheDate) < consistencyCacheDuration {
            return cached
        }

        // Calculate and cache
        let result = calculateOverallConsistency()
        cachedConsistency = result
        consistencyCacheDate = Date()
        return result
    }

    /// Force recalculation of consistency (call after data changes)
    func invalidateConsistencyCache() {
        cachedConsistency = nil
        consistencyCacheDate = nil
    }

    /// Optimized consistency calculation - queries logs once instead of per-day
    private func calculateOverallConsistency() -> Double {
        guard let tasks = tasks, !tasks.isEmpty else { return 0.0 }

        let calendar = Calendar.current
        var totalExpected = 0
        var totalCompleted = 0

        // Collect all logs once for efficiency
        var allLogDates: Set<String> = []
        for task in tasks {
            if let logs = task.logs {
                for log in logs {
                    let dateKey = "\(task.id.uuidString)_\(calendar.startOfDay(for: log.date).timeIntervalSince1970)"
                    allLogDates.insert(dateKey)
                }
            }
        }

        // Now calculate expected vs completed
        for task in tasks {
            let taskStart = calendar.startOfDay(for: task.createdAt)
            let now = calendar.startOfDay(for: Date())

            guard let daysSince = calendar.dateComponents([.day], from: taskStart, to: now).day else { continue }

            // Limit lookback to prevent excessive computation (max 1 year)
            let daysToCheck = min(daysSince, 365)

            for dayOffset in 0...daysToCheck {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: taskStart) else { continue }

                if task.shouldBeCompletedOn(date: date) {
                    totalExpected += 1

                    // Check if completed using pre-fetched log dates
                    let dateKey = "\(task.id.uuidString)_\(calendar.startOfDay(for: date).timeIntervalSince1970)"
                    if allLogDates.contains(dateKey) {
                        totalCompleted += 1
                    }
                }
            }
        }

        guard totalExpected > 0 else { return 0.0 }

        return min(1.0, Double(totalCompleted) / Double(totalExpected))
    }

    /// Current streak (consecutive days where all tasks were completed)
    var currentStreak: Int {
        calculateStreak()
    }

    /// Tests that are due for measurement
    var dueTests: [PerformanceTest] {
        tests?.filter { $0.isDue() } ?? []
    }

    // MARK: - Helper Methods

    private func calculateStreak() -> Int {
        guard let tasks = tasks, !tasks.isEmpty else { return 0 }

        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        // Safety: Don't go back further than system creation date or 365 days
        let earliestDate = calendar.date(byAdding: .day, value: -365, to: Date()) ?? createdAt
        let systemStart = calendar.startOfDay(for: createdAt)
        let stopDate = max(earliestDate, systemStart)

        var daysChecked = 0
        let maxDaysToCheck = 365

        while currentDate >= stopDate && daysChecked < maxDaysToCheck {
            daysChecked += 1

            // Check if all tasks due on this date were completed
            let tasksForDate = tasks.filter { task in
                // Only check tasks that existed on this date
                guard calendar.startOfDay(for: task.createdAt) <= currentDate else {
                    return false
                }
                return task.shouldBeCompletedOn(date: currentDate)
            }

            // If no tasks for this date, skip to previous day
            guard !tasksForDate.isEmpty else {
                guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                    break
                }
                currentDate = previousDate
                continue
            }

            // Check if all tasks were completed
            let allCompleted = tasksForDate.allSatisfy { task in
                task.wasCompletedOn(date: currentDate)
            }

            if allCompleted {
                streak += 1
                guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                    break
                }
                currentDate = previousDate
            } else {
                break
            }
        }

        return streak
    }
}

// MARK: - System Category

enum SystemCategory: String, Codable, CaseIterable {
    case athletics = "Athletics"
    case health = "Health"
    case mind = "Mind"
    case work = "Work"
    case relationships = "Relationships"
    case creativity = "Creativity"
    case learning = "Learning"
    case lifestyle = "Lifestyle"

    var systemIcon: String {
        switch self {
        case .athletics: return "flame.fill"           // Alternative: "figure.run", "bolt.fill", "dumbbell.fill"
        case .health: return "heart.circle.fill"       // Alternative: "heart.fill", "cross.circle.fill", "leaf.fill"
        case .mind: return "brain.fill"                // Alternative: "brain.head.profile", "lightbulb.fill", "sparkles"
        case .work: return "square.stack.3d.up.fill"   // Alternative: "briefcase.fill", "chart.line.uptrend.xyaxis", "target"
        case .relationships: return "person.2.fill"     // Alternative: "heart.fill", "hands.sparkles.fill", "bubble.left.and.bubble.right.fill"
        case .creativity: return "wand.and.stars"      // Alternative: "paintbrush.fill", "camera.fill", "pencil.and.scribble"
        case .learning: return "graduationcap.fill"    // Alternative: "book.fill", "text.book.closed.fill", "brain.fill"
        case .lifestyle: return "sparkles"             // Alternative: "house.fill", "sun.horizon.fill", "leaf.fill"
        }
    }

    var defaultColor: String {
        switch self {
        case .athletics: return "#FF6B35"
        case .health: return "#FF3B30"
        case .mind: return "#5856D6"
        case .work: return "#007AFF"
        case .relationships: return "#FF2D55"
        case .creativity: return "#FF9500"
        case .learning: return "#34C759"
        case .lifestyle: return "#00C7BE"
        }
    }
}
