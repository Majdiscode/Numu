//
//  CalendarView.swift
//  Numu
//
//  Visual consistency calendar showing daily and weekly progress
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var systems: [System]

    @State private var currentMonth = Date()
    @State private var selectedDate: Date?
    @State private var selectedWeekStart: Date?
    @State private var showDayDetail = false
    @State private var showWeekSummary = false
    @State private var selectedSystemFilter: System?

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Month Navigation
                monthNavigationHeader

                // System Filter
                if !systems.isEmpty {
                    systemFilterPicker
                }

                // Calendar Grid
                ScrollView {
                    VStack(spacing: 24) {
                        calendarGrid

                        // Legend
                        legendSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showDayDetail) {
                if let date = selectedDate {
                    DayDetailView(date: date, systems: filteredSystems)
                }
            }
            .sheet(isPresented: $showWeekSummary) {
                if let weekStart = selectedWeekStart {
                    WeekSummaryView(weekStart: weekStart, systems: filteredSystems)
                }
            }
        }
    }

    // MARK: - Month Navigation

    private var monthNavigationHeader: some View {
        HStack {
            Button {
                withAnimation {
                    currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }

            Spacer()

            Text(currentMonth, format: .dateTime.month(.wide).year())
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            Button {
                withAnimation {
                    currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }

            Button {
                withAnimation {
                    currentMonth = Date()
                }
            } label: {
                Text("Today")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    // MARK: - System Filter

    private var systemFilterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All Systems
                Button {
                    selectedSystemFilter = nil
                } label: {
                    Text("All Systems")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedSystemFilter == nil ? Color.accentColor : Color(.systemGray5))
                        .foregroundStyle(selectedSystemFilter == nil ? .white : .primary)
                        .clipShape(Capsule())
                }

                // Individual Systems
                ForEach(systems) { system in
                    Button {
                        selectedSystemFilter = system
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: system.icon)
                                .font(.caption)
                            Text(system.name)
                                .font(.subheadline)
                        }
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedSystemFilter?.id == system.id ? Color(hex: system.color) : Color(.systemGray5))
                        .foregroundStyle(selectedSystemFilter?.id == system.id ? .white : .primary)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        VStack(spacing: 0) {
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 8)

            // Weeks
            ForEach(weeksInMonth, id: \.self) { week in
                weekRow(weekStart: week)
            }
        }
    }

    private func weekRow(weekStart: Date) -> some View {
        let weekColor = weekBackgroundColor(for: weekStart)

        return VStack(spacing: 4) {
            HStack(spacing: 0) {
                ForEach(daysInWeek(weekStart: weekStart), id: \.self) { date in
                    dayCell(date: date)
                }
            }
            .padding(.vertical, 12)
            .background(weekColor.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onTapGesture {
                selectedWeekStart = weekStart
                showWeekSummary = true
            }
        }
        .padding(.bottom, 8)
    }

    private func dayCell(date: Date) -> some View {
        let isCurrentMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
        let isToday = calendar.isDateInToday(date)
        let dayColor = dayCircleColor(for: date)

        return Button {
            selectedDate = date
            showDayDetail = true
        } label: {
            VStack(spacing: 4) {
                Text(date, format: .dateTime.day())
                    .font(.subheadline)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(isCurrentMonth ? .primary : .secondary)

                Circle()
                    .fill(dayColor)
                    .frame(width: 8, height: 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Legend

    private var legendSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Legend")
                .font(.headline)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                // Daily circles
                VStack(alignment: .leading, spacing: 8) {
                    Text("Daily Tasks")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    HStack(spacing: 16) {
                        legendItem(color: .green, label: "80-100%")
                        legendItem(color: .yellow, label: "50-79%")
                        legendItem(color: .red, label: "0-49%")
                        legendItem(color: .gray, label: "No tasks")
                    }
                }

                Divider()

                // Weekly backgrounds
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weekly Goals")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    HStack(spacing: 16) {
                        legendItem(color: .green, label: "80-100%", isBackground: true)
                        legendItem(color: .yellow, label: "50-79%", isBackground: true)
                        legendItem(color: .red, label: "0-49%", isBackground: true)
                        legendItem(color: .gray, label: "No goals", isBackground: true)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func legendItem(color: Color, label: String, isBackground: Bool = false) -> some View {
        HStack(spacing: 6) {
            if isBackground {
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.opacity(0.15))
                    .frame(width: 24, height: 16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(color, lineWidth: 1)
                    )
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
            }

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private var filteredSystems: [System] {
        if let filter = selectedSystemFilter {
            return [filter]
        }
        return systems
    }

    private var weeksInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }

        var weeks: [Date] = []
        var currentWeekStart = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start)?.start ?? monthInterval.start

        while currentWeekStart < monthInterval.end {
            weeks.append(currentWeekStart)
            guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart) else {
                break
            }
            currentWeekStart = nextWeek
        }

        return weeks
    }

    private func daysInWeek(weekStart: Date) -> [Date] {
        var days: [Date] = []
        for dayOffset in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) {
                days.append(day)
            }
        }
        return days
    }

    // MARK: - Color Calculations

    private func dayCircleColor(for date: Date) -> Color {
        let startOfDay = calendar.startOfDay(for: date)

        // Check if date is in the future
        if startOfDay > calendar.startOfDay(for: Date()) {
            return .clear
        }

        var totalTasks = 0
        var completedTasks = 0

        for system in filteredSystems {
            guard let tasks = system.tasks else { continue }

            for task in tasks {
                // Only count daily tasks (not weekly)
                if task.shouldBeCompletedOn(date: startOfDay) {
                    totalTasks += 1
                    if task.wasCompletedOn(date: startOfDay) {
                        completedTasks += 1
                    }
                }
            }
        }

        // No tasks due that day
        if totalTasks == 0 {
            return .gray.opacity(0.3)
        }

        let completionRate = Double(completedTasks) / Double(totalTasks)

        if completionRate >= 0.8 {
            return .green
        } else if completionRate >= 0.5 {
            return .yellow
        } else {
            return .red
        }
    }

    private func weekBackgroundColor(for weekStart: Date) -> Color {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: weekStart) else {
            return .gray
        }

        // Check if week is in the future
        if weekInterval.start > Date() {
            return .clear
        }

        var totalWeeklyTargets = 0
        var completedWeeklyTargets = 0

        for system in filteredSystems {
            guard let tasks = system.tasks else { continue }

            for task in tasks {
                // Only count weekly tasks
                if case .weeklyTarget(let times) = task.frequency {
                    totalWeeklyTargets += times
                    let completions = task.completionsInWeek(containing: weekStart)
                    completedWeeklyTargets += min(completions, times)
                }
            }
        }

        // No weekly goals
        if totalWeeklyTargets == 0 {
            return .gray
        }

        let completionRate = Double(completedWeeklyTargets) / Double(totalWeeklyTargets)

        if completionRate >= 0.8 {
            return .green
        } else if completionRate >= 0.5 {
            return .yellow
        } else {
            return .red
        }
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [System.self, HabitTask.self, HabitTaskLog.self])
}
