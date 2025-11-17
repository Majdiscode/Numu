stop t//
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

    /// Number of today's tasks that are completed
    var completedTodayCount: Int {
        todaysTasks.filter { $0.isCompletedToday() }.count
    }

    /// System completion rate for today (0.0 to 1.0)
    var todayCompletionRate: Double {
        guard !todaysTasks.isEmpty else { return 0.0 }
        return Double(completedTodayCount) / Double(todaysTasks.count)
    }

    /// Overall system consistency since creation
    var overallConsistency: Double {
        guard let tasks = tasks, !tasks.isEmpty else { return 0.0 }

        let calendar = Calendar.current
        var totalExpected = 0
        var totalCompleted = 0

        for task in tasks {
            // Calculate days between task creation and now
            let taskStart = calendar.startOfDay(for: task.createdAt)
            let now = calendar.startOfDay(for: Date())

            guard let daysSince = calendar.dateComponents([.day], from: taskStart, to: now).day else { continue }

            // Count how many days this task was DUE (based on frequency)
            for dayOffset in 0...daysSince {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: taskStart) else { continue }

                if task.shouldBeCompletedOn(date: date) {
                    totalExpected += 1

                    if task.wasCompletedOn(date: date) {
                        totalCompleted += 1
                    }
                }
            }
        }

        guard totalExpected > 0 else { return 0.0 }

        // Cap at 100% to prevent display issues
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
        guard let tasks = tasks else { return 0 }

        var streak = 0
        var currentDate = Calendar.current.startOfDay(for: Date())

        while true {
            // Check if all tasks due on this date were completed
            let tasksForDate = tasks.filter { task in
                task.shouldBeCompletedOn(date: currentDate)
            }

            // If there are no tasks for this date, or not all were completed, break
            guard !tasksForDate.isEmpty else {
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
                continue
            }

            let allCompleted = tasksForDate.allSatisfy { task in
                task.wasCompletedOn(date: currentDate)
            }

            if allCompleted {
                streak += 1
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
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
        case .athletics: return "figure.run"
        case .health: return "heart.fill"
        case .mind: return "brain.head.profile"
        case .work: return "briefcase.fill"
        case .relationships: return "person.2.fill"
        case .creativity: return "paintbrush.fill"
        case .learning: return "book.fill"
        case .lifestyle: return "house.fill"
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
