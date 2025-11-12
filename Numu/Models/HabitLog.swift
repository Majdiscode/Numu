//
//  HabitLog.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//

import Foundation
import SwiftData

@Model
final class HabitLog {
    var id: UUID
    var date: Date

    // Optional: Track time of completion
    var completedAt: Date

    // Optional: Notes about the completion
    var notes: String?

    // Optional: Mood/feeling after completion (1-5 scale)
    var satisfaction: Int?

    // Relationship
    var habit: Habit?

    init(date: Date = Date(), notes: String? = nil, satisfaction: Int? = nil) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.completedAt = Date()
        self.notes = notes
        self.satisfaction = satisfaction
    }
}
