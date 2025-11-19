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

    #if DEBUG
    @State private var showDebugMenu = false
    @State private var debugTapCount = 0
    #endif

    var overallCompletionRate: Double {
        // Don't access systems during deletion to avoid accessing deleted objects
        guard !isDeletingTestData else { return 0.0 }
        guard !systems.isEmpty else { return 0.0 }

        let totalTasks = systems.reduce(0) { $0 + $1.todaysTasks.count }
        guard totalTasks > 0 else { return 0.0 }

        let completedTasks = systems.reduce(0) { $0 + $1.completedTodayCount }
        return Double(completedTasks) / Double(totalTasks)
    }

    var totalActiveSystems: Int {
        // Don't access systems during deletion to avoid accessing deleted objects
        guard !isDeletingTestData else { return 0 }
        return systems.filter { !$0.todaysTasks.isEmpty }.count
    }

    var overallWeeklyCompletionRate: Double {
        // Don't access systems during deletion to avoid accessing deleted objects
        guard !isDeletingTestData else { return 0.0 }
        guard !systems.isEmpty else { return 0.0 }

        // Calculate based on total completions vs total target
        // Example: Task1 (2/3) + Task2 (1/2) = 3/5 = 60%
        let totalCompletions = totalWeeklyCompletions
        let totalTarget = totalWeeklyTarget

        guard totalTarget > 0 else { return 0.0 }

        let rate = Double(totalCompletions) / Double(totalTarget)
        return min(1.0, max(0.0, rate))
    }

    var totalWeeklyTasks: Int {
        // Don't access systems during deletion to avoid accessing deleted objects
        guard !isDeletingTestData else { return 0 }
        return systems.reduce(0) { total, system in
            total + system.weeklyTasks.count
        }
    }

    var totalCompletedWeeklyTasks: Int {
        // Don't access systems during deletion to avoid accessing deleted objects
        guard !isDeletingTestData else { return 0 }
        return systems.reduce(0) { total, system in
            total + system.completedWeeklyCount
        }
    }

    var totalWeeklyCompletions: Int {
        // Don't access systems during deletion to avoid accessing deleted objects
        guard !isDeletingTestData else { return 0 }
        return systems.reduce(0) { total, system in
            total + system.totalWeeklyCompletions
        }
    }

    var totalWeeklyTarget: Int {
        // Don't access systems during deletion to avoid accessing deleted objects
        guard !isDeletingTestData else { return 0 }
        return systems.reduce(0) { total, system in
            total + system.totalWeeklyTarget
        }
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
        // Don't access systems during deletion to avoid accessing deleted objects
        guard !isDeletingTestData else { return 0 }
        return systems.reduce(0) { $0 + $1.todaysTasks.count }
    }

    private var totalCompletedTasks: Int {
        // Don't access systems during deletion to avoid accessing deleted objects
        guard !isDeletingTestData else { return 0 }
        return systems.reduce(0) { $0 + $1.completedTodayCount }
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

    // MARK: - Systems List
    private var systemsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Don't render systems during deletion to avoid accessing deleted objects
            if !isDeletingTestData && !systems.isEmpty {
                Text("Your Systems")
                    .font(.title2)
                    .fontWeight(.bold)

                ForEach(systems) { system in
                    NavigationLink(destination: SystemDetailView(system: system)) {
                        SystemCard(system: system, modelContext: modelContext)
                    }
                    .buttonStyle(ScaleButtonStyle())
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

// MARK: - System Card Component
struct SystemCard: View {
    let system: System
    let modelContext: ModelContext

    var body: some View {
        // Defensive: Safely get tasks and tests
        let todaysTasks: [HabitTask]
        let weeklyTasks: [HabitTask]
        let dueTests: [PerformanceTest]

        // Safe access to system properties with defensive coding
        todaysTasks = system.todaysTasks
        weeklyTasks = system.weeklyTasks
        dueTests = system.dueTests

        return VStack(spacing: 16) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: system.color).opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: system.icon)
                        .font(.title3)
                        .foregroundStyle(Color(hex: system.color))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(system.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Label(system.category.rawValue, systemImage: system.category.systemIcon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Completion indicator - defensive calculation
                let completionRate = (try? system.todayCompletionRate) ?? 0.0
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                        .frame(width: 44, height: 44)

                    Circle()
                        .trim(from: 0, to: max(0, min(1, completionRate)))
                        .stroke(Color(hex: system.color), lineWidth: 4)
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(max(0, min(100, completionRate * 100))))")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
            }

            // Today's Tasks (daily/weekdays/weekends)
            if !todaysTasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Today's Tasks")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(todaysTasks) { task in
                        TaskRow(task: task, modelContext: modelContext)
                    }
                }
                .padding(12)
                .background(Color(.systemGray6).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
                )
            }

            // Weekly Goals (weekly frequency tasks)
            if !weeklyTasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "target")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Weekly Goals")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(weeklyTasks) { task in
                        TaskRow(task: task, modelContext: modelContext)
                    }
                }
                .padding(12)
                .background(Color(.systemGray6).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
                )
            }

            // Due Tests
            if !dueTests.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.badge.questionmark")
                        .foregroundStyle(.orange)
                    Text("\(dueTests.count) test\(dueTests.count == 1 ? "" : "s") due")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
        .elevatedCard(elevation: .level1, cornerRadius: 16, padding: 16)
    }
}

// MARK: - Task Row Component
struct TaskRow: View {
    let task: HabitTask
    let modelContext: ModelContext

    @State private var isCompleted: Bool = false
    @State private var showCheckIn: Bool = false

    var isTimeBased: Bool {
        task.habitType == .negative && task.hasTimeLimit
    }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                handleTaskTap()
            } label: {
                let completionColor: Color = task.habitType == .positive ? .green : .orange
                let isOverTarget = task.isOverWeeklyTarget()
                Image(systemName: isCompleted || isOverTarget ? task.habitType.icon : "circle")
                    .font(.title3)
                    .foregroundStyle((isCompleted || isOverTarget) ? completionColor.opacity(isOverTarget && !isCompleted ? 0.5 : 1.0) : .gray.opacity(0.3))
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

                // Show weekly progress for weekly targets
                if let progressText = task.weeklyProgressText() {
                    Text(progressText)
                        .font(.caption2)
                        .foregroundStyle(task.weeklyTargetMet() ? .green : .blue)
                }
            }

            Spacer()

            if task.currentStreak > 0 {
                HStack(spacing: 4) {
                    // Show warning icon if streak is at risk (one miss already)
                    if task.isStreakAtRisk {
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
                        Text("\(task.currentStreak)w")
                            .font(.caption2)
                            .foregroundStyle(task.isStreakAtRisk ? .yellow : .orange)
                    } else {
                        Text("\(task.currentStreak)")
                            .font(.caption2)
                            .foregroundStyle(task.isStreakAtRisk ? .yellow : .orange)
                    }
                }
            }
        }
        .onAppear {
            isCompleted = task.isCompletedToday()
        }
        .sheet(isPresented: $showCheckIn) {
            TaskCheckInView(task: task)
                .onDisappear {
                    isCompleted = task.isCompletedToday()
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