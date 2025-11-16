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

    /// Generate a complete test system with historical task completion data
    func generateTestSystem(daysOfHistory: Int = 30) {
        print("🧪 [TEST DATA] Generating test system with \(daysOfHistory) days of history...")

        // Create test system
        let testSystem = System(
            name: "🧪 Test System",
            category: .athletics,
            description: "Generated test data for analytics testing",
            color: "#FF6B35",
            icon: "testtube.2"
        )

        // Set creation date to N days ago for realistic history
        let calendar = Calendar.current
        if let createdDate = calendar.date(byAdding: .day, value: -daysOfHistory, to: Date()) {
            testSystem.createdAt = createdDate
        }

        modelContext.insert(testSystem)

        // Create test tasks with different frequencies
        let tasks = [
            createTestTask(name: "🧪 Daily Task", frequency: .daily, system: testSystem),
            createTestTask(name: "🧪 Weekday Task", frequency: .weekdays, system: testSystem),
            createTestTask(name: "🧪 Weekend Task", frequency: .weekends, system: testSystem)
        ]

        // Generate historical task logs
        for task in tasks {
            generateTaskLogs(for: task, daysOfHistory: daysOfHistory)
        }

        // Create a test performance test
        let test = PerformanceTest(
            name: "🧪 Test Metric",
            unit: "reps",
            goalDirection: .higher,
            trackingFrequency: .weekly,
            description: "Generated test performance metric"
        )
        test.system = testSystem
        modelContext.insert(test)

        // Generate test entries showing improvement over time
        generateTestEntries(for: test, weeks: daysOfHistory / 7)

        // Save everything
        do {
            try modelContext.save()
            print("✅ [TEST DATA] Test system created successfully!")
            print("   - System: \(testSystem.name)")
            print("   - Tasks: \(tasks.count)")
            print("   - History: \(daysOfHistory) days")
        } catch {
            print("❌ [TEST DATA] Error saving: \(error)")
        }
    }

    /// Generate multiple test systems with varying completion rates
    func generateMultipleTestSystems() {
        print("🧪 [TEST DATA] Generating multiple test systems...")

        // High performer (80-100% completion)
        generateTestSystemWithPattern(
            name: "🧪 High Performer",
            category: .health,
            completionRate: 0.9,
            daysOfHistory: 30
        )

        // Average performer (50-70% completion)
        generateTestSystemWithPattern(
            name: "🧪 Average Performer",
            category: .mind,
            completionRate: 0.6,
            daysOfHistory: 30
        )

        // Improving trend (starts low, ends high)
        generateImprovingSystem()

        do {
            try modelContext.save()
            print("✅ [TEST DATA] Multiple test systems created!")
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
                // Manually delete tasks and logs
                if let tasks = system.tasks {
                    for task in tasks {
                        if let logs = task.logs {
                            for log in logs {
                                modelContext.delete(log)
                            }
                        }
                        modelContext.delete(task)
                    }
                }

                // Manually delete tests and entries
                if let tests = system.tests {
                    for test in tests {
                        if let entries = test.entries {
                            for entry in entries {
                                modelContext.delete(entry)
                            }
                        }
                        modelContext.delete(test)
                    }
                }

                modelContext.delete(system)
            }

            try modelContext.save()
            print("✅ [TEST DATA] Test data cleared successfully!")
        } catch {
            print("❌ [TEST DATA] Error clearing test data: \(error)")
        }
    }

    // MARK: - Private Helpers

    private func createTestTask(name: String, frequency: TaskFrequency, system: System) -> HabitTask {
        let task = HabitTask(
            name: name,
            description: "Generated for testing",
            frequency: frequency
        )
        task.system = system
        modelContext.insert(task)
        return task
    }

    private func generateTaskLogs(for task: HabitTask, daysOfHistory: Int) {
        let calendar = Calendar.current
        let now = Date()

        // Generate logs with 70% completion rate (realistic)
        for dayOffset in (0..<daysOfHistory).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: date)

            // Check if task should be completed on this day
            if task.shouldBeCompletedOn(date: startOfDay) {
                // 70% chance of completion
                if Double.random(in: 0...1) < 0.7 {
                    let log = HabitTaskLog(
                        notes: "Test log entry",
                        satisfaction: Int.random(in: 3...5),
                        minutesSpent: nil
                    )
                    log.task = task
                    log.date = startOfDay
                    modelContext.insert(log)
                }
            }
        }
    }

    private func generateTestSystemWithPattern(name: String, category: SystemCategory, completionRate: Double, daysOfHistory: Int) {
        let system = System(
            name: name,
            category: category,
            description: "Test system with \(Int(completionRate * 100))% completion rate"
        )

        if let createdDate = Calendar.current.date(byAdding: .day, value: -daysOfHistory, to: Date()) {
            system.createdAt = createdDate
        }

        modelContext.insert(system)

        let task = createTestTask(name: "🧪 Task", frequency: .daily, system: system)

        // Generate logs with specified completion rate
        let calendar = Calendar.current
        let now = Date()

        for dayOffset in (0..<daysOfHistory).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: date)

            if Double.random(in: 0...1) < completionRate {
                let log = HabitTaskLog()
                log.task = task
                log.date = startOfDay
                modelContext.insert(log)
            }
        }
    }

    private func generateImprovingSystem() {
        let system = System(
            name: "🧪 Improving Trend",
            category: .learning,
            description: "Test system showing improvement over time"
        )

        if let createdDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) {
            system.createdAt = createdDate
        }

        modelContext.insert(system)

        let task = createTestTask(name: "🧪 Improving Task", frequency: .daily, system: system)

        // Start at 30% completion, gradually improve to 90%
        let calendar = Calendar.current
        let now = Date()

        for dayOffset in (0..<30).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: date)

            // Completion rate improves from 0.3 to 0.9 over 30 days
            let progress = Double(30 - dayOffset) / 30.0
            let completionRate = 0.3 + (progress * 0.6) // 30% to 90%

            if Double.random(in: 0...1) < completionRate {
                let log = HabitTaskLog()
                log.task = task
                log.date = startOfDay
                modelContext.insert(log)
            }
        }
    }

    private func generateTestEntries(for test: PerformanceTest, weeks: Int) {
        let calendar = Calendar.current
        let now = Date()

        var baseValue = 10.0

        for weekOffset in (0..<weeks).reversed() {
            guard let date = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) else { continue }

            // Show improvement: gradually increase value
            let improvement = Double(weeks - weekOffset) * 1.5
            let value = baseValue + improvement + Double.random(in: -2...2) // Add some variance

            let entry = PerformanceTestEntry(
                value: value,
                notes: "Test entry",
                conditions: "Good"
            )
            entry.test = test
            entry.date = date
            modelContext.insert(entry)
        }
    }
}

#endif
