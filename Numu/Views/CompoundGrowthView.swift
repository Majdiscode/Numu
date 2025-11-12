//
//  CompoundGrowthView.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//

import SwiftUI
import SwiftData
import Charts

struct CompoundGrowthView: View {
    let habit: Habit

    private var analytics: MetricAnalytics {
        habit.getMetricAnalytics()
    }

    private var metricConfig: MetricConfig? {
        habit.metricConfig
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Header
                header

                // MARK: - Key Insights
                if analytics.entries.count >= 2 {
                    keyInsights
                }

                // MARK: - Progress Chart
                if analytics.entries.count >= 2 {
                    progressChart
                }

                // MARK: - Consistency Correlation
                if analytics.entries.count >= 3 {
                    consistencyCorrelation
                }

                // MARK: - Compound Effect Projection
                if analytics.entries.count >= 2 {
                    compoundProjection
                }

                // MARK: - All Entries
                allEntries
            }
            .padding()
        }
        .navigationTitle("Outcome Tracking")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 12) {
            if let config = metricConfig {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(config.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Tracked \(config.trackingFrequency.displayText.lowercased())")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: config.goalDirection.systemIcon)
                        .font(.title)
                        .foregroundStyle(Color(hex: habit.color))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    // MARK: - Key Insights
    private var keyInsights: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                if let latest = analytics.latestValue, let config = metricConfig {
                    InsightCard(
                        title: "Current",
                        value: String(format: "%.1f", latest),
                        unit: config.unit,
                        color: Color(hex: habit.color),
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }

                if let improvement = analytics.improvement {
                    InsightCard(
                        title: "Change",
                        value: String(format: "%.1f%%", abs(improvement)),
                        unit: improvement > 0 ? "↑" : "↓",
                        color: improvement > 0 ? .green : .red,
                        icon: analytics.trend.icon
                    )
                }
            }

            HStack(spacing: 16) {
                InsightCard(
                    title: "Consistency",
                    value: String(format: "%.0f%%", analytics.consistencyRate * 100),
                    unit: "",
                    color: .blue,
                    icon: "calendar.badge.checkmark"
                )

                if let best = analytics.bestValue, let config = metricConfig {
                    InsightCard(
                        title: "Best",
                        value: String(format: "%.1f", best),
                        unit: config.unit,
                        color: .yellow,
                        icon: "trophy.fill"
                    )
                }
            }
        }
    }

    // MARK: - Progress Chart
    private var progressChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Progress Over Time", systemImage: "chart.xyaxis.line")
                .font(.headline)

            if let config = metricConfig {
                Chart {
                    ForEach(analytics.entries.sorted(by: { $0.date < $1.date }), id: \.id) { entry in
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("Value", entry.value)
                        )
                        .foregroundStyle(Color(hex: habit.color))
                        .lineStyle(StrokeStyle(lineWidth: 3))

                        PointMark(
                            x: .value("Date", entry.date),
                            y: .value("Value", entry.value)
                        )
                        .foregroundStyle(Color(hex: habit.color))
                        .symbolSize(100)
                    }
                }
                .chartYAxisLabel(config.unit)
                .frame(height: 200)
            }

            Text("Each point represents a measurement. The line shows your trajectory.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    // MARK: - Consistency Correlation
    private var consistencyCorrelation: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("System → Results", systemImage: "arrow.right.circle.fill")
                .font(.headline)

            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your System")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("\(Int(analytics.consistencyRate * 100))% consistent")
                            .font(.title3)
                            .fontWeight(.bold)
                    }

                    Spacer()

                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Your Results")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let improvement = analytics.improvement {
                            Text("\(String(format: "%.1f%%", abs(improvement))) change")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                    }
                }

                Divider()

                Text(analytics.consistencyCorrelation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("\"You do not rise to the level of your goals. You fall to the level of your systems.\" - James Clear")
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    // MARK: - Compound Projection
    private var compoundProjection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Compound Effect", systemImage: "chart.line.uptrend.xyaxis.circle.fill")
                .font(.headline)

            VStack(spacing: 16) {
                Text("If you maintain your current consistency...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // 90 day projection
                if let currentRate = analytics.improvement,
                   let latest = analytics.latestValue,
                   let config = metricConfig {

                    let daysTracked = Calendar.current.dateComponents([.day],
                        from: analytics.entries.sorted(by: { $0.date < $1.date }).first!.date,
                        to: Date()
                    ).day ?? 1
                    let dailyChangeRate = currentRate / Double(max(daysTracked, 1))
                    let projectedChange90Days = dailyChangeRate * 90
                    let projected90DayValue = latest * (1 + (projectedChange90Days / 100))

                    Group {
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("In 30 days")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Text(String(format: "%.1f %@", latest * (1 + (dailyChangeRate * 30 / 100)), config.unit))
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("In 90 days")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Text(String(format: "%.1f %@", projected90DayValue, config.unit))
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color(hex: habit.color))
                                }
                            }

                            Text("Small consistent improvements compound over time. 1% better each day = 37x better in a year.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .italic()
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color(hex: habit.color).opacity(0.1), Color(.systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: habit.color).opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - All Entries
    private var allEntries: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("All Entries", systemImage: "list.bullet")
                .font(.headline)

            if analytics.entries.isEmpty {
                Text("No entries yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(analytics.entries.sorted(by: { $0.date > $1.date }), id: \.id) { entry in
                    MetricEntryRow(entry: entry, config: metricConfig)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Insight Card Component
struct InsightCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Metric Entry Row
struct MetricEntryRow: View {
    let entry: MetricEntry
    let config: MetricConfig?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(String(format: "%.1f", entry.value))
                        .font(.headline)

                    if let config = config {
                        Text(config.unit)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(dateString(for: entry.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let conditions = entry.conditions {
                    Text(conditions)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }

            Spacer()

            if let notes = entry.notes, !notes.isEmpty {
                Image(systemName: "note.text")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

