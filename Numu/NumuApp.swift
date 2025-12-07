//
//  NumuApp.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct NumuApp: App {
    let modelContainer: ModelContainer
    @State private var notificationManager = NotificationManager()
    @State private var healthKitService = HealthKitService()
    @State private var hapticManager = HapticManager()
    @State private var motionManager = MotionManager()

    // Notification delegate for foreground notifications
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

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
            print("      - Achievement.self")
            print("      - UserProgress.self")
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
                PerformanceTestEntry.self,
                Achievement.self,
                UserProgress.self
            ])
            print("✅ Schema created with \(schema.entities.count) entities")

            print("")
            print("🔧 [STEP 2] Creating ModelConfiguration with CloudKit...")

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
            MainTabView()
                .environment(notificationManager)
                .environment(healthKitService)
                .environment(hapticManager)
                .environment(motionManager)
                .task {
                    // Request notification permissions on first launch
                    if notificationManager.authorizationStatus == .notDetermined {
                        _ = await notificationManager.requestAuthorization()
                    }

                    // Request HealthKit authorization on first launch
                    if healthKitService.isHealthKitAvailable {
                        if !healthKitService.isAuthorized {
                            _ = await healthKitService.requestAuthorization()
                        }
                    }
                }
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Sync HealthKit data every time the app becomes active
            if newPhase == .active {
                print("🔄 [HealthKit] App became active - syncing...")
                Task {
                    if healthKitService.isAuthorized {
                        let context = modelContainer.mainContext
                        let descriptor = FetchDescriptor<HabitTask>()

                        do {
                            let allTasks = try context.fetch(descriptor)
                            await healthKitService.checkAllMappedTasksForToday(
                                tasks: allTasks,
                                modelContext: context
                            )
                        } catch {
                            print("❌ [HealthKit] Failed to fetch tasks for sync: \(error)")
                        }
                    }
                }
            }
        }
    }

    @Environment(\.scenePhase) private var scenePhase
}

// MARK: - App Delegate for Foreground Notifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Set the notification delegate
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // This method is called when a notification arrives while the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show the notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification taps
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle the notification tap here if needed
        print("📬 Notification tapped: \(response.notification.request.content.title)")
        completionHandler()
    }
}
