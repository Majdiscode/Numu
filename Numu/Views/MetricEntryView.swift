//
//  MetricEntryView.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//

import SwiftUI
import SwiftData

struct MetricEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let habit: Habit

    @State private var value: String = ""
    @State private var notes: String = ""
    @State private var conditions: String = ""

    var metricConfig: MetricConfig? {
        habit.metricConfig
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Context Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: habit.icon)
                                .foregroundStyle(Color(hex: habit.color))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(habit.identity.capitalized)
                                    .font(.headline)

                                if let config = metricConfig {
                                    Text("Tracking: \(config.name)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()
                        }
                    }
                    .padding(.vertical, 4)
                }

                // MARK: - Value Entry
                if let config = metricConfig {
                    Section {
                        HStack {
                            TextField("0.0", text: $value)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)

                            Text(config.unit)
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Label(config.name, systemImage: config.goalDirection.systemIcon)
                    } footer: {
                        if config.goalDirection == .lower {
                            Text("Lower is better")
                        } else {
                            Text("Higher is better")
                        }
                    }

                    // MARK: - Context Fields
                    Section {
                        TextField("How did it feel?", text: $conditions, axis: .vertical)
                            .lineLimit(2...4)
                    } header: {
                        Text("Conditions (Optional)")
                    } footer: {
                        Text("e.g., \"Felt tired\", \"Perfect weather\", \"New personal best!\"")
                    }

                    Section {
                        TextField("Any additional notes...", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                    } header: {
                        Text("Notes (Optional)")
                    }

                    // MARK: - Previous Entries
                    if !habit.metricEntries.isEmpty {
                        Section {
                            ForEach(habit.metricEntries.sorted(by: { $0.date > $1.date }).prefix(3), id: \.id) { entry in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(String(format: "%.1f", entry.value)) \(config.unit)")
                                            .font(.headline)

                                        Text(relativeDateString(for: entry.date))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    if let conditions = entry.conditions {
                                        Text(conditions)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        } header: {
                            Text("Recent Entries")
                        }
                    }

                    // MARK: - Insights
                    if let analytics = habit.getMetricAnalytics() as MetricAnalytics?, analytics.entries.count >= 2 {
                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                if let improvement = analytics.improvement {
                                    HStack {
                                        Image(systemName: analytics.trend.icon)
                                            .foregroundStyle(Color(hex: analytics.trend.color))

                                        Text("Trend: \(String(format: "%.1f%%", abs(improvement)))")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)

                                        Spacer()
                                    }
                                }

                                Text(analytics.consistencyCorrelation)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } header: {
                            Label("Insight", systemImage: "lightbulb.fill")
                        }
                    }
                }
            }
            .navigationTitle("Log Metric")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var isValid: Bool {
        guard let doubleValue = Double(value), doubleValue > 0 else {
            return false
        }
        return true
    }

    private func saveEntry() {
        guard let doubleValue = Double(value) else { return }

        let entry = MetricEntry(
            value: doubleValue,
            notes: notes.isEmpty ? nil : notes,
            conditions: conditions.isEmpty ? nil : conditions
        )
        entry.habit = habit

        modelContext.insert(entry)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving metric entry: \(error)")
        }
    }

    private func relativeDateString(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}