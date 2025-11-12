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

    var body: some View {
        ScrollView {
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
        .alert("Delete System?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSystem()
            }
        } message: {
            Text("This will permanently delete '\(system.name)' and all associated tasks, tests, and data. This action cannot be undone.")
        }
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
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                SystemStatCard(
                    title: "Today",
                    value: "\(Int(system.todayCompletionRate * 100))%",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                SystemStatCard(
                    title: "Streak",
                    value: "\(system.currentStreak)",
                    icon: "flame.fill",
                    color: .orange
                )
            }

            HStack(spacing: 16) {
                SystemStatCard(
                    title: "Consistency",
                    value: "\(Int(system.overallConsistency * 100))%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                )

                SystemStatCard(
                    title: "Active Tests",
                    value: "\(system.tests.count)",
                    icon: "chart.bar.fill",
                    color: .purple
                )
            }
        }
    }

    // MARK: - Tasks Section
    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Daily Tasks", systemImage: "checkmark.square")
                    .font(.headline)

                Spacer()

                Text("\(system.completedTodayCount)/\(system.todaysTasks.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if system.tasks.isEmpty {
                Text("No tasks in this system yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(system.tasks) { task in
                    TaskDetailRow(task: task, modelContext: modelContext)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    // MARK: - Tests Section
    private var testsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Periodic Tests", systemImage: "chart.bar")
                .font(.headline)

            if system.tests.isEmpty {
                Text("No tests in this system yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(system.tests) { test in
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
        modelContext.delete(system)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error deleting system: \(error)")
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
    let task: Task
    let modelContext: ModelContext

    @State private var isCompleted: Bool = false
    @State private var showTaskCheckIn = false

    var body: some View {
        Button {
            if isCompleted {
                toggleCompletion()
            } else {
                showTaskCheckIn = true
            }
        } label: {
            HStack(spacing: 16) {
                // Completion indicator
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isCompleted ? .green : .gray.opacity(0.3))

                // Task details
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(task.frequency.displayText)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Stats
                    HStack(spacing: 12) {
                        if task.currentStreak > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                                Text("\(task.currentStreak) day")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
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
        }
        .buttonStyle(.plain)
        .padding()
        .background(Color(.systemGray6))
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

    private func toggleCompletion() {
        withAnimation(.spring(response: 0.3)) {
            if isCompleted {
                if let todayLog = task.logs.first(where: { Calendar.current.isDateInToday($0.date) }) {
                    modelContext.delete(todayLog)
                }
            }

            do {
                try modelContext.save()
                isCompleted = task.isCompletedToday()
            } catch {
                print("Error toggling task: \(error)")
            }
        }
    }
}

// MARK: - Test Card
struct TestCard: View {
    let test: Test
    let systemConsistency: Double

    @State private var showTestEntry = false

    var analytics: TestAnalytics {
        test.getAnalytics(systemConsistency: systemConsistency)
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
                        Text(String(format: "%.1f", latest))
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(test.unit)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        if let improvement = analytics.improvement {
                            HStack(spacing: 4) {
                                Image(systemName: improvement > 0 ? "arrow.up" : "arrow.down")
                                Text(String(format: "%.1f%%", abs(improvement)))
                            }
                            .font(.caption)
                            .foregroundStyle(improvement > 0 ? .green : .red)
                        }
                    }
                }

                if test.entries.count >= 3 {
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

    let task: Task

    @State private var notes: String = ""
    @State private var satisfaction: Int = 5

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(task.name)
                            .font(.headline)

                        Text("Mark as completed for today")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

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
        let log = TaskLog(
            notes: notes.isEmpty ? nil : notes,
            satisfaction: satisfaction
        )
        log.task = task

        modelContext.insert(log)

        do {
            try modelContext.save()
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

    let test: Test

    @State private var value: String = ""
    @State private var notes: String = ""
    @State private var conditions: String = ""

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
                    HStack {
                        TextField("0.0", text: $value)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)

                        Text(test.unit)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text(test.name)
                } footer: {
                    Text(test.goalDirection.rawValue)
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

                if !test.entries.isEmpty {
                    Section {
                        ForEach(test.entries.sorted(by: { $0.date > $1.date }).prefix(3), id: \.id) { entry in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(String(format: "%.1f", entry.value)) \(test.unit)")
                                        .font(.headline)

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
        guard let doubleValue = Double(value), doubleValue > 0 else {
            return false
        }
        return true
    }

    private func saveEntry() {
        guard let doubleValue = Double(value) else { return }

        let entry = TestEntry(
            value: doubleValue,
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
}