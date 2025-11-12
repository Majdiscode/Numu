//
//  DashboardView.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    @Query private var systemMetrics: [SystemMetrics]

    @State private var showCreateHabit = false

    var todaysMetrics: SystemMetrics? {
        let today = Calendar.current.startOfDay(for: Date())
        return systemMetrics.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    var todaysHabits: [Habit] {
        // Filter habits based on frequency
        habits.filter { habit in
            switch habit.frequency {
            case .daily:
                return true
            case .weekdays:
                let weekday = Calendar.current.component(.weekday, from: Date())
                return weekday >= 2 && weekday <= 6 // Monday to Friday
            case .weekends:
                let weekday = Calendar.current.component(.weekday, from: Date())
                return weekday == 1 || weekday == 7 // Saturday or Sunday
            case .custom:
                return true // Handle custom logic later
            }
        }
    }

    var completedToday: Int {
        todaysHabits.filter { $0.isCompletedToday() }.count
    }

    var systemStrength: Double {
        guard !todaysHabits.isEmpty else { return 0.0 }
        return Double(completedToday) / Double(todaysHabits.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - System Strength
                    systemStrengthCard

                    // MARK: - Today's Habits
                    todaysHabitsSection

                    // MARK: - Empty State
                    if habits.isEmpty {
                        emptyState
                    }
                }
                .padding()
            }
            .navigationTitle("Today's Systems")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateHabit = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showCreateHabit) {
                CreateHabitView()
            }
        }
    }

    // MARK: - System Strength Card
    private var systemStrengthCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("System Strength")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text("\(Int(systemStrength * 100))%")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 4) {
                        Text("\(completedToday)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("/ \(todaysHabits.count)")
                            .foregroundStyle(.secondary)
                    }
                    Text("completed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * systemStrength)
                }
            }
            .frame(height: 12)

            // Motivational message
            Text(motivationalMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private var motivationalMessage: String {
        if todaysHabits.isEmpty {
            return "Create your first habit to start building your systems"
        } else if systemStrength == 1.0 {
            return "Perfect! You're living your identity today"
        } else if systemStrength >= 0.75 {
            return "Excellent! Your systems are strong"
        } else if systemStrength >= 0.5 {
            return "Keep going! Every action reinforces your identity"
        } else if completedToday == 0 {
            return "Today is a new opportunity to become who you want to be"
        } else {
            return "Progress, not perfection. Keep showing up"
        }
    }

    // MARK: - Today's Habits Section
    private var todaysHabitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Identity")
                .font(.title2)
                .fontWeight(.bold)

            if todaysHabits.isEmpty {
                Text("No habits for today")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(todaysHabits) { habit in
                    NavigationLink(destination: HabitDetailView(habit: habit)) {
                        HabitCard(habit: habit, modelContext: modelContext)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Start Your Journey")
                .font(.title2)
                .fontWeight(.bold)

            Text("Focus on who you want to become,\nnot what you want to achieve")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showCreateHabit = true
            } label: {
                Text("Create Your First Habit")
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

// MARK: - Habit Card Component
struct HabitCard: View {
    let habit: Habit
    let modelContext: ModelContext

    @State private var isCompleted: Bool = false
    @State private var showCheckIn: Bool = false

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: habit.color).opacity(0.15))
                    .frame(width: 50, height: 50)

                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color(hex: habit.color))
                } else {
                    Image(systemName: habit.icon)
                        .font(.title3)
                        .foregroundStyle(Color(hex: habit.color))
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text("I am a \(habit.identity)")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("I am a person who \(habit.actionName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Streak
                if habit.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text("\(habit.currentStreak) day streak")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            // Checkmark Button
            Button {
                if isCompleted {
                    toggleCompletion()
                } else {
                    showCheckIn = true
                }
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isCompleted ? .green : .gray.opacity(0.3))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .onAppear {
            isCompleted = habit.isCompletedToday()
        }
        .sheet(isPresented: $showCheckIn) {
            HabitCheckInView(habit: habit)
                .onDisappear {
                    isCompleted = habit.isCompletedToday()
                }
        }
    }

    private func toggleCompletion() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if isCompleted {
                // Remove today's log
                if let todayLog = habit.logs.first(where: { Calendar.current.isDateInToday($0.date) }) {
                    modelContext.delete(todayLog)
                }
                isCompleted = false
            }

            do {
                try modelContext.save()
            } catch {
                print("Error toggling habit: \(error)")
            }
        }
    }
}