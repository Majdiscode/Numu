//
//  HabitCalendarView.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//

import SwiftUI
import SwiftData

struct HabitCalendarView: View {
    let habit: Habit

    @State private var selectedDate: Date?
    @State private var currentMonth: Date = Date()

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        VStack(spacing: 20) {
            // MARK: - Month Picker
            monthPicker

            // MARK: - Weekday Headers
            weekdayHeaders

            // MARK: - Calendar Grid
            calendarGrid

            // MARK: - Legend
            legend

            // MARK: - Selected Date Info
            if let selected = selectedDate {
                selectedDateInfo(for: selected)
            }
        }
        .padding()
    }

    // MARK: - Month Picker
    private var monthPicker: some View {
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

            Text(monthYearString(for: currentMonth))
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
            .disabled(calendar.isDate(currentMonth, equalTo: Date(), toGranularity: .month))
        }
        .padding(.horizontal)
    }

    // MARK: - Weekday Headers
    private var weekdayHeaders: some View {
        HStack(spacing: 4) {
            ForEach(0..<7) { index in
                Text(weekdaySymbol(for: index))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        let days = daysInMonth()

        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(days, id: \.self) { date in
                if let date = date {
                    DayCell(
                        date: date,
                        habit: habit,
                        isSelected: selectedDate != nil && calendar.isDate(date, inSameDayAs: selectedDate!)
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            selectedDate = date
                        }
                    }
                } else {
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
    }

    // MARK: - Legend
    private var legend: some View {
        HStack(spacing: 8) {
            Text("Less")
                .font(.caption2)
                .foregroundStyle(.secondary)

            ForEach(0..<5) { level in
                RoundedRectangle(cornerRadius: 4)
                    .fill(intensityColor(for: level))
                    .frame(width: 20, height: 20)
            }

            Text("More")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    // MARK: - Selected Date Info
    private func selectedDateInfo(for date: Date) -> some View {
        let isCompleted = habit.logs.contains { calendar.isDate($0.date, inSameDayAs: date) }
        let log = habit.logs.first { calendar.isDate($0.date, inSameDayAs: date) }

        return VStack(spacing: 12) {
            HStack {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isCompleted ? .green : .gray)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(dateString(for: date))
                        .font(.headline)

                    Text(isCompleted ? "Completed" : "Not completed")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            if let log = log, let notes = log.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(notes)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if let log = log, let satisfaction = log.satisfaction {
                HStack {
                    Text("Satisfaction")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { level in
                            Image(systemName: level <= satisfaction ? "star.fill" : "star")
                                .foregroundStyle(.yellow)
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    // MARK: - Helper Methods

    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday else {
            return []
        }

        var days: [Date?] = []

        // Add empty cells for days before the first day of the month
        for _ in 0..<(firstWeekday - 1) {
            days.append(nil)
        }

        // Add all days in the month
        var date = monthInterval.start
        while date < monthInterval.end {
            days.append(date)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else { break }
            date = nextDate
        }

        return days
    }

    private func weekdaySymbol(for index: Int) -> String {
        let symbols = calendar.shortWeekdaySymbols
        return String(symbols[index].prefix(1))
    }

    private func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func intensityColor(for level: Int) -> Color {
        let baseColor = Color(hex: habit.color)
        switch level {
        case 0: return Color(.systemGray6)
        case 1: return baseColor.opacity(0.2)
        case 2: return baseColor.opacity(0.4)
        case 3: return baseColor.opacity(0.7)
        case 4: return baseColor
        default: return Color(.systemGray6)
        }
    }
}

// MARK: - Day Cell
struct DayCell: View {
    let date: Date
    let habit: Habit
    let isSelected: Bool

    private let calendar = Calendar.current

    var isCompleted: Bool {
        habit.logs.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }

    var isToday: Bool {
        calendar.isDateInToday(date)
    }

    var isFuture: Bool {
        date > Date()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(cellColor)

            if isToday {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color(hex: habit.color), lineWidth: 2)
            }

            if isSelected {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.blue, lineWidth: 3)
            }

            Text("\(calendar.component(.day, from: date))")
                .font(.caption)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(textColor)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var cellColor: Color {
        if isFuture {
            return Color(.systemGray6)
        } else if isCompleted {
            return Color(hex: habit.color)
        } else {
            return Color(.systemGray5)
        }
    }

    private var textColor: Color {
        if isFuture {
            return Color(.systemGray3)
        } else if isCompleted {
            return .white
        } else {
            return .primary
        }
    }
}