//
//  AnalyticsView.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//

import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var systems: [System]

    @State private var selectedTimeRange: TimeRange = .week

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Overall Trends (Chart at top)
                    overallTrendsSection

                    // MARK: - Overview Stats
                    overviewStats

                    // MARK: - Per-System Analytics
                    perSystemAnalytics
                }
                .padding()
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Overview Stats
    private var overviewStats: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 12) {
                StatCard(
                    title: "Total Systems",
                    value: "\(systems.count)",
                    icon: "gearshape.2.fill",
                    color: .blue
                )

                StatCard(
                    title: "Active Tasks",
                    value: "\(totalActiveTasks)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                StatCard(
                    title: "Tests",
                    value: "\(totalTests)",
                    icon: "chart.bar.fill",
                    color: .purple
                )
            }
        }
    }

    // MARK: - Per-System Analytics
    private var perSystemAnalytics: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Systems")
                .font(.title2)
                .fontWeight(.bold)

            if systems.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "gearshape.2")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)

                    Text("No systems yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("Create a system to track tasks and tests")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
            } else {
                ForEach(systems) { system in
                    SystemAnalyticsCard(system: system, selectedTimeRange: $selectedTimeRange)
                }
            }
        }
    }

    // MARK: - Overall Trends Section
    private var overallTrendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                Text("Completion Trend")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                // Time range picker
                Picker("Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.displayText).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }

            VStack(spacing: 16) {
                if completionData.isEmpty {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)

                        Text("No data yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("Complete tasks to see your trend")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    // Chart
                    Chart(completionData) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Completion %", dataPoint.completionRate * 100)
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                        // Area under the line
                        AreaMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Completion %", dataPoint.completionRate * 100)
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    .chartYScale(domain: 0...100)
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let intValue = value.as(Int.self) {
                                    Text("\(intValue)%")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            AxisGridLine()
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel(format: .dateTime.month().day())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(height: 200)

                    // Stats below chart
                    HStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Average")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(Int(averageCompletionRate * 100))%")
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Best Day")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(Int(bestCompletionRate * 100))%")
                                .font(.headline)
                                .foregroundStyle(.green)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Trend")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 4) {
                                Image(systemName: trendDirection.icon)
                                    .font(.caption)
                                Text(trendDirection.text)
                                    .font(.headline)
                            }
                            .foregroundStyle(trendDirection.color)
                        }

                        Spacer()
                    }
                    .padding(.top, 8)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
    }

    // MARK: - Computed Properties
    private var totalActiveTasks: Int {
        systems.reduce(0) { $0 + ($1.tasks?.count ?? 0) }
    }

    private var totalTests: Int {
        systems.reduce(0) { $0 + ($1.tests?.count ?? 0) }
    }

    // MARK: - Completion Data (Overall)

    /// Calculate daily completion rates for the selected time range (across ALL systems)
    private var completionData: [CompletionDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        let daysToShow = selectedTimeRange.days

        var dataPoints: [CompletionDataPoint] = []

        for dayOffset in (0..<daysToShow).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: date)

            // Calculate completion rate for this day across all systems
            var totalTasksDue = 0
            var totalCompleted = 0

            for system in systems {
                guard let tasks = system.tasks else { continue }

                for task in tasks {
                    // Check if task was due on this day
                    if task.shouldBeCompletedOn(date: startOfDay) {
                        totalTasksDue += 1

                        // Check if task was completed on this day
                        if task.wasCompletedOn(date: startOfDay) {
                            totalCompleted += 1
                        }
                    }
                }
            }

            let completionRate = totalTasksDue > 0 ? Double(totalCompleted) / Double(totalTasksDue) : 0.0

            // Only add data points where there were tasks due
            if totalTasksDue > 0 {
                dataPoints.append(CompletionDataPoint(date: startOfDay, completionRate: completionRate))
            }
        }

        return dataPoints
    }

    private var averageCompletionRate: Double {
        guard !completionData.isEmpty else { return 0.0 }
        let sum = completionData.reduce(0.0) { $0 + $1.completionRate }
        return sum / Double(completionData.count)
    }

    private var bestCompletionRate: Double {
        completionData.map { $0.completionRate }.max() ?? 0.0
    }

    private var trendDirection: TrendDirection {
        guard completionData.count >= 2 else { return .stable }

        let halfPoint = completionData.count / 2
        let firstHalf = completionData.prefix(halfPoint)
        let secondHalf = completionData.suffix(halfPoint)

        let firstAverage = firstHalf.isEmpty ? 0 : firstHalf.reduce(0.0) { $0 + $1.completionRate } / Double(firstHalf.count)
        let secondAverage = secondHalf.isEmpty ? 0 : secondHalf.reduce(0.0) { $0 + $1.completionRate } / Double(secondHalf.count)

        let difference = secondAverage - firstAverage

        if difference > 0.05 {
            return .improving
        } else if difference < -0.05 {
            return .declining
        } else {
            return .stable
        }
    }
}

// MARK: - System Analytics Card
struct SystemAnalyticsCard: View {
    let system: System
    @Binding var selectedTimeRange: TimeRange

    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible)
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    // System icon
                    ZStack {
                        Circle()
                            .fill(Color(hex: system.color).opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: system.icon)
                            .font(.title3)
                            .foregroundStyle(Color(hex: system.color))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(system.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        HStack(spacing: 12) {
                            Label("\(system.tasks?.count ?? 0) tasks", systemImage: "checkmark.circle")
                            Label("\(system.tests?.count ?? 0) tests", systemImage: "chart.bar")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Expand/collapse indicator
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding()
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                VStack(spacing: 20) {
                    Divider()

                    // System completion chart
                    SystemCompletionChart(system: system, timeRange: selectedTimeRange)
                        .padding(.horizontal)

                    // Individual task charts/stats
                    if let tasks = system.tasks, !tasks.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tasks")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.horizontal)

                            ForEach(tasks) { task in
                                TaskAnalyticsRow(task: task, timeRange: selectedTimeRange)
                                    .padding(.horizontal)
                            }
                        }
                    }

                    // Individual test charts
                    if let tests = system.tests, !tests.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tests")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.horizontal)

                            ForEach(tests) { test in
                                TestPerformanceCard(test: test)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

// MARK: - System Completion Chart
struct SystemCompletionChart: View {
    let system: System
    let timeRange: TimeRange

    private var completionData: [CompletionDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        let daysToShow = timeRange.days

        var dataPoints: [CompletionDataPoint] = []

        for dayOffset in (0..<daysToShow).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: date)

            guard let tasks = system.tasks else { continue }

            var tasksDue = 0
            var tasksCompleted = 0

            for task in tasks {
                if task.shouldBeCompletedOn(date: startOfDay) {
                    tasksDue += 1
                    if task.wasCompletedOn(date: startOfDay) {
                        tasksCompleted += 1
                    }
                }
            }

            if tasksDue > 0 {
                let rate = Double(tasksCompleted) / Double(tasksDue)
                dataPoints.append(CompletionDataPoint(date: startOfDay, completionRate: rate))
            }
        }

        return dataPoints
    }

    private var averageCompletion: Double {
        guard !completionData.isEmpty else { return 0.0 }
        return completionData.reduce(0.0) { $0 + $1.completionRate } / Double(completionData.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("System Completion")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(Int(averageCompletion * 100))% avg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if completionData.isEmpty {
                Text("No task completion data for this period")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                Chart(completionData) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Completion", dataPoint.completionRate * 100)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(Color(hex: system.color))
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))

                    AreaMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Completion", dataPoint.completionRate * 100)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(Color(hex: system.color).opacity(0.2))
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)%")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        AxisGridLine()
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel(format: .dateTime.month().day())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: 120)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Task Analytics Row
struct TaskAnalyticsRow: View {
    let task: HabitTask
    let timeRange: TimeRange

    private var completionStats: (completed: Int, due: Int, rate: Double) {
        let calendar = Calendar.current
        let now = Date()
        let daysToShow = timeRange.days

        var tasksDue = 0
        var tasksCompleted = 0

        for dayOffset in 0..<daysToShow {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: date)

            if task.shouldBeCompletedOn(date: startOfDay) {
                tasksDue += 1
                if task.wasCompletedOn(date: startOfDay) {
                    tasksCompleted += 1
                }
            }
        }

        let rate = tasksDue > 0 ? Double(tasksCompleted) / Double(tasksDue) : 0.0
        return (tasksCompleted, tasksDue, rate)
    }

    private var completionRate: Double {
        completionStats.rate
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    Label(task.frequency.displayText, systemImage: "calendar")

                    if task.currentStreak > 0 {
                        Label("\(task.currentStreak) day", systemImage: "flame.fill")
                            .foregroundStyle(.orange)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Completion rate
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(completionStats.completed)/\(completionStats.due)")
                    .font(.headline)
                    .foregroundStyle(completionRate >= 0.8 ? .green : completionRate >= 0.5 ? .orange : .red)

                Text("\(Int(completionRate * 100))% consistency")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Supporting Types

struct CompletionDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let completionRate: Double
}

enum TimeRange: CaseIterable {
    case week
    case twoWeeks
    case month

    var days: Int {
        switch self {
        case .week: return 7
        case .twoWeeks: return 14
        case .month: return 30
        }
    }

    var displayText: String {
        switch self {
        case .week: return "7D"
        case .twoWeeks: return "14D"
        case .month: return "30D"
        }
    }
}

enum TrendDirection {
    case improving
    case stable
    case declining

    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }

    var text: String {
        switch self {
        case .improving: return "Improving"
        case .stable: return "Stable"
        case .declining: return "Declining"
        }
    }

    var color: Color {
        switch self {
        case .improving: return .green
        case .stable: return .blue
        case .declining: return .orange
        }
    }
}

// MARK: - Test Performance Card
struct TestPerformanceCard: View {
    let test: PerformanceTest

    var testData: [PerformanceTestDataPoint] {
        guard let entries = test.entries, !entries.isEmpty else { return [] }

        return entries
            .sorted { $0.date < $1.date }
            .map { entry in
                PerformanceTestDataPoint(date: entry.date, value: entry.value)
            }
    }

    var systemConsistency: Double {
        test.system?.overallConsistency ?? 0.0
    }

    var analytics: PerformanceTestAnalytics {
        test.getAnalytics(systemConsistency: systemConsistency)
    }

    // Helper to format time values (seconds -> MM:SS)
    private func formatTimeValue(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60
        return "\(minutes):\(String(format: "%02d", remainingSeconds))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(test.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(test.trackingFrequency.displayText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Latest value
                if let latest = analytics.latestValue {
                    VStack(alignment: .trailing, spacing: 2) {
                        if test.unit == "time" {
                            Text(formatTimeValue(latest))
                                .font(.title3)
                                .fontWeight(.bold)
                        } else {
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text(String(format: "%.1f", latest))
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text(test.unit)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text("Latest")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if testData.isEmpty {
                // Empty state
                Text("No entries yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                // Chart
                Chart(testData) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value(test.unit, dataPoint.value)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(.purple)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                    PointMark(
                        x: .value("Date", dataPoint.date),
                        y: .value(test.unit, dataPoint.value)
                    )
                    .foregroundStyle(.purple)
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel(format: .dateTime.month().day())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel()
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        AxisGridLine()
                    }
                }
                .frame(height: 120)

                // Stats
                HStack(spacing: 16) {
                    if let improvement = analytics.improvement {
                        // Determine if improvement is positive based on goal direction
                        let isImproving: Bool = {
                            switch test.goalDirection {
                            case .higher:
                                return improvement > 0  // Higher is better, so positive change is good
                            case .lower:
                                return improvement < 0  // Lower is better, so negative change is good
                            }
                        }()

                        HStack(spacing: 4) {
                            Image(systemName: improvement > 0 ? "arrow.up" : "arrow.down")
                                .font(.caption2)
                            Text(String(format: "%.1f%%", abs(improvement)))
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(isImproving ? .green : .red)
                    }

                    Spacer()
                }

                // Insight message
                if testData.count >= 3 {
                    Text(analytics.consistencyCorrelation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct PerformanceTestDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}
