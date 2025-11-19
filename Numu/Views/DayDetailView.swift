//
//  DayDetailView.swift
//  Numu
//
//  Detail view showing tasks and completion for a specific day
//

import SwiftUI
import SwiftData

struct DayDetailView: View {
    let date: Date
    let systems: [System]

    @Environment(\.dismiss) private var dismiss

    private let calendar = Calendar.current

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Summary Card
                    summaryCard

                    // Tasks by System
                    ForEach(systems) { system in
                        if !tasksForSystem(system).isEmpty {
                            SystemTasksSection(system: system, date: date, tasks: tasksForSystem(system))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(formattedDate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        let stats = dayStatistics
        let completionRate = stats.total > 0 ? Double(stats.completed) / Double(stats.total) : 0
        let color = completionRateColor(completionRate, hasTask: stats.total > 0)

        return VStack(spacing: 16) {
            // Completion Circle
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: completionRate)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(completionRate * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
            }

            // Stats
            HStack(spacing: 32) {
                VStack(spacing: 4) {
                    Text("\(stats.completed)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Completed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text("\(stats.total)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text(stats.total == 0 ? "No tasks" : statusText(completionRate))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(color)
                    Text("Status")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statusText(_ rate: Double) -> String {
        if rate >= 0.8 {
            return "Great!"
        } else if rate >= 0.5 {
            return "Good"
        } else if rate > 0 {
            return "Needs work"
        } else {
            return "Missed"
        }
    }

    // MARK: - Helpers

    private var dayStatistics: (completed: Int, total: Int) {
        let startOfDay = calendar.startOfDay(for: date)
        var completed = 0
        var total = 0

        for system in systems {
            guard let tasks = system.tasks else { continue }

            for task in tasks {
                if task.shouldBeCompletedOn(date: startOfDay) {
                    total += 1
                    if task.wasCompletedOn(date: startOfDay) {
                        completed += 1
                    }
                }
            }
        }

        return (completed, total)
    }

    private func tasksForSystem(_ system: System) -> [HabitTask] {
        let startOfDay = calendar.startOfDay(for: date)
        guard let tasks = system.tasks else { return [] }

        return tasks.filter { task in
            task.shouldBeCompletedOn(date: startOfDay)
        }
    }

    private func completionRateColor(_ rate: Double, hasTask: Bool) -> Color {
        if !hasTask {
            return .gray
        }

        if rate >= 0.8 {
            return .green
        } else if rate >= 0.5 {
            return .yellow
        } else {
            return .red
        }
    }
}

// MARK: - System Tasks Section

struct SystemTasksSection: View {
    let system: System
    let date: Date
    let tasks: [HabitTask]

    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // System Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: system.color).opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: system.icon)
                        .font(.body)
                        .foregroundStyle(Color(hex: system.color))
                }

                Text(system.name)
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                let stats = systemStats
                Text("\(stats.completed)/\(stats.total)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Tasks
            VStack(spacing: 8) {
                ForEach(tasks) { task in
                    CalendarTaskRow(task: task, date: date)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var systemStats: (completed: Int, total: Int) {
        let startOfDay = calendar.startOfDay(for: date)
        var completed = 0
        let total = tasks.count

        for task in tasks {
            if task.wasCompletedOn(date: startOfDay) {
                completed += 1
            }
        }

        return (completed, total)
    }
}

// MARK: - Calendar Task Row

struct CalendarTaskRow: View {
    let task: HabitTask
    let date: Date

    private let calendar = Calendar.current

    var body: some View {
        HStack(spacing: 12) {
            // Completion Checkmark
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isCompleted ? .green : .gray)

            // Task Info
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let log = taskLog {
                    HStack(spacing: 8) {
                        if let notes = log.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        if let satisfaction = log.satisfaction {
                            HStack(spacing: 2) {
                                ForEach(0..<satisfaction, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.yellow)
                                }
                            }
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var isCompleted: Bool {
        let startOfDay = calendar.startOfDay(for: date)
        return task.wasCompletedOn(date: startOfDay)
    }

    private var taskLog: HabitTaskLog? {
        let startOfDay = calendar.startOfDay(for: date)
        guard let logs = task.logs else { return nil }

        return logs.first { log in
            calendar.isDate(log.date, inSameDayAs: startOfDay)
        }
    }
}

#Preview {
    DayDetailView(date: Date(), systems: [])
}
