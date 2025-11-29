//
//  SystemDetailView.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//

import SwiftUI
import SwiftData

struct SystemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let system: System

    @State private var showDeleteAlert = false
    @State private var showEditSystem = false
    @State private var isDeleted = false

    var body: some View {
        // Safety check: if system is deleted, show empty view and dismiss
        if isDeleted {
            return AnyView(
                Color.clear
                    .onAppear {
                        dismiss()
                    }
            )
        }

        // Safety check: if system.tasks is nil, show error state
        if system.tasks == nil {
            return AnyView(
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)

                    Text("Unable to load system data")
                        .font(.headline)

                    Text("This system may have been corrupted. Try deleting and recreating it.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Button("Go Back") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .navigationTitle("Error")
            )
        }

        return AnyView(ScrollView {
            VStack(spacing: 24) {
                // MARK: - System Header
                systemHeader

                // MARK: - Key Stats
                keyStats

                // MARK: - Tasks Section
                tasksSection

                // MARK: - Tests Section
                testsSection

                // MARK: - Delete Button
                deleteButton
            }
            .padding()
        }
        .navigationTitle(system.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showEditSystem = true
                } label: {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $showEditSystem) {
            EditSystemView(system: system)
        }
        .alert("Delete System?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSystem()
            }
        } message: {
            Text("This will permanently delete '\(system.name)' and all associated tasks, tests, and data. This action cannot be undone.")
        })
    }

    // MARK: - System Header
    private var systemHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: system.color).opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: system.icon)
                    .font(.system(size: 44))
                    .foregroundStyle(Color(hex: system.color))
            }

            VStack(spacing: 8) {
                Text(system.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                if let description = system.systemDescription, !description.isEmpty {
                    Text(description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            Label(system.category.rawValue, systemImage: system.category.systemIcon)
                .font(.subheadline)
                .foregroundStyle(Color(hex: system.color))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: system.color).opacity(0.15))
                .clipShape(Capsule())
        }
    }

    // MARK: - Key Stats
    private var keyStats: some View {
        // Defensive: Calculate stats safely to prevent crashes
        let todayRate = (system.tasks != nil) ? system.todayCompletionRate : 0.0
        let streak = (system.tasks != nil) ? system.currentStreak : 0
        let consistency = (system.tasks != nil) ? system.overallConsistency : 0.0
        let testsCount = system.tests?.count ?? 0

        return VStack(spacing: 16) {
            HStack(spacing: 16) {
                SystemStatCard(
                    title: "Today",
                    value: "\(Int(max(0, min(100, todayRate * 100))))%",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                SystemStatCard(
                    title: "Streak",
                    value: "\(max(0, streak))",
                    icon: "flame.fill",
                    color: .orange
                )
            }

            HStack(spacing: 16) {
                SystemStatCard(
                    title: "Consistency",
                    value: "\(Int(max(0, min(100, consistency * 100))))%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                )

                SystemStatCard(
                    title: "Active Tests",
                    value: "\(max(0, testsCount))",
                    icon: "chart.bar.fill",
                    color: .purple
                )
            }
        }
    }

    // MARK: - Tasks Section
    private var tasksSection: some View {
        // Defensive: Safely get tasks to prevent crashes
        let todaysTasks = (system.tasks != nil) ? system.todaysTasks : []
        let weeklyTasks = (system.tasks != nil) ? system.weeklyTasks : []
        let completedToday = (system.tasks != nil) ? system.completedTodayCount : 0

        // Defensive: Safely calculate weekly completions
        let completedWeekly = weeklyTasks.filter { task in
            // Safely check if target is met, ensure logs exist
            guard case .weeklyTarget = task.frequency,
                  task.logs != nil else {
                return false
            }
            return task.weeklyTargetMet()
        }.count

        return VStack(alignment: .leading, spacing: 16) {
            // Today's Tasks (daily/weekdays/weekends)
            if !todaysTasks.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Today's Tasks", systemImage: "calendar")
                            .font(.headline)

                        Spacer()

                        Text("\(completedToday)/\(todaysTasks.count)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(todaysTasks) { task in
                        TaskDetailRow(task: task, modelContext: modelContext)
                    }
                }
                .padding(16)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.separator).opacity(0.2), lineWidth: 1)
                )
            }

            // Weekly Goals (weekly frequency tasks)
            if !weeklyTasks.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Weekly Goals", systemImage: "target")
                            .font(.headline)

                        Spacer()

                        Text("\(completedWeekly)/\(weeklyTasks.count) targets met")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(weeklyTasks) { task in
                        TaskDetailRow(task: task, modelContext: modelContext)
                    }
                }
                .padding(16)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.separator).opacity(0.2), lineWidth: 1)
                )
            }

            // Empty state if no tasks at all
            if todaysTasks.isEmpty && weeklyTasks.isEmpty {
                VStack(spacing: 12) {
                    Text("No tasks in this system yet")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
            }
        }
    }

    // MARK: - Tests Section
    private var testsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Periodic Tests", systemImage: "chart.bar")
                .font(.headline)

            if system.tests?.isEmpty ?? true {
                Text("No tests in this system yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(system.tests ?? []) { test in
                    TestCard(test: test, systemConsistency: system.overallConsistency)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    // MARK: - Delete Button
    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteAlert = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete System")
            }
            .font(.headline)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func deleteSystem() {
        // Defensive: Manually delete all tasks and their logs first
        // This ensures deletion works regardless of when the system was created
        if let tasks = system.tasks {
            for task in tasks {
                // Manually delete all logs for this task
                if let logs = task.logs {
                    for log in logs {
                        modelContext.delete(log)
                    }
                }

                // Delete the task itself
                modelContext.delete(task)
            }
        }

        // Defensive: Manually delete all tests and their entries first
        if let tests = system.tests {
            for test in tests {
                // Manually delete all entries for this test
                if let entries = test.entries {
                    for entry in entries {
                        modelContext.delete(entry)
                    }
                }

                // Delete the test itself
                modelContext.delete(test)
            }
        }

        // Perform the delete on the system itself
        modelContext.delete(system)

        do {
            try modelContext.save()

            // Mark as deleted BEFORE dismissing to prevent re-renders with deleted object
            isDeleted = true

            // Add a small delay to ensure state updates before dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                dismiss()
            }
        } catch {
            print("❌ Error deleting system '\(system.name)': \(error.localizedDescription)")
        }
    }
}

// MARK: - System Stat Card
struct SystemStatCard: View {
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

// MARK: - Task Detail Row
struct TaskDetailRow: View {
    let task: HabitTask
    let modelContext: ModelContext

    @State private var isCompleted: Bool = false
    @State private var showTaskCheckIn = false
    @State private var showAtomicHabits: Bool = false

    var hasAtomicHabits: Bool {
        task.cue != nil || task.cueTime != nil || task.attractiveness != nil ||
        task.easeStrategy != nil || task.reward != nil
    }

    var isTimeBased: Bool {
        task.habitType == .negative && task.hasTimeLimit
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main task row
            Button {
                handleTaskTap()
            } label: {
                HStack(spacing: 16) {
                    // Completion indicator
                    let completionColor: Color = task.habitType == .positive ? .green : .orange
                    let isOverTarget = task.isOverWeeklyTarget()
                    Image(systemName: isCompleted || isOverTarget ? task.habitType.icon : "circle")
                        .font(.title2)
                        .foregroundStyle((isCompleted || isOverTarget) ? completionColor.opacity(isOverTarget && !isCompleted ? 0.5 : 1.0) : .gray.opacity(0.3))

                    // Task details
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(task.name)
                                .font(.headline)
                                .foregroundStyle(.primary)

                            if task.habitType == .negative {
                                Text("Break")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange)
                                    .clipShape(Capsule())
                            }
                        }

                        HStack(spacing: 6) {
                            Text(task.frequency.displayText)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            // Weekly progress indicator
                            if let progressText = task.weeklyProgressText() {
                                Text("•")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(progressText)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(task.weeklyTargetMet() ? .green : .blue)
                            }
                        }

                        // Stats
                        HStack(spacing: 12) {
                            if task.currentStreak > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "flame.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                    // Show "week" for weekly targets, "day" for others
                                    if case .weeklyTarget = task.frequency {
                                        Text("\(task.currentStreak) week\(task.currentStreak == 1 ? "" : "s")")
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                    } else {
                                        Text("\(task.currentStreak) day\(task.currentStreak == 1 ? "" : "s")")
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                    }
                                }
                            }

                            HStack(spacing: 4) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.caption2)
                                Text("\(Int(task.completionRate * 100))%")
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .buttonStyle(.plain)

            // Atomic Habits section (if any fields are filled)
            if hasAtomicHabits {
                Divider()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showAtomicHabits.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: "book.closed")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("The 4 Laws")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(showAtomicHabits ? 180 : 0))
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                if showAtomicHabits {
                    Divider()

                    VStack(alignment: .leading, spacing: 10) {
                        if let cue = task.cue {
                            atomicHabitRow(
                                icon: "eye",
                                color: .blue,
                                title: "Make it Obvious",
                                content: cue
                            )
                        }

                        if let cueTime = task.cueTime {
                            atomicHabitRow(
                                icon: "clock",
                                color: .blue,
                                title: "Cue Time",
                                content: cueTime.formatted(date: .omitted, time: .shortened)
                            )
                        }

                        if let attractiveness = task.attractiveness {
                            atomicHabitRow(
                                icon: "sparkles",
                                color: .purple,
                                title: "Make it Attractive",
                                content: attractiveness
                            )
                        }

                        if let easeStrategy = task.easeStrategy {
                            atomicHabitRow(
                                icon: "bolt",
                                color: .green,
                                title: "Make it Easy",
                                content: easeStrategy
                            )
                        }

                        if let reward = task.reward {
                            atomicHabitRow(
                                icon: "star",
                                color: .orange,
                                title: "Make it Satisfying",
                                content: reward
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            isCompleted = task.isCompletedToday()
        }
        .sheet(isPresented: $showTaskCheckIn) {
            TaskCheckInView(task: task)
                .onDisappear {
                    isCompleted = task.isCompletedToday()
                }
        }
    }

    private func atomicHabitRow(icon: String, color: Color, title: String, content: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Text(content)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
        }
    }

    private func handleTaskTap() {
        if isTimeBased {
            // Time-based negative habits MUST use check-in for time input
            if isCompleted {
                // Allow unchecking
                toggleCompletion()
            } else {
                // Force check-in sheet
                showTaskCheckIn = true
            }
        } else {
            // Regular tasks
            if isCompleted {
                toggleCompletion()
            } else {
                showTaskCheckIn = true
            }
        }
    }

    private func toggleCompletion() {
        withAnimation(.spring(response: 0.3)) {
            if isCompleted {
                if let todayLog = task.logs?.first(where: { Calendar.current.isDateInToday($0.date) }) {
                    modelContext.delete(todayLog)
                }
            }

            do {
                try modelContext.save()

                // Invalidate system cache to ensure fresh calculations
                task.system?.invalidateConsistencyCache()

                isCompleted = task.isCompletedToday()
            } catch {
                print("Error toggling task: \(error)")
            }
        }
    }
}

// MARK: - Test Card
struct TestCard: View {
    let test: PerformanceTest
    let systemConsistency: Double

    @State private var showTestEntry = false

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
        Button {
            showTestEntry = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(test.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(test.trackingFrequency.displayText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if test.isDue() {
                        Text("Due")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .clipShape(Capsule())
                    }
                }

                if let latest = analytics.latestValue {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        if test.unit == "time" {
                            Text(formatTimeValue(latest))
                                .font(.title2)
                                .fontWeight(.bold)
                        } else {
                            Text(String(format: "%.1f", latest))
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(test.unit)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

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
                                Text(String(format: "%.1f%%", abs(improvement)))
                            }
                            .font(.caption)
                            .foregroundStyle(isImproving ? .green : .red)
                        }
                    }
                }

                if (test.entries?.count ?? 0) >= 3 {
                    Text(analytics.consistencyCorrelation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showTestEntry) {
            TestEntryView(test: test)
        }
    }
}

// MARK: - Task Check-In View
struct TaskCheckInView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let task: HabitTask

    @State private var notes: String = ""
    @State private var satisfaction: Int = 5

    // For time-based negative habits
    @State private var hoursSpent: Int = 0
    @State private var minutesSpent: Int = 0

    var isTimeBased: Bool {
        task.habitType == .negative && task.hasTimeLimit
    }

    var totalMinutesSpent: Int {
        (hoursSpent * 60) + minutesSpent
    }

    var remainingLimit: Int {
        task.remainingTimeToday()
    }

    var performanceZone: HabitTask.PerformanceZone {
        task.getPerformanceZone(minutesSpent: totalMinutesSpent)
    }

    var statusColor: Color {
        switch performanceZone {
        case .excellent: return .green
        case .good: return .yellow
        case .overLimit: return .red
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text(task.name)
                                .font(.headline)

                            if task.habitType == .negative {
                                Text("Break")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange)
                                    .clipShape(Capsule())
                            }
                        }

                        if isTimeBased {
                            Text("Log time spent today")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(task.habitType == .positive ? "Mark as completed for today" : "Mark as avoided for today")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Time input for negative habits with limits
                if isTimeBased {
                    Section {
                        HStack {
                            Picker("Hours", selection: $hoursSpent) {
                                ForEach(0..<24) { hour in
                                    Text("\(hour)").tag(hour)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(maxWidth: .infinity)

                            Text("hr")
                                .foregroundStyle(.secondary)

                            Picker("Minutes", selection: $minutesSpent) {
                                ForEach([0, 15, 30, 45], id: \.self) { minute in
                                    Text("\(minute)").tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(maxWidth: .infinity)

                            Text("min")
                                .foregroundStyle(.secondary)
                        }
                        .labelsHidden()
                    } header: {
                        Text("Time Spent Today")
                    } footer: {
                        VStack(alignment: .leading, spacing: 8) {
                            // Current week limit
                            HStack {
                                Text("This week's limit:")
                                    .foregroundStyle(.secondary)
                                Text(HabitTask.formatMinutes(task.currentWeekLimit))
                                    .fontWeight(.semibold)
                            }
                            .font(.caption)

                            // Goal target
                            HStack {
                                Text("Goal target:")
                                    .foregroundStyle(.secondary)
                                Text(HabitTask.formatMinutes(task.targetLimit))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.green)
                            }
                            .font(.caption)

                            // Performance status
                            if totalMinutesSpent > 0 {
                                HStack(spacing: 6) {
                                    Text(performanceZone.emoji)
                                    Text(performanceZone.displayText)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(statusColor)
                                }
                                .font(.caption)
                                .padding(.top, 4)
                            }
                        }
                    }
                } else {
                    // Regular satisfaction picker for non-time-based habits
                    Section {
                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { rating in
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        satisfaction = rating
                                    }
                                } label: {
                                    Text(emojiForRating(rating))
                                        .font(.title2)
                                        .opacity(satisfaction >= rating ? 1.0 : 0.3)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    } header: {
                        Text("How do you feel?")
                    }
                }

                Section {
                    TextField("Any notes?", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes (Optional)")
                }
            }
            .navigationTitle("Complete Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        completeTask()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func emojiForRating(_ rating: Int) -> String {
        switch rating {
        case 1: return "😞"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "🙂"
        case 5: return "😄"
        default: return "😐"
        }
    }

    private func completeTask() {
        let log = HabitTaskLog(
            notes: notes.isEmpty ? nil : notes,
            satisfaction: isTimeBased ? nil : satisfaction,
            minutesSpent: isTimeBased ? totalMinutesSpent : nil
        )
        log.task = task

        modelContext.insert(log)

        do {
            try modelContext.save()

            // Invalidate system cache to ensure fresh calculations
            task.system?.invalidateConsistencyCache()

            dismiss()
        } catch {
            print("Error saving task log: \(error)")
        }
    }
}

// MARK: - Test Entry View
struct TestEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let test: PerformanceTest

    @State private var value: String = ""
    @State private var notes: String = ""
    @State private var conditions: String = ""

    // Time-based input
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0

    var isTimeBased: Bool {
        test.unit == "time"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(test.name)
                            .font(.headline)

                        Text("Log your measurement")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    if isTimeBased {
                        // Time input (MM:SS) - Apple-style wheel pickers
                        HStack(spacing: 0) {
                            // Minutes picker
                            Picker("Minutes", selection: $minutes) {
                                ForEach(0..<100) { minute in
                                    Text("\(minute)").tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(maxWidth: .infinity)

                            Text("min")
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)

                            // Seconds picker
                            Picker("Seconds", selection: $seconds) {
                                ForEach(0..<60) { second in
                                    Text("\(second)").tag(second)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(maxWidth: .infinity)

                            Text("sec")
                                .foregroundStyle(.secondary)
                                .padding(.trailing, 8)
                        }
                        .labelsHidden()
                    } else {
                        // Regular numeric input
                        HStack {
                            TextField("0.0", text: $value)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)

                            Text(test.unit)
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text(test.name)
                } footer: {
                    if isTimeBased {
                        Text("Scroll to select time. \(test.goalDirection.rawValue)")
                    } else {
                        Text(test.goalDirection.rawValue)
                    }
                }

                Section {
                    TextField("How did it feel?", text: $conditions, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Conditions (Optional)")
                }

                Section {
                    TextField("Any additional notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes (Optional)")
                }

                if !(test.entries?.isEmpty ?? true) {
                    Section {
                        ForEach((test.entries ?? []).sorted(by: { $0.date > $1.date }).prefix(3), id: \.id) { entry in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    if test.unit == "time" {
                                        Text(formatTimeValue(entry.value))
                                            .font(.headline)
                                    } else {
                                        Text("\(String(format: "%.1f", entry.value)) \(test.unit)")
                                            .font(.headline)
                                    }

                                    Text(relativeDateString(for: entry.date))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if let conditions = entry.conditions {
                                    Text(conditions)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    } header: {
                        Text("Recent Entries")
                    }
                }
            }
            .navigationTitle("Log Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var isValid: Bool {
        if isTimeBased {
            // For time-based tests, validate minutes and seconds
            return minutes > 0 || seconds > 0  // At least one must be non-zero
        } else {
            // For regular tests, validate numeric input
            guard let doubleValue = Double(value), doubleValue > 0 else {
                return false
            }
            return true
        }
    }

    private func saveEntry() {
        let finalValue: Double

        if isTimeBased {
            // Convert MM:SS to total seconds
            finalValue = Double(minutes * 60 + seconds)
        } else {
            // Use the numeric value directly
            guard let doubleValue = Double(value) else { return }
            finalValue = doubleValue
        }

        let entry = PerformanceTestEntry(
            value: finalValue,
            notes: notes.isEmpty ? nil : notes,
            conditions: conditions.isEmpty ? nil : conditions
        )
        entry.test = test

        modelContext.insert(entry)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving test entry: \(error)")
        }
    }

    private func relativeDateString(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // Helper to format time values (seconds -> MM:SS)
    private func formatTimeValue(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60
        return "\(minutes):\(String(format: "%02d", remainingSeconds))"
    }
}