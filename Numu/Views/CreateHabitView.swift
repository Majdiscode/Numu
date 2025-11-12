//
//  CreateHabitView.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//

import SwiftUI
import SwiftData

struct CreateHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var identity: String = ""
    @State private var actionName: String = ""
    @State private var selectedCategory: HabitCategory = .health
    @State private var frequency: HabitFrequency = .daily

    // Atomic Habits - The 4 Laws (Optional for now)
    @State private var showAdvanced = false
    @State private var cue: String = ""
    @State private var cueTime: Date?
    @State private var attractiveness: String = ""
    @State private var easeStrategy: String = ""
    @State private var reward: String = ""

    // Outcome Metrics (Optional)
    @State private var enableMetrics = false
    @State private var metricName: String = ""
    @State private var metricUnit: String = ""
    @State private var metricGoalDirection: MetricGoalDirection = .higher
    @State private var metricFrequency: TrackingFrequency = .biweekly

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Identity Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Who do you want to become?")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text("Focus on identity, not outcomes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)

                    HStack(spacing: 4) {
                        Text("I am a person who")
                            .foregroundStyle(.secondary)
                        TextField("reads every day", text: $actionName)
                            .textFieldStyle(.plain)
                    }

                    TextField("Identity (e.g., reader, athlete, creator)", text: $identity)
                        .textFieldStyle(.plain)
                } header: {
                    Label("Identity-Based Habit", systemImage: "person.fill")
                }

                // MARK: - Category & Appearance
                Section {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(HabitCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.systemIcon)
                                .tag(category)
                        }
                    }

                    Picker("Frequency", selection: $frequency) {
                        Text("Every Day").tag(HabitFrequency.daily)
                        Text("Weekdays").tag(HabitFrequency.weekdays)
                        Text("Weekends").tag(HabitFrequency.weekends)
                    }
                } header: {
                    Label("System Details", systemImage: "gearshape.fill")
                }

                // MARK: - The 4 Laws (Advanced)
                Section {
                    Button {
                        withAnimation {
                            showAdvanced.toggle()
                        }
                    } label: {
                        HStack {
                            Text("The 4 Laws (Optional)")
                            Spacer()
                            Image(systemName: showAdvanced ? "chevron.up" : "chevron.down")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)

                    if showAdvanced {
                        VStack(alignment: .leading, spacing: 12) {
                            // Law 1: Make it Obvious
                            VStack(alignment: .leading, spacing: 4) {
                                Text("1. Make it Obvious")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                TextField("When/where will you do this?", text: $cue)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.caption)
                            }

                            // Law 2: Make it Attractive
                            VStack(alignment: .leading, spacing: 4) {
                                Text("2. Make it Attractive")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                TextField("How to make it enjoyable?", text: $attractiveness)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.caption)
                            }

                            // Law 3: Make it Easy
                            VStack(alignment: .leading, spacing: 4) {
                                Text("3. Make it Easy")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                TextField("2-minute version?", text: $easeStrategy)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.caption)
                            }

                            // Law 4: Make it Satisfying
                            VStack(alignment: .leading, spacing: 4) {
                                Text("4. Make it Satisfying")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                TextField("Immediate reward?", text: $reward)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Label("Atomic Habits Framework", systemImage: "atom")
                }

                // MARK: - Outcome Metrics (Optional)
                Section {
                    Toggle("Track outcome metrics", isOn: $enableMetrics)

                    if enableMetrics {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("What will you measure?")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                TextField("e.g., Mile time, Weight, Pages", text: $metricName)
                                    .textFieldStyle(.roundedBorder)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Unit of measurement")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                TextField("e.g., minutes, lbs, pages", text: $metricUnit)
                                    .textFieldStyle(.roundedBorder)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Goal direction")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Picker("Direction", selection: $metricGoalDirection) {
                                    Text("Higher is better").tag(MetricGoalDirection.higher)
                                    Text("Lower is better").tag(MetricGoalDirection.lower)
                                }
                                .pickerStyle(.segmented)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("How often to track")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Picker("Frequency", selection: $metricFrequency) {
                                    Text("Weekly").tag(TrackingFrequency.weekly)
                                    Text("Every 2 weeks").tag(TrackingFrequency.biweekly)
                                    Text("Monthly").tag(TrackingFrequency.days(30))
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Label("Outcome Tracking (Optional)", systemImage: "chart.xyaxis.line")
                } footer: {
                    if enableMetrics {
                        Text("Track real-world results to see how your consistency correlates with improvement. Example: Track mile time every 2 weeks to see how daily running impacts your performance.")
                    } else {
                        Text("Focus on systems, not goals. Optionally track outcomes to prove your system works.")
                    }
                }

                // MARK: - Preview
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: selectedCategory.systemIcon)
                            .font(.title2)
                            .foregroundStyle(Color(hex: selectedCategory.defaultColor))
                            .frame(width: 44, height: 44)
                            .background(Color(hex: selectedCategory.defaultColor).opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        VStack(alignment: .leading, spacing: 4) {
                            if !identity.isEmpty {
                                Text("I am a \(identity)")
                                    .font(.headline)
                            }
                            if !actionName.isEmpty {
                                Text("I am a person who \(actionName)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Preview")
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createHabit()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var isValid: Bool {
        !identity.isEmpty && !actionName.isEmpty
    }

    private func createHabit() {
        let habit = Habit(
            identity: identity,
            actionName: actionName,
            frequency: frequency,
            category: selectedCategory,
            color: selectedCategory.defaultColor,
            icon: selectedCategory.systemIcon
        )

        // Add optional 4 Laws data
        if !cue.isEmpty { habit.cue = cue }
        if !attractiveness.isEmpty { habit.attractiveness = attractiveness }
        if !easeStrategy.isEmpty { habit.easeStrategy = easeStrategy }
        if !reward.isEmpty { habit.reward = reward }

        // Add optional metric tracking
        if enableMetrics && !metricName.isEmpty && !metricUnit.isEmpty {
            habit.metricConfig = MetricConfig(
                name: metricName,
                unit: metricUnit,
                goalDirection: metricGoalDirection,
                trackingFrequency: metricFrequency
            )
        }

        modelContext.insert(habit)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving habit: \(error)")
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}