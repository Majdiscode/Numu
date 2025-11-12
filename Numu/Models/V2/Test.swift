//
//  Test.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//

import Foundation
import SwiftData

/// A Test represents a periodic measurement for a System
/// Example: "Mile time", "Max pushups" for "Hybrid Athlete" system
@Model
final class Test {
    var id: UUID
    var createdAt: Date

    // Test details
    var name: String  // e.g., "Mile time", "Max pushups"
    var unit: String  // e.g., "minutes", "reps"
    var testDescription: String?

    // Goal configuration
    var goalDirection: TestGoalDirection  // Higher or lower is better
    var targetValue: Double?  // Optional target to hit

    // Tracking frequency
    var trackingFrequency: TestFrequency  // How often to measure

    // Relationship to parent System
    var system: System?

    // Relationship to measurement entries
    @Relationship(deleteRule: .cascade, inverse: \TestEntry.test)
    var entries: [TestEntry] = []

    init(
        name: String,
        unit: String,
        goalDirection: TestGoalDirection,
        trackingFrequency: TestFrequency,
        description: String? = nil,
        targetValue: Double? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.name = name
        self.unit = unit
        self.goalDirection = goalDirection
        self.trackingFrequency = trackingFrequency
        self.testDescription = description
        self.targetValue = targetValue
    }

    // MARK: - Computed Properties

    /// Latest recorded value
    var latestValue: Double? {
        entries.sorted { $0.date > $1.date }.first?.value
    }

    /// Best recorded value based on goal direction
    var bestValue: Double? {
        guard !entries.isEmpty else { return nil }

        switch goalDirection {
        case .higher:
            return entries.max { $0.value < $1.value }?.value
        case .lower:
            return entries.min { $0.value < $1.value }?.value
        }
    }

    /// Overall improvement percentage
    var improvementPercentage: Double? {
        guard entries.count >= 2 else { return nil }

        let sorted = entries.sorted { $0.date < $1.date }
        let first = sorted.first!.value
        let last = sorted.last!.value

        guard first != 0 else { return nil }

        let change = last - first
        return (change / first) * 100
    }

    /// Trend direction
    var trend: TestTrend {
        guard let improvement = improvementPercentage else { return .noData }

        let isPositive = (goalDirection == .higher && improvement > 0) ||
                        (goalDirection == .lower && improvement < 0)

        if abs(improvement) < 5 {
            return .stable
        } else if isPositive {
            return .improving
        } else {
            return .declining
        }
    }

    // MARK: - Helper Methods

    /// Check if test is due for a new measurement
    func isDue() -> Bool {
        guard let lastEntry = entries.sorted(by: { $0.date > $1.date }).first else {
            return true  // Never measured, so it's due
        }

        let daysSince = Calendar.current.dateComponents([.day], from: lastEntry.date, to: Date()).day ?? 0
        return daysSince >= trackingFrequency.daysInterval
    }

    /// Get the next due date for this test
    func nextDueDate() -> Date? {
        guard let lastEntry = entries.sorted(by: { $0.date > $1.date }).first else {
            return Date()  // Due now
        }

        return Calendar.current.date(
            byAdding: .day,
            value: trackingFrequency.daysInterval,
            to: lastEntry.date
        )
    }

    /// Get analytics including system consistency correlation
    func getAnalytics(systemConsistency: Double) -> TestAnalytics {
        TestAnalytics(
            test: self,
            systemConsistency: systemConsistency
        )
    }
}

// MARK: - Test Goal Direction

enum TestGoalDirection: String, Codable {
    case higher = "Higher is better"
    case lower = "Lower is better"

    var systemIcon: String {
        switch self {
        case .higher: return "arrow.up.circle.fill"
        case .lower: return "arrow.down.circle.fill"
        }
    }
}

// MARK: - Test Frequency

enum TestFrequency: Codable, Equatable, Hashable {
    case days(Int)
    case weeks(Int)

    var displayText: String {
        switch self {
        case .days(let count):
            return count == 1 ? "Daily" : "Every \(count) days"
        case .weeks(let count):
            return count == 1 ? "Weekly" : "Every \(count) weeks"
        }
    }

    var daysInterval: Int {
        switch self {
        case .days(let count):
            return count
        case .weeks(let count):
            return count * 7
        }
    }

    // Common presets
    static let daily = TestFrequency.days(1)
    static let weekly = TestFrequency.weeks(1)
    static let biweekly = TestFrequency.weeks(2)
    static let monthly = TestFrequency.days(30)
}

// MARK: - Test Trend

enum TestTrend {
    case improving
    case stable
    case declining
    case noData

    var icon: String {
        switch self {
        case .improving: return "arrow.up.right.circle.fill"
        case .stable: return "arrow.right.circle.fill"
        case .declining: return "arrow.down.right.circle.fill"
        case .noData: return "questionmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .improving: return "#34C759"
        case .stable: return "#007AFF"
        case .declining: return "#FF9500"
        case .noData: return "#8E8E93"
        }
    }
}

// MARK: - Test Analytics

struct TestAnalytics {
    let entries: [TestEntry]
    let systemConsistency: Double

    init(test: Test, systemConsistency: Double) {
        self.entries = test.entries
        self.systemConsistency = systemConsistency
    }

    var latestValue: Double? {
        entries.sorted { $0.date > $1.date }.first?.value
    }

    var improvement: Double? {
        guard entries.count >= 2 else { return nil }

        let sorted = entries.sorted { $0.date < $1.date }
        let first = sorted.first!.value
        let last = sorted.last!.value

        guard first != 0 else { return nil }

        let change = last - first
        return (change / first) * 100
    }

    var averageValue: Double {
        guard !entries.isEmpty else { return 0.0 }
        return entries.reduce(0.0) { $0 + $1.value } / Double(entries.count)
    }

    /// Correlation message between system consistency and test results
    var consistencyCorrelation: String {
        guard let imp = improvement, entries.count >= 3 else {
            return "Keep tracking to see how your system correlates with results"
        }

        let consistencyPercent = Int(systemConsistency * 100)
        let improvementPercent = abs(Int(imp))

        if systemConsistency >= 0.8 && abs(imp) >= 10 {
            return "Your \(consistencyPercent)% consistency across all tasks led to \(improvementPercent)% improvement!"
        } else if systemConsistency >= 0.6 {
            return "With \(consistencyPercent)% consistency, you're making steady progress"
        } else {
            return "Higher consistency in your daily tasks could accelerate your progress"
        }
    }
}
