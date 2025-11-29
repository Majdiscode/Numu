//
//  PerformanceMonitorView.swift
//  Numu
//
//  Real-time performance monitoring dashboard
//  Only available in DEBUG builds
//

import SwiftUI
import SwiftData

#if DEBUG

struct PerformanceMonitorView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var monitor = PerformanceMonitor.shared
    @State private var healthReport: SystemHealthReport?
    @State private var isRunningHealthCheck = false

    // Data counts
    @Query private var allSystems: [System]
    @Query private var allTasks: [HabitTask]
    @Query private var allLogs: [HabitTaskLog]

    var body: some View {
        List {
            // MARK: - Monitoring Status

            Section {
                HStack {
                    if monitor.isMonitoring {
                        Image(systemName: "circle.fill")
                            .foregroundStyle(.green)
                            .imageScale(.small)
                        Text("Monitoring Active")
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: "circle.fill")
                            .foregroundStyle(.gray)
                            .imageScale(.small)
                        Text("Monitoring Inactive")
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        if monitor.isMonitoring {
                            monitor.stopMonitoring()
                        } else {
                            monitor.startMonitoring()
                        }
                    } label: {
                        Text(monitor.isMonitoring ? "Stop" : "Start")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            } header: {
                Label("Monitoring Status", systemImage: "antenna.radiowaves.left.and.right")
            } footer: {
                Text("Enable monitoring to track real-time performance metrics.")
            }

            // MARK: - Real-Time Metrics

            if monitor.isMonitoring {
                Section {
                    MetricRow(
                        icon: "memorychip",
                        label: "Memory Usage",
                        value: String(format: "%.1f MB", monitor.memoryUsage),
                        status: monitor.memoryPressure.displayText,
                        statusColor: monitor.memoryPressure.color
                    )

                    MetricRow(
                        icon: "gauge.with.dots.needle.67percent",
                        label: "Frame Rate",
                        value: String(format: "%.1f FPS", monitor.frameRate),
                        status: monitor.frameRate > 50 ? "Smooth" : "Needs Attention",
                        statusColor: monitor.frameRate > 50 ? .green : .orange
                    )

                    MetricRow(
                        icon: "timer",
                        label: "Avg Frame Time",
                        value: String(format: "%.2f ms", monitor.averageFrameTime),
                        status: monitor.averageFrameTime < 16.67 ? "Good" : "Slow",
                        statusColor: monitor.averageFrameTime < 16.67 ? .green : .orange
                    )
                } header: {
                    Label("Real-Time Metrics", systemImage: "chart.xyaxis.line")
                }
            }

            // MARK: - Data Statistics

            Section {
                DataStatRow(label: "Systems", count: allSystems.count, icon: "gearshape.2")
                DataStatRow(label: "Tasks", count: allTasks.count, icon: "checklist")
                DataStatRow(label: "Completion Logs", count: allLogs.count, icon: "calendar.badge.checkmark")

                let testSystems = allSystems.filter { $0.name.contains("🧪") }.count
                let stressSystems = allSystems.filter { $0.name.contains("🔥") }.count

                if testSystems > 0 || stressSystems > 0 {
                    Divider()

                    if testSystems > 0 {
                        DataStatRow(label: "Test Systems (🧪)", count: testSystems, icon: "testtube.2")
                    }

                    if stressSystems > 0 {
                        DataStatRow(label: "Stress Test Systems (🔥)", count: stressSystems, icon: "flame.fill")
                    }
                }
            } header: {
                Label("Data Statistics", systemImage: "chart.bar.doc.horizontal")
            } footer: {
                Text("Current database record counts. Large datasets may impact performance.")
            }

            // MARK: - Health Check

            Section {
                if isRunningHealthCheck {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Running diagnostics...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button {
                        runHealthCheck()
                    } label: {
                        Label("Run System Health Check", systemImage: "stethoscope")
                    }
                }

                if let report = healthReport {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Overall Health")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(report.overallHealth)
                                .font(.caption)
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "memorychip")
                                    .foregroundStyle(.secondary)
                                    .imageScale(.small)
                                Text("Memory: \(String(format: "%.1f MB", report.memoryStatus.current))")
                                    .font(.caption)
                                Spacer()
                                Text(report.memoryStatus.pressure.displayText)
                                    .font(.caption)
                                    .foregroundStyle(report.memoryStatus.pressure.color)
                            }

                            HStack {
                                Image(systemName: "gauge.with.dots.needle.67percent")
                                    .foregroundStyle(.secondary)
                                    .imageScale(.small)
                                Text("Frame Rate: \(String(format: "%.1f FPS", report.frameRateStatus.current))")
                                    .font(.caption)
                                Spacer()
                                Image(systemName: report.frameRateStatus.isHealthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundStyle(report.frameRateStatus.isHealthy ? .green : .orange)
                                    .imageScale(.small)
                            }

                            if report.slowOperations > 0 {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundStyle(.orange)
                                        .imageScale(.small)
                                    Text("Slow Operations: \(report.slowOperations)")
                                        .font(.caption)
                                }
                            }
                        }

                        Divider()

                        HStack {
                            Text("Performance Grade")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(report.performanceGrade)
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Label("System Health", systemImage: "heart.text.square")
            } footer: {
                Text("Comprehensive diagnostics of app performance and stability.")
            }

            // MARK: - Performance Logs

            if !monitor.performanceLogs.isEmpty {
                Section {
                    ForEach(monitor.performanceLogs.reversed().prefix(20)) { log in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(log.event)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Spacer()
                                if let duration = log.formattedDuration {
                                    Text(duration)
                                        .font(.caption)
                                        .monospacedDigit()
                                        .foregroundStyle((log.duration ?? 0) < 0.05 ? .green : (log.duration ?? 0) < 0.1 ? .orange : .red)
                                }
                            }

                            HStack {
                                Text(log.formattedTime)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("Mem: \(String(format: "%.1f MB", log.memoryUsage))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    Button(role: .destructive) {
                        monitor.clearLogs()
                    } label: {
                        Label("Clear Logs", systemImage: "trash")
                    }
                } header: {
                    Label("Performance Logs (Recent 20)", systemImage: "list.bullet.rectangle")
                } footer: {
                    Text("Timed operations are logged automatically. Green = fast (<50ms), Orange = moderate (<100ms), Red = slow (>100ms).")
                }
            }

            // MARK: - Recommendations

            if let report = healthReport {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        if !report.memoryStatus.isHealthy {
                            RecommendationRow(
                                icon: "memorychip",
                                text: "High memory usage detected. Consider clearing stress test data or running on a device with more RAM.",
                                color: .orange
                            )
                        }

                        if !report.frameRateStatus.isHealthy {
                            RecommendationRow(
                                icon: "gauge",
                                text: "Low frame rate detected. Reduce complexity in UI or optimize heavy calculations.",
                                color: .orange
                            )
                        }

                        if report.slowOperations > 5 {
                            RecommendationRow(
                                icon: "exclamationmark.triangle",
                                text: "Multiple slow operations detected. Review performance logs to identify bottlenecks.",
                                color: .red
                            )
                        }

                        if allLogs.count > 10000 {
                            RecommendationRow(
                                icon: "cylinder",
                                text: "Large dataset detected (\(allLogs.count) logs). Consider implementing data archiving for older records.",
                                color: .blue
                            )
                        }

                        if report.memoryStatus.isHealthy && report.frameRateStatus.isHealthy && report.slowOperations == 0 {
                            RecommendationRow(
                                icon: "checkmark.circle",
                                text: "All systems operating normally. No performance issues detected.",
                                color: .green
                            )
                        }
                    }
                } header: {
                    Label("Recommendations", systemImage: "lightbulb")
                }
            }
        }
        .navigationTitle("Performance Monitor")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Auto-start monitoring when view appears
            if !monitor.isMonitoring {
                monitor.startMonitoring()
            }
        }
        .onDisappear {
            // Keep monitoring running in background
        }
    }

    // MARK: - Actions

    private func runHealthCheck() {
        isRunningHealthCheck = true

        // Ensure monitoring is active
        if !monitor.isMonitoring {
            monitor.startMonitoring()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            healthReport = monitor.runHealthCheck()
            isRunningHealthCheck = false
        }
    }
}

// MARK: - Supporting Views

private struct MetricRow: View {
    let icon: String
    let label: String
    let value: String
    let status: String
    let statusColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                    .imageScale(.small)
                Text(label)
                    .font(.caption)
                Spacer()
                Text(status)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(statusColor)
            }

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
    }
}

private struct DataStatRow: View {
    let label: String
    let count: Int
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .imageScale(.small)
            Text(label)
                .font(.caption)
            Spacer()
            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
    }
}

private struct RecommendationRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .imageScale(.small)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        PerformanceMonitorView()
            .modelContainer(for: [System.self, HabitTask.self, HabitTaskLog.self])
    }
}

#endif
