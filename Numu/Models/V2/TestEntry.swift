//
//  TestEntry.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//

import Foundation
import SwiftData

/// A TestEntry represents a single measurement of a Test
@Model
final class TestEntry {
    var id: UUID
    var date: Date

    // Measurement data
    var value: Double

    // Optional metadata
    var notes: String?
    var conditions: String?  // e.g., "felt tired", "perfect weather"

    // Relationship to parent Test
    var test: Test?

    init(
        value: Double,
        date: Date = Date(),
        notes: String? = nil,
        conditions: String? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.value = value
        self.notes = notes
        self.conditions = conditions
    }
}
