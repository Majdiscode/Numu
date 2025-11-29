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

    private var currentMonthName: String {
        let components = calendar.dateComponents([.month], from: currentMonth)
        guard let month = components.month else { return "" }
        return calendar.monthSymbols[month - 1]
    }

    private var currentYearString: String {
        let components = calendar.dateComponents([.year], from: currentMonth)
        guard let year = components.year else { return "" }
        return String(year)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

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
                                .padding(.horizontal)

                            // Legend
                            legendSection
                                .padding(.horizontal)
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                    }
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
        HStack(spacing: 8) {
            // Previous month button
            Button {
                withAnimation {
                    currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .frame(width: 40, height: 40)
            }

            Spacer()

            // Month selector
            Menu {
                ForEach(calendar.monthSymbols.indices, id: \.self) { index in
                    Button {
                        if let newDate = calendar.date(bySetting: .month, value: index + 1, of: currentMonth) {
                            withAnimation {
                                currentMonth = newDate
                            }
                        }
                    } label: {
                        Text(calendar.monthSymbols[index])
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(currentMonthName)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Year selector
            Menu {
                ForEach((2020...2030), id: \.self) { year in
                    Button {
                        if let newDate = calendar.date(bySetting: .year, value: year, of: currentMonth) {
                            withAnimation {
                                currentMonth = newDate
                            }
                        }
                    } label: {
                        Text(String(year))
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(currentYearString)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Spacer()

            // Next month button
            Button {
                withAnimation {
                    currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
                ForEach(Array(calendar.veryShortWeekdaySymbols.enumerated()), id: \.offset) { index, day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 12)
            .padding(.top, 8)

            // Weeks
            ForEach(weeksInMonth, id: \.self) { week in
                weekRow(weekStart: week)
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func weekRow(weekStart: Date) -> some View {
        let weekColor = weekBackgroundColor(for: weekStart)

        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(daysInWeek(weekStart: weekStart), id: \.self) { date in
                    dayCell(date: date)
                }
            }
            .padding(.vertical, 6)
            .background(weekColor != .clear && weekColor != .gray ? weekColor.opacity(0.25) : Color.clear)
            .clipShape(Capsule())
            .onTapGesture {
                selectedWeekStart = weekStart
                showWeekSummary = true
            }
        }
        .padding(.bottom, 2)
    }

    private func dayCell(date: Date) -> some View {
        let isCurrentMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
        let isToday = calendar.isDateInToday(date)
        let isSelected = selectedDate != nil && calendar.isDate(date, equalTo: selectedDate!, toGranularity: .day)
        let dayColor = dayCircleColor(for: date)
        let showIndicator = dayColor != .clear

        return Button {
            selectedDate = date
            showDayDetail = true
        } label: {
            VStack(spacing: 4) {
                Text(date, format: .dateTime.day())
                    .font(.system(size: 15))
                    .fontWeight(isToday ? .semibold : .regular)
                    .foregroundStyle(isSelected ? .primary : (isCurrentMonth ? .primary : .tertiary))

                if showIndicator {
                    Circle()
                        .fill(dayColor)
                        .frame(width: 5, height: 5)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 5, height: 5)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(isSelected ? Color(.systemBackground) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
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
        var hasTasksOnThisDay = false

        for system in filteredSystems {
            guard let tasks = system.tasks else { continue }

            for task in tasks {
                // Check if this task existed on this day
                let taskCreationDate = calendar.startOfDay(for: task.createdAt)

                // Only count tasks that were created on or before this day
                if taskCreationDate <= startOfDay {
                    // Only count daily tasks (not weekly)
                    if task.shouldBeCompletedOn(date: startOfDay) {
                        hasTasksOnThisDay = true
                        totalTasks += 1
                        if task.wasCompletedOn(date: startOfDay) {
                            completedTasks += 1
                        }
                    }
                }
            }
        }

        // No tasks existed or were due that day
        if !hasTasksOnThisDay || totalTasks == 0 {
            return .clear
        }

        let completionRate = Double(completedTasks) / Double(totalTasks)

        if completionRate >= 0.8 {
            return Color(red: 0.2, green: 0.8, blue: 0.3)  // Brighter green
        } else if completionRate >= 0.5 {
            return Color(red: 1.0, green: 0.8, blue: 0.0)  // Brighter yellow
        } else {
            return Color(red: 1.0, green: 0.3, blue: 0.3)  // Brighter red
        }
    }

    private func weekBackgroundColor(for weekStart: Date) -> Color {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: weekStart) else {
            return .clear
        }

        // Check if week is in the future
        if weekInterval.start > Date() {
            return .clear
        }

        // Calculate per-system completion rates, then average them
        // This prevents one system from diluting another's performance
        var systemCompletionRates: [Double] = []

        for system in filteredSystems {
            guard let tasks = system.tasks else { continue }

            var systemTotalTargets = 0
            var systemCompletedTargets = 0

            for task in tasks {
                // Only count weekly tasks
                if case .weeklyTarget(let times) = task.frequency {
                    // Check if this task existed during this week
                    let taskCreationDate = calendar.startOfDay(for: task.createdAt)

                    // Only count this task if it was created before or during this week
                    if taskCreationDate <= weekInterval.end {
                        systemTotalTargets += times
                        let completions = task.completionsInWeek(containing: weekStart)
                        systemCompletedTargets += min(completions, times)
                    }
                }
            }

            // Only include systems that had weekly goals this week
            if systemTotalTargets > 0 {
                let systemRate = Double(systemCompletedTargets) / Double(systemTotalTargets)
                systemCompletionRates.append(systemRate)
            }
        }

        // No weekly goals existed during this week
        if systemCompletionRates.isEmpty {
            return .clear
        }

        // Average the completion rates across all systems
        let completionRate = systemCompletionRates.reduce(0, +) / Double(systemCompletionRates.count)

        if completionRate >= 0.8 {
            return Color(red: 0.2, green: 0.8, blue: 0.3)  // Brighter green
        } else if completionRate >= 0.5 {
            return Color(red: 1.0, green: 0.8, blue: 0.0)  // Brighter yellow
        } else {
            return Color(red: 1.0, green: 0.3, blue: 0.3)  // Brighter red
        }
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [System.self, HabitTask.self, HabitTaskLog.self])
}
