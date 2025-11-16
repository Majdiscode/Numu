//
//  TaskLog.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//
// NOTE: Class renamed to HabitTaskLog to match HabitTask rename

import Foundation
import SwiftData

/// A HabitTaskLog represents a single completion of a HabitTask
@Model
final class HabitTaskLog {
    // CloudKit requires: all properties must have default values or be optional
    var id: UUID = UUID()
    var date: Date = Date()  // Date when task was completed (normalized to start of day)
    var completedAt: Date = Date()  // Actual timestamp of completion

    // Optional completion metadata
    var notes: String?
    var satisfaction: Int?  // 1-5 scale

    // For time-based negative habits
    var minutesSpent: Int?  // Time spent on the habit (for negative habits with limits)

    // Relationship to parent HabitTask
    var task: HabitTask?

    init(
        date: Date = Date(),
        notes: String? = nil,
        satisfaction: Int? = nil,
        minutesSpent: Int? = nil
    ) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.completedAt = Date()
        self.notes = notes
        self.satisfaction = satisfaction
        self.minutesSpent = minutesSpent
    }
}
