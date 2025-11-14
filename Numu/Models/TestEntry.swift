//
//  TestEntry.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//
// NOTE: Class renamed to PerformanceTestEntry to match PerformanceTest rename

import Foundation
import SwiftData

/// A PerformanceTestEntry represents a single measurement of a PerformanceTest
@Model
final class PerformanceTestEntry {
    // CloudKit requires: all properties must have default values or be optional
    var id: UUID = UUID()
    var date: Date = Date()

    // Measurement data
    var value: Double = 0.0

    // Optional metadata
    var notes: String?
    var conditions: String?  // e.g., "felt tired", "perfect weather"

    // Relationship to parent PerformanceTest
    var test: PerformanceTest?

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
