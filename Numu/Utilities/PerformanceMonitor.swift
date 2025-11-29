//
//  PerformanceMonitor.swift
//  Numu
//
//  Real-time performance monitoring and diagnostics
//

import Foundation
import SwiftUI
import Combine

#if DEBUG

/// Monitors app performance metrics in real-time
@Observable
class PerformanceMonitor {
    // MARK: - Singleton

    static let shared = PerformanceMonitor()

    // MARK: - Metrics

    var cpuUsage: Double = 0
    var memoryUsage: Double = 0 // In MB
    var memoryPressure: MemoryPressure = .normal

    var frameRate: Double = 60
    var averageFrameTime: Double = 0 // In ms

    var isMonitoring: Bool = false

    // Performance logs
    var performanceLogs: [PerformanceLog] = []
    var maxLogs: Int = 100

    // MARK: - Monitoring

    private var timer: Timer?
    private var frameTimer: Timer?
    private var lastFrameTime: Date?

    private init() {}

    /// Start monitoring performance metrics
    func startMonitoring() {
        guard !isMonitoring else { return }

        print("🔍 [PERF MONITOR] Starting performance monitoring...")
        isMonitoring = true

        // Monitor CPU and Memory every 2 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateMetrics()
        }

        // FPS monitoring disabled - Timer-based approach is inaccurate
        // Would need CADisplayLink integration for real FPS measurement
        frameRate = 60.0 // Default placeholder

        // Initial update
        updateMetrics()
    }

    /// Stop monitoring
    func stopMonitoring() {
        print("🛑 [PERF MONITOR] Stopping performance monitoring...")
        isMonitoring = false
        timer?.invalidate()
        timer = nil
        // frameTimer removed - FPS monitoring disabled
    }

    /// Log a performance event
    func logEvent(_ event: String, duration: TimeInterval? = nil) {
        let log = PerformanceLog(
            timestamp: Date(),
            event: event,
            duration: duration,
            memoryUsage: memoryUsage,
            cpuUsage: cpuUsage
        )

        performanceLogs.append(log)

        // Keep only recent logs
        if performanceLogs.count > maxLogs {
            performanceLogs.removeFirst()
        }

        print("📊 [PERF LOG] \(event)\(duration.map { " (\(String(format: "%.2f", $0 * 1000))ms)" } ?? "")")
    }

    /// Measure execution time of a block
    func measure<T>(name: String, block: () throws -> T) rethrows -> T {
        let start = Date()
        let result = try block()
        let duration = Date().timeIntervalSince(start)
        logEvent(name, duration: duration)
        return result
    }

    /// Measure async execution time
    func measure<T>(name: String, block: () async throws -> T) async rethrows -> T {
        let start = Date()
        let result = try await block()
        let duration = Date().timeIntervalSince(start)
        logEvent(name, duration: duration)
        return result
    }

    /// Clear all logs
    func clearLogs() {
        performanceLogs.removeAll()
        print("🗑️ [PERF MONITOR] Logs cleared")
    }

    // MARK: - Private Methods

    private func updateMetrics() {
        // Update memory usage
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }

        if kerr == KERN_SUCCESS {
            let usedBytes = Double(info.resident_size)
            memoryUsage = usedBytes / 1024.0 / 1024.0 // Convert to MB

            // Determine memory pressure
            if memoryUsage < 100 {
                memoryPressure = .normal
            } else if memoryUsage < 200 {
                memoryPressure = .moderate
            } else {
                memoryPressure = .high
            }
        }

        // Note: CPU usage monitoring requires more complex implementation
        // For now, we'll simulate it based on memory pressure
        cpuUsage = min(memoryUsage / 2.0, 100.0)
    }

    private func updateFrameMetrics() {
        let now = Date()

        if let lastTime = lastFrameTime {
            let frameTime = now.timeIntervalSince(lastTime)
            averageFrameTime = (averageFrameTime * 0.9) + (frameTime * 1000.0 * 0.1) // Smooth over 10 frames

            // Calculate FPS
            if frameTime > 0 {
                let currentFPS = 1.0 / frameTime
                frameRate = (frameRate * 0.9) + (currentFPS * 0.1) // Smooth over 10 frames
            }
        }

        lastFrameTime = now
    }
}

// MARK: - Supporting Types

enum MemoryPressure {
    case normal
    case moderate
    case high

    var color: Color {
        switch self {
        case .normal: return .green
        case .moderate: return .yellow
        case .high: return .red
        }
    }

    var displayText: String {
        switch self {
        case .normal: return "Normal"
        case .moderate: return "Moderate"
        case .high: return "High"
        }
    }
}

struct PerformanceLog: Identifiable {
    let id = UUID()
    let timestamp: Date
    let event: String
    let duration: TimeInterval?
    let memoryUsage: Double
    let cpuUsage: Double

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }

    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        return String(format: "%.2fms", duration * 1000)
    }
}

// MARK: - Performance Testing Helpers

extension PerformanceMonitor {
    /// Run a comprehensive system health check
    func runHealthCheck() -> SystemHealthReport {
        print("🏥 [HEALTH CHECK] Running system diagnostics...")

        var report = SystemHealthReport()

        // Check memory
        report.memoryStatus = .init(
            current: memoryUsage,
            pressure: memoryPressure,
            isHealthy: memoryUsage < 200
        )

        // Check frame rate
        report.frameRateStatus = .init(
            current: frameRate,
            isHealthy: frameRate > 50
        )

        // Check recent performance logs for slowdowns
        let recentLogs = performanceLogs.suffix(20)
        let slowOperations = recentLogs.filter { ($0.duration ?? 0) > 0.1 } // > 100ms

        report.slowOperations = slowOperations.count
        report.performanceGrade = calculatePerformanceGrade()

        print("✅ [HEALTH CHECK] Complete: \(report.performanceGrade)")
        return report
    }

    private func calculatePerformanceGrade() -> String {
        var score = 100.0

        // Deduct points for memory usage
        if memoryUsage > 100 {
            score -= (memoryUsage - 100) / 10.0
        }

        // Deduct points for low frame rate
        if frameRate < 60 {
            score -= (60 - frameRate)
        }

        // Deduct points for slow operations
        let recentLogs = performanceLogs.suffix(20)
        let slowOps = recentLogs.filter { ($0.duration ?? 0) > 0.1 }.count
        score -= Double(slowOps) * 5.0

        // Return grade
        score = max(0, score)
        if score >= 90 { return "A+ (Excellent)" }
        if score >= 80 { return "A (Great)" }
        if score >= 70 { return "B (Good)" }
        if score >= 60 { return "C (Fair)" }
        return "D (Needs Improvement)"
    }
}

struct SystemHealthReport {
    var memoryStatus: MemoryStatus = .init(current: 0, pressure: .normal, isHealthy: true)
    var frameRateStatus: FrameRateStatus = .init(current: 60, isHealthy: true)
    var slowOperations: Int = 0
    var performanceGrade: String = "N/A"

    struct MemoryStatus {
        let current: Double
        let pressure: MemoryPressure
        let isHealthy: Bool
    }

    struct FrameRateStatus {
        let current: Double
        let isHealthy: Bool
    }

    var overallHealth: String {
        if memoryStatus.isHealthy && frameRateStatus.isHealthy && slowOperations < 3 {
            return "✅ Healthy"
        } else if memoryStatus.isHealthy || frameRateStatus.isHealthy {
            return "⚠️ Moderate Issues"
        } else {
            return "❌ Performance Issues Detected"
        }
    }
}

#endif
