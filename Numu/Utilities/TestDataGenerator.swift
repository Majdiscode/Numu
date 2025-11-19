//
//  TestDataGenerator.swift
//  Numu
//
//  Debug utility for generating fake historical data for testing
//

import Foundation
import SwiftData

#if DEBUG

/// Generates realistic test data for debugging and testing features
struct TestDataGenerator {
    let modelContext: ModelContext

    /// Generate comprehensive test data showcasing all new features
    func generateMultipleTestSystems() {
        print("🧪 [TEST DATA] Generating comprehensive test systems...")

        // System 1: Perfect Hybrid Athlete (demonstrates 100% celebration)
        generatePerfectHybridAthleteSystem()

        // System 2: Never Miss Twice Demo (demonstrates streak grace days)
        generateNeverMissTwiceSystem()

        // System 3: Weekly Goals System (demonstrates weekly tracking)
        generateWeeklyGoalsSystem()

        // System 4: At-Risk Streaks (demonstrates warning states)
        generateAtRiskStreaksSystem()

        do {
            try modelContext.save()
            print("✅ [TEST DATA] Comprehensive test systems created!")
        } catch {
            print("❌ [TEST DATA] Error saving: \(error)")
        }
    }

    /// Clear all test data (systems with 🧪 emoji)
    func clearTestData() {
        print("🗑️ [TEST DATA] Clearing all test data...")

        let descriptor = FetchDescriptor<System>()

        do {
            let allSystems = try modelContext.fetch(descriptor)
            let testSystems = allSystems.filter { $0.name.contains("🧪") }

            print("   Found \(testSystems.count) test systems to delete")

            for system in testSystems {
                modelContext.delete(system)
            }

            try modelContext.save()
            modelContext.processPendingChanges()

            print("✅ [TEST DATA] Test data cleared successfully!")
        } catch {
            print("❌ [TEST DATA] Error clearing test data: \(error)")
        }
    }

    // MARK: - System 1: Perfect Hybrid Athlete
    // Demonstrates: 100% completion celebration, perfect streaks

    private func generatePerfectHybridAthleteSystem() {
        let system = System(
            name: "🧪 Perfect Athlete",
            category: .athletics,
            description: "All tasks completed today - triggers 100% celebration!",
            color: "#FF6B35",
            icon: "trophy.fill"
        )

        let calendar = Calendar.current
        if let createdDate = calendar.date(byAdding: .day, value: -14, to: Date()) {
            system.createdAt = createdDate
        }

        modelContext.insert(system)

        // Create daily tasks
        let tasks = [
            createTask(name: "Morning Run", frequency: .daily, system: system),
            createTask(name: "Strength Training", frequency: .daily, system: system),
            createTask(name: "Stretching", frequency: .daily, system: system)
        ]

        // Generate perfect completion for last 7 days + TODAY IS INCOMPLETE (so user can complete to trigger celebration)
        for task in tasks {
            generatePerfectStreak(task: task, days: 7, includeToday: false)
        }

        print("   ✅ Perfect Athlete: Complete today's tasks to see 🎉 celebration!")
    }

    // MARK: - System 2: Never Miss Twice Demo
    // Demonstrates: Grace days, at-risk streaks, recovered streaks

    private func generateNeverMissTwiceSystem() {
        let system = System(
            name: "🧪 Never Miss Twice Demo",
            category: .mind,
            description: "Demonstrates 'Never Miss Twice' streak logic",
            color: "#5856D6",
            icon: "brain.head.profile"
        )

        let calendar = Calendar.current
        if let createdDate = calendar.date(byAdding: .day, value: -14, to: Date()) {
            system.createdAt = createdDate
        }

        modelContext.insert(system)

        // Task 1: Healthy streak (no misses)
        let healthyTask = createTask(name: "📚 Read (Healthy Streak)", frequency: .daily, system: system)
        generatePerfectStreak(task: healthyTask, days: 7, includeToday: true)

        // Task 2: At-Risk streak (missed yesterday, need to complete today)
        let atRiskTask = createTask(name: "⚠️ Meditate (AT RISK!)", frequency: .daily, system: system)
        generateAtRiskStreak(task: atRiskTask)

        // Task 3: Recovered streak (missed 3 days ago, but completed yesterday)
        let recoveredTask = createTask(name: "💪 Exercise (Recovered)", frequency: .daily, system: system)
        generateRecoveredStreak(task: recoveredTask)

        // Task 4: Broken streak (missed yesterday AND day before - streak reset to 0)
        let brokenTask = createTask(name: "❌ Write (Streak Broken)", frequency: .daily, system: system)
        generateBrokenStreak(task: brokenTask)

        print("   ✅ Never Miss Twice: Check streak indicators!")
        print("      🔥 = Healthy | ⚠️ = At Risk | ❌ = Broken")
    }

    // MARK: - System 3: Weekly Goals
    // Demonstrates: Weekly task tracking, weekly progress bar, weekly celebration

    private func generateWeeklyGoalsSystem() {
        let system = System(
            name: "🧪 Weekly Goals",
            category: .athletics,
            description: "Demonstrates weekly targets and progress tracking",
            color: "#34C759",
            icon: "target"
        )

        let calendar = Calendar.current
        if let createdDate = calendar.date(byAdding: .day, value: -21, to: Date()) {
            system.createdAt = createdDate
        }

        modelContext.insert(system)

        // Weekly task 1: Almost complete (2/3) - one more to go!
        let gymTask = createTask(name: "🏋️ Gym Session", frequency: .weeklyTarget(times: 3), system: system)
        generateWeeklyProgress(task: gymTask, completedThisWeek: 2, previousWeeks: 3)

        // Weekly task 2: Halfway (1/2)
        let yogaTask = createTask(name: "🧘 Yoga Class", frequency: .weeklyTarget(times: 2), system: system)
        generateWeeklyProgress(task: yogaTask, completedThisWeek: 1, previousWeeks: 3)

        // Weekly task 3: Not started yet (0/3)
        let swimTask = createTask(name: "🏊 Swimming", frequency: .weeklyTarget(times: 3), system: system)
        generateWeeklyProgress(task: swimTask, completedThisWeek: 0, previousWeeks: 2)

        // Add one daily task to mix daily + weekly
        let waterTask = createTask(name: "💧 Hydration", frequency: .daily, system: system)
        generatePerfectStreak(task: waterTask, days: 5, includeToday: true)

        print("   ✅ Weekly Goals: Complete remaining tasks to see 🏆 celebration!")
        print("      Progress: 3/8 weekly completions (37.5%)")
    }

    // MARK: - System 4: At-Risk Streaks
    // Demonstrates: Multiple tasks at risk, urgency to complete

    private func generateAtRiskStreaksSystem() {
        let system = System(
            name: "🧪 At-Risk Streaks",
            category: .health,
            description: "Multiple tasks at risk - complete today or lose streaks!",
            color: "#FF9500",
            icon: "exclamationmark.triangle.fill"
        )

        let calendar = Calendar.current
        if let createdDate = calendar.date(byAdding: .day, value: -10, to: Date()) {
            system.createdAt = createdDate
        }

        modelContext.insert(system)

        // All tasks are at risk!
        let task1 = createTask(name: "⚠️ Morning Routine", frequency: .daily, system: system)
        generateAtRiskStreak(task: task1)

        let task2 = createTask(name: "⚠️ Healthy Eating", frequency: .daily, system: system)
        generateAtRiskStreak(task: task2)

        let task3 = createTask(name: "⚠️ Evening Walk", frequency: .daily, system: system)
        generateAtRiskStreak(task: task3)

        print("   ⚠️ At-Risk Streaks: All tasks missed yesterday!")
        print("      Complete today or streaks will break!")
    }

    // MARK: - Helper: Create Task

    private func createTask(name: String, frequency: TaskFrequency, system: System) -> HabitTask {
        let task = HabitTask(name: name, description: "Test task", frequency: frequency)
        task.system = system
        task.createdAt = system.createdAt
        modelContext.insert(task)
        return task
    }

    // MARK: - Pattern Generators

    /// Perfect streak - all days completed
    private func generatePerfectStreak(task: HabitTask, days: Int, includeToday: Bool) {
        let calendar = Calendar.current
        let now = Date()

        for dayOffset in (1...days).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            addCompletion(task: task, date: date)
        }

        if includeToday {
            addCompletion(task: task, date: now)
        }
    }

    /// At-risk streak - missed yesterday, but streak still alive
    private func generateAtRiskStreak(task: HabitTask) {
        let calendar = Calendar.current
        let now = Date()

        // Complete 5 days ago through 2 days ago (perfect)
        for dayOffset in 2...6 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            addCompletion(task: task, date: date)
        }

        // MISS yesterday (day -1) - this puts streak at risk!
        // Don't complete today yet - user needs to do it

        // Streak is now at risk: if user misses today, streak breaks
    }

    /// Recovered streak - missed one day, but completed next day (grace day used)
    private func generateRecoveredStreak(task: HabitTask) {
        let calendar = Calendar.current
        let now = Date()

        // Complete 6-4 days ago
        for dayOffset in 4...6 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            addCompletion(task: task, date: date)
        }

        // MISS 3 days ago (this used the grace day)

        // Complete 2 days ago (recovered!)
        if let date = calendar.date(byAdding: .day, value: -2, to: now) {
            addCompletion(task: task, date: date)
        }

        // Complete yesterday
        if let date = calendar.date(byAdding: .day, value: -1, to: now) {
            addCompletion(task: task, date: date)
        }

        // Complete today
        addCompletion(task: task, date: now)
    }

    /// Broken streak - missed two consecutive days (streak reset)
    private func generateBrokenStreak(task: HabitTask) {
        let calendar = Calendar.current
        let now = Date()

        // Had a good streak 6-3 days ago
        for dayOffset in 3...6 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            addCompletion(task: task, date: date)
        }

        // MISS 2 days ago AND yesterday - streak breaks!
        // Streak is now 0

        // Can complete today to start new streak
    }

    /// Weekly progress - generate completions for weekly tasks
    private func generateWeeklyProgress(task: HabitTask, completedThisWeek: Int, previousWeeks: Int) {
        let calendar = Calendar.current
        let now = Date()

        // Add completions for previous weeks (full weeks)
        guard case .weeklyTarget(let times) = task.frequency else { return }

        for weekOffset in 1...previousWeeks {
            guard let weekDate = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) else { continue }

            // Complete the full target for previous weeks
            for completion in 0..<times {
                let dayOffset = completion % 7
                if let date = calendar.date(byAdding: .day, value: dayOffset, to: weekDate) {
                    addCompletion(task: task, date: date)
                }
            }
        }

        // Add partial completions for this week
        for completion in 0..<completedThisWeek {
            let dayOffset = completion * 2 // Spread them out across the week
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) {
                addCompletion(task: task, date: date)
            }
        }
    }

    /// Add a completion log for a task on a specific date
    private func addCompletion(task: HabitTask, date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        let log = HabitTaskLog(
            notes: "Test completion",
            satisfaction: Int.random(in: 3...5),
            minutesSpent: nil
        )
        log.task = task
        log.date = startOfDay
        modelContext.insert(log)
    }
}

#endif
