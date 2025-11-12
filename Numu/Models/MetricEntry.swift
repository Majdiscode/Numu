//
//  MetricEntry.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//

import Foundation
import SwiftData

@Model
final class MetricEntry {
    var id: UUID
    var date: Date

    // Metric data
    var value: Double
    var notes: String?

    // Context (optional - track conditions)
    var conditions: String?  // e.g., "felt tired", "perfect weather"

    // Relationship
    var habit: Habit?

    init(value: Double, date: Date = Date(), notes: String? = nil, conditions: String? = nil) {
        self.id = UUID()
        self.date = date
        self.value = value
        self.notes = notes
        self.conditions = conditions
    }
}

// MARK: - Metric Configuration
struct MetricConfig: Codable {
    var isEnabled: Bool
    var name: String  // e.g., "Mile time", "Weight lifted"
    var unit: String  // e.g., "minutes", "lbs", "pages"
    var goalDirection: MetricGoalDirection
    var trackingFrequency: TrackingFrequency
    var reminderEnabled: Bool

    // For visualization
    var targetValue: Double?  // Optional goal

    init(
        name: String,
        unit: String,
        goalDirection: MetricGoalDirection,
        trackingFrequency: TrackingFrequency,
        reminderEnabled: Bool = true,
        targetValue: Double? = nil
    ) {
        self.isEnabled = true
        self.name = name
        self.unit = unit
        self.goalDirection = goalDirection
        self.trackingFrequency = trackingFrequency
        self.reminderEnabled = reminderEnabled
        self.targetValue = targetValue
    }
}

enum MetricGoalDirection: String, Codable {
    case higher = "Higher is better"
    case lower = "Lower is better"

    var systemIcon: String {
        switch self {
        case .higher: return "arrow.up.circle.fill"
        case .lower: return "arrow.down.circle.fill"
        }
    }
}

enum TrackingFrequency: Codable, Equatable, Hashable {
    case days(Int)  // Every X days
    case weeks(Int)  // Every X weeks

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
    static let daily = TrackingFrequency.days(1)
    static let weekly = TrackingFrequency.weeks(1)
    static let biweekly = TrackingFrequency.weeks(2)
    static let monthly = TrackingFrequency.days(30)
}

// MARK: - Metric Analytics
struct MetricAnalytics {
    let entries: [MetricEntry]
    let consistencyRate: Double

    var improvement: Double? {
        guard entries.count >= 2 else { return nil }
        let sorted = entries.sorted { $0.date < $1.date }
        let first = sorted.first!.value
        let last = sorted.last!.value
        let change = last - first
        return (change / first) * 100
    }

    var trend: MetricTrend {
        guard let imp = improvement else { return .noData }
        if imp > 5 { return .improving }
        if imp < -5 { return .declining }
        return .stable
    }

    var averageValue: Double {
        guard !entries.isEmpty else { return 0.0 }
        return entries.reduce(0.0) { $0 + $1.value } / Double(entries.count)
    }

    var bestValue: Double? {
        entries.max { $0.value < $1.value }?.value
    }

    var latestValue: Double? {
        entries.sorted { $0.date > $1.date }.first?.value
    }

    // Correlation between consistency and improvement
    var consistencyCorrelation: String {
        guard let imp = improvement, entries.count >= 3 else {
            return "Not enough data yet"
        }

        let consistencyPercent = Int(consistencyRate * 100)
        let improvementPercent = abs(Int(imp))

        if consistencyRate >= 0.8 && abs(imp) >= 10 {
            return "Your \(consistencyPercent)% consistency led to \(improvementPercent)% improvement!"
        } else if consistencyRate >= 0.6 {
            return "With \(consistencyPercent)% consistency, you're making steady progress"
        } else {
            return "Higher consistency could accelerate your progress"
        }
    }
}

enum MetricTrend {
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
