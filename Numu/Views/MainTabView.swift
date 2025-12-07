//
//  MainTabView.swift
//  Numu
//
//  Root tab navigation view
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false

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
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
        }
        .onAppear {
            // Show onboarding if not completed
            if !hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        .onChange(of: hasCompletedOnboarding) { _, newValue in
            // Show onboarding when reset from settings
            if !newValue {
                showOnboarding = true
            }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [System.self, HabitTask.self, HabitTaskLog.self, PerformanceTest.self, PerformanceTestEntry.self])
}
