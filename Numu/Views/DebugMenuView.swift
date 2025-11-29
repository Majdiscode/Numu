//
//  DebugMenuView.swift
//  Numu
//
//  Debug menu for testing features with generated data
//  Only available in DEBUG builds
//

import SwiftUI
import SwiftData

#if DEBUG

struct DebugMenuView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Binding var isDeletingTestData: Bool

    @State private var showClearConfirmation = false
    @State private var showClearStressTestConfirmation = false
    @State private var generatingData = false

    // Stress testing
    @State private var selectedStressLevel: StressTestGenerator.StressLevel = .medium
    @State private var isRunningStressTest = false
    @State private var stressTestProgress: Double = 0
    @State private var stressTestStatus: String = ""
    @State private var showPerformanceMonitor = false

    // Benchmarks
    @State private var benchmarkResults: PerformanceBenchmark?
    @State private var isRunningBenchmark = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("⚠️ This menu is only available in debug builds")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Label("Debug Mode", systemImage: "exclamationmark.triangle")
                }

                // MARK: - Basic Test Data

                Section {
                    Button {
                        generateTestData()
                    } label: {
                        Label("Generate Test Data", systemImage: "testtube.2")
                    }
                    .disabled(generatingData)
                } header: {
                    Label("Basic Test Data", systemImage: "wand.and.stars")
                } footer: {
                    Text("Creates 5 test systems showcasing all features:\n• Perfect Athlete (100% celebration)\n• Never Miss Twice (streak grace days)\n• Weekly Goals (progress tracking)\n• At-Risk Streaks (warning states)\n• Calendar Heat Map (green/yellow/red weeks)\n\nCheck the Calendar tab to see green weeks!")
                }

                // MARK: - Stress Testing

                Section {
                    if isRunningStressTest {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                ProgressView(value: stressTestProgress)
                                Text("\(Int(stressTestProgress * 100))%")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 40)
                            }

                            Text(stressTestStatus)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    } else {
                        Picker("Stress Level", selection: $selectedStressLevel) {
                            ForEach([StressTestGenerator.StressLevel.light, .medium, .heavy, .extreme], id: \.self) { level in
                                Text(level.displayName).tag(level)
                            }
                        }

                        Text(selectedStressLevel.expectedDataCount)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button {
                            runStressTest()
                        } label: {
                            Label("Run Stress Test", systemImage: "flame.fill")
                                .foregroundStyle(.orange)
                        }
                        .disabled(isRunningStressTest)
                    }

                    Button {
                        runRapidOperationsTest()
                    } label: {
                        Label("Test Rapid Operations", systemImage: "bolt.fill")
                    }
                    .disabled(isRunningStressTest)

                    Button {
                        runWeekBoundaryTest()
                    } label: {
                        Label("Test Week Boundaries", systemImage: "calendar")
                    }
                    .disabled(isRunningStressTest)

                    Button {
                        runStreakEdgeCasesTest()
                    } label: {
                        Label("Test Streak Edge Cases", systemImage: "repeat.circle")
                    }
                    .disabled(isRunningStressTest)

                    Button(role: .destructive) {
                        showClearStressTestConfirmation = true
                    } label: {
                        Label("Clear Stress Test Data", systemImage: "trash")
                    }
                    .disabled(isRunningStressTest)
                } header: {
                    Label("Stress Testing", systemImage: "flame.fill")
                } footer: {
                    Text("Stress tests validate app performance under extreme conditions. Data is marked with 🔥 emoji.")
                }

                // MARK: - Performance Monitoring

                Section {
                    NavigationLink {
                        PerformanceMonitorView()
                    } label: {
                        Label("Performance Monitor", systemImage: "chart.xyaxis.line")
                    }

                    if isRunningBenchmark {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Running benchmarks...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Button {
                            runBenchmark()
                        } label: {
                            Label("Run Performance Benchmark", systemImage: "speedometer")
                        }
                    }

                    if let results = benchmarkResults {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Latest Benchmark Results")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text(results.grade)
                                    .font(.caption)
                                    .foregroundStyle(results.isHealthy ? .green : .orange)
                            }

                            Divider()

                            BenchmarkRow(label: "Streak Calc", time: results.streakCalculation)
                            BenchmarkRow(label: "Completion Rate", time: results.completionRate)
                            BenchmarkRow(label: "Weekly Count", time: results.weeklyCompletions)
                            BenchmarkRow(label: "System Consistency", time: results.systemConsistency)
                            BenchmarkRow(label: "Query Performance", time: results.queryPerformance)

                            Divider()

                            HStack {
                                Text("Total Time")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text(String(format: "%.2fms", results.totalTime * 1000))
                                    .font(.caption)
                                    .monospacedDigit()
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Label("Performance", systemImage: "speedometer")
                } footer: {
                    Text("Monitor real-time performance metrics and run benchmarks to validate app speed.")
                }

                // MARK: - Clear Data

                Section {
                    Button(role: .destructive) {
                        showClearConfirmation = true
                    } label: {
                        Label("Clear All Test Data", systemImage: "trash")
                    }
                } header: {
                    Label("Clear Data", systemImage: "eraser")
                } footer: {
                    Text("Removes all systems marked with 🧪 emoji. Your real data is safe.")
                }

                // MARK: - Info

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🧪 = Basic test data (5 systems)")
                            .font(.caption)
                        Text("🔥 = Stress test data (large scale)")
                            .font(.caption)
                        Text("• Use basic test data to preview features")
                            .font(.caption)
                        Text("• Use stress tests to validate performance")
                            .font(.caption)
                        Text("• Monitor real-time metrics during testing")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                } header: {
                    Label("How It Works", systemImage: "info.circle")
                }
            }
            .navigationTitle("Debug Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Clear Test Data?", isPresented: $showClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    clearTestData()
                }
            } message: {
                Text("This will delete all systems marked with 🧪. Your real data will not be affected.")
            }
            .alert("Clear Stress Test Data?", isPresented: $showClearStressTestConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    clearStressTestData()
                }
            } message: {
                Text("This will delete all systems marked with 🔥. This may take a moment for large datasets.")
            }
        }
    }

    // MARK: - Actions

    private func generateTestData() {
        generatingData = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let generator = TestDataGenerator(modelContext: modelContext)
            generator.generateMultipleTestSystems()

            generatingData = false
        }
    }

    private func clearTestData() {
        // Capture context before dismissing
        let context = modelContext

        // Show loading overlay on parent view
        isDeletingTestData = true

        // Dismiss this sheet
        dismiss()

        // Delete after sheet animation completes (0.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let generator = TestDataGenerator(modelContext: context)
            generator.clearTestData()

            // Hide loading overlay after deletion completes (give @Query time to update)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isDeletingTestData = false
            }
        }
    }

    // MARK: - Stress Testing

    private func runStressTest() {
        isRunningStressTest = true
        stressTestProgress = 0
        stressTestStatus = "Initializing..."

        Task {
            let generator = StressTestGenerator(modelContext: modelContext)

            generator.generateStressTest(level: selectedStressLevel) { progress, status in
                DispatchQueue.main.async {
                    stressTestProgress = progress
                    stressTestStatus = status
                }
            }

            DispatchQueue.main.async {
                isRunningStressTest = false
                stressTestStatus = ""
            }
        }
    }

    private func runRapidOperationsTest() {
        Task {
            let generator = StressTestGenerator(modelContext: modelContext)
            generator.testRapidOperations()
        }
    }

    private func runWeekBoundaryTest() {
        Task {
            let generator = StressTestGenerator(modelContext: modelContext)
            generator.testWeekBoundaries()
        }
    }

    private func runStreakEdgeCasesTest() {
        Task {
            let generator = StressTestGenerator(modelContext: modelContext)
            generator.testNeverMissTwiceEdgeCases()
        }
    }

    private func clearStressTestData() {
        let context = modelContext

        isDeletingTestData = true
        dismiss()

        Task {
            let generator = StressTestGenerator(modelContext: context)

            generator.clearStressTestData { progress, status in
                // Only log milestones (0%, 25%, 50%, 75%, 100%)
                let percentage = Int(progress * 100)
                if percentage % 25 == 0 || progress == 1.0 {
                    print("🗑️ [\(percentage)%] \(status)")
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isDeletingTestData = false
            }
        }
    }

    // MARK: - Performance Benchmarking

    private func runBenchmark() {
        isRunningBenchmark = true

        Task {
            let generator = StressTestGenerator(modelContext: modelContext)
            let results = generator.benchmarkPerformance()

            DispatchQueue.main.async {
                benchmarkResults = results
                isRunningBenchmark = false
            }
        }
    }
}

// MARK: - Supporting Views

private struct BenchmarkRow: View {
    let label: String
    let time: TimeInterval

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
            Spacer()
            Text(String(format: "%.2fms", time * 1000))
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(time < 0.05 ? .green : time < 0.1 ? .orange : .red)
        }
    }
}

#Preview {
    DebugMenuView(isDeletingTestData: .constant(false))
}

#endif
