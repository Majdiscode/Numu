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
                    // MARK: - Overview Stats
                    overviewStats

                    // MARK: - Completion Chart Section
                    completionChartSection

                    // MARK: - Test Performance Section
                    testPerformanceSection

                    // MARK: - Streak Section
                    streakSection
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

    // MARK: - Completion Chart Section
    private var completionChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Completion Trend")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                // Time range picker
                Picker("Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.displayText).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
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

    // MARK: - Test Performance Section (Placeholder)
    private var testPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test Performance")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 16) {
                Text("Test Charts Coming in Stage 3")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
    }

    // MARK: - Streak Section (Placeholder)
    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Streaks & Consistency")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 16) {
                Text("Streak Visualization Coming in Stage 4")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
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

    // MARK: - Completion Data

    /// Calculate daily completion rates for the selected time range
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
