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

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - System Identity
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What system do you want to build?")
                            .font(.headline)

                        Text("Examples: Hybrid Athlete, Consistent Reader, Creative Professional")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)

                    TextField("System name", text: $systemName)
                        .textFieldStyle(.plain)

                    TextField("Description (optional)", text: $systemDescription, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(2...4)
                } header: {
                    Label("System Identity", systemImage: "gearshape.2")
                }

                // MARK: - Category
                Section {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(SystemCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.systemIcon)
                                .tag(category)
                        }
                    }
                } header: {
                    Label("Category", systemImage: "folder")
                }

                // MARK: - Daily Tasks
                Section {
                    if tasks.isEmpty {
                        Text("No tasks yet")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
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
                    }

                    Button {
                        showAddTask = true
                    } label: {
                        Label("Add Daily Task", systemImage: "plus.circle")
                    }
                } header: {
                    Label("Daily Tasks", systemImage: "checkmark.square")
                } footer: {
                    Text("Add the daily habits that make up this system. Example: Run, Lift weights")
                }

                // MARK: - Periodic Tests
                Section {
                    if tests.isEmpty {
                        Text("No tests yet")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(tests) { test in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(test.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    HStack(spacing: 4) {
                                        Text(test.frequency.displayText)
                                        Text("•")
                                        Text(test.unit)
                                    }
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
                    }

                    Button {
                        showAddTest = true
                    } label: {
                        Label("Add Periodic Test", systemImage: "plus.circle")
                    }
                } header: {
                    Label("Periodic Tests", systemImage: "chart.bar")
                } footer: {
                    Text("Add measurements to track system effectiveness. Example: Mile time, Max pushups")
                }

                // MARK: - Preview
                if !systemName.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: selectedCategory.systemIcon)
                                    .font(.title2)
                                    .foregroundStyle(Color(hex: selectedCategory.defaultColor))
                                    .frame(width: 44, height: 44)
                                    .background(Color(hex: selectedCategory.defaultColor).opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(systemName)
                                        .font(.headline)

                                    Text("\(tasks.count) tasks • \(tests.count) tests")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } header: {
                        Text("Preview")
                    }
                }
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
        for taskBuilder in tasks {
            let task = HabitTask(
                name: taskBuilder.name,
                description: taskBuilder.description,
                frequency: taskBuilder.frequency
            )
            task.system = system
            modelContext.insert(task)
        }

        // Create tests
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
        }

        modelContext.insert(system)

        do {
            try modelContext.save()
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
                    Picker("Frequency", selection: $selectedFrequency) {
                        Text("Every Day").tag(TaskFrequency.daily)
                        Text("Weekdays").tag(TaskFrequency.weekdays)
                        Text("Weekends").tag(TaskFrequency.weekends)
                    }
                } header: {
                    Text("Frequency")
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
                        let task = TaskBuilder(
                            name: taskName,
                            description: taskDescription.isEmpty ? nil : taskDescription,
                            frequency: selectedFrequency
                        )
                        onAdd(task)
                        dismiss()
                    }
                    .disabled(taskName.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Add Test Sheet
struct AddTestSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var testName: String = ""
    @State private var testUnit: String = ""
    @State private var testDescription: String = ""
    @State private var goalDirection: TestGoalDirection = .higher
    @State private var frequency: TestFrequency = .biweekly

    let onAdd: (TestBuilder) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Test name", text: $testName)
                    TextField("Unit", text: $testUnit)
                    TextField("Description (optional)", text: $testDescription, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Test Details")
                } footer: {
                    Text("Example: Mile time (minutes), Max pushups (reps)")
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
                            unit: testUnit,
                            goalDirection: goalDirection,
                            frequency: frequency,
                            description: testDescription.isEmpty ? nil : testDescription
                        )
                        onAdd(test)
                        dismiss()
                    }
                    .disabled(testName.isEmpty || testUnit.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}