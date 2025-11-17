//
//  CreateSystemView.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//

import SwiftUI
import SwiftData

struct CreateSystemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // System details
    @State private var systemName: String = ""
    @State private var systemDescription: String = ""
    @State private var selectedCategory: SystemCategory = .athletics

    // Tasks
    @State private var tasks: [TaskBuilder] = []
    @State private var showAddTask = false

    // Tests
    @State private var tests: [TestBuilder] = []
    @State private var showAddTest = false

    // Callback for scheduling notifications
    var onSystemCreated: ((System) -> Void)?

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - System Identity
                Section {
                    TextField("System name", text: $systemName)
                        .textFieldStyle(.plain)

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

                // MARK: - Daily Tasks
                Section {
                    ForEach(tasks) { task in
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

                            Button(role: .destructive) {
                                withAnimation {
                                    tasks.removeAll { $0.id == task.id }
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                        }
                    }

                    Button {
                        showAddTask = true
                    } label: {
                        Label(tasks.isEmpty ? "Add Your First Task" : "Add Task", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Daily Tasks")
                } footer: {
                    Text("Add the daily habits that make up this system")
                }

                // MARK: - Periodic Tests
                Section {
                    ForEach(tests) { test in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(test.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Text("\(test.frequency.displayText) • \(test.unit)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button(role: .destructive) {
                                withAnimation {
                                    tests.removeAll { $0.id == test.id }
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                        }
                    }

                    Button {
                        showAddTest = true
                    } label: {
                        Label(tests.isEmpty ? "Add Your First Test" : "Add Test", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Periodic Tests")
                } footer: {
                    Text("Track measurements like mile time or max pushups")
                }

                // Preview removed - was causing keyboard delays
            }
            .navigationTitle("New System")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createSystem()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                    .buttonStyle(.borderedProminent)
                }
            }
            .sheet(isPresented: $showAddTask) {
                AddTaskSheet { task in
                    withAnimation {
                        tasks.append(task)
                    }
                }
            }
            .sheet(isPresented: $showAddTest) {
                AddTestSheet { test in
                    withAnimation {
                        tests.append(test)
                    }
                }
            }
        }
    }

    private var isValid: Bool {
        !systemName.isEmpty && !tasks.isEmpty
    }

    private func createSystem() {
        let system = System(
            name: systemName,
            category: selectedCategory,
            description: systemDescription.isEmpty ? nil : systemDescription
        )

        // Create tasks
        var createdTasks: [HabitTask] = []
        for taskBuilder in tasks {
            let task = HabitTask(
                name: taskBuilder.name,
                description: taskBuilder.description,
                frequency: taskBuilder.frequency,
                habitType: taskBuilder.habitType,
                baselineLimit: taskBuilder.baselineLimit,
                targetLimit: taskBuilder.targetLimit
            )
            // Atomic Habits - The 4 Laws
            task.cue = taskBuilder.cue
            task.cueTime = taskBuilder.cueTime
            task.attractiveness = taskBuilder.attractiveness
            task.easeStrategy = taskBuilder.easeStrategy
            task.reward = taskBuilder.reward

            task.system = system
            modelContext.insert(task)
            createdTasks.append(task)
        }

        // Create tests
        var createdTests: [PerformanceTest] = []
        for testBuilder in tests {
            let test = PerformanceTest(
                name: testBuilder.name,
                unit: testBuilder.unit,
                goalDirection: testBuilder.goalDirection,
                trackingFrequency: testBuilder.frequency,
                description: testBuilder.description
            )
            test.system = system
            modelContext.insert(test)
            createdTests.append(test)
        }

        modelContext.insert(system)

        do {
            try modelContext.save()

            // Schedule notifications for tasks with cue times
            for task in createdTasks where task.cueTime != nil {
                notificationManager.scheduleTaskReminder(for: task)
            }

            // Schedule notifications for tests
            for test in createdTests {
                notificationManager.scheduleTestReminder(for: test)
            }

            dismiss()
        } catch {
            print("Error saving system: \(error)")
        }
    }
}

// MARK: - Task Builder
struct TaskBuilder: Identifiable {
    let id = UUID()
    var name: String
    var description: String?
    var frequency: TaskFrequency
    var habitType: HabitType

    // Time limits for negative habits
    var baselineLimit: Int?  // Starting limit in minutes
    var targetLimit: Int?  // Goal limit in minutes

    // Atomic Habits - The 4 Laws
    var cue: String?
    var cueTime: Date?
    var attractiveness: String?
    var easeStrategy: String?
    var reward: String?
}

// MARK: - Test Unit Enum
enum TestUnit: String, CaseIterable, Identifiable {
    // Time-based
    case time = "Time (MM:SS)"
    case minutes = "Minutes"
    case seconds = "Seconds"
    case hours = "Hours"

    // Distance
    case miles = "Miles"
    case kilometers = "Kilometers"
    case meters = "Meters"
    case feet = "Feet"

    // Weight
    case pounds = "Pounds (lbs)"
    case kilograms = "Kilograms (kg)"

    // Reps/Count
    case reps = "Reps"
    case count = "Count"

    // Percentage
    case percentage = "Percentage (%)"

    // Other
    case calories = "Calories"
    case heartRate = "BPM"

    var id: String { rawValue }

    var displayValue: String {
        switch self {
        case .time: return "time"
        case .minutes: return "min"
        case .seconds: return "sec"
        case .hours: return "hr"
        case .miles: return "mi"
        case .kilometers: return "km"
        case .meters: return "m"
        case .feet: return "ft"
        case .pounds: return "lbs"
        case .kilograms: return "kg"
        case .reps: return "reps"
        case .count: return "count"
        case .percentage: return "%"
        case .calories: return "cal"
        case .heartRate: return "bpm"
        }
    }

    var isTimeBased: Bool {
        self == .time
    }
}

// MARK: - Test Builder
struct TestBuilder: Identifiable {
    let id = UUID()
    var name: String
    var unit: String
    var goalDirection: TestGoalDirection
    var frequency: TestFrequency
    var description: String?
}

// MARK: - Add Task Sheet
struct AddTaskSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var taskName: String = ""
    @State private var taskDescription: String = ""
    @State private var selectedFrequency: TaskFrequency = .daily
    @State private var selectedHabitType: HabitType = .positive

    // Time limits for negative habits
    @State private var baselineHours: Int = 2
    @State private var baselineMinutes: Int = 0
    @State private var targetHours: Int = 0
    @State private var targetMinutes: Int = 15

    // Atomic Habits - The 4 Laws
    @State private var cue: String = ""
    @State private var cueTime: Date = Date()
    @State private var useCueTime: Bool = false
    @State private var attractiveness: String = ""
    @State private var easeStrategy: String = ""
    @State private var reward: String = ""
    @State private var showAtomicHabits: Bool = false

    let onAdd: (TaskBuilder) -> Void

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
                } footer: {
                    if selectedHabitType == .positive {
                        Text("Build good habits: things you want to do more of")
                    } else {
                        Text("Break bad habits: things you want to avoid or do less of")
                    }
                }

                Section {
                    Picker("Frequency", selection: $selectedFrequency) {
                        Text("Every Day").tag(TaskFrequency.daily)
                        Text("Weekdays").tag(TaskFrequency.weekdays)
                        Text("Weekends").tag(TaskFrequency.weekends)
                    }
                } header: {
                    Text("Frequency")
                }

                // MARK: - Time Limits (Negative Habits Only)
                if selectedHabitType == .negative {
                    Section {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Set your gradual reduction plan")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            // Baseline limit
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

                            // Target limit
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
                        Text("Your limit will gradually decrease each week. Need 4 successful days per week to progress.")
                    }
                }

                // MARK: - Atomic Habits Section
                Section {
                    DisclosureGroup("The 4 Laws (Optional)", isExpanded: $showAtomicHabits) {
                        VStack(alignment: .leading, spacing: 16) {
                            // Law 1: Make it Obvious
                            VStack(alignment: .leading, spacing: 8) {
                                Label("1st Law: Make it Obvious", systemImage: "eye")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.blue)

                                TextField("When/where will you do this?", text: $cue, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(2...3)

                                Toggle("Set specific time", isOn: $useCueTime)
                                    .tint(.blue)

                                if useCueTime {
                                    DatePicker("Time", selection: $cueTime, displayedComponents: .hourAndMinute)
                                }
                            }
                            .padding(.vertical, 8)

                            Divider()

                            // Law 2: Make it Attractive
                            VStack(alignment: .leading, spacing: 8) {
                                Label("2nd Law: Make it Attractive", systemImage: "sparkles")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.purple)

                                TextField("How can you make this appealing?", text: $attractiveness, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(2...3)
                            }
                            .padding(.vertical, 8)

                            Divider()

                            // Law 3: Make it Easy
                            VStack(alignment: .leading, spacing: 8) {
                                Label("3rd Law: Make it Easy", systemImage: "bolt")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.green)

                                TextField("2-minute version or strategy", text: $easeStrategy, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(2...3)
                            }
                            .padding(.vertical, 8)

                            Divider()

                            // Law 4: Make it Satisfying
                            VStack(alignment: .leading, spacing: 8) {
                                Label("4th Law: Make it Satisfying", systemImage: "star")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.orange)

                                TextField("Immediate reward after completing", text: $reward, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(2...3)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                } header: {
                    Text("Atomic Habits")
                } footer: {
                    Text("Apply James Clear's 4 Laws to make this habit stick. These are optional but powerful.")
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
                        // Calculate total minutes for limits
                        let baselineTotal = (baselineHours * 60) + baselineMinutes
                        let targetTotal = (targetHours * 60) + targetMinutes

                        let task = TaskBuilder(
                            name: taskName,
                            description: taskDescription.isEmpty ? nil : taskDescription,
                            frequency: selectedFrequency,
                            habitType: selectedHabitType,
                            baselineLimit: selectedHabitType == .negative ? baselineTotal : nil,
                            targetLimit: selectedHabitType == .negative ? targetTotal : nil,
                            cue: cue.isEmpty ? nil : cue,
                            cueTime: useCueTime ? cueTime : nil,
                            attractiveness: attractiveness.isEmpty ? nil : attractiveness,
                            easeStrategy: easeStrategy.isEmpty ? nil : easeStrategy,
                            reward: reward.isEmpty ? nil : reward
                        )
                        onAdd(task)
                        dismiss()
                    }
                    .disabled(taskName.isEmpty)
                    .fontWeight(.semibold)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

// MARK: - Add Test Sheet
struct AddTestSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var testName: String = ""
    @State private var selectedUnit: TestUnit = .time
    @State private var testDescription: String = ""
    @State private var goalDirection: TestGoalDirection = .higher
    @State private var frequency: TestFrequency = .biweekly

    let onAdd: (TestBuilder) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Test name", text: $testName)

                    Picker("Unit", selection: $selectedUnit) {
                        ForEach(TestUnit.allCases) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }

                    TextField("Description (optional)", text: $testDescription, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Test Details")
                } footer: {
                    Text("Select the unit for measuring this test")
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
                        let test = TestBuilder(
                            name: testName,
                            unit: selectedUnit.displayValue,
                            goalDirection: goalDirection,
                            frequency: frequency,
                            description: testDescription.isEmpty ? nil : testDescription
                        )
                        onAdd(test)
                        dismiss()
                    }
                    .disabled(testName.isEmpty)
                    .fontWeight(.semibold)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}