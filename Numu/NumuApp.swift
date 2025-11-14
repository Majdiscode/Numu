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
        print("🚀 [NUMU] ========================================")
        print("🚀 [NUMU] App initialization started")
        print("📋 [NUMU] Date: \(Date())")
        print("🚀 [NUMU] ========================================")

        do {
            print("")
            print("📦 [STAGE 1] Adding NEW models with CloudKit-compatible optional relationships")
            print("    V1 Models (baseline):")
            print("      - Habit.self")
            print("      - HabitLog.self")
            print("      - SystemMetrics.self")
            print("      - MetricEntry.self")
            print("")
            print("    NEW V2 Models (with optional relationships):")
            print("      - System.self")
            print("      - HabitTask.self (renamed from Task)")
            print("      - HabitTaskLog.self (renamed from TaskLog)")
            print("      - PerformanceTest.self (renamed from Test)")
            print("      - PerformanceTestEntry.self (renamed from TestEntry)")
            print("")
            print("    🔍 KEY FIX: All @Relationship properties are NOW OPTIONAL (required for CloudKit)")
            print("       Example: var tasks: [HabitTask]? (not [HabitTask] = [])")

            // STAGE 1: Add new models with CloudKit-compatible optional relationships
            modelContainer = try ModelContainer(
                for: System.self, HabitTask.self, HabitTaskLog.self, PerformanceTest.self, PerformanceTestEntry.self,
                     Habit.self, HabitLog.self, SystemMetrics.self, MetricEntry.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )

            print("")
            print("✅ [STAGE 1] ModelContainer initialized successfully!")
            print("    - Schema entities: \(modelContainer.schema.entities.count)")
            print("    - Entities registered:")
            for (index, entity) in modelContainer.schema.entities.enumerated() {
                print("      \(index + 1). \(entity.name) (\(entity.properties.count) properties, \(entity.relationships.count) relationships)")
            }

        } catch {
            print("")
            print("❌ [NUMU] ========================================")
            print("❌ [NUMU] FATAL ERROR during initialization")
            print("❌ [NUMU] ========================================")
            print("❌ Error Type: \(type(of: error))")
            print("❌ Error Description: \(error)")
            print("❌ Localized Description: \(error.localizedDescription)")

            if let nsError = error as NSError? {
                print("❌ NSError Details:")
                print("   - Domain: \(nsError.domain)")
                print("   - Code: \(nsError.code)")
                print("   - UserInfo:")
                for (key, value) in nsError.userInfo {
                    print("     • \(key): \(value)")
                }
            }
            print("❌ [NUMU] ========================================")
            fatalError("Failed to initialize ModelContainer: \(error)")
        }

        print("")
        print("🎉 [NUMU] ========================================")
        print("🎉 [NUMU] STAGE 1 COMPLETE - V1 Baseline Ready!")
        print("🎉 [NUMU] ========================================")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
