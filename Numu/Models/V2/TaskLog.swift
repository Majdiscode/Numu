//
//  TaskLog.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//

import Foundation
import SwiftData

/// A TaskLog represents a single completion of a Task
@Model
final class TaskLog {
    var id: UUID
    var date: Date  // Date when task was completed (normalized to start of day)
    var completedAt: Date  // Actual timestamp of completion

    // Optional completion metadata
    var notes: String?
    var satisfaction: Int?  // 1-5 scale

    // Relationship to parent Task
    var task: Task?

    init(
        date: Date = Date(),
        notes: String? = nil,
        satisfaction: Int? = nil
    ) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.completedAt = Date()
        self.notes = notes
        self.satisfaction = satisfaction
    }
}
