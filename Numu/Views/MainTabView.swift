//
//  MainTabView.swift
//  Numu
//
//  Root tab navigation view
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Systems", systemImage: "gearshape.2") {
                SystemsDashboardView()
            }

            Tab("Analytics", systemImage: "chart.line.uptrend.xyaxis") {
                AnalyticsView()
            }

            Tab("Calendar", systemImage: "calendar") {
                CalendarView()
            }

            Tab("Settings", systemImage: "gear") {
                SettingsView()
            }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [System.self, HabitTask.self, HabitTaskLog.self, PerformanceTest.self, PerformanceTestEntry.self])
}
