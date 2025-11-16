//
//  AnalyticsView.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//

import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var systems: [System]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Overview Stats
                    overviewStats

                    // MARK: - Completion Chart Section
                    completionChartSection

                    // MARK: - Test Performance Section
                    testPerformanceSection

                    // MARK: - Streak Section
                    streakSection
                }
                .padding()
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Overview Stats
    private var overviewStats: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 12) {
                StatCard(
                    title: "Total Systems",
                    value: "\(systems.count)",
                    icon: "gearshape.2.fill",
                    color: .blue
                )

                StatCard(
                    title: "Active Tasks",
                    value: "\(totalActiveTasks)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                StatCard(
                    title: "Tests",
                    value: "\(totalTests)",
                    icon: "chart.bar.fill",
                    color: .purple
                )
            }
        }
    }

    // MARK: - Completion Chart Section (Placeholder)
    private var completionChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completion Trend")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 16) {
                Text("Chart Coming in Stage 2")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
    }

    // MARK: - Test Performance Section (Placeholder)
    private var testPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test Performance")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 16) {
                Text("Test Charts Coming in Stage 3")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
    }

    // MARK: - Streak Section (Placeholder)
    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Streaks & Consistency")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 16) {
                Text("Streak Visualization Coming in Stage 4")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
    }

    // MARK: - Computed Properties
    private var totalActiveTasks: Int {
        systems.reduce(0) { $0 + ($1.tasks?.count ?? 0) }
    }

    private var totalTests: Int {
        systems.reduce(0) { $0 + ($1.tests?.count ?? 0) }
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
