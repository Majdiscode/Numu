//
//  WeekSummaryView.swift
//  Numu
//
//  Summary view showing weekly goals progress for a specific week
//

import SwiftUI
import SwiftData

struct WeekSummaryView: View {
    let weekStart: Date
    let systems: [System]

    @Environment(\.dismiss) private var dismiss

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Week Overview Card
                    weekOverviewCard

                    // Daily Breakdown
                    dailyBreakdownSection

                    // Weekly Goals by System
                    ForEach(systems) { system in
                        if !weeklyTasksForSystem(system).isEmpty {
                            SystemWeeklyGoalsSection(system: system, weekStart: weekStart, tasks: weeklyTasksForSystem(system))
                        }
                    }

                    // Summary Stats
                    weekSummaryStats
                }
                .padding()
            }
            .navigationTitle(weekTitle)
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

    // MARK: - Week Overview Card

    private var weekOverviewCard: some View {
        let stats = weekStatistics
        let completionRate = stats.target > 0 ? Double(stats.completed) / Double(stats.target) : 0
        let color = weekCompletionColor(completionRate, hasGoals: stats.target > 0)

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
                    Text("\(stats.target)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Target")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text(stats.target == 0 ? "No goals" : weekStatusText(completionRate))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(color)
                    Text("Status")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text("Weekly Goals Progress")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color, lineWidth: 2)
        )
    }

    // MARK: - Daily Breakdown

    private var dailyBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Breakdown")
                .font(.headline)
                .fontWeight(.bold)

            HStack(spacing: 8) {
                ForEach(daysInWeek, id: \.self) { date in
                    DayCircleView(date: date, systems: systems)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Week Summary Stats

    private var weekSummaryStats: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Week Summary")
                .font(.headline)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                let dailyStats = weekDailyStats
                let dailyRate = dailyStats.total > 0 ? Double(dailyStats.completed) / Double(dailyStats.total) : 0

                StatRow(label: "Daily Tasks", value: "\(dailyStats.completed)/\(dailyStats.total)", percentage: dailyRate)
                StatRow(label: "Weekly Goals", value: "\(weekStatistics.completed)/\(weekStatistics.target)", percentage: weekStatistics.target > 0 ? Double(weekStatistics.completed) / Double(weekStatistics.target) : 0)
                StatRow(label: "Best Day", value: bestDayText)
                StatRow(label: "Total Completions", value: "\(dailyStats.completed + weekStatistics.completed)")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private var weekTitle: String {
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        return "\(formatter.string(from: weekStart)) - \(formatter.string(from: weekEnd))"
    }

    private var daysInWeek: [Date] {
        var days: [Date] = []
        for dayOffset in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) {
                days.append(day)
            }
        }
        return days
    }

    private func weeklyTasksForSystem(_ system: System) -> [HabitTask] {
        guard let tasks = system.tasks else { return [] }
        return tasks.filter { task in
            if case .weeklyTarget = task.frequency {
                return true
            }
            return false
        }
    }

    private var weekStatistics: (completed: Int, target: Int) {
        var completed = 0
        var target = 0

        for system in systems {
            guard let tasks = system.tasks else { continue }

            for task in tasks {
                if case .weeklyTarget(let times) = task.frequency {
                    target += times
                    let completions = task.completionsInWeek(containing: weekStart)
                    completed += min(completions, times)
                }
            }
        }

        return (completed, target)
    }

    private var weekDailyStats: (completed: Int, total: Int) {
        var completed = 0
        var total = 0

        for day in daysInWeek {
            let startOfDay = calendar.startOfDay(for: day)

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
        }

        return (completed, total)
    }

    private var bestDayText: String {
        var bestDay: Date?
        var bestRate: Double = 0

        for day in daysInWeek {
            let startOfDay = calendar.startOfDay(for: day)
            var dayTotal = 0
            var dayCompleted = 0

            for system in systems {
                guard let tasks = system.tasks else { continue }

                for task in tasks {
                    if task.shouldBeCompletedOn(date: startOfDay) {
                        dayTotal += 1
                        if task.wasCompletedOn(date: startOfDay) {
                            dayCompleted += 1
                        }
                    }
                }
            }

            if dayTotal > 0 {
                let rate = Double(dayCompleted) / Double(dayTotal)
                if rate > bestRate {
                    bestRate = rate
                    bestDay = day
                }
            }
        }

        if let best = bestDay {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: best)
        }

        return "N/A"
    }

    private func weekStatusText(_ rate: Double) -> String {
        if rate >= 0.8 {
            return "Excellent!"
        } else if rate >= 0.5 {
            return "Good"
        } else if rate > 0 {
            return "Keep going"
        } else {
            return "Not started"
        }
    }

    private func weekCompletionColor(_ rate: Double, hasGoals: Bool) -> Color {
        if !hasGoals {
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

// MARK: - Day Circle View

struct DayCircleView: View {
    let date: Date
    let systems: [System]

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 4) {
            Text(date, format: .dateTime.weekday(.narrow))
                .font(.caption2)
                .foregroundStyle(.secondary)

            Circle()
                .fill(dayColor)
                .frame(width: 32, height: 32)
                .overlay(
                    Text(date, format: .dateTime.day())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(dayColor == .gray.opacity(0.3) ? .secondary : .white)
                )
        }
        .frame(maxWidth: .infinity)
    }

    private var dayColor: Color {
        let startOfDay = calendar.startOfDay(for: date)

        if startOfDay > calendar.startOfDay(for: Date()) {
            return .gray.opacity(0.3)
        }

        var total = 0
        var completed = 0

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

        if total == 0 {
            return .gray.opacity(0.3)
        }

        let rate = Double(completed) / Double(total)

        if rate >= 0.8 {
            return .green
        } else if rate >= 0.5 {
            return .yellow
        } else {
            return .red
        }
    }
}

// MARK: - System Weekly Goals Section

struct SystemWeeklyGoalsSection: View {
    let system: System
    let weekStart: Date
    let tasks: [HabitTask]

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
            }

            // Weekly Tasks
            VStack(spacing: 8) {
                ForEach(tasks) { task in
                    WeeklyTaskRow(task: task, weekStart: weekStart)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Weekly Task Row

struct WeeklyTaskRow: View {
    let task: HabitTask
    let weekStart: Date

    var body: some View {
        HStack(spacing: 12) {
            if case .weeklyTarget(let times) = task.frequency {
                let completions = task.completionsInWeek(containing: weekStart)
                let isComplete = completions >= times

                // Progress Circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                        .frame(width: 32, height: 32)

                    Circle()
                        .trim(from: 0, to: min(1.0, Double(completions) / Double(times)))
                        .stroke(isComplete ? Color.green : Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(-90))

                    Image(systemName: isComplete ? "checkmark" : "")
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                // Task Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.name)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("\(completions)/\(times) completed")
                        .font(.caption)
                        .foregroundStyle(isComplete ? .green : .secondary)
                }

                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Stat Row

struct StatRow: View {
    let label: String
    let value: String
    var percentage: Double? = nil

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            if let percentage = percentage {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("(\(Int(percentage * 100))%)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
    }
}

#Preview {
    WeekSummaryView(weekStart: Date(), systems: [])
}
