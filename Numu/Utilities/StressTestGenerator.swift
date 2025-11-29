//
//  StressTestGenerator.swift
//  Numu
//
//  Comprehensive stress testing utility for validating app performance
//  and stability under extreme conditions
//

import Foundation
import SwiftData

#if DEBUG

/// Generates stress test scenarios to validate app performance and stability
struct StressTestGenerator {
    let modelContext: ModelContext

    // MARK: - Stress Test Levels

    enum StressLevel {
        case light      // 10 systems, 50 tasks, 500 logs (~1 month)
        case medium     // 25 systems, 150 tasks, 3,000 logs (~6 months)
        case heavy      // 50 systems, 300 tasks, 15,000 logs (~1 year)
        case extreme    // 100 systems, 500 tasks, 50,000 logs (~2 years)

        var systemCount: Int {
            switch self {
            case .light: return 10
            case .medium: return 25
            case .heavy: return 50
            case .extreme: return 100
            }
        }

        var tasksPerSystem: Int {
            switch self {
            case .light: return 5
            case .medium: return 6
            case .heavy: return 6
            case .extreme: return 5
            }
        }

        var historicalDays: Int {
            switch self {
            case .light: return 30      // 1 month
            case .medium: return 180    // 6 months
            case .heavy: return 365     // 1 year
            case .extreme: return 730   // 2 years
            }
        }

        var displayName: String {
            switch self {
            case .light: return "Light (1 month)"
            case .medium: return "Medium (6 months)"
            case .heavy: return "Heavy (1 year)"
            case .extreme: return "Extreme (2 years)"
            }
        }

        var expectedDataCount: String {
            let systems = systemCount
            let tasks = systemCount * tasksPerSystem
            let avgLogsPerTaskPerDay = 0.7 // 70% completion rate
            let logs = Int(Double(tasks) * Double(historicalDays) * avgLogsPerTaskPerDay)
            return "\(systems) systems, \(tasks) tasks, ~\(logs) logs"
        }
    }

    // MARK: - Main Stress Test Generator

    /// Generate comprehensive stress test data
    func generateStressTest(level: StressLevel, progress: @escaping (Double, String) -> Void) {
        print("🔥 [STRESS TEST] ========================================")
        print("🔥 [STRESS TEST] Starting \(level.displayName) stress test...")
        print("🔥 [STRESS TEST] Expected: \(level.expectedDataCount)")
        print("🔥 [STRESS TEST] ========================================")

        let overallStartTime = Date()
        let calendar = Calendar.current

        // Calculate total operations for progress tracking
        let totalSystems = level.systemCount
        let totalTasks = totalSystems * level.tasksPerSystem
        let avgLogsPerTask = Int(Double(level.historicalDays) * 0.7)
        let totalLogs = totalTasks * avgLogsPerTask
        let totalOperations = Double(totalSystems + totalTasks + totalLogs)
        var completedOperations: Double = 0

        // PHASE 1: Generate systems
        print("")
        print("📦 [PHASE 1/3] Creating \(totalSystems) systems...")
        let systemsStartTime = Date()

        var systems: [System] = []
        for i in 0..<level.systemCount {
            progress(completedOperations / totalOperations, "Creating system \(i + 1)/\(level.systemCount)...")

            let system = createRandomSystem(index: i, daysOld: level.historicalDays)
            systems.append(system)
            modelContext.insert(system)

            completedOperations += 1
        }

        // Save systems batch
        let systemsSaveStart = Date()
        try? modelContext.save()
        let systemsSaveDuration = Date().timeIntervalSince(systemsSaveStart)
        let systemsDuration = Date().timeIntervalSince(systemsStartTime)

        print("✅ [PHASE 1] Created \(systems.count) systems in \(String(format: "%.2f", systemsDuration))s")
        print("   💾 Save time: \(String(format: "%.2f", systemsSaveDuration))s")

        // PHASE 2: Generate tasks
        print("")
        print("📋 [PHASE 2/3] Creating \(totalTasks) tasks...")
        let tasksStartTime = Date()

        var allTasks: [(task: HabitTask, system: System)] = []
        for (sysIndex, system) in systems.enumerated() {
            for taskIndex in 0..<level.tasksPerSystem {
                let globalTaskNum = sysIndex * level.tasksPerSystem + taskIndex + 1
                progress(completedOperations / totalOperations, "Creating task \(globalTaskNum)/\(totalTasks)...")

                let task = createRandomTask(index: taskIndex, system: system)
                allTasks.append((task, system))
                modelContext.insert(task)

                completedOperations += 1
            }
        }

        // Save tasks batch
        let tasksSaveStart = Date()
        try? modelContext.save()
        let tasksSaveDuration = Date().timeIntervalSince(tasksSaveStart)
        let tasksDuration = Date().timeIntervalSince(tasksStartTime)

        print("✅ [PHASE 2] Created \(allTasks.count) tasks in \(String(format: "%.2f", tasksDuration))s")
        print("   💾 Save time: \(String(format: "%.2f", tasksSaveDuration))s")

        // PHASE 3: Generate historical logs
        print("")
        print("📝 [PHASE 3/3] Creating ~\(totalLogs) completion logs...")
        print("   Batch size: \(500) logs per save")
        print("   Historical days: \(level.historicalDays) days")
        let logsStartTime = Date()

        var batchSaveCounter = 0
        let batchSize = 500 // Save every 500 logs to reduce WAL checkpoints
        var totalLogsCreated = 0
        var saveCount = 0
        var slowSaveWarnings = 0

        for (taskIndex, (task, system)) in allTasks.enumerated() {
            let startDate = calendar.startOfDay(for: system.createdAt)
            let endDate = calendar.startOfDay(for: Date())

            // Generate logs based on task frequency and realistic patterns
            var currentDate = startDate
            var logCount = 0

            while currentDate <= endDate {
                // Progress update every 500 logs (reduced frequency)
                if logCount % 500 == 0 {
                    let globalLogNum = Int(completedOperations - Double(totalSystems + totalTasks))
                    let percentComplete = (completedOperations / totalOperations) * 100
                    progress(completedOperations / totalOperations, "Generating logs: \(globalLogNum)/~\(totalLogs)... (\(Int(percentComplete))%)")
                }

                // Check if task should be completed on this date
                if task.shouldBeCompletedOn(date: currentDate) {
                    // Use realistic completion rates (60-90% depending on task age)
                    let daysSinceCreation = calendar.dateComponents([.day], from: startDate, to: currentDate).day ?? 0
                    let completionRate = calculateRealisticCompletionRate(daysSinceCreation: daysSinceCreation)

                    if Double.random(in: 0...1) < completionRate {
                        let log = HabitTaskLog(
                            notes: generateRandomNote(),
                            satisfaction: Int.random(in: 3...5),
                            minutesSpent: task.habitType == .negative ? Int.random(in: 10...120) : nil
                        )
                        log.task = task
                        log.date = currentDate
                        modelContext.insert(log)

                        completedOperations += 1
                        logCount += 1
                        batchSaveCounter += 1
                        totalLogsCreated += 1

                        // Batch save to reduce database writes
                        if batchSaveCounter >= batchSize {
                            do {
                                let saveStart = Date()
                                try modelContext.save()
                                let saveDuration = Date().timeIntervalSince(saveStart)
                                saveCount += 1

                                // Track slow saves silently
                                if saveDuration > 2.0 {
                                    slowSaveWarnings += 1
                                }
                            } catch {
                                print("   ❌ Save error: \(error.localizedDescription)")
                            }
                            batchSaveCounter = 0
                        }
                    }
                } else if case .weeklyTarget(let times) = task.frequency {
                    // For weekly tasks, randomly complete within the week
                    let weekday = calendar.component(.weekday, from: currentDate)
                    if weekday >= 2 && weekday <= 6 { // Weekdays more likely
                        let weekCompletions = task.completionsThisWeek()
                        if weekCompletions < times && Double.random(in: 0...1) < 0.4 {
                            let log = HabitTaskLog(
                                notes: generateRandomNote(),
                                satisfaction: Int.random(in: 3...5),
                                minutesSpent: nil
                            )
                            log.task = task
                            log.date = currentDate
                            modelContext.insert(log)

                            completedOperations += 1
                            logCount += 1
                            batchSaveCounter += 1
                            totalLogsCreated += 1

                            // Batch save
                            if batchSaveCounter >= batchSize {
                                do {
                                    let saveStart = Date()
                                    try modelContext.save()
                                    let saveDuration = Date().timeIntervalSince(saveStart)
                                    saveCount += 1

                                    // Track slow saves silently
                                    if saveDuration > 2.0 {
                                        slowSaveWarnings += 1
                                    }
                                } catch {
                                    print("   ❌ Save error: \(error.localizedDescription)")
                                }
                                batchSaveCounter = 0
                            }
                        }
                    }
                }

                guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
                currentDate = nextDate
            }
        }

        // Final save for any remaining logs
        print("")
        print("💾 [FINAL SAVE] Saving remaining data...")
        let finalSaveStart = Date()
        progress(0.95, "Saving final batch...")

        do {
            try modelContext.save()
            modelContext.processPendingChanges()
            let finalSaveDuration = Date().timeIntervalSince(finalSaveStart)
            print("✅ [FINAL SAVE] Completed in \(String(format: "%.2f", finalSaveDuration))s")
        } catch {
            print("❌ [FINAL SAVE] Error: \(error.localizedDescription)")
        }

        let logsDuration = Date().timeIntervalSince(logsStartTime)
        print("✅ [PHASE 3] Created \(totalLogsCreated) logs in \(String(format: "%.2f", logsDuration))s")
        print("   💾 Total saves: \(saveCount + 1)")
        if slowSaveWarnings > 0 {
            print("   ⚠️ Slow saves detected: \(slowSaveWarnings) saves took > 2s")
        }

        // Overall summary
        let overallDuration = Date().timeIntervalSince(overallStartTime)
        progress(1.0, "Complete!")

        print("")
        print("🎉 [STRESS TEST] ========================================")
        print("🎉 [STRESS TEST] COMPLETED in \(String(format: "%.2f", overallDuration))s")
        print("🎉 [STRESS TEST] ========================================")
        print("   📊 Generated:")
        print("      • Systems: \(systems.count)")
        print("      • Tasks: \(allTasks.count)")
        print("      • Logs: \(totalLogsCreated)")
        print("")
        print("   ⏱️ Timing Breakdown:")
        print("      • Systems: \(String(format: "%.2f", systemsDuration))s (\(Int((systemsDuration/overallDuration)*100))%)")
        print("      • Tasks: \(String(format: "%.2f", tasksDuration))s (\(Int((tasksDuration/overallDuration)*100))%)")
        print("      • Logs: \(String(format: "%.2f", logsDuration))s (\(Int((logsDuration/overallDuration)*100))%)")
        print("")
        print("   💾 Database Performance:")
        print("      • Total saves: \(saveCount + 1)")
        print("      • Avg save time: \(String(format: "%.3f", logsDuration / Double(saveCount + 1)))s")
        if slowSaveWarnings > 0 {
            print("      • ⚠️ WARNING: \(slowSaveWarnings) slow saves (> 2s)")
        }
        print("🎉 [STRESS TEST] ========================================")
    }

    // MARK: - Specific Stress Test Scenarios

    /// Test rapid concurrent operations (simulates CloudKit sync conflicts)
    func testRapidOperations() {
        print("⚡️ [RAPID OPS] Testing rapid concurrent operations...")

        let system = System(name: "🔥 Rapid Test System", category: .athletics)
        modelContext.insert(system)

        // Create 50 tasks rapidly
        for i in 0..<50 {
            let task = HabitTask(name: "Rapid Task \(i)", frequency: .daily)
            task.system = system
            modelContext.insert(task)
        }

        try? modelContext.save()

        // Complete all tasks rapidly (simulates bulk update)
        if let tasks = system.tasks {
            for task in tasks {
                let log = HabitTaskLog(notes: "Rapid completion", satisfaction: 5)
                log.task = task
                log.date = Date()
                modelContext.insert(log)
            }
        }

        try? modelContext.save()
        modelContext.processPendingChanges()

        print("✅ [RAPID OPS] Completed")
    }

    /// Test edge cases around week boundaries
    func testWeekBoundaries() {
        print("📅 [WEEK BOUNDARY] Testing week boundary edge cases...")

        let calendar = Calendar.current
        let system = System(name: "🔥 Week Boundary Test", category: .mind)

        // Create system at week boundary
        if let sundayMidnight = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) {
            system.createdAt = sundayMidnight
        }

        modelContext.insert(system)

        // Create weekly target task
        let task = HabitTask(name: "Week Boundary Task", frequency: .weeklyTarget(times: 3))
        task.system = system
        modelContext.insert(task)

        // Add completions at week boundaries
        for weekOffset in -4..<1 {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: Date()) else { continue }

            // Add completions on Saturday (day before week boundary)
            if let saturday = calendar.date(byAdding: .day, value: -1, to: weekStart) {
                let log = HabitTaskLog(notes: "Saturday completion", satisfaction: 4)
                log.task = task
                log.date = saturday
                modelContext.insert(log)
            }

            // Add completions on Sunday (week boundary)
            let log = HabitTaskLog(notes: "Sunday completion", satisfaction: 5)
            log.task = task
            log.date = weekStart
            modelContext.insert(log)

            // Add completions on Monday (day after boundary)
            if let monday = calendar.date(byAdding: .day, value: 1, to: weekStart) {
                let log = HabitTaskLog(notes: "Monday completion", satisfaction: 4)
                log.task = task
                log.date = monday
                modelContext.insert(log)
            }
        }

        try? modelContext.save()
        modelContext.processPendingChanges()

        print("✅ [WEEK BOUNDARY] Completed - Streak: \(task.currentStreak)")
    }

    /// Test "Never Miss Twice" edge cases
    func testNeverMissTwiceEdgeCases() {
        print("🔁 [NEVER MISS TWICE] Testing streak grace period edge cases...")

        let calendar = Calendar.current
        let system = System(name: "🔥 Streak Test System", category: .athletics)
        modelContext.insert(system)

        // Scenario 1: Miss, complete, miss, complete (should maintain streak)
        let task1 = HabitTask(name: "Alternating Misses", frequency: .daily)
        task1.system = system
        modelContext.insert(task1)

        for dayOffset in (0...10).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }

            // Alternate pattern: complete, miss, complete, miss...
            if dayOffset % 2 == 0 {
                let log = HabitTaskLog(notes: "Completed", satisfaction: 5)
                log.task = task1
                log.date = date
                modelContext.insert(log)
            }
            // Else: miss this day
        }

        // Scenario 2: Long streak, miss once, continue (grace day)
        let task2 = HabitTask(name: "Grace Day Test", frequency: .daily)
        task2.system = system
        modelContext.insert(task2)

        for dayOffset in (0...20).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }

            // Complete all except day -5 (single miss)
            if dayOffset != 5 {
                let log = HabitTaskLog(notes: "Completed", satisfaction: 5)
                log.task = task2
                log.date = date
                modelContext.insert(log)
            }
        }

        // Scenario 3: Miss two in a row (streak breaks)
        let task3 = HabitTask(name: "Broken Streak Test", frequency: .daily)
        task3.system = system
        modelContext.insert(task3)

        for dayOffset in (0...20).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }

            // Complete all except days -5 and -4 (two consecutive misses)
            if dayOffset != 5 && dayOffset != 4 {
                let log = HabitTaskLog(notes: "Completed", satisfaction: 5)
                log.task = task3
                log.date = date
                modelContext.insert(log)
            }
        }

        try? modelContext.save()
        modelContext.processPendingChanges()

        print("   Task 1 (Alternating): Streak = \(task1.currentStreak) (should be ~5)")
        print("   Task 2 (Grace Day): Streak = \(task2.currentStreak) (should be ~20)")
        print("   Task 3 (Broken): Streak = \(task3.currentStreak) (should be ~0-3)")
        print("✅ [NEVER MISS TWICE] Completed")
    }

    /// Benchmark performance of key calculations
    func benchmarkPerformance() -> PerformanceBenchmark {
        print("⏱️ [BENCHMARK] Running performance benchmarks...")

        var results = PerformanceBenchmark()

        // Create test system with moderate data
        let system = System(name: "🔥 Benchmark System", category: .athletics)
        let creationDate = Calendar.current.date(byAdding: .day, value: -365, to: Date())!
        system.createdAt = creationDate
        modelContext.insert(system)

        let task = HabitTask(name: "Benchmark Task", frequency: .daily)
        task.system = system
        task.createdAt = creationDate
        modelContext.insert(task)

        // Generate 365 days of data (70% completion)
        let calendar = Calendar.current
        for dayOffset in 0..<365 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: creationDate) else { continue }

            if Double.random(in: 0...1) < 0.7 {
                let log = HabitTaskLog(notes: "Test", satisfaction: 4)
                log.task = task
                log.date = date
                modelContext.insert(log)
            }
        }

        try? modelContext.save()

        // Benchmark 1: Streak Calculation
        let streakStart = Date()
        let streak = task.currentStreak
        results.streakCalculation = Date().timeIntervalSince(streakStart)

        // Benchmark 2: Completion Rate
        let completionStart = Date()
        let rate = task.completionRate
        results.completionRate = Date().timeIntervalSince(completionStart)

        // Benchmark 3: Weekly Completions
        let weeklyStart = Date()
        let weekly = task.completionsThisWeek()
        results.weeklyCompletions = Date().timeIntervalSince(weeklyStart)

        // Benchmark 4: System Consistency
        let consistencyStart = Date()
        let consistency = system.overallConsistency
        results.systemConsistency = Date().timeIntervalSince(consistencyStart)

        // Benchmark 5: Query Performance (fetch all logs)
        let queryStart = Date()
        let descriptor = FetchDescriptor<HabitTaskLog>()
        _ = try? modelContext.fetch(descriptor)
        results.queryPerformance = Date().timeIntervalSince(queryStart)

        // Clean up
        modelContext.delete(system)
        try? modelContext.save()

        print("   Streak Calculation: \(String(format: "%.4f", results.streakCalculation))s")
        print("   Completion Rate: \(String(format: "%.4f", results.completionRate))s")
        print("   Weekly Completions: \(String(format: "%.4f", results.weeklyCompletions))s")
        print("   System Consistency: \(String(format: "%.4f", results.systemConsistency))s")
        print("   Query Performance: \(String(format: "%.4f", results.queryPerformance))s")
        print("✅ [BENCHMARK] Completed")

        return results
    }

    // MARK: - Helper Methods

    private func createRandomSystem(index: Int, daysOld: Int) -> System {
        let categories = SystemCategory.allCases
        let category = categories[index % categories.count]

        let names = [
            "Hybrid Athlete", "Knowledge Worker", "Creative Mind", "Healthy Living",
            "Mindful Person", "Consistent Learner", "Strong Body", "Sharp Mind",
            "Productive Worker", "Balanced Life", "Focused Individual", "Energetic Person",
            "Disciplined Achiever", "Calm Professional", "Active Lifestyle"
        ]

        let system = System(
            name: "🔥 \(names[index % names.count]) #\(index + 1)",
            category: category,
            description: "Stress test system for performance validation"
        )

        // Randomize creation date
        let calendar = Calendar.current
        let randomDays = Int.random(in: 0...daysOld)
        if let date = calendar.date(byAdding: .day, value: -randomDays, to: Date()) {
            system.createdAt = date
        }

        return system
    }

    private func createRandomTask(index: Int, system: System) -> HabitTask {
        let frequencies: [TaskFrequency] = [
            .daily,
            .weekdays,
            .weekends,
            .specificDays([2, 4, 6]), // Mon, Wed, Fri
            .weeklyTarget(times: 3)
        ]

        let taskNames = [
            "Morning Run", "Read", "Meditate", "Workout", "Journaling",
            "Cold Shower", "Stretching", "Learn", "Create", "Focus Work"
        ]

        let habitTypes: [HabitType] = [.positive, .positive, .positive, .negative] // 75% positive

        let task = HabitTask(
            name: taskNames[index % taskNames.count],
            description: "Auto-generated stress test task",
            frequency: frequencies[index % frequencies.count],
            habitType: habitTypes[index % habitTypes.count]
        )

        task.system = system
        task.createdAt = system.createdAt

        return task
    }

    private func generateRandomNote() -> String {
        let notes = [
            "Completed successfully",
            "Great session!",
            "Felt energized",
            "Quick completion",
            "Consistent effort",
            "Making progress",
            "Staying committed",
            ""
        ]
        return notes.randomElement()!
    }

    private func calculateRealisticCompletionRate(daysSinceCreation: Int) -> Double {
        // Realistic pattern: high motivation at start, dip in middle, slight recovery
        if daysSinceCreation < 7 {
            return 0.95 // 95% completion in first week (honeymoon phase)
        } else if daysSinceCreation < 30 {
            return 0.85 // 85% in first month
        } else if daysSinceCreation < 90 {
            return 0.70 // 70% in first quarter (dip)
        } else {
            return 0.75 // 75% long-term (slight recovery)
        }
    }

    /// Clear all stress test data (marked with 🔥 emoji)
    func clearStressTestData(progress: @escaping (Double, String) -> Void) {
        print("🗑️ [STRESS TEST] Clearing all stress test data...")

        let descriptor = FetchDescriptor<System>()

        do {
            let allSystems = try modelContext.fetch(descriptor)
            let testSystems = allSystems.filter { $0.name.contains("🔥") }

            print("   Found \(testSystems.count) stress test systems to delete")

            for (index, system) in testSystems.enumerated() {
                // Only report progress every 10 systems or at the end
                if index % 10 == 0 || index == testSystems.count - 1 {
                    progress(Double(index) / Double(testSystems.count), "Deleting \(index + 1)/\(testSystems.count)...")
                }
                modelContext.delete(system)
            }

            progress(0.9, "Saving changes...")
            try modelContext.save()
            modelContext.processPendingChanges()

            progress(1.0, "Complete!")
            print("✅ [STRESS TEST] Cleared successfully!")
        } catch {
            print("❌ [STRESS TEST] Error clearing: \(error)")
        }
    }
}

// MARK: - Performance Benchmark Results

struct PerformanceBenchmark {
    var streakCalculation: TimeInterval = 0
    var completionRate: TimeInterval = 0
    var weeklyCompletions: TimeInterval = 0
    var systemConsistency: TimeInterval = 0
    var queryPerformance: TimeInterval = 0

    var totalTime: TimeInterval {
        streakCalculation + completionRate + weeklyCompletions + systemConsistency + queryPerformance
    }

    var isHealthy: Bool {
        // All operations should complete in < 100ms
        return totalTime < 0.5
    }

    var grade: String {
        if totalTime < 0.1 { return "A+ (Excellent)" }
        if totalTime < 0.25 { return "A (Great)" }
        if totalTime < 0.5 { return "B (Good)" }
        if totalTime < 1.0 { return "C (Acceptable)" }
        return "D (Needs Optimization)"
    }
}

#endif
