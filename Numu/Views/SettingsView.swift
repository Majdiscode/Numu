//
//  SettingsView.swift
//  Numu
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(HealthKitService.self) private var healthKitService
    @Environment(\.modelContext) private var modelContext
    @Query private var systems: [System]

    @AppStorage("endOfDayEnabled") private var endOfDayEnabled = true
    @AppStorage("endOfDayHour") private var endOfDayHour = 21
    @AppStorage("streakAlertsEnabled") private var streakAlertsEnabled = true
    @AppStorage("streakAlertHour") private var streakAlertHour = 20
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var pendingNotificationCount = 0

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Notification Status
                Section {
                    HStack {
                        Label("Notifications", systemImage: "bell.badge")

                        Spacer()

                        switch notificationManager.authorizationStatus {
                        case .authorized:
                            Label("Enabled", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        case .denied:
                            Label("Disabled", systemImage: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        case .notDetermined:
                            Label("Not Set", systemImage: "questionmark.circle.fill")
                                .foregroundStyle(.orange)
                        case .provisional, .ephemeral:
                            Label("Limited", systemImage: "exclamationmark.circle.fill")
                                .foregroundStyle(.orange)
                        @unknown default:
                            Label("Unknown", systemImage: "questionmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.subheadline)

                    if notificationManager.authorizationStatus == .denied {
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Label("Open Settings", systemImage: "gear")
                        }
                    } else if notificationManager.authorizationStatus == .notDetermined {
                        Button {
                            Task {
                                await notificationManager.requestAuthorization()
                            }
                        } label: {
                            Label("Enable Notifications", systemImage: "bell")
                        }
                    }
                } header: {
                    Text("Status")
                }

                // MARK: - HealthKit Integration
                Section {
                    if healthKitService.isHealthKitAvailable {
                        // Authorization Status
                        HStack {
                            Label("HealthKit", systemImage: "heart.fill")

                            Spacer()

                            if healthKitService.isAuthorized {
                                Label("Authorized", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Label(healthKitService.authorizationStatus, systemImage: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                        .font(.subheadline)

                        // Last Sync Time
                        if let lastSync = healthKitService.lastSyncDate {
                            HStack {
                                Text("Last Sync")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(lastSync, style: .relative)
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }

                        // Manual Sync Button
                        Button {
                            Task {
                                await healthKitService.checkAllMappedTasksForToday(
                                    tasks: allTasks,
                                    modelContext: modelContext
                                )
                            }
                        } label: {
                            HStack {
                                if healthKitService.isSyncing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Syncing...")
                                } else {
                                    Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                                }
                            }
                        }
                        .disabled(healthKitService.isSyncing || !healthKitService.isAuthorized)

                        // Open Settings Button if not authorized
                        if !healthKitService.isAuthorized {
                            Button {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                Label("Open Settings", systemImage: "gear")
                            }
                        }
                    } else {
                        Text("HealthKit not available on this device")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                } header: {
                    Text("Health Integration")
                } footer: {
                    if healthKitService.isHealthKitAvailable {
                        Text("Numu can automatically complete tasks when your HealthKit data meets configured thresholds")
                    }
                }

                // MARK: - End of Day Summary
                Section {
                    Toggle("Daily Summary", isOn: $endOfDayEnabled)
                        .onChange(of: endOfDayEnabled) { _, newValue in
                            if newValue {
                                notificationManager.scheduleEndOfDaySummary(at: endOfDayHour)
                            } else {
                                notificationManager.cancelEndOfDaySummary()
                            }
                        }

                    if endOfDayEnabled {
                        Picker("Time", selection: $endOfDayHour) {
                            ForEach(17...23, id: \.self) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .onChange(of: endOfDayHour) { _, newValue in
                            if endOfDayEnabled {
                                notificationManager.scheduleEndOfDaySummary(at: newValue)
                            }
                        }
                    }
                } header: {
                    Text("End of Day")
                } footer: {
                    Text("Get a daily reminder to review your progress and complete remaining tasks")
                }

                // MARK: - Streak Alerts
                Section {
                    Toggle("Streak Protection", isOn: $streakAlertsEnabled)
                        .onChange(of: streakAlertsEnabled) { _, newValue in
                            if newValue {
                                scheduleAllStreakAlerts()
                            } else {
                                cancelAllStreakAlerts()
                            }
                        }

                    if streakAlertsEnabled {
                        Picker("Alert Time", selection: $streakAlertHour) {
                            ForEach(17...23, id: \.self) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .onChange(of: streakAlertHour) { _, newValue in
                            if streakAlertsEnabled {
                                scheduleAllStreakAlerts()
                            }
                        }
                    }
                } header: {
                    Text("Streaks")
                } footer: {
                    Text("Get reminded about tasks with active streaks to help you maintain them")
                }

                // MARK: - Task Reminders
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Task reminders are automatically set based on the cue time you specify in The 4 Laws")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        let tasksWithReminders = allTasks.filter { $0.cueTime != nil }

                        if tasksWithReminders.isEmpty {
                            Text("No tasks have cue times set")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .italic()
                        } else {
                            ForEach(tasksWithReminders) { task in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(task.name)
                                            .font(.subheadline)

                                        if let systemName = task.system?.name {
                                            Text(systemName)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Spacer()

                                    if let cueTime = task.cueTime {
                                        Text(cueTime.formatted(date: .omitted, time: .shortened))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    Text("Task Reminders")
                }

                // MARK: - App Settings
                Section {
                    Button("View Onboarding Again") {
                        hasCompletedOnboarding = false
                    }
                } header: {
                    Text("About")
                }

                // MARK: - Debug Info
                #if DEBUG
                Section {

                    HStack {
                        Text("Pending Notifications")
                        Spacer()
                        Text("\(pendingNotificationCount)")
                            .foregroundStyle(.secondary)
                    }

                    Button("Refresh Count") {
                        Task {
                            pendingNotificationCount = await notificationManager.getPendingNotificationCount()
                        }
                    }

                    Button("Print Pending") {
                        Task {
                            await notificationManager.printPendingNotifications()
                        }
                    }

                    Button("Clear All Notifications") {
                        notificationManager.removeAllNotifications()
                        pendingNotificationCount = 0
                    }
                    .foregroundStyle(.red)
                } header: {
                    Text("Debug")
                }
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                // Load pending notification count
                pendingNotificationCount = await notificationManager.getPendingNotificationCount()

                // Schedule end-of-day if enabled
                if endOfDayEnabled {
                    notificationManager.scheduleEndOfDaySummary(at: endOfDayHour)
                }

                // Schedule streak alerts if enabled
                if streakAlertsEnabled {
                    scheduleAllStreakAlerts()
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:00 a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }

    private var allTasks: [HabitTask] {
        var tasks: [HabitTask] = []
        for system in systems {
            if let systemTasks = system.tasks {
                tasks.append(contentsOf: systemTasks)
            }
        }
        return tasks
    }

    private func scheduleAllStreakAlerts() {
        let tasksWithStreaks = allTasks.filter { $0.currentStreak >= 3 }
        for task in tasksWithStreaks {
            notificationManager.scheduleStreakAlert(for: task, at: streakAlertHour)
        }
    }

    private func cancelAllStreakAlerts() {
        for task in allTasks {
            notificationManager.cancelStreakAlert(for: task)
        }
    }
}
