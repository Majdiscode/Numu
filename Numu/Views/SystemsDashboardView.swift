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
        let dueTests: [PerformanceTest]

        do {
            todaysTasks = system.todaysTasks
            dueTests = system.dueTests
        } catch {
            todaysTasks = []
            dueTests = []
        }

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

            // Tasks
            if !todaysTasks.isEmpty {
                VStack(spacing: 8) {
                    ForEach(todaysTasks) { task in
                        TaskRow(task: task, modelContext: modelContext)
                    }
                }
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
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    // Show week/day based on frequency type
                    if case .weeklyTarget = task.frequency {
                        Text("\(task.currentStreak)w")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    } else {
                        Text("\(task.currentStreak)")
                            .font(.caption2)
                            .foregroundStyle(.orange)
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