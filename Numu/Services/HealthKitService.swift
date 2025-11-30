//
//  HealthKitService.swift
//  Numu
//
//  Created by Claude Code
//

import Foundation
import HealthKit
import SwiftData

@Observable
class HealthKitService {
    // MARK: - Properties

    var isAuthorized: Bool = false
    var authorizationStatus: String = "Not Determined"
    var isHealthKitAvailable: Bool = HKHealthStore.isHealthDataAvailable()
    var isSyncing: Bool = false
    var lastSyncDate: Date?

    private let healthStore = HKHealthStore()

    // MARK: - Initialization

    init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    /// Request authorization to read HealthKit data
    func requestAuthorization() async -> Bool {
        guard isHealthKitAvailable else {
            authorizationStatus = "HealthKit not available on this device"
            return false
        }

        // Define all read types we want to access
        let readTypes: Set<HKSampleType> = Set(
            HealthKitMetricType.allCases.compactMap { $0.getHealthKitType() }
        )

        do {
            // Request authorization (read-only, no write permissions needed)
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)

            // Mark that we've requested authorization
            UserDefaults.standard.set(true, forKey: "hasRequestedHealthKitAuth")

            // Update status
            checkAuthorizationStatus()

            print("✅ [HealthKit] Authorization request completed successfully")
            return true
        } catch {
            print("❌ [HealthKit] Error requesting authorization: \(error)")
            authorizationStatus = "Authorization Failed"
            return false
        }
    }

    /// Check current authorization status
    /// Note: For privacy reasons, iOS doesn't reliably report READ authorization status.
    /// We assume authorization if requestAuthorization() was called successfully.
    private func checkAuthorizationStatus() {
        guard isHealthKitAvailable else {
            authorizationStatus = "Not Available"
            isAuthorized = false
            return
        }

        // For read-only permissions, iOS doesn't provide reliable authorization status
        // If we successfully requested authorization, assume we have it
        // The only way to truly know is to try querying data

        // Check if we've requested authorization before (stored in UserDefaults)
        let hasRequestedAuth = UserDefaults.standard.bool(forKey: "hasRequestedHealthKitAuth")

        if hasRequestedAuth {
            authorizationStatus = "Authorized"
            isAuthorized = true
        } else {
            authorizationStatus = "Not Determined"
            isAuthorized = false
        }
    }

    // MARK: - Query Methods (Priority Metrics)

    /// Query step count for a specific date
    func queryStepsForDate(_ date: Date) async -> Double? {
        return await queryQuantityForDate(.stepCount, date: date)
    }

    /// Query walking + running distance for a specific date
    func queryDistanceForDate(_ date: Date) async -> Double? {
        return await queryQuantityForDate(.distance, date: date)
    }

    /// Query active energy burned for a specific date
    func queryActiveEnergyForDate(_ date: Date) async -> Double? {
        return await queryQuantityForDate(.activeEnergy, date: date)
    }

    /// Query exercise minutes for a specific date
    func queryExerciseMinutesForDate(_ date: Date) async -> Double? {
        return await queryQuantityForDate(.exerciseMinutes, date: date)
    }

    // MARK: - Generic Query Method

    /// Query a workout-based metric for a specific date (e.g., running distance, cycling distance)
    private func queryWorkoutForDate(_ metric: HealthKitMetricType, date: Date) async -> Double? {
        guard let activityType = metric.getWorkoutActivityType() else {
            print("⚠️ [HealthKit] Metric \(metric.displayName) is not workout-based")
            return nil
        }

        guard let unit = metric.getHealthKitUnit() else {
            print("⚠️ [HealthKit] Invalid unit for metric: \(metric.displayName)")
            return nil
        }

        // Create predicate for the specific date and activity type
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return nil
        }

        // Filter by date and activity type
        let datePredicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        let activityPredicate = HKQuery.predicateForWorkouts(with: activityType)
        let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, activityPredicate])

        return await withCheckedContinuation { continuation in
            // Query all workouts of this type for the date
            let query = HKSampleQuery(
                sampleType: HKWorkoutType.workoutType(),
                predicate: combinedPredicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, results, error in
                if let error = error {
                    print("❌ [HealthKit] Workout query error for \(metric.displayName): \(error)")
                    continuation.resume(returning: nil)
                    return
                }

                guard let workouts = results as? [HKWorkout], !workouts.isEmpty else {
                    print("📊 [HealthKit] No \(metric.displayName) workouts on \(startOfDay)")
                    continuation.resume(returning: nil)
                    return
                }

                // Sum up total distance from all matching workouts
                let totalDistance = workouts.reduce(0.0) { sum, workout in
                    guard let distance = workout.totalDistance else { return sum }
                    return sum + distance.doubleValue(for: unit)
                }

                print("✅ [HealthKit] \(metric.displayName): \(totalDistance) meters (\(workouts.count) workouts)")
                continuation.resume(returning: totalDistance)
            }

            healthStore.execute(query)
        }
    }

    /// Query a quantity metric for a specific date
    private func queryQuantityForDate(_ metric: HealthKitMetricType, date: Date) async -> Double? {
        // If this is a workout-based metric, use workout query instead
        if metric.isWorkoutBased {
            return await queryWorkoutForDate(metric, date: date)
        }
        guard let quantityType = metric.getHealthKitType() as? HKQuantityType else {
            print("⚠️ [HealthKit] Invalid quantity type for metric: \(metric.displayName)")
            return nil
        }

        guard let unit = metric.getHealthKitUnit() else {
            print("⚠️ [HealthKit] Invalid unit for metric: \(metric.displayName)")
            return nil
        }

        // Create predicate for the specific date (start of day to end of day)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return nil
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            // Create statistics query to sum all samples for the day
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    print("❌ [HealthKit] Query error for \(metric.displayName): \(error)")
                    continuation.resume(returning: nil)
                    return
                }

                guard let result = result,
                      let sum = result.sumQuantity() else {
                    print("📊 [HealthKit] No data for \(metric.displayName) on \(startOfDay)")
                    continuation.resume(returning: nil)
                    return
                }

                let value = sum.doubleValue(for: unit)
                print("✅ [HealthKit] \(metric.displayName): \(value) \(metric.unit)")
                continuation.resume(returning: value)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Auto-Completion Logic

    /// Evaluate a single task and auto-complete if activity was logged in HealthKit today
    func evaluateAndCompleteTask(_ task: HabitTask, modelContext: ModelContext) async {
        // Skip if HealthKit mapping not enabled
        guard task.healthKitAutoCompleteEnabled,
              !task.healthKitMetricsToCheck.isEmpty else {
            return
        }

        // Skip if task already has any log for today (manual takes priority)
        if task.isCompletedToday() {
            print("⏭️ [HealthKit] Task '\(task.name)' already completed today - skipping")
            return
        }

        let today = Date()

        // Check if ANY of the metrics/activities in the group were performed
        for metric in task.healthKitMetricsToCheck {
            if let value = await queryQuantityForDate(metric, date: today), value > 0 {
                print("✅ [HealthKit] Activity detected for '\(task.name)': \(metric.displayName) - \(value) \(metric.unit)")

                // Create HabitTaskLog entry
                let log = HabitTaskLog(task: task)
                log.syncedFromHealthKit = true
                log.healthKitValue = value

                // Show which specific activity completed it
                let groupInfo = task.healthKitActivityGroup != nil ? " (\(task.healthKitActivityGroup!.rawValue))" : ""
                log.notes = "Auto-completed via HealthKit: \(metric.displayName)\(groupInfo)"

                modelContext.insert(log)

                do {
                    try modelContext.save()
                    print("💾 [HealthKit] Auto-completed task '\(task.name)'")
                    return  // Stop after first matching activity
                } catch {
                    print("❌ [HealthKit] Failed to save auto-completion: \(error)")
                }
            }
        }

        print("⚠️ [HealthKit] No matching activity logged today for task '\(task.name)'")
    }

    /// Check all mapped tasks for today and auto-complete if activity was logged
    func checkAllMappedTasksForToday(tasks: [HabitTask], modelContext: ModelContext) async {
        guard isAuthorized else {
            print("⚠️ [HealthKit] Not authorized - skipping sync")
            return
        }

        isSyncing = true
        defer { isSyncing = false }

        print("🔄 [HealthKit] Starting sync for \(tasks.count) tasks...")

        // Filter to only tasks with HealthKit mapping enabled
        let mappedTasks = tasks.filter { task in
            task.healthKitAutoCompleteEnabled &&
            !task.healthKitMetricsToCheck.isEmpty
        }

        print("📊 [HealthKit] Found \(mappedTasks.count) tasks with HealthKit mapping")

        // Process each mapped task
        for task in mappedTasks {
            await evaluateAndCompleteTask(task, modelContext: modelContext)
        }

        lastSyncDate = Date()
        print("✅ [HealthKit] Sync completed at \(lastSyncDate!)")
    }

    // MARK: - Helper Methods

    /// Get current value for a metric (for preview in UI)
    func getCurrentValue(for metric: HealthKitMetricType) async -> Double? {
        return await queryQuantityForDate(metric, date: Date())
    }

    /// Format a value with the appropriate unit
    func formatValue(_ value: Double, for metric: HealthKitMetricType) -> String {
        let formatted: String

        // Format based on typical ranges
        switch metric {
        case .stepCount:
            formatted = Int(value).formatted()
        case .distance:
            formatted = (value / 1000).formatted(.number.precision(.fractionLength(2)))  // meters to km
        case .activeEnergy, .calorieIntake:
            formatted = Int(value).formatted()
        case .bodyFat:
            formatted = value.formatted(.number.precision(.fractionLength(1)))
        default:
            formatted = value.formatted(.number.precision(.fractionLength(0)))
        }

        return "\(formatted) \(metric.unit)"
    }
}
