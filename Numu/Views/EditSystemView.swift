//
//  EditSystemView.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//

import SwiftUI
import SwiftData

struct EditSystemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(NotificationManager.self) private var notificationManager

    let system: System

    // System details
    @State private var systemName: String = ""
    @State private var systemDescription: String = ""
    @State private var selectedCategory: SystemCategory = .athletics
    @State private var selectedColor: String = "#FF6B35"
    @State private var selectedIcon: String = "figure.run"
    @State private var showColorPicker = false
    @State private var showIconPicker = false

    // Tasks - work with existing tasks
    @State private var showAddTask = false
    @State private var taskToEdit: HabitTask?
    @State private var showEditTask = false

    // Tests - work with existing tests
    @State private var showAddTest = false
    @State private var testToEdit: PerformanceTest?
    @State private var showEditTest = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - System Identity
                Section {
                    TextField("System name", text: $systemName)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()

                    TextField("Description (optional)", text: $systemDescription, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(2...4)
                } header: {
                    Text("System Identity")
                } footer: {
                    Text("Examples: Hybrid Athlete, Consistent Reader, Creative Professional")
                }

                // MARK: - Category
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(SystemCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }

                // MARK: - Appearance
                Section {
                    // Color Picker
                    Button {
                        showColorPicker = true
                    } label: {
                        HStack {
                            Text("Color")
                                .foregroundStyle(.primary)
                            Spacer()
                            Circle()
                                .fill(Color(hex: selectedColor))
                                .frame(width: 30, height: 30)
                        }
                    }
                    .buttonStyle(.plain)

                    // Icon Picker
                    Button {
                        showIconPicker = true
                    } label: {
                        HStack {
                            Text("Icon")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: selectedIcon)
                                .font(.title3)
                                .foregroundStyle(Color(hex: selectedColor))
                        }
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("Appearance")
                }

                // MARK: - Tasks
                Section {
                    ForEach(system.tasks ?? []) { task in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Text(task.frequency.displayText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                taskToEdit = task
                                showEditTask = true
                            } label: {
                                Image(systemName: "pencil")
                                    .foregroundStyle(.blue)
                            }
                            .buttonStyle(.borderless)

                            Button(role: .destructive) {
                                deleteTask(task)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                    }

                    Button {
                        showAddTask = true
                    } label: {
                        Label((system.tasks?.isEmpty ?? true) ? "Add Your First Task" : "Add Task", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Tasks")
                } footer: {
                    Text("Add or edit the tasks that make up this system")
                }

                // MARK: - Tests
                Section {
                    ForEach(system.tests ?? []) { test in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(test.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Text("\(test.trackingFrequency.displayText) • \(test.unit)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                testToEdit = test
                                showEditTest = true
                            } label: {
                                Image(systemName: "pencil")
                                    .foregroundStyle(.blue)
                            }
                            .buttonStyle(.borderless)

                            Button(role: .destructive) {
                                deleteTest(test)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                    }

                    Button {
                        showAddTest = true
                    } label: {
                        Label((system.tests?.isEmpty ?? true) ? "Add Your First Test" : "Add Test", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Periodic Tests")
                } footer: {
                    Text("Track measurements like mile time or max pushups")
                }
            }
            .navigationTitle("Edit System")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showColorPicker) {
                ColorPickerSheet(selectedColor: $selectedColor)
            }
            .sheet(isPresented: $showIconPicker) {
                IconPickerSheet(selectedIcon: $selectedIcon, color: selectedColor)
            }
            .sheet(isPresented: $showAddTask) {
                AddTaskToSystemSheet(system: system)
            }
            .sheet(isPresented: $showEditTask) {
                if let task = taskToEdit {
                    EditTaskSheet(task: task)
                }
            }
            .sheet(isPresented: $showAddTest) {
                AddTestToSystemSheet(system: system)
            }
            .sheet(isPresented: $showEditTest) {
                if let test = testToEdit {
                    EditTestSheet(test: test)
                }
            }
        }
        .onAppear {
            // Initialize with current system values
            systemName = system.name
            systemDescription = system.systemDescription ?? ""
            selectedCategory = system.category
            selectedColor = system.color
            selectedIcon = system.icon
        }
    }

    private var isValid: Bool {
        !systemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveChanges() {
        system.name = systemName.trimmingCharacters(in: .whitespacesAndNewlines)
        system.systemDescription = systemDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : systemDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        system.category = selectedCategory
        system.color = selectedColor
        system.icon = selectedIcon

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving system changes: \(error)")
        }
    }

    private func deleteTask(_ task: HabitTask) {
        withAnimation {
            // Cancel notifications for this task
            notificationManager.cancelTaskReminder(for: task)

            modelContext.delete(task)

            do {
                try modelContext.save()
            } catch {
                print("Error deleting task: \(error)")
            }
        }
    }

    private func deleteTest(_ test: PerformanceTest) {
        withAnimation {
            // Cancel notifications for this test
            notificationManager.cancelTestReminder(for: test)

            modelContext.delete(test)

            do {
                try modelContext.save()
            } catch {
                print("Error deleting test: \(error)")
            }
        }
    }
}

// MARK: - Add Task to Existing System Sheet
struct AddTaskToSystemSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(HealthKitService.self) private var healthKitService

    let system: System

    @State private var taskName: String = ""
    @State private var taskDescription: String = ""
    @State private var selectedFrequency: TaskFrequency = .daily
    @State private var selectedHabitType: HabitType = .positive

    // Weekly frequency state
    @State private var frequencyMode: FrequencyMode = .daily
    @State private var weeklyTargetTimes: Int = 3

    enum FrequencyMode: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
    }

    // Time limits for negative habits
    @State private var baselineHours: Int = 2
    @State private var baselineMinutes: Int = 0
    @State private var targetHours: Int = 0
    @State private var targetMinutes: Int = 15

    // HealthKit Integration
    @State private var healthKitAutoComplete: Bool = false
    @State private var selectedActivityGroup: ActivityGroup = .anyCardio
    @State private var selectedMetric: HealthKitMetricType = .stepCount
    @State private var showHealthKitSection: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task name", text: $taskName)
                    TextField("Description (optional)", text: $taskDescription, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Task Details")
                }

                Section {
                    Picker("Type", selection: $selectedHabitType) {
                        Text("Build (Do More)").tag(HabitType.positive)
                        Text("Break (Do Less)").tag(HabitType.negative)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Habit Type")
                }

                Section {
                    Picker("Frequency Type", selection: $frequencyMode) {
                        ForEach(FrequencyMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: frequencyMode) { _, newMode in
                        switch newMode {
                        case .daily:
                            selectedFrequency = .daily
                        case .weekly:
                            selectedFrequency = .weeklyTarget(times: weeklyTargetTimes)
                        }
                    }

                    if frequencyMode == .daily {
                        Picker("Schedule", selection: $selectedFrequency) {
                            Text("Every Day").tag(TaskFrequency.daily)
                            Text("Weekdays").tag(TaskFrequency.weekdays)
                            Text("Weekends").tag(TaskFrequency.weekends)
                        }
                    } else {
                        Picker("Times per week", selection: $weeklyTargetTimes) {
                            ForEach(1...7, id: \.self) { count in
                                Text("\(count)x per week").tag(count)
                            }
                        }
                        .onChange(of: weeklyTargetTimes) { _, newValue in
                            selectedFrequency = .weeklyTarget(times: newValue)
                        }
                    }
                } header: {
                    Text("Frequency")
                }

                if selectedHabitType == .negative {
                    Section {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Set your gradual reduction plan")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Current Usage (per day)")
                                    .font(.caption)
                                    .fontWeight(.semibold)

                                HStack {
                                    Picker("Hours", selection: $baselineHours) {
                                        ForEach(0..<10) { hour in
                                            Text("\(hour)").tag(hour)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(maxWidth: .infinity)

                                    Text("hr")
                                        .foregroundStyle(.secondary)

                                    Picker("Minutes", selection: $baselineMinutes) {
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
                            }

                            Divider()

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Goal (per day)")
                                    .font(.caption)
                                    .fontWeight(.semibold)

                                HStack {
                                    Picker("Hours", selection: $targetHours) {
                                        ForEach(0..<10) { hour in
                                            Text("\(hour)").tag(hour)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(maxWidth: .infinity)

                                    Text("hr")
                                        .foregroundStyle(.secondary)

                                    Picker("Minutes", selection: $targetMinutes) {
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
                            }
                        }
                    } header: {
                        Text("Time Limits")
                    } footer: {
                        Text("Your limit will gradually decrease each week")
                    }
                }

                // MARK: - HealthKit Integration
                if healthKitService.isHealthKitAvailable {
                    Section {
                        DisclosureGroup("Auto-Complete via HealthKit (Optional)", isExpanded: $showHealthKitSection) {
                            VStack(alignment: .leading, spacing: 20) {
                                Toggle("Enable Auto-Complete", isOn: $healthKitAutoComplete)
                                    .tint(.blue)

                                if healthKitAutoComplete {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("Select the activity or metric to track")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)

                                        // Activity Group Picker
                                        Picker("Tracking Mode", selection: $selectedActivityGroup) {
                                            ForEach(ActivityGroup.allCases, id: \.self) { group in
                                                Label(group.rawValue, systemImage: group.icon)
                                                    .tag(group)
                                            }
                                        }
                                        .pickerStyle(.menu)

                                        // Show description of what's included
                                        Text(selectedActivityGroup.description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 12)
                                            .background(Color(.systemGray6).opacity(0.5), in: RoundedRectangle(cornerRadius: 8))

                                        // If specific activity selected, show metric picker
                                        if selectedActivityGroup == .specificActivity {
                                            Picker("Specific Activity", selection: $selectedMetric) {
                                                ForEach(HealthKitCategory.allCases, id: \.self) { category in
                                                    Section(header: Text(category.rawValue)) {
                                                        ForEach(HealthKitMetricType.allCases.filter { $0.category == category }, id: \.self) { metric in
                                                            Label(metric.displayName, systemImage: metric.icon)
                                                                .tag(metric)
                                                        }
                                                    }
                                                }
                                            }
                                            .pickerStyle(.menu)
                                        }

                                        // Preview / Example
                                        HStack(spacing: 8) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                                .font(.caption)

                                            if selectedActivityGroup == .specificActivity {
                                                Text("Auto-completes when you track \(selectedMetric.displayName.lowercased())")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            } else {
                                                Text("Auto-completes when you do ANY of these activities")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(Color(.systemGreen).opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                    } header: {
                        Text("HealthKit Integration")
                    } footer: {
                        if !healthKitService.isAuthorized {
                            Text("⚠️ HealthKit authorization required. Enable in Settings → Health → Data Access.")
                        } else {
                            Text("Task will automatically complete when you log the activity in Apple Health or your Apple Watch.")
                        }
                    }
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addTask()
                    }
                    .disabled(taskName.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func addTask() {
        let baselineTotal = selectedHabitType == .negative ? (baselineHours * 60) + baselineMinutes : nil
        let targetTotal = selectedHabitType == .negative ? (targetHours * 60) + targetMinutes : nil

        let task = HabitTask(
            name: taskName,
            description: taskDescription.isEmpty ? nil : taskDescription,
            frequency: selectedFrequency,
            habitType: selectedHabitType,
            baselineLimit: baselineTotal,
            targetLimit: targetTotal
        )

        // Add HealthKit settings if enabled
        if healthKitAutoComplete {
            if selectedActivityGroup == .specificActivity {
                // Save specific metric
                task.healthKitMetric = selectedMetric
                task.healthKitActivityGroup = nil
            } else {
                // Save activity group
                task.healthKitActivityGroup = selectedActivityGroup
                task.healthKitMetric = nil
            }
            task.healthKitAutoCompleteEnabled = true
        }

        task.system = system
        modelContext.insert(task)

        do {
            try modelContext.save()

            // Schedule notification if there's a cue time
            if task.cueTime != nil {
                notificationManager.scheduleTaskReminder(for: task)
            }

            dismiss()
        } catch {
            print("Error saving task: \(error)")
        }
    }
}

// MARK: - Edit Task Sheet
struct EditTaskSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let task: HabitTask

    @State private var taskName: String
    @State private var taskDescription: String

    init(task: HabitTask) {
        self.task = task
        _taskName = State(initialValue: task.name)
        _taskDescription = State(initialValue: task.taskDescription ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task name", text: $taskName)
                    TextField("Description (optional)", text: $taskDescription, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Task Details")
                }

                Section {
                    Text("Frequency: \(task.frequency.displayText)")
                        .foregroundStyle(.secondary)
                    Text("Type: \(task.habitType == .positive ? "Build" : "Break")")
                        .foregroundStyle(.secondary)

                    if task.healthKitAutoCompleteEnabled {
                        if let activityGroup = task.healthKitActivityGroup {
                            Text("HealthKit: \(activityGroup.rawValue)")
                                .foregroundStyle(.secondary)
                        } else if let metric = task.healthKitMetric {
                            Text("HealthKit: \(metric.displayName)")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Task Properties")
                } footer: {
                    Text("To change frequency, type, or HealthKit settings, delete and recreate the task")
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(taskName.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveChanges() {
        task.name = taskName
        task.taskDescription = taskDescription.isEmpty ? nil : taskDescription

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving task changes: \(error)")
        }
    }
}

// MARK: - Add Test to Existing System Sheet
struct AddTestToSystemSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(NotificationManager.self) private var notificationManager

    let system: System

    @State private var testName: String = ""
    @State private var selectedUnit: String = "Time (MM:SS)"
    @State private var testDescription: String = ""
    @State private var goalDirection: TestGoalDirection = .higher
    @State private var frequency: TestFrequency = .biweekly
    @State private var initialOffsetDays: Int = 0

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Test name", text: $testName)
                    TextField("Unit", text: $selectedUnit)
                    TextField("Description (optional)", text: $testDescription, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Test Details")
                }

                Section {
                    Picker("Goal", selection: $goalDirection) {
                        Text("Higher is better").tag(TestGoalDirection.higher)
                        Text("Lower is better").tag(TestGoalDirection.lower)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Goal Direction")
                }

                Section {
                    Picker("Frequency", selection: $frequency) {
                        Text("Weekly").tag(TestFrequency.weekly)
                        Text("Every 2 weeks").tag(TestFrequency.biweekly)
                        Text("Monthly").tag(TestFrequency.monthly)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("How Often to Test")
                }

                Section {
                    Picker("First Test", selection: $initialOffsetDays) {
                        Text("Due today").tag(0)
                        Text("Due in 2 days").tag(2)
                        Text("Due in 3 days").tag(3)
                        Text("Due in 5 days").tag(5)
                        Text("Due in 7 days").tag(7)
                    }
                } header: {
                    Text("When to Start")
                }
            }
            .navigationTitle("Add Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addTest()
                    }
                    .disabled(testName.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func addTest() {
        let test = PerformanceTest(
            name: testName,
            unit: selectedUnit,
            goalDirection: goalDirection,
            trackingFrequency: frequency,
            description: testDescription.isEmpty ? nil : testDescription,
            initialOffsetDays: initialOffsetDays
        )

        test.system = system
        modelContext.insert(test)

        do {
            try modelContext.save()

            // Schedule notification
            notificationManager.scheduleTestReminder(for: test)

            dismiss()
        } catch {
            print("Error saving test: \(error)")
        }
    }
}

// MARK: - Edit Test Sheet
struct EditTestSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let test: PerformanceTest

    @State private var testName: String
    @State private var testDescription: String

    init(test: PerformanceTest) {
        self.test = test
        _testName = State(initialValue: test.name)
        _testDescription = State(initialValue: test.testDescription ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Test name", text: $testName)
                    TextField("Description (optional)", text: $testDescription, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Test Details")
                }

                Section {
                    Text("Unit: \(test.unit)")
                        .foregroundStyle(.secondary)
                    Text("Frequency: \(test.trackingFrequency.displayText)")
                        .foregroundStyle(.secondary)
                    Text("Goal: \(test.goalDirection == .higher ? "Higher is better" : "Lower is better")")
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Test Properties")
                } footer: {
                    Text("To change these properties, delete and recreate the test")
                }
            }
            .navigationTitle("Edit Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(testName.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveChanges() {
        test.name = testName
        test.testDescription = testDescription.isEmpty ? nil : testDescription

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving test changes: \(error)")
        }
    }
}

// MARK: - Color Picker Sheet
struct ColorPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedColor: String

    let colors = [
        // Reds & Oranges
        "#FF6B35", "#E94560", "#FF4757", "#EE5A6F",
        "#F7931E", "#FF9F43", "#FDC830", "#F8B500",

        // Pinks & Purples
        "#FF6B9D", "#E056FD", "#590696", "#A55EEA",
        "#C471ED", "#8854D0", "#6C5CE7", "#A29BFE",

        // Blues & Teals
        "#4A5899", "#3742FA", "#1E90FF", "#5F27CD",
        "#37E2D5", "#22A39F", "#0FBCF9", "#48DBfB",

        // Greens
        "#C5E99B", "#26DE81", "#20BF6B", "#01A3A4",
        "#2ECC71", "#00D2D3", "#1ABC9C", "#16A085",

        // Neutrals & Darks
        "#C9ADA7", "#95A5A6", "#1A1A2E", "#2C3E50"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 16) {
                    ForEach(colors, id: \.self) { color in
                        Button {
                            selectedColor = color
                            dismiss()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 60, height: 60)

                                if selectedColor == color {
                                    Image(systemName: "checkmark")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Icon Picker Sheet
struct IconPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedIcon: String
    let color: String

    let icons = [
        "figure.run", "figure.walk", "dumbbell.fill", "heart.fill",
        "book.fill", "pencil", "paintbrush.fill", "music.note",
        "brain.head.profile", "leaf.fill", "sun.max.fill", "moon.stars.fill",
        "flame.fill", "star.fill", "bolt.fill", "sparkles"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 16) {
                    ForEach(icons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                            dismiss()
                        } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: color).opacity(0.15))
                                        .frame(width: 60, height: 60)

                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundStyle(Color(hex: color))
                                }

                                if selectedIcon == icon {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.caption)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
