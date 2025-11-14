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
            print("📦 [STAGE 2-3] Initializing with CloudKit Support")
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
            print("    ☁️ CloudKit Configuration:")
            print("       - Container ID: iCloud.com.majdiskandarani.Numu")
            print("       - Database: .automatic (uses entitlements)")
            print("       - All relationships: OPTIONAL (CloudKit requirement)")

            // STAGE 2-3: Add CloudKit support with explicit configuration
            print("")
            print("🔧 [STEP 1] Creating explicit Schema...")
            let schema = Schema([
                System.self, HabitTask.self, HabitTaskLog.self, PerformanceTest.self, PerformanceTestEntry.self,
                Habit.self, HabitLog.self, SystemMetrics.self, MetricEntry.self
            ])
            print("✅ Schema created with \(schema.entities.count) entities")

            print("")
            print("🔧 [STEP 2] Creating ModelConfiguration with CloudKit...")
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic  // Uses iCloud container from entitlements
            )
            print("✅ ModelConfiguration created")
            print("    - CloudKit container: iCloud.com.majdiskandarani.Numu")
            print("    - Storage: Persistent (not in-memory)")
            print("    - Sync: Automatic across all devices")

            print("")
            print("🔧 [STEP 3] Creating ModelContainer...")
            modelContainer = try ModelContainer(
                for: schema,
                configurations: configuration
            )

            print("")
            print("✅ [STAGES 2-3] ModelContainer initialized successfully!")
            print("    - Schema entities: \(modelContainer.schema.entities.count)")
            print("    - CloudKit: ENABLED")
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
        print("🎉 [NUMU] STAGES 2-3 COMPLETE!")
        print("🎉 [NUMU] CloudKit + SwiftData Ready to Sync!")
        print("🎉 [NUMU] ========================================")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
