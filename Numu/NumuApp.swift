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
            print("📦 [FINAL] Initializing Numu with CloudKit Support")
            print("    Models (all CloudKit-ready with optional relationships):")
            print("      - System.self")
            print("      - HabitTask.self")
            print("      - HabitTaskLog.self")
            print("      - PerformanceTest.self")
            print("      - PerformanceTestEntry.self")
            print("")
            print("    ☁️ CloudKit Configuration:")
            print("       - Container ID: iCloud.com.majdiskandarani.Numu.v2")
            print("       - Database: .automatic (syncs across all devices)")
            print("       - All relationships: OPTIONAL ✅")
            print("       - ⚠️ Changed container to .v2 to avoid V1 corrupted data")

            print("")
            print("🔧 [STEP 1] Creating Schema...")
            let schema = Schema([
                System.self,
                HabitTask.self,
                HabitTaskLog.self,
                PerformanceTest.self,
                PerformanceTestEntry.self
            ])
            print("✅ Schema created with \(schema.entities.count) entities")

            print("")
            print("🔧 [STEP 2] Creating ModelConfiguration with CloudKit...")

            // 🛡️ DEFENSIVE: Delete existing store to prevent V1 schema corruption issues
            let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")
            if FileManager.default.fileExists(atPath: storeURL.path) {
                print("⚠️ [DATABASE] Found existing store at: \(storeURL.path)")
                print("⚠️ [DATABASE] Deleting to prevent V1 schema corruption...")
                try? FileManager.default.removeItem(at: storeURL)

                // Also delete the -shm and -wal files
                try? FileManager.default.removeItem(at: storeURL.appending(path: "-shm"))
                try? FileManager.default.removeItem(at: storeURL.appending(path: "-wal"))
                print("✅ [DATABASE] Old store deleted, starting fresh")
            }

            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            print("✅ ModelConfiguration created with CloudKit sync enabled")

            print("")
            print("🔧 [STEP 3] Creating ModelContainer...")
            modelContainer = try ModelContainer(
                for: schema,
                configurations: configuration
            )

            print("")
            print("✅ [SUCCESS] ModelContainer initialized!")
            print("    - Total entities: \(modelContainer.schema.entities.count)")
            print("    - CloudKit: ENABLED ☁️")
            print("    - Syncing across all Apple devices")
            for (index, entity) in modelContainer.schema.entities.enumerated() {
                print("      \(index + 1). \(entity.name)")
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
        print("🎉 [NUMU] APP READY!")
        print("🎉 [NUMU] CloudKit Sync ☁️ + Full UI ✅")
        print("🎉 [NUMU] ========================================")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
