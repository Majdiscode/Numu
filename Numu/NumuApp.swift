//
//  NumuApp.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//

import SwiftUI
import SwiftData

@main
struct NumuApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            // V2 Architecture: System -> Tasks -> Tests
            modelContainer = try ModelContainer(
                for: System.self, Task.self, TaskLog.self, Test.self, TestEntry.self,
                // Legacy V1 models (will be migrated/removed later)
                Habit.self, HabitLog.self, SystemMetrics.self, MetricEntry.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
