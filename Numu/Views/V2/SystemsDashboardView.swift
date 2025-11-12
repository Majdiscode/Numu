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

    var overallCompletionRate: Double {
        guard !systems.isEmpty else { return 0.0 }

        let totalTasks = systems.reduce(0) { $0 + $1.todaysTasks.count }
        guard totalTasks > 0 else { return 0.0 }

        let completedTasks = systems.reduce(0) { $0 + $1.completedTodayCount }
        return Double(completedTasks) / Double(totalTasks)
    }

    var totalActiveSystems: Int {
        systems.filter { !$0.todaysTasks.isEmpty }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
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
            }
            .sheet(isPresented: $showCreateSystem) {
                CreateSystemView()
            }
        }
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
                        .frame(width: geometry.size.width * overallCompletionRate)
                }
            }
            .frame(height: 12)

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

    private var totalTodaysTasks: Int {
        systems.reduce(0) { $0 + $1.todaysTasks.count }
    }

    private var totalCompletedTasks: Int {
        systems.reduce(0) { $0 + $1.completedTodayCount }
    }

    private var motivationalMessage: String {
        if systems.isEmpty {
            return "Create your first system to start building your identity"
        } else if overallCompletionRate == 1.0 {
            return "Perfect! All systems are running smoothly"
        } else if overallCompletionRate >= 0.75 {
            return "Excellent! Your systems are strong today"
        } else if overallCompletionRate >= 0.5 {
            return "Keep going! Every task reinforces your identity"
        } else if totalCompletedTasks == 0 {
            return "Today is a new opportunity to live your systems"
        } else {
            return "Progress, not perfection. Keep showing up"
        }
    }

    // MARK: - Systems List
    private var systemsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !systems.isEmpty {
                Text("Your Systems")
                    .font(.title2)
                    .fontWeight(.bold)

                ForEach(systems) { system in
                    NavigationLink(destination: SystemDetailView(system: system)) {
                        SystemCard(system: system, modelContext: modelContext)
                    }
                    .buttonStyle(.plain)
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
        VStack(spacing: 16) {
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

                // Completion indicator
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                        .frame(width: 44, height: 44)

                    Circle()
                        .trim(from: 0, to: system.todayCompletionRate)
                        .stroke(Color(hex: system.color), lineWidth: 4)
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(system.todayCompletionRate * 100))")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
            }

            // Tasks
            if !system.todaysTasks.isEmpty {
                VStack(spacing: 8) {
                    ForEach(system.todaysTasks.prefix(3)) { task in
                        TaskRow(task: task, modelContext: modelContext)
                    }

                    if system.todaysTasks.count > 3 {
                        Text("+\(system.todaysTasks.count - 3) more tasks")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Due Tests
            if !system.dueTests.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.badge.questionmark")
                        .foregroundStyle(.orange)
                    Text("\(system.dueTests.count) test\(system.dueTests.count == 1 ? "" : "s") due")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Task Row Component
struct TaskRow: View {
    let task: Task
    let modelContext: ModelContext

    @State private var isCompleted: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Button {
                toggleCompletion()
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isCompleted ? .green : .gray.opacity(0.3))
            }
            .buttonStyle(.plain)

            Text(task.name)
                .font(.subheadline)
                .foregroundStyle(isCompleted ? .secondary : .primary)

            Spacer()

            if task.currentStreak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text("\(task.currentStreak)")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .onAppear {
            isCompleted = task.isCompletedToday()
        }
    }

    private func toggleCompletion() {
        withAnimation(.spring(response: 0.3)) {
            if isCompleted {
                // Remove today's log
                if let todayLog = task.logs.first(where: { Calendar.current.isDateInToday($0.date) }) {
                    modelContext.delete(todayLog)
                }
            } else {
                // Add today's log
                let log = TaskLog()
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