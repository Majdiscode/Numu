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

        // Hybrid Athlete (high performer)
        generateHybridAthleteSystem()

        // Knowledge Worker (average performer)
        generateKnowledgeWorkerSystem()

        // Healthy Lifestyle (improving trend)
        generateHealthyLifestyleSystem()

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

            // Simply delete the systems - cascade delete will handle all related data
            // (tasks, logs, tests, entries) automatically
            for system in testSystems {
                modelContext.delete(system)
            }

            try modelContext.save()

            // Process pending changes to ensure cleanup is complete
            modelContext.processPendingChanges()

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

        // Add performance test with realistic improvement
        let test = PerformanceTest(
            name: "🧪 Performance",
            unit: "reps",
            goalDirection: .higher,
            trackingFrequency: .weekly,
            description: "Test metric"
        )
        test.system = system
        modelContext.insert(test)

        // Generate test entries
        generateTestEntries(for: test, weeks: max(1, daysOfHistory / 7))
    }

    // MARK: - Realistic System Generators

    private func generateHybridAthleteSystem() {
        let system = System(
            name: "🧪 Hybrid Athlete",
            category: .athletics,
            description: "Building strength and endurance",
            color: "#FF6B35",
            icon: "figure.run"
        )

        if let createdDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) {
            system.createdAt = createdDate
        }

        modelContext.insert(system)

        // Create realistic tasks
        let tasks = [
            createTestTask(name: "Morning Run", frequency: .daily, system: system),
            createTestTask(name: "Strength Training", frequency: .specificDays([2, 4, 6]), system: system), // Mon, Wed, Fri
            createTestTask(name: "Stretch & Mobility", frequency: .daily, system: system)
        ]

        // Generate high completion rate (85-95%)
        generateTaskLogsWithRate(tasks: tasks, completionRate: 0.9, daysOfHistory: 30)

        // Add performance tests
        createMileTimeTest(system: system, improving: true)
        createPushupsTest(system: system, improving: true)
    }

    private func generateKnowledgeWorkerSystem() {
        let system = System(
            name: "🧪 Knowledge Worker",
            category: .learning,
            description: "Continuous learning and deep work",
            color: "#34C759",
            icon: "book.fill"
        )

        if let createdDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) {
            system.createdAt = createdDate
        }

        modelContext.insert(system)

        // Create realistic tasks
        let tasks = [
            createTestTask(name: "Read 30 minutes", frequency: .daily, system: system),
            createTestTask(name: "Write", frequency: .weekdays, system: system),
            createTestTask(name: "Deep Work Block", frequency: .weekdays, system: system)
        ]

        // Generate average completion rate (60-70%)
        generateTaskLogsWithRate(tasks: tasks, completionRate: 0.65, daysOfHistory: 30)

        // Add performance tests
        createPagesReadTest(system: system)
        createWordsWrittenTest(system: system)
    }

    private func generateHealthyLifestyleSystem() {
        let system = System(
            name: "🧪 Healthy Lifestyle",
            category: .health,
            description: "Building healthy daily habits",
            color: "#FF3B30",
            icon: "heart.fill"
        )

        if let createdDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) {
            system.createdAt = createdDate
        }

        modelContext.insert(system)

        // Create realistic tasks
        let tasks = [
            createTestTask(name: "Drink 8 glasses of water", frequency: .daily, system: system),
            createTestTask(name: "Sleep 8 hours", frequency: .daily, system: system),
            createTestTask(name: "Healthy meal prep", frequency: .weekends, system: system)
        ]

        // Generate improving trend (starts 40%, ends 85%)
        generateImprovingTaskLogs(tasks: tasks, startRate: 0.4, endRate: 0.85, daysOfHistory: 30)

        // Add performance tests
        createWeightTest(system: system)
        createRestingHeartRateTest(system: system)
    }

    // MARK: - Task Log Generators

    private func generateTaskLogsWithRate(tasks: [HabitTask], completionRate: Double, daysOfHistory: Int) {
        let calendar = Calendar.current
        let now = Date()

        for dayOffset in (0..<daysOfHistory).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: date)

            for task in tasks {
                if task.shouldBeCompletedOn(date: startOfDay) {
                    // Add some variance (±10%)
                    let variance = Double.random(in: -0.1...0.1)
                    let adjustedRate = min(1.0, max(0.0, completionRate + variance))

                    if Double.random(in: 0...1) < adjustedRate {
                        let log = HabitTaskLog(
                            notes: nil,
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
    }

    private func generateImprovingTaskLogs(tasks: [HabitTask], startRate: Double, endRate: Double, daysOfHistory: Int) {
        let calendar = Calendar.current
        let now = Date()

        for dayOffset in (0..<daysOfHistory).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: date)

            // Calculate progress-based completion rate
            let progress = Double(daysOfHistory - dayOffset) / Double(daysOfHistory)
            let completionRate = startRate + (progress * (endRate - startRate))

            for task in tasks {
                if task.shouldBeCompletedOn(date: startOfDay) {
                    if Double.random(in: 0...1) < completionRate {
                        let log = HabitTaskLog(
                            notes: nil,
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
    }

    // MARK: - Performance Test Generators

    private func createMileTimeTest(system: System, improving: Bool = true) {
        let test = PerformanceTest(
            name: "Mile Time",
            unit: "time",
            goalDirection: .lower,
            trackingFrequency: .weekly,
            description: "Measured on track"
        )
        test.system = system
        modelContext.insert(test)

        let calendar = Calendar.current
        let now = Date()
        let weeks = 4

        var baseTime: Double = improving ? 540.0 : 480.0 // 9:00 or 8:00 in seconds

        for weekOffset in (0..<weeks).reversed() {
            guard let date = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) else { continue }

            let improvement = improving ? Double(weeks - weekOffset) * 12.0 : 0.0
            let variance = Double.random(in: -8...8)
            let time = max(300, baseTime - improvement + variance) // Don't go below 5:00

            let entry = PerformanceTestEntry(
                value: time,
                notes: "Morning run",
                conditions: weekOffset % 2 == 0 ? "Good conditions" : "Felt strong"
            )
            entry.test = test
            entry.date = date
            modelContext.insert(entry)
        }
    }

    private func createPushupsTest(system: System, improving: Bool = true) {
        let test = PerformanceTest(
            name: "Max Pushups",
            unit: "reps",
            goalDirection: .higher,
            trackingFrequency: .weekly,
            description: "One set to failure"
        )
        test.system = system
        modelContext.insert(test)

        let calendar = Calendar.current
        let now = Date()
        let weeks = 4

        var baseReps: Double = improving ? 25.0 : 45.0

        for weekOffset in (0..<weeks).reversed() {
            guard let date = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) else { continue }

            let improvement = improving ? Double(weeks - weekOffset) * 3.0 : 0.0
            let variance = Double.random(in: -2...2)
            let reps = baseReps + improvement + variance

            let entry = PerformanceTestEntry(
                value: reps,
                notes: "After warmup",
                conditions: weekOffset % 2 == 0 ? "Fresh" : "Good form"
            )
            entry.test = test
            entry.date = date
            modelContext.insert(entry)
        }
    }

    private func createPagesReadTest(system: System) {
        let test = PerformanceTest(
            name: "Pages Read (Weekly)",
            unit: "pages",
            goalDirection: .higher,
            trackingFrequency: .weekly,
            description: "Total pages per week"
        )
        test.system = system
        modelContext.insert(test)

        let calendar = Calendar.current
        let now = Date()
        let weeks = 4

        for weekOffset in (0..<weeks).reversed() {
            guard let date = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) else { continue }

            let basePages = 80.0
            let variance = Double.random(in: -15...20)
            let pages = basePages + variance

            let entry = PerformanceTestEntry(
                value: pages,
                notes: "Mix of fiction and non-fiction",
                conditions: nil
            )
            entry.test = test
            entry.date = date
            modelContext.insert(entry)
        }
    }

    private func createWordsWrittenTest(system: System) {
        let test = PerformanceTest(
            name: "Words Written (Weekly)",
            unit: "words",
            goalDirection: .higher,
            trackingFrequency: .weekly,
            description: "Blog posts and notes"
        )
        test.system = system
        modelContext.insert(test)

        let calendar = Calendar.current
        let now = Date()
        let weeks = 4

        var baseWords = 1200.0

        for weekOffset in (0..<weeks).reversed() {
            guard let date = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) else { continue }

            // Slight improvement over time
            let improvement = Double(weeks - weekOffset) * 150.0
            let variance = Double.random(in: -200...300)
            let words = baseWords + improvement + variance

            let entry = PerformanceTestEntry(
                value: words,
                notes: "Writing sessions",
                conditions: nil
            )
            entry.test = test
            entry.date = date
            modelContext.insert(entry)
        }
    }

    private func createWeightTest(system: System) {
        let test = PerformanceTest(
            name: "Weight",
            unit: "lbs",
            goalDirection: .lower,
            trackingFrequency: .weekly,
            description: "Morning weigh-in"
        )
        test.system = system
        modelContext.insert(test)

        let calendar = Calendar.current
        let now = Date()
        let weeks = 4

        var baseWeight = 180.0

        for weekOffset in (0..<weeks).reversed() {
            guard let date = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) else { continue }

            // Gradual weight loss
            let improvement = Double(weeks - weekOffset) * 1.5
            let variance = Double.random(in: -0.5...0.5)
            let weight = baseWeight - improvement + variance

            let entry = PerformanceTestEntry(
                value: weight,
                notes: "After waking up",
                conditions: nil
            )
            entry.test = test
            entry.date = date
            modelContext.insert(entry)
        }
    }

    private func createRestingHeartRateTest(system: System) {
        let test = PerformanceTest(
            name: "Resting Heart Rate",
            unit: "bpm",
            goalDirection: .lower,
            trackingFrequency: .weekly,
            description: "Morning measurement"
        )
        test.system = system
        modelContext.insert(test)

        let calendar = Calendar.current
        let now = Date()
        let weeks = 4

        var baseHR = 72.0

        for weekOffset in (0..<weeks).reversed() {
            guard let date = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) else { continue }

            // Improving cardiovascular health
            let improvement = Double(weeks - weekOffset) * 2.0
            let variance = Double.random(in: -1...1)
            let hr = baseHR - improvement + variance

            let entry = PerformanceTestEntry(
                value: hr,
                notes: "Using watch",
                conditions: "After 5 min rest"
            )
            entry.test = test
            entry.date = date
            modelContext.insert(entry)
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
