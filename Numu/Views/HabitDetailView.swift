//
//  HabitDetailView.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//

import SwiftUI
import SwiftData

struct HabitDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let habit: Habit

    @State private var showMetricEntry = false
    @State private var showEditHabit = false
    @State private var showDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Identity Header
                identityHeader

                // MARK: - Key Stats
                keyStats

                // MARK: - Metric Tracking (if enabled)
                if habit.hasMetricTracking {
                    NavigationLink(destination: CompoundGrowthView(habit: habit)) {
                        metricSection
                    }
                    .buttonStyle(.plain)
                }

                // MARK: - Calendar
                calendarSection

                // MARK: - The 4 Laws
                if hasAnyLaws {
                    fourLawsSection
                }

                // MARK: - Delete Button
                deleteButton
            }
            .padding()
        }
        .navigationTitle(habit.identity.capitalized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showEditHabit = true
                } label: {
                    Text("Edit")
                        .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showMetricEntry) {
            if habit.hasMetricTracking {
                MetricEntryView(habit: habit)
            }
        }
        .alert("Delete Habit?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteHabit()
            }
        } message: {
            Text("This will permanently delete '\(habit.identity)' and all associated data. This action cannot be undone.")
        }
    }

    // MARK: - Identity Header
    private var identityHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: habit.color).opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: habit.icon)
                    .font(.system(size: 44))
                    .foregroundStyle(Color(hex: habit.color))
            }

            VStack(spacing: 8) {
                Text("I am a \(habit.identity)")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("I am a person who \(habit.actionName)")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Label(habit.category.rawValue, systemImage: habit.category.systemIcon)
                .font(.subheadline)
                .foregroundStyle(Color(hex: habit.color))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: habit.color).opacity(0.15))
                .clipShape(Capsule())
        }
    }

    // MARK: - Key Stats
    private var keyStats: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StatCard(
                    title: "Current Streak",
                    value: "\(habit.currentStreak)",
                    icon: "flame.fill",
                    color: .orange
                )

                StatCard(
                    title: "Best Streak",
                    value: "\(habit.longestStreak)",
                    icon: "trophy.fill",
                    color: .yellow
                )
            }

            HStack(spacing: 16) {
                StatCard(
                    title: "Completion Rate",
                    value: "\(Int(habit.completionRate * 100))%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )

                StatCard(
                    title: "Total Days",
                    value: "\(habit.logs.count)",
                    icon: "calendar",
                    color: .blue
                )
            }
        }
    }

    // MARK: - Metric Section
    private var metricSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Outcome Tracking", systemImage: "chart.xyaxis.line")
                    .font(.headline)

                Spacer()

                HStack(spacing: 12) {
                    if habit.isMetricDue() {
                        Button {
                            showMetricEntry = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text("Log")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: habit.color))
                            .clipShape(Capsule())
                        }
                    }

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }

            if let config = habit.metricConfig {
                VStack(alignment: .leading, spacing: 8) {
                    Text(config.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("Tracked \(config.trackingFrequency.displayText.lowercased())")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let analytics = habit.getMetricAnalytics() as MetricAnalytics?,
                       let latest = analytics.latestValue {
                        HStack {
                            Text("\(String(format: "%.1f", latest)) \(config.unit)")
                                .font(.title2)
                                .fontWeight(.bold)

                            if let improvement = analytics.improvement {
                                HStack(spacing: 4) {
                                    Image(systemName: improvement > 0 ? "arrow.up" : "arrow.down")
                                    Text("\(String(format: "%.1f", abs(improvement)))%")
                                }
                                .font(.caption)
                                .foregroundStyle(improvement > 0 ? .green : .red)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    // MARK: - Calendar Section
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("History", systemImage: "calendar")
                .font(.headline)

            HabitCalendarView(habit: habit)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    // MARK: - Four Laws Section
    private var hasAnyLaws: Bool {
        habit.cue != nil || habit.attractiveness != nil || habit.easeStrategy != nil || habit.reward != nil
    }

    private var fourLawsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("The 4 Laws", systemImage: "atom")
                .font(.headline)

            VStack(spacing: 12) {
                if let cue = habit.cue {
                    LawRow(number: 1, title: "Make it Obvious", content: cue)
                }

                if let attractiveness = habit.attractiveness {
                    LawRow(number: 2, title: "Make it Attractive", content: attractiveness)
                }

                if let ease = habit.easeStrategy {
                    LawRow(number: 3, title: "Make it Easy", content: ease)
                }

                if let reward = habit.reward {
                    LawRow(number: 4, title: "Make it Satisfying", content: reward)
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
                Text("Delete Habit")
            }
            .font(.headline)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Actions
    private func deleteHabit() {
        modelContext.delete(habit)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error deleting habit: \(error)")
        }
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
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

// MARK: - Law Row Component
struct LawRow: View {
    let number: Int
    let title: String
    let content: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 32, height: 32)

                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(content)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}