//
//  SystemsDashboardView.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//

import SwiftUI
import SwiftData

struct SystemsDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var systems: [System]

    @State private var showCreateSystem = false
    @State private var cloudKitService = CloudKitService()
    @State private var isDeletingTestData = false
    @State private var showCelebration = false
    @State private var showWeeklyCelebration = false
    @State private var previousCompletionRate: Double = 0
    @State private var previousWeeklyCompletionRate: Double = 0

    // MARK: - Performance Optimization: Cached Stats
    @State private var cachedOverallCompletionRate: Double = 0.0
    @State private var cachedTotalActiveSystems: Int = 0
    @State private var cachedOverallWeeklyCompletionRate: Double = 0.0
    @State private var cachedTotalWeeklyTasks: Int = 0
    @State private var cachedTotalCompletedWeeklyTasks: Int = 0
    @State private var cachedTotalWeeklyCompletions: Int = 0
    @State private var cachedTotalWeeklyTarget: Int = 0
    @State private var cachedTotalTodaysTasks: Int = 0
    @State private var cachedTotalCompletedTasks: Int = 0
    @State private var statsNeedRefresh: Bool = true

    #if DEBUG
    @State private var showDebugMenu = false
    @State private var debugTapCount = 0
    #endif

    // MARK: - Optimized Computed Properties (Use Cached Values)

    var overallCompletionRate: Double {
        guard !isDeletingTestData else { return 0.0 }
        return cachedOverallCompletionRate
    }

    var totalActiveSystems: Int {
        guard !isDeletingTestData else { return 0 }
        return cachedTotalActiveSystems
    }

    var overallWeeklyCompletionRate: Double {
        guard !isDeletingTestData else { return 0.0 }
        return cachedOverallWeeklyCompletionRate
    }

    var totalWeeklyTasks: Int {
        guard !isDeletingTestData else { return 0 }
        return cachedTotalWeeklyTasks
    }

    var totalCompletedWeeklyTasks: Int {
        guard !isDeletingTestData else { return 0 }
        return cachedTotalCompletedWeeklyTasks
    }

    var totalWeeklyCompletions: Int {
        guard !isDeletingTestData else { return 0 }
        return cachedTotalWeeklyCompletions
    }

    var totalWeeklyTarget: Int {
        guard !isDeletingTestData else { return 0 }
        return cachedTotalWeeklyTarget
    }

    // MARK: - Batch Stats Calculation (Optimized)

    /// Calculate all dashboard stats in a single pass for optimal performance
    private func refreshDashboardStats() {
        guard !isDeletingTestData else { return }
        guard !systems.isEmpty else {
            resetCachedStats()
            return
        }

        // Single-pass calculation for all stats
        var tempTotalTodaysTasks = 0
        var tempTotalCompletedTasks = 0
        var tempActiveSystems = 0
        var tempTotalWeeklyTasks = 0
        var tempCompletedWeeklyTasks = 0
        var tempTotalWeeklyCompletions = 0
        var tempTotalWeeklyTarget = 0

        for system in systems {
            let todaysTasks = system.todaysTasks
            let todaysCompleted = system.completedTodayCount

            tempTotalTodaysTasks += todaysTasks.count
            tempTotalCompletedTasks += todaysCompleted

            if !todaysTasks.isEmpty {
                tempActiveSystems += 1
            }

            tempTotalWeeklyTasks += system.weeklyTasks.count
            tempCompletedWeeklyTasks += system.completedWeeklyCount
            tempTotalWeeklyCompletions += system.totalWeeklyCompletions
            tempTotalWeeklyTarget += system.totalWeeklyTarget
        }

        // Update all cached values atomically with animation
        withAnimation(.easeInOut(duration: 0.2)) {
            cachedTotalTodaysTasks = tempTotalTodaysTasks
            cachedTotalCompletedTasks = tempTotalCompletedTasks
            cachedTotalActiveSystems = tempActiveSystems
            cachedTotalWeeklyTasks = tempTotalWeeklyTasks
            cachedTotalCompletedWeeklyTasks = tempCompletedWeeklyTasks
            cachedTotalWeeklyCompletions = tempTotalWeeklyCompletions
            cachedTotalWeeklyTarget = tempTotalWeeklyTarget

            // Calculate rates
            cachedOverallCompletionRate = tempTotalTodaysTasks > 0
                ? Double(tempTotalCompletedTasks) / Double(tempTotalTodaysTasks)
                : 0.0

            cachedOverallWeeklyCompletionRate = tempTotalWeeklyTarget > 0
                ? min(1.0, max(0.0, Double(tempTotalWeeklyCompletions) / Double(tempTotalWeeklyTarget)))
                : 0.0

            statsNeedRefresh = false
        }
    }

    private func resetCachedStats() {
        cachedOverallCompletionRate = 0.0
        cachedTotalActiveSystems = 0
        cachedOverallWeeklyCompletionRate = 0.0
        cachedTotalWeeklyTasks = 0
        cachedTotalCompletedWeeklyTasks = 0
        cachedTotalWeeklyCompletions = 0
        cachedTotalWeeklyTarget = 0
        cachedTotalTodaysTasks = 0
        cachedTotalCompletedTasks = 0
    }

    // MARK: - Celebration
    private func triggerCelebration(isWeekly: Bool = false) {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Show confetti animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            if isWeekly {
                showWeeklyCelebration = true
            } else {
                showCelebration = true
            }
        }

        // Hide after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation {
                if isWeekly {
                    showWeeklyCelebration = false
                } else {
                    showCelebration = false
                }
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Layered background for depth
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - CloudKit Status Banner
                        if cloudKitService.syncStatus == .notSignedIn {
                            cloudKitStatusBanner
                        }

                        // MARK: - Overall Progress
                        if !systems.isEmpty {
                            overallProgressCard
                        }

                        // MARK: - Weekly Progress
                        if totalWeeklyTasks > 0 {
                            weeklyProgressCard
                        }

                        // MARK: - Systems List
                        systemsList

                        // MARK: - Empty State
                        if systems.isEmpty {
                            emptyState
                        }
                    }
                    .padding()
                }
                .blur(radius: isDeletingTestData ? 10 : 0)

                // Loading overlay during deletion
                if isDeletingTestData {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)

                        Text("Clearing test data...")
                            .foregroundStyle(.white)
                            .font(.headline)
                    }
                }

                // Celebration overlays
                if showCelebration {
                    CelebrationView(isWeekly: false)
                        .allowsHitTesting(false)
                }

                if showWeeklyCelebration {
                    CelebrationView(isWeekly: true)
                        .allowsHitTesting(false)
                }
            }
            .navigationTitle("Systems")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateSystem = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }

                #if DEBUG
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        handleDebugTap()
                    } label: {
                        Image(systemName: "ant.circle")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                #endif
            }
            .sheet(isPresented: $showCreateSystem) {
                CreateSystemView()
            }
            #if DEBUG
            .sheet(isPresented: $showDebugMenu) {
                DebugMenuView(isDeletingTestData: $isDeletingTestData)
            }
            #endif
            .onAppear {
                cloudKitService.checkAccountStatus()
                refreshDashboardStats()
            }
            .onChange(of: systems.count) { _, _ in
                refreshDashboardStats()
            }
            .onChange(of: isDeletingTestData) { _, newValue in
                if !newValue {
                    refreshDashboardStats()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Refresh when app returns from background
                refreshDashboardStats()
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("TaskCompletionChanged"))) { _ in
                // Refresh when a task is completed/uncompleted
                refreshDashboardStats()
            }
        }
    }

    #if DEBUG
    private func handleDebugTap() {
        showDebugMenu = true
    }
    #endif

    // MARK: - CloudKit Status Banner
    private var cloudKitStatusBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: cloudKitService.syncStatus.icon)
                .font(.title3)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("iCloud Sync Disabled")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Sign into iCloud in Settings to sync across devices")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                if let url = URL(string: "App-prefs:APPLE_ACCOUNT") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Settings")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .elevation(.level1)
    }

    // MARK: - Overall Progress Card
    private var overallProgressCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Progress")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text("\(Int(overallCompletionRate * 100))%")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .onChange(of: overallCompletionRate) { oldValue, newValue in
                            // Trigger celebration when reaching 100%
                            if newValue == 1.0 && oldValue < 1.0 && !systems.isEmpty {
                                triggerCelebration()
                            }
                            previousCompletionRate = newValue
                        }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 4) {
                        Text("\(totalCompletedTasks)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("/ \(totalTodaysTasks)")
                            .foregroundStyle(.secondary)
                    }
                    Text("tasks")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Progress Bar
            GeometryReader { geometry in
                let filledWidth = geometry.size.width * overallCompletionRate

                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))

                    // Full-width gradient layer
                    RoundedRectangle(cornerRadius: 8)
                        .fill(progressBarGradient)
                        .frame(width: geometry.size.width) // FULL width
                        .mask(
                            // Mask to only show the filled portion from the left (with rounded end)
                            HStack(spacing: 0) {
                                RoundedRectangle(cornerRadius: 8)
                                    .frame(width: filledWidth)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: filledWidth)
                                Spacer(minLength: 0)
                            }
                        )
                }
            }
            .frame(height: 12)

            Text(motivationalMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(
            // Subtle gradient for depth
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemBackground).opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .cardBorder(cornerRadius: 16, opacity: 0.1)
        .elevation(.level2)
    }

    private var totalTodaysTasks: Int {
        guard !isDeletingTestData else { return 0 }
        return cachedTotalTodaysTasks
    }

    private var totalCompletedTasks: Int {
        guard !isDeletingTestData else { return 0 }
        return cachedTotalCompletedTasks
    }

    private var motivationalMessage: String {
        // Don't access systems during deletion to avoid accessing deleted objects
        guard !isDeletingTestData else { return "Clearing test data..." }

        if systems.isEmpty {
            return "Create your first system to begin"
        } else if overallCompletionRate == 1.0 {
            return "Perfect! All systems running smoothly"
        } else if overallCompletionRate >= 0.75 {
            return "Excellent work today"
        } else if overallCompletionRate >= 0.5 {
            return "Keep going, you're doing great"
        } else if totalCompletedTasks == 0 {
            return "Start fresh, one task at a time"
        } else {
            return "Progress, not perfection"
        }
    }

    // Smooth gradient that flows from blue → cyan → purple → magenta as progress increases
    private var progressBarGradient: LinearGradient {
        // Vibrant, saturated colors that avoid washing out to white
        let brightBlue = Color(red: 0.2, green: 0.6, blue: 1.0)        // Electric blue
        let brightCyan = Color(red: 0.0, green: 0.8, blue: 1.0)        // Vivid cyan
        let brightPurple = Color(red: 0.7, green: 0.3, blue: 1.0)      // Bright purple (bridge color)
        let brightMagenta = Color(red: 1.0, green: 0.2, blue: 0.9)     // Hot magenta/pink

        return LinearGradient(
            colors: [brightBlue, brightCyan, brightPurple, brightMagenta],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Weekly Progress Card
    private var weeklyProgressCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Goals")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text("\(Int(min(100, max(0, overallWeeklyCompletionRate * 100))))%")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .onChange(of: overallWeeklyCompletionRate) { oldValue, newValue in
                            // Trigger celebration when reaching 100%
                            if newValue == 1.0 && oldValue < 1.0 && totalWeeklyTasks > 0 {
                                triggerCelebration(isWeekly: true)
                            }
                            previousWeeklyCompletionRate = newValue
                        }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 4) {
                        Text("\(max(0, totalWeeklyCompletions))")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("/ \(max(0, totalWeeklyTarget))")
                            .foregroundStyle(.secondary)
                    }
                    Text("completions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Progress Bar
            GeometryReader { geometry in
                // Clamp filledWidth to valid range
                let safeRate = min(1.0, max(0.0, overallWeeklyCompletionRate))
                let filledWidth = max(0, min(geometry.size.width, geometry.size.width * safeRate))

                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))

                    // Full-width gradient layer
                    RoundedRectangle(cornerRadius: 8)
                        .fill(progressBarGradient)
                        .frame(width: geometry.size.width) // FULL width
                        .mask(
                            // Mask to only show the filled portion from the left (with rounded end)
                            HStack(spacing: 0) {
                                RoundedRectangle(cornerRadius: 8)
                                    .frame(width: filledWidth)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: filledWidth)
                                Spacer(minLength: 0)
                            }
                        )
                }
            }
            .frame(height: 12)

            Text(weeklyMotivationalMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(
            // Subtle gradient for depth
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemBackground).opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .cardBorder(cornerRadius: 16, opacity: 0.1)
        .elevation(.level2)
    }

    private var weeklyMotivationalMessage: String {
        // Don't access systems during deletion to avoid accessing deleted objects
        guard !isDeletingTestData else { return "Clearing test data..." }

        if totalWeeklyTasks == 0 {
            return "No weekly goals set yet"
        } else if overallWeeklyCompletionRate == 1.0 {
            return "All weekly goals completed! Outstanding!"
        } else if overallWeeklyCompletionRate >= 0.75 {
            return "Nearly there, finish strong this week"
        } else if overallWeeklyCompletionRate >= 0.5 {
            return "Solid progress, keep the momentum going"
        } else if totalWeeklyCompletions == 0 {
            return "Plenty of time left this week"
        } else {
            return "Every rep counts, keep going"
        }
    }

    // MARK: - Systems Grid (Widget Layout)
    private var systemsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Don't render systems during deletion to avoid accessing deleted objects
            if !isDeletingTestData && !systems.isEmpty {
                HStack {
                    Text("Your Systems")
                        .font(.title2)
                        .fontWeight(.bold)

                    Spacer()

                    Text("\(systems.count)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }

                // Full-width stacked layout for better readability
                VStack(spacing: 12) {
                    ForEach(systems) { system in
                        NavigationLink(destination: SystemDetailView(system: system)) {
                            SystemWidgetCard(system: system, modelContext: modelContext)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "gearshape.2")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Build Your Systems")
                .font(.title2)
                .fontWeight(.bold)

            Text("Create systems with daily tasks and periodic tests.\nExample: Hybrid Athlete with running + workouts")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showCreateSystem = true
            } label: {
                Text("Create Your First System")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 8)
        }
        .padding(32)
    }
}

// MARK: - System Widget Card (Compact 2-Column Layout)
struct SystemWidgetCard: View {
    let system: System
    let modelContext: ModelContext

    // Performance optimization: Cache expensive calculations
    @State private var cachedTodaysTasks: [HabitTask] = []
    @State private var cachedWeeklyTasks: [HabitTask] = []
    @State private var cachedDueTests: [PerformanceTest] = []
    @State private var cachedCompletionRate: Double = 0.0
    @State private var isExpanded: Bool = false

    private func refreshCache() {
        cachedTodaysTasks = system.todaysTasks
        cachedWeeklyTasks = system.weeklyTasks
        cachedDueTests = system.dueTests

        // Calculate completion rate including both daily and weekly tasks
        let dailyTasks = cachedTodaysTasks
        let weeklyTasks = cachedWeeklyTasks

        if dailyTasks.isEmpty && weeklyTasks.isEmpty {
            cachedCompletionRate = 0.0
        } else if dailyTasks.isEmpty {
            // Only weekly tasks - show average weekly progress (e.g., 1/3 = 33%)
            var totalProgress: Double = 0.0
            for task in weeklyTasks {
                if case .weeklyTarget(let times) = task.frequency {
                    let completions = task.completionsThisWeek()
                    let progress = min(1.0, Double(completions) / Double(times))
                    totalProgress += progress
                }
            }
            cachedCompletionRate = weeklyTasks.isEmpty ? 0.0 : totalProgress / Double(weeklyTasks.count)
        } else if weeklyTasks.isEmpty {
            // Only daily tasks - use today's completion
            cachedCompletionRate = system.todayCompletionRate
        } else {
            // Both daily and weekly - combine them proportionally
            let dailyProgress = Double(dailyTasks.filter { $0.isCompletedToday() }.count)
            var weeklyProgress: Double = 0.0
            for task in weeklyTasks {
                if case .weeklyTarget(let times) = task.frequency {
                    let completions = task.completionsThisWeek()
                    weeklyProgress += min(1.0, Double(completions) / Double(times))
                }
            }
            let totalTasks = dailyTasks.count + weeklyTasks.count
            cachedCompletionRate = (dailyProgress + weeklyProgress) / Double(totalTasks)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Compact Widget Header
            VStack(spacing: 20) {
                // Icon & Name
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: system.color).opacity(0.15))
                            .frame(width: 60, height: 60)

                        Image(systemName: system.icon)
                            .font(.title2)
                            .foregroundStyle(Color(hex: system.color))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(system.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        HStack(spacing: 10) {
                            if !cachedTodaysTasks.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar")
                                        .font(.caption2)
                                    Text("\(cachedTodaysTasks.count)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                            }

                            if !cachedWeeklyTasks.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "target")
                                        .font(.caption2)
                                    Text("\(cachedWeeklyTasks.count)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                            }

                            if !cachedDueTests.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "chart.bar.fill")
                                        .font(.caption2)
                                    Text("\(cachedDueTests.count)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                .foregroundStyle(.orange)
                            }
                        }
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Smaller completion circle (like before)
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                            .frame(width: 52, height: 52)

                        Circle()
                            .trim(from: 0, to: max(0, min(1, cachedCompletionRate)))
                            .stroke(Color(hex: system.color), lineWidth: 4)
                            .frame(width: 52, height: 52)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.5), value: cachedCompletionRate)

                        Text("\(Int(max(0, min(100, cachedCompletionRate * 100))))")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 150)
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemBackground).opacity(0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Expandable Tasks Dropdown
            if !cachedTodaysTasks.isEmpty || !cachedWeeklyTasks.isEmpty {
                VStack(spacing: 0) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        HStack {
                            Text(isExpanded ? "Hide Tasks" : "Show Tasks")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Spacer()

                            Image(systemName: "chevron.down")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        }
                        .foregroundStyle(Color(hex: system.color))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)

                    // Expanded Tasks
                    if isExpanded {
                        VStack(spacing: 0) {
                            // Today's Tasks
                            if !cachedTodaysTasks.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Today")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 16)
                                        .padding(.top, 12)

                                    ForEach(cachedTodaysTasks) { task in
                                        CompactTaskRow(task: task, modelContext: modelContext)
                                    }
                                }
                            }

                            // Weekly Goals
                            if !cachedWeeklyTasks.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Weekly")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 16)
                                        .padding(.top, cachedTodaysTasks.isEmpty ? 12 : 16)

                                    ForEach(cachedWeeklyTasks) { task in
                                        CompactTaskRow(task: task, modelContext: modelContext)
                                    }
                                }
                                .padding(.bottom, 12)
                            }
                        }
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator).opacity(0.1), lineWidth: 1)
        )
        .onAppear {
            refreshCache()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("TaskCompletionChanged"))) { _ in
            refreshCache()
        }
    }
}

// MARK: - Compact Task Row (For Widget Cards)
struct CompactTaskRow: View {
    let task: HabitTask
    let modelContext: ModelContext

    @State private var isCompleted: Bool = false
    @State private var showCheckIn: Bool = false

    private func refreshCompletion() {
        isCompleted = task.isCompletedToday()
    }

    var body: some View {
        HStack(spacing: 10) {
            Button {
                toggleCompletion()
            } label: {
                let completionColor: Color = task.habitType == .positive ? .green : .orange
                Image(systemName: isCompleted ? task.habitType.icon : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isCompleted ? completionColor : .gray.opacity(0.3))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.name)
                    .font(.subheadline)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                    .lineLimit(1)

                if let progressText = task.weeklyProgressText() {
                    Text(progressText)
                        .font(.caption2)
                        .foregroundStyle(task.weeklyTargetMet() ? .green : .blue)
                }
            }

            Spacer()

            if task.currentStreak > 0 {
                HStack(spacing: 3) {
                    Image(systemName: task.isStreakAtRisk ? "exclamationmark.triangle.fill" : "flame.fill")
                        .font(.caption)
                    Text("\(task.currentStreak)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(task.isStreakAtRisk ? .yellow : .orange)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .onAppear {
            refreshCompletion()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("TaskCompletionChanged"))) { _ in
            refreshCompletion()
        }
    }

    private func toggleCompletion() {
        withAnimation(.spring(response: 0.3)) {
            if isCompleted {
                if let todayLog = task.logs?.first(where: { Calendar.current.isDateInToday($0.date) }) {
                    modelContext.delete(todayLog)
                }
            } else {
                let log = HabitTaskLog()
                log.task = task
                modelContext.insert(log)
            }

            do {
                try modelContext.save()
                isCompleted.toggle()
                NotificationCenter.default.post(name: Notification.Name("TaskCompletionChanged"), object: nil)
            } catch {
                print("Error toggling task: \(error)")
            }
        }
    }
}

// MARK: - Task Row Component
struct TaskRow: View {
    let task: HabitTask
    let modelContext: ModelContext

    @State private var isCompleted: Bool = false
    @State private var showCheckIn: Bool = false
    @State private var cachedWeeklyProgressText: String? = nil
    @State private var cachedCurrentStreak: Int = 0
    @State private var cachedIsStreakAtRisk: Bool = false
    @State private var cachedIsOverTarget: Bool = false

    var isTimeBased: Bool {
        task.habitType == .negative && task.hasTimeLimit
    }

    private func refreshTaskCache() {
        isCompleted = task.isCompletedToday()
        cachedWeeklyProgressText = task.weeklyProgressText()
        cachedCurrentStreak = task.currentStreak
        cachedIsStreakAtRisk = task.isStreakAtRisk
        cachedIsOverTarget = task.isOverWeeklyTarget()
    }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                handleTaskTap()
            } label: {
                let completionColor: Color = task.habitType == .positive ? .green : .orange
                Image(systemName: isCompleted || cachedIsOverTarget ? task.habitType.icon : "circle")
                    .font(.title3)
                    .foregroundStyle((isCompleted || cachedIsOverTarget) ? completionColor.opacity(cachedIsOverTarget && !isCompleted ? 0.5 : 1.0) : .gray.opacity(0.3))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(task.name)
                        .font(.subheadline)
                        .foregroundStyle(isCompleted ? .secondary : .primary)

                    if task.habitType == .negative {
                        Text("Break")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.orange.opacity(0.8))
                            .clipShape(Capsule())
                    }
                }

                // Show weekly progress for weekly targets (cached)
                if let progressText = cachedWeeklyProgressText {
                    Text(progressText)
                        .font(.caption2)
                        .foregroundStyle(task.weeklyTargetMet() ? .green : .blue)
                }
            }

            Spacer()

            if cachedCurrentStreak > 0 {
                HStack(spacing: 4) {
                    // Show warning icon if streak is at risk (one miss already)
                    if cachedIsStreakAtRisk {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    } else {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }

                    // Show week/day based on frequency type
                    if case .weeklyTarget = task.frequency {
                        Text("\(cachedCurrentStreak)w")
                            .font(.caption2)
                            .foregroundStyle(cachedIsStreakAtRisk ? .yellow : .orange)
                    } else {
                        Text("\(cachedCurrentStreak)")
                            .font(.caption2)
                            .foregroundStyle(cachedIsStreakAtRisk ? .yellow : .orange)
                    }
                }
            }
        }
        .onAppear {
            refreshTaskCache()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("TaskCompletionChanged"))) { _ in
            refreshTaskCache()
        }
        .sheet(isPresented: $showCheckIn) {
            TaskCheckInView(task: task)
                .onDisappear {
                    refreshTaskCache()
                }
        }
    }

    private func handleTaskTap() {
        if isTimeBased {
            // Time-based negative habits MUST use check-in for time input
            if isCompleted {
                // Allow unchecking by removing log
                toggleCompletion()
            } else {
                // Force check-in sheet for time input
                showCheckIn = true
            }
        } else {
            // Regular tasks can quick toggle
            toggleCompletion()
        }
    }

    private func toggleCompletion() {
        withAnimation(.spring(response: 0.3)) {
            if isCompleted {
                // Remove today's log
                if let todayLog = task.logs?.first(where: { Calendar.current.isDateInToday($0.date) }) {
                    modelContext.delete(todayLog)
                }
            } else {
                // Add today's log
                let log = HabitTaskLog()
                log.task = task
                modelContext.insert(log)
            }

            do {
                try modelContext.save()
                isCompleted.toggle()

                // Notify dashboard to refresh stats
                NotificationCenter.default.post(name: Notification.Name("TaskCompletionChanged"), object: nil)

                // Refresh local cache
                refreshTaskCache()
            } catch {
                print("Error toggling task: \(error)")
            }
        }
    }
}

// MARK: - Celebration View
struct CelebrationView: View {
    let isWeekly: Bool
    @State private var isAnimating = false

    private var celebrationEmoji: String {
        isWeekly ? "🏆" : "🎉"
    }

    private var celebrationTitle: String {
        isWeekly ? "Week Complete!" : "All Done!"
    }

    private var celebrationMessage: String {
        isWeekly ? "You crushed all your weekly goals!" : "You completed all your tasks today!"
    }

    var body: some View {
        ZStack {
            ForEach(0..<30, id: \.self) { index in
                ConfettiPiece(index: index)
            }

            // Success message
            VStack(spacing: 16) {
                Text(celebrationEmoji)
                    .font(.system(size: 80))
                    .scaleEffect(isAnimating ? 1.2 : 0.5)
                    .opacity(isAnimating ? 1.0 : 0.0)

                Text(celebrationTitle)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .opacity(isAnimating ? 1.0 : 0.0)

                Text(celebrationMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(isAnimating ? 1.0 : 0.0)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.2), radius: 20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
    }
}

struct ConfettiPiece: View {
    let index: Int
    @State private var animate = false

    private var randomX: CGFloat {
        CGFloat.random(in: -200...200)
    }

    private var randomRotation: Double {
        Double.random(in: 0...360)
    }

    private var randomDelay: Double {
        Double.random(in: 0...0.3)
    }

    private var confettiColors: [Color] {
        [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    }

    private var randomColor: Color {
        confettiColors.randomElement() ?? .blue
    }

    var body: some View {
        Circle()
            .fill(randomColor)
            .frame(width: 10, height: 10)
            .offset(x: animate ? randomX : 0, y: animate ? 800 : -100)
            .rotationEffect(.degrees(animate ? randomRotation * 4 : randomRotation))
            .opacity(animate ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 2.5).delay(randomDelay)) {
                    animate = true
                }
            }
    }
}