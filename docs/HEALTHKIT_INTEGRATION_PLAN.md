# HealthKit Integration Plan for Numu

**Last Updated:** November 21, 2025
**Status:** Planning Phase
**Branch:** `claude/brainstorm-app-improvements-01HP6H4K3C3WCvEDR2kuVYtu`

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Problem Statement](#problem-statement)
3. [Solution Architecture](#solution-architecture)
4. [Data Model Changes](#data-model-changes)
5. [User Experience Flows](#user-experience-flows)
6. [Technical Implementation](#technical-implementation)
7. [Preset Systems](#preset-systems)
8. [Implementation Roadmap](#implementation-roadmap)
9. [Edge Cases & Considerations](#edge-cases--considerations)

---

## Overview

### Goals
Enable Numu to integrate with Apple HealthKit to:
- **Automatically track task completions** from Apple Watch workouts and iPhone health data
- **Reduce friction** for users who already track fitness activities
- **Support non-watch users** with seamless manual entry fallback
- **Maintain data transparency** by showing completion sources

### Key Principles
- ✅ **Always optional** - Manual entry always works
- ✅ **Multi-metric support** - One task can match multiple workout types
- ✅ **Smart deduplication** - No double-counting manual + auto entries
- ✅ **Privacy-first** - Granular permissions, data stays on device
- ✅ **Source transparency** - Users always see how tasks were completed

---

## Problem Statement

### Use Case: Hybrid Athlete System

**Scenario:**
- System: "Hybrid Athlete"
- Task: "Cardio" (4x per week)
- Multiple workout types should count: running, cycling, soccer, swimming, etc.

**Challenges:**
1. **Watch users:** Should auto-track when any cardio workout is logged
2. **Non-watch users:** Need simple manual checkbox
3. **Hybrid users:** Prevent duplicates if both manual + HealthKit happen
4. **Flexibility:** Different workout types should map to same task

**Solution Requirements:**
- One task → multiple HealthKit workout types
- Background monitoring for automatic completion
- Manual override/completion always available
- Clear indication of data source (manual vs HealthKit)
- Minimum duration thresholds (e.g., 20+ min workouts only)

---

## Solution Architecture

### Approach: Multi-Metric Linking with Flexible Completion

```
┌─────────────────────────────────────────────────────────┐
│                     TASK: "Cardio"                      │
│                   (4x per week target)                  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  HealthKit Enabled: ✅                                  │
│  Metrics: [running, cycling, soccer, swimming, ...]    │
│  Min Duration: 20 minutes                               │
│  Auto-Complete: ✅                                      │
│                                                         │
└───────────┬─────────────────────────────┬───────────────┘
            │                             │
            ▼                             ▼
    ┌───────────────┐           ┌──────────────────┐
    │  Apple Watch  │           │  Manual Entry    │
    │   Workouts    │           │   (No Watch)     │
    └───────┬───────┘           └────────┬─────────┘
            │                            │
            │   Background Delivery      │   Tap Checkbox
            │                            │
            ▼                            ▼
    ┌───────────────────────────────────────────┐
    │        HabitTaskLog Created               │
    │  • completionSource: .healthkit/.manual   │
    │  • healthKitWorkoutType: "Running" / nil  │
    │  • healthKitWorkoutUUID: UUID / nil       │
    │  • deduplication check                    │
    └───────────────────────────────────────────┘
```

---

## Data Model Changes

### 1. HabitTask.swift - Add HealthKit Fields

**Location:** After line 96 (after `reward` property)

```swift
// MARK: - HealthKit Integration (Optional)

/// Whether this task is linked to Apple Health data
var healthKitEnabled: Bool = false

/// Array of HealthKit workout/metric IDs that trigger completion
/// Example: ["workout.running", "workout.cycling", "workout.soccer"]
var healthKitMetrics: [String] = []

/// Minimum workout duration in minutes (0 = any duration counts)
/// Example: 20 means only workouts 20+ minutes will trigger completion
var healthKitMinDuration: Int = 0

/// If true, automatically creates log when HealthKit data detected
/// If false, HealthKit only suggests completion but user must confirm
var healthKitAutoComplete: Bool = true
```

**CloudKit Compatibility Notes:**
- All new properties have default values ✅
- Arrays are supported in SwiftData/CloudKit ✅
- No new relationships added ✅

---

### 2. HabitTaskLog.swift - Add Source Tracking

**Location:** After line 25 (after `minutesSpent` property)

```swift
// MARK: - Completion Source Tracking

/// Source of this completion (manual or HealthKit)
private var completionSourceRaw: String = "manual"
var completionSource: CompletionSource {
    get { CompletionSource(rawValue: completionSourceRaw) ?? .manual }
    set { completionSourceRaw = newValue.rawValue }
}

/// Human-readable workout type from HealthKit (e.g., "Running", "Cycling")
var healthKitWorkoutType: String?

/// UUID of the HealthKit workout for deduplication
var healthKitWorkoutUUID: String?
```

**Add to bottom of TaskLog.swift:**

```swift
// MARK: - Completion Source Enum

enum CompletionSource: String, Codable {
    case manual = "manual"
    case healthkit = "healthkit"

    var icon: String {
        switch self {
        case .manual: return "hand.tap.fill"
        case .healthkit: return "heart.fill"
        }
    }

    var displayName: String {
        switch self {
        case .manual: return "Manual"
        case .healthkit: return "Apple Health"
        }
    }
}
```

---

### 3. New File: HealthKitWorkoutCategories.swift

**Location:** `Numu/Models/HealthKitWorkoutCategories.swift`

```swift
//
//  HealthKitWorkoutCategories.swift
//  Numu
//
//  Created for HealthKit Integration
//

import Foundation
import HealthKit

/// Workout category groupings for easy selection in UI
enum WorkoutCategory: String, CaseIterable {
    case cardio = "Cardio"
    case strength = "Strength & Resistance"
    case flexibility = "Flexibility & Balance"
    case sports = "Sports"
    case mindBody = "Mind & Body"
    case outdoor = "Outdoor Activities"

    var workouts: [HealthKitWorkoutType] {
        switch self {
        case .cardio:
            return [.running, .cycling, .swimming, .rowing, .elliptical,
                    .stairStepper, .hiking, .walking]
        case .strength:
            return [.traditionalStrengthTraining, .functionalStrengthTraining,
                    .coreTraining, .crossTraining]
        case .flexibility:
            return [.yoga, .flexibility, .pilates, .stretching]
        case .sports:
            return [.soccer, .basketball, .tennis, .golf, .baseball,
                    .hockey, .volleyball, .boxing, .martialArts]
        case .mindBody:
            return [.yoga, .taiChi, .pilates, .mindAndBody]
        case .outdoor:
            return [.hiking, .climbing, .snowboarding, .skiing,
                    .surfing, .sailing, .openWaterSwimming]
        }
    }

    var icon: String {
        switch self {
        case .cardio: return "heart.circle.fill"
        case .strength: return "dumbbell.fill"
        case .flexibility: return "figure.flexibility"
        case .sports: return "sportscourt.fill"
        case .mindBody: return "brain.head.profile"
        case .outdoor: return "mountain.2.fill"
        }
    }
}

/// Represents a specific HealthKit workout type
struct HealthKitWorkoutType: Identifiable {
    let id: String  // e.g., "workout.running"
    let displayName: String  // "Running"
    let icon: String  // SF Symbol
    let hkIdentifier: HKWorkoutActivityType

    // MARK: - Cardio Workouts

    static let running = HealthKitWorkoutType(
        id: "workout.running",
        displayName: "Running",
        icon: "figure.run",
        hkIdentifier: .running
    )

    static let cycling = HealthKitWorkoutType(
        id: "workout.cycling",
        displayName: "Cycling",
        icon: "figure.outdoor.cycle",
        hkIdentifier: .cycling
    )

    static let swimming = HealthKitWorkoutType(
        id: "workout.swimming",
        displayName: "Swimming",
        icon: "figure.pool.swim",
        hkIdentifier: .swimming
    )

    static let rowing = HealthKitWorkoutType(
        id: "workout.rowing",
        displayName: "Rowing",
        icon: "figure.indoor.cycle",  // No rowing icon, use closest
        hkIdentifier: .rowing
    )

    static let elliptical = HealthKitWorkoutType(
        id: "workout.elliptical",
        displayName: "Elliptical",
        icon: "figure.elliptical",
        hkIdentifier: .elliptical
    )

    static let stairStepper = HealthKitWorkoutType(
        id: "workout.stairStepper",
        displayName: "Stair Stepper",
        icon: "figure.stairs",
        hkIdentifier: .stairStepping
    )

    static let hiking = HealthKitWorkoutType(
        id: "workout.hiking",
        displayName: "Hiking",
        icon: "figure.hiking",
        hkIdentifier: .hiking
    )

    static let walking = HealthKitWorkoutType(
        id: "workout.walking",
        displayName: "Walking",
        icon: "figure.walk",
        hkIdentifier: .walking
    )

    // MARK: - Strength Workouts

    static let traditionalStrengthTraining = HealthKitWorkoutType(
        id: "workout.traditionalStrengthTraining",
        displayName: "Strength Training",
        icon: "dumbbell.fill",
        hkIdentifier: .traditionalStrengthTraining
    )

    static let functionalStrengthTraining = HealthKitWorkoutType(
        id: "workout.functionalStrengthTraining",
        displayName: "Functional Strength",
        icon: "figure.strengthtraining.traditional",
        hkIdentifier: .functionalStrengthTraining
    )

    static let coreTraining = HealthKitWorkoutType(
        id: "workout.coreTraining",
        displayName: "Core Training",
        icon: "figure.core.training",
        hkIdentifier: .coreTraining
    )

    static let crossTraining = HealthKitWorkoutType(
        id: "workout.crossTraining",
        displayName: "Cross Training",
        icon: "figure.cross.training",
        hkIdentifier: .crossTraining
    )

    // MARK: - Flexibility Workouts

    static let yoga = HealthKitWorkoutType(
        id: "workout.yoga",
        displayName: "Yoga",
        icon: "figure.yoga",
        hkIdentifier: .yoga
    )

    static let flexibility = HealthKitWorkoutType(
        id: "workout.flexibility",
        displayName: "Flexibility",
        icon: "figure.flexibility",
        hkIdentifier: .flexibility
    )

    static let pilates = HealthKitWorkoutType(
        id: "workout.pilates",
        displayName: "Pilates",
        icon: "figure.pilates",
        hkIdentifier: .pilates
    )

    static let stretching = HealthKitWorkoutType(
        id: "workout.stretching",
        displayName: "Stretching",
        icon: "figure.flexibility",
        hkIdentifier: .flexibility
    )

    // MARK: - Sports

    static let soccer = HealthKitWorkoutType(
        id: "workout.soccer",
        displayName: "Soccer",
        icon: "figure.soccer",
        hkIdentifier: .soccer
    )

    static let basketball = HealthKitWorkoutType(
        id: "workout.basketball",
        displayName: "Basketball",
        icon: "figure.basketball",
        hkIdentifier: .basketball
    )

    static let tennis = HealthKitWorkoutType(
        id: "workout.tennis",
        displayName: "Tennis",
        icon: "figure.tennis",
        hkIdentifier: .tennis
    )

    static let golf = HealthKitWorkoutType(
        id: "workout.golf",
        displayName: "Golf",
        icon: "figure.golf",
        hkIdentifier: .golf
    )

    static let baseball = HealthKitWorkoutType(
        id: "workout.baseball",
        displayName: "Baseball",
        icon: "figure.baseball",
        hkIdentifier: .baseball
    )

    static let hockey = HealthKitWorkoutType(
        id: "workout.hockey",
        displayName: "Hockey",
        icon: "figure.hockey",
        hkIdentifier: .hockey
    )

    static let volleyball = HealthKitWorkoutType(
        id: "workout.volleyball",
        displayName: "Volleyball",
        icon: "figure.volleyball",
        hkIdentifier: .volleyball
    )

    static let boxing = HealthKitWorkoutType(
        id: "workout.boxing",
        displayName: "Boxing",
        icon: "figure.boxing",
        hkIdentifier: .boxing
    )

    static let martialArts = HealthKitWorkoutType(
        id: "workout.martialArts",
        displayName: "Martial Arts",
        icon: "figure.martial.arts",
        hkIdentifier: .martialArts
    )

    // MARK: - Mind & Body

    static let taiChi = HealthKitWorkoutType(
        id: "workout.taiChi",
        displayName: "Tai Chi",
        icon: "figure.tai.chi",
        hkIdentifier: .taiChi
    )

    static let mindAndBody = HealthKitWorkoutType(
        id: "workout.mindAndBody",
        displayName: "Mind & Body",
        icon: "brain.head.profile",
        hkIdentifier: .mindAndBody
    )

    // MARK: - Outdoor Activities

    static let climbing = HealthKitWorkoutType(
        id: "workout.climbing",
        displayName: "Climbing",
        icon: "figure.climbing",
        hkIdentifier: .climbing
    )

    static let snowboarding = HealthKitWorkoutType(
        id: "workout.snowboarding",
        displayName: "Snowboarding",
        icon: "figure.snowboarding",
        hkIdentifier: .snowboarding
    )

    static let skiing = HealthKitWorkoutType(
        id: "workout.skiing",
        displayName: "Skiing",
        icon: "figure.skiing.downhill",
        hkIdentifier: .downhillSkiing
    )

    static let surfing = HealthKitWorkoutType(
        id: "workout.surfing",
        displayName: "Surfing",
        icon: "figure.surfing",
        hkIdentifier: .surfingSports
    )

    static let sailing = HealthKitWorkoutType(
        id: "workout.sailing",
        displayName: "Sailing",
        icon: "sailboat.fill",
        hkIdentifier: .sailing
    )

    static let openWaterSwimming = HealthKitWorkoutType(
        id: "workout.openWaterSwimming",
        displayName: "Open Water Swimming",
        icon: "figure.open.water.swim",
        hkIdentifier: .openWaterSwimming
    )

    // MARK: - Helper Methods

    /// Convert HKWorkoutActivityType to our workout ID
    static func idFromHKType(_ type: HKWorkoutActivityType) -> String {
        // Map HK types back to our IDs
        switch type {
        case .running: return "workout.running"
        case .cycling: return "workout.cycling"
        case .swimming: return "workout.swimming"
        case .rowing: return "workout.rowing"
        case .elliptical: return "workout.elliptical"
        case .stairClimbing: return "workout.stairStepper"
        case .hiking: return "workout.hiking"
        case .walking: return "workout.walking"
        case .traditionalStrengthTraining: return "workout.traditionalStrengthTraining"
        case .functionalStrengthTraining: return "workout.functionalStrengthTraining"
        case .coreTraining: return "workout.coreTraining"
        case .crossTraining: return "workout.crossTraining"
        case .yoga: return "workout.yoga"
        case .flexibility: return "workout.flexibility"
        case .pilates: return "workout.pilates"
        case .soccer: return "workout.soccer"
        case .basketball: return "workout.basketball"
        case .tennis: return "workout.tennis"
        case .golf: return "workout.golf"
        case .baseball: return "workout.baseball"
        case .hockey: return "workout.hockey"
        case .volleyball: return "workout.volleyball"
        case .boxing: return "workout.boxing"
        case .martialArts: return "workout.martialArts"
        case .taiChi: return "workout.taiChi"
        case .mindAndBody: return "workout.mindAndBody"
        case .climbing: return "workout.climbing"
        case .snowboarding: return "workout.snowboarding"
        case .downhillSkiing: return "workout.skiing"
        case .surfingSports: return "workout.surfing"
        case .sailing: return "workout.sailing"
        case .swimBikeRun: return "workout.swimming" // Triathlon
        default: return "workout.other"
        }
    }

    /// Get display name for HKWorkoutActivityType
    static func displayNameFromHKType(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .rowing: return "Rowing"
        case .elliptical: return "Elliptical"
        case .stairClimbing: return "Stair Stepper"
        case .hiking: return "Hiking"
        case .walking: return "Walking"
        case .traditionalStrengthTraining: return "Strength Training"
        case .functionalStrengthTraining: return "Functional Strength"
        case .coreTraining: return "Core Training"
        case .crossTraining: return "Cross Training"
        case .yoga: return "Yoga"
        case .flexibility: return "Flexibility"
        case .pilates: return "Pilates"
        case .soccer: return "Soccer"
        case .basketball: return "Basketball"
        case .tennis: return "Tennis"
        case .golf: return "Golf"
        case .baseball: return "Baseball"
        case .hockey: return "Hockey"
        case .volleyball: return "Volleyball"
        case .boxing: return "Boxing"
        case .martialArts: return "Martial Arts"
        case .taiChi: return "Tai Chi"
        case .mindAndBody: return "Mind & Body"
        case .climbing: return "Climbing"
        case .snowboarding: return "Snowboarding"
        case .downhillSkiing: return "Skiing"
        case .surfingSports: return "Surfing"
        case .sailing: return "Sailing"
        default: return "Other"
        }
    }
}
```

---

## User Experience Flows

### Flow 1: Creating "Cardio" Task with Multi-Workout Linking

#### Screen 1: Create Task (Standard View)

```
┌─────────────────────────────────────┐
│  ← Create Task                      │
├─────────────────────────────────────┤
│                                     │
│  Task Name                          │
│  ┌───────────────────────────────┐ │
│  │ Cardio                        │ │
│  └───────────────────────────────┘ │
│                                     │
│  Frequency                          │
│  ┌───────────────────────────────┐ │
│  │ 4x per week              ▼   │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 🍎 Link to Apple Health    │   │
│  │                         ○→ │   │  ← Toggle OFF by default
│  └─────────────────────────────┘   │
│                                     │
│  Description (Optional)             │
│  ┌───────────────────────────────┐ │
│  │                               │ │
│  └───────────────────────────────┘ │
│                                     │
│         [ Save Task ]               │
│                                     │
└─────────────────────────────────────┘
```

#### Screen 2: HealthKit Link Configuration (When Toggle ON)

```
┌─────────────────────────────────────┐
│  ← Link to Apple Health             │
├─────────────────────────────────────┤
│                                     │
│  Which workouts count as "Cardio"?  │
│  Select all that apply              │
│                                     │
│  ┌─── CARDIO WORKOUTS ───────────┐ │
│  │ ✅ Running                     │ │
│  │ ✅ Cycling                     │ │
│  │ ✅ Swimming                    │ │
│  │ ✅ Rowing                      │ │
│  │ ✅ Elliptical                  │ │
│  │ ✅ Stair Stepper              │ │
│  │ ✅ Hiking                      │ │
│  │ ☐  Walking                    │ │
│  └────────────────────────────────┘ │
│                                     │
│  ┌─── SPORTS ─────────────────────┐ │
│  │ ✅ Soccer                      │ │
│  │ ✅ Basketball                  │ │
│  │ ✅ Tennis                      │ │
│  │ ☐  Golf                       │ │
│  └────────────────────────────────┘ │
│                                     │
│  ┌─── ADVANCED ───────────────────┐ │
│  │ Minimum workout duration       │ │
│  │ ┌──────┐                       │ │
│  │ │ 20  │ minutes (0 = any)     │ │
│  │ └──────┘                       │ │
│  │                                │ │
│  │ ☑ Auto-complete when detected │ │
│  │ ☐ Only suggest, I'll confirm  │ │
│  └────────────────────────────────┘ │
│                                     │
│  ℹ️  9 workout types selected       │
│                                     │
│         [ Save & Continue ]         │
│                                     │
└─────────────────────────────────────┘
```

#### Quick Select Buttons

Add toolbar buttons for common selections:
- "Select All Cardio" → Checks all cardio workouts
- "Select All Sports" → Checks all sports
- "Clear All" → Unchecks everything

---

### Flow 2: Task Completion Scenarios

#### Scenario A: Watch User - Auto-Completion

**Timeline:**
1. **8:00 AM** - User starts "Outdoor Run" workout on Apple Watch
2. **8:30 AM** - User finishes workout (30 min), taps "End"
3. **8:31 AM** - HealthKit saves workout data
4. **8:31 AM** - Numu receives background notification
5. **8:31 AM** - Numu checks: matches "Cardio" task (running ✓, 30min > 20min ✓)
6. **8:31 AM** - Auto-creates `HabitTaskLog`:
   ```swift
   HabitTaskLog(
       date: today,
       completionSource: .healthkit,
       healthKitWorkoutType: "Running",
       healthKitWorkoutUUID: workout.uuid.uuidString,
       notes: "30 min outdoor run"
   )
   ```
7. **9:00 AM** - User opens Numu → Task already checked ✅

**Visual on Task Card:**
```
┌────────────────────────────────────┐
│ ✅ Cardio                 2/4 ★★☆☆│
│    ❤️ Running · 30 min · 8:31 AM  │
│    Tap to view details             │
└────────────────────────────────────┘
```

#### Scenario B: Non-Watch User - Manual Completion

**Timeline:**
1. User does cardio at gym (no watch)
2. Opens Numu
3. Taps checkbox on "Cardio" task
4. **Optional quick modal appears:**

```
┌─────────────────────────────┐
│  Cardio Completed! 🎉      │
├─────────────────────────────┤
│  What did you do? (Optional)│
│  ┌─────────────────────┐   │
│  │ Select...        ▼ │   │
│  └─────────────────────┘   │
│     Running                 │
│     Cycling                 │
│     Swimming                │
│     Other                   │
│                             │
│  Notes? (Optional)          │
│  ┌─────────────────────┐   │
│  │                     │   │
│  └─────────────────────┘   │
│                             │
│  [ Skip ]    [ Save ]       │
└─────────────────────────────┘
```

5. Task marked complete with `completionSource: .manual`

**Visual on Task Card:**
```
┌────────────────────────────────────┐
│ ✅ Cardio                 2/4 ★★☆☆│
│    ✋ Manual · 2:15 PM             │
└────────────────────────────────────┘
```

#### Scenario C: Smart Deduplication

**Situation:** User forgets watch, does workout, manually logs it, then later syncs watch

**Timeline:**
1. **8:00 AM** - User runs without watch
2. **9:00 AM** - User manually logs "Cardio" in Numu
3. **10:00 AM** - User syncs Apple Watch (had tracked workout from another device/later sync)
4. **10:01 AM** - HealthKit delivers workout data to Numu
5. **10:01 AM** - Numu deduplication logic:
   ```swift
   // Check: Manual log exists at 9:00 AM
   // Check: Workout was at 8:00 AM
   // Time difference: 1 hour (< 2 hour threshold)
   // Decision: SKIP creating HealthKit log (likely same workout)
   ```
6. No duplicate created ✅

---

### Flow 3: Viewing Completion Details

**Tap on completed task:**

```
┌─────────────────────────────────────┐
│  ← Cardio                           │
├─────────────────────────────────────┤
│                                     │
│  This Week: 2/4 completions         │
│  ████████░░░░░░░░░░░░               │
│                                     │
│  ┌─── MONDAY, NOV 18 ─────────────┐│
│  │ ✅ Running                      ││
│  │    ❤️ Apple Health             ││
│  │    30 min outdoor run           ││
│  │    8:31 AM                      ││
│  │                                 ││
│  │    [View in Health App]         ││
│  │    [Remove Completion]          ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─── WEDNESDAY, NOV 20 ───────────┐│
│  │ ✅ Cycling                      ││
│  │    ✋ Manual entry              ││
│  │    At the gym                   ││
│  │    2:15 PM                      ││
│  │                                 ││
│  │    [Edit] [Remove]              ││
│  └─────────────────────────────────┘│
│                                     │
│  ⚙️ [Manage HealthKit Link]         │
│                                     │
└─────────────────────────────────────┘
```

---

## Technical Implementation

### 1. HealthKitManager Service

**Location:** `Numu/Services/HealthKitManager.swift`

```swift
//
//  HealthKitManager.swift
//  Numu
//
//  HealthKit integration service for automatic task completion
//

import Foundation
import HealthKit
import SwiftData

@Observable
class HealthKitManager {
    let healthStore = HKHealthStore()
    private var backgroundObservers: [HKObserverQuery] = []

    // MARK: - Availability Check

    static var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization

    /// Request authorization for workout data
    func requestWorkoutAuthorization() async throws {
        let workoutType = HKObjectType.workoutType()

        try await healthStore.requestAuthorization(
            toShare: [],
            read: [workoutType]
        )
    }

    /// Check if we have authorization for workouts
    func hasWorkoutAuthorization() -> Bool {
        let workoutType = HKObjectType.workoutType()
        let status = healthStore.authorizationStatus(for: workoutType)
        return status == .sharingAuthorized
    }

    // MARK: - Background Delivery

    /// Enable background delivery for workouts
    func enableBackgroundDelivery() {
        let workoutType = HKObjectType.workoutType()

        // Create observer query
        let query = HKObserverQuery(sampleType: workoutType, predicate: nil) { [weak self] query, completionHandler, error in
            guard error == nil else {
                print("❌ [HealthKit] Observer query error: \(error!.localizedDescription)")
                completionHandler()
                return
            }

            print("📲 [HealthKit] New workout detected, processing...")

            // Fetch and process new workouts
            Task {
                await self?.fetchAndProcessRecentWorkouts()
                completionHandler()
            }
        }

        healthStore.execute(query)
        backgroundObservers.append(query)

        // Enable background delivery
        healthStore.enableBackgroundDelivery(for: workoutType, frequency: .immediate) { success, error in
            if success {
                print("✅ [HealthKit] Background delivery enabled")
            } else if let error = error {
                print("❌ [HealthKit] Failed to enable background delivery: \(error.localizedDescription)")
            }
        }
    }

    /// Disable background delivery
    func disableBackgroundDelivery() {
        let workoutType = HKObjectType.workoutType()

        // Stop all observer queries
        backgroundObservers.forEach { healthStore.stop($0) }
        backgroundObservers.removeAll()

        // Disable background delivery
        healthStore.disableBackgroundDelivery(for: workoutType) { success, error in
            if success {
                print("✅ [HealthKit] Background delivery disabled")
            } else if let error = error {
                print("❌ [HealthKit] Failed to disable background delivery: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Workout Processing

    /// Fetch workouts from the last 24 hours and process them
    private func fetchAndProcessRecentWorkouts() async {
        let workoutType = HKObjectType.workoutType()
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!

        let predicate = HKQuery.predicateForSamples(
            withStart: yesterday,
            end: now,
            options: .strictStartDate
        )

        let query = HKSampleQuery(
            sampleType: workoutType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        ) { [weak self] query, samples, error in
            guard error == nil,
                  let workouts = samples as? [HKWorkout] else {
                print("❌ [HealthKit] Failed to fetch workouts: \(error?.localizedDescription ?? "unknown error")")
                return
            }

            print("📊 [HealthKit] Fetched \(workouts.count) recent workouts")

            // Process each workout
            Task {
                for workout in workouts {
                    await self?.processWorkout(workout)
                }
            }
        }

        healthStore.execute(query)
    }

    /// Process a single workout and check for matching tasks
    func processWorkout(_ workout: HKWorkout) async {
        print("🏃 [HealthKit] Processing workout: \(workout.workoutActivityType.name) at \(workout.startDate)")

        // Get workout type ID
        let workoutTypeID = HealthKitWorkoutType.idFromHKType(workout.workoutActivityType)
        let durationMinutes = Int(workout.duration / 60)

        // Get model context (need to pass from app or create new one)
        // For now, we'll use a notification to trigger processing in the main app
        // This allows access to the existing ModelContext

        let userInfo: [String: Any] = [
            "workoutTypeID": workoutTypeID,
            "workoutUUID": workout.uuid.uuidString,
            "workoutType": HealthKitWorkoutType.displayNameFromHKType(workout.workoutActivityType),
            "duration": durationMinutes,
            "startDate": workout.startDate
        ]

        NotificationCenter.default.post(
            name: .healthKitWorkoutDetected,
            object: nil,
            userInfo: userInfo
        )
    }

    // MARK: - Task Matching & Auto-Completion

    /// Check if workout matches a task and create log if needed
    /// This should be called from the app with access to ModelContext
    static func handleWorkoutDetection(
        workoutTypeID: String,
        workoutUUID: String,
        workoutType: String,
        duration: Int,
        startDate: Date,
        modelContext: ModelContext
    ) async {
        print("🔍 [HealthKit] Checking tasks for workout: \(workoutType)")

        // Fetch all HealthKit-enabled tasks
        let descriptor = FetchDescriptor<HabitTask>(
            predicate: #Predicate { $0.healthKitEnabled == true }
        )

        guard let tasks = try? modelContext.fetch(descriptor) else {
            print("❌ [HealthKit] Failed to fetch tasks")
            return
        }

        print("📋 [HealthKit] Found \(tasks.count) HealthKit-enabled tasks")

        for task in tasks {
            // Check if workout type matches any of task's metrics
            guard task.healthKitMetrics.contains(workoutTypeID) else {
                continue
            }

            print("✓ [HealthKit] Task '\(task.name)' matches workout type")

            // Check minimum duration requirement
            if duration < task.healthKitMinDuration {
                print("⏱️ [HealthKit] Duration \(duration)min < minimum \(task.healthKitMinDuration)min, skipping")
                continue
            }

            print("✓ [HealthKit] Duration requirement met")

            // Check if auto-complete is enabled
            guard task.healthKitAutoComplete else {
                print("⚠️ [HealthKit] Auto-complete disabled for this task")
                // TODO: Send notification to suggest completion instead
                continue
            }

            // Check for duplicates
            if shouldCreateLog(for: workoutUUID, task: task, startDate: startDate) {
                // Create auto-completion log
                let log = HabitTaskLog(date: startDate)
                log.completionSource = .healthkit
                log.healthKitWorkoutType = workoutType
                log.healthKitWorkoutUUID = workoutUUID
                log.notes = "\(duration) min \(workoutType.lowercased())"
                log.task = task

                modelContext.insert(log)

                do {
                    try modelContext.save()
                    print("✅ [HealthKit] Created log for task '\(task.name)'")

                    // Send success notification
                    await sendCompletionNotification(taskName: task.name, workoutType: workoutType)
                } catch {
                    print("❌ [HealthKit] Failed to save log: \(error)")
                }
            } else {
                print("⚠️ [HealthKit] Duplicate detected, skipping log creation")
            }
        }
    }

    // MARK: - Deduplication Logic

    /// Check if we should create a log for this workout (deduplication)
    private static func shouldCreateLog(for workoutUUID: String, task: HabitTask, startDate: Date) -> Bool {
        let workoutDate = Calendar.current.startOfDay(for: startDate)

        // Check if this exact workout is already logged
        if let logs = task.logs {
            if logs.contains(where: { $0.healthKitWorkoutUUID == workoutUUID }) {
                print("🔍 [HealthKit] Exact workout UUID already exists")
                return false
            }
        }

        // Check for manual logs on same day within ±2 hours
        let sameDayLogs = task.logs?.filter { log in
            Calendar.current.isDate(log.date, inSameDayAs: workoutDate)
        } ?? []

        for log in sameDayLogs where log.completionSource == .manual {
            let timeDiff = abs(log.completedAt.timeIntervalSince(startDate))
            if timeDiff < 7200 { // 2 hours = 7200 seconds
                print("🔍 [HealthKit] Manual log within 2 hours detected")
                return false
            }
        }

        // All checks passed, create log
        return true
    }

    // MARK: - Notifications

    /// Send local notification when task is auto-completed
    private static func sendCompletionNotification(taskName: String, workoutType: String) async {
        let content = UNMutableNotificationContent()
        content.title = "✅ \(taskName) Completed!"
        content.body = "We tracked your \(workoutType) workout"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("📬 [HealthKit] Sent completion notification")
        } catch {
            print("❌ [HealthKit] Failed to send notification: \(error)")
        }
    }
}

// MARK: - Notification Name Extension

extension Notification.Name {
    static let healthKitWorkoutDetected = Notification.Name("healthKitWorkoutDetected")
}

// MARK: - HKWorkoutActivityType Extension

extension HKWorkoutActivityType {
    var name: String {
        HealthKitWorkoutType.displayNameFromHKType(self)
    }
}
```

---

### 2. App Integration (NumuApp.swift)

Add to your main app file:

```swift
import SwiftUI
import SwiftData

@main
struct NumuApp: App {
    let modelContainer: ModelContainer
    let healthKitManager = HealthKitManager()

    init() {
        do {
            modelContainer = try ModelContainer(for: System.self, HabitTask.self, HabitTaskLog.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // Setup HealthKit background delivery if authorized
        if HealthKitManager.isHealthDataAvailable && healthKitManager.hasWorkoutAuthorization() {
            healthKitManager.enableBackgroundDelivery()
        }

        // Listen for workout detection notifications
        NotificationCenter.default.addObserver(
            forName: .healthKitWorkoutDetected,
            object: nil,
            queue: .main
        ) { [weak modelContainer] notification in
            guard let userInfo = notification.userInfo,
                  let workoutTypeID = userInfo["workoutTypeID"] as? String,
                  let workoutUUID = userInfo["workoutUUID"] as? String,
                  let workoutType = userInfo["workoutType"] as? String,
                  let duration = userInfo["duration"] as? Int,
                  let startDate = userInfo["startDate"] as? Date,
                  let container = modelContainer else {
                return
            }

            Task { @MainActor in
                await HealthKitManager.handleWorkoutDetection(
                    workoutTypeID: workoutTypeID,
                    workoutUUID: workoutUUID,
                    workoutType: workoutType,
                    duration: duration,
                    startDate: startDate,
                    modelContext: container.mainContext
                )
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environment(healthKitManager)
        }
    }
}
```

---

### 3. UI Components

#### WorkoutTypePickerView.swift

**Location:** `Numu/Views/Components/HealthKit/WorkoutTypePickerView.swift`

```swift
//
//  WorkoutTypePickerView.swift
//  Numu
//
//  Picker for selecting which workout types trigger task completion
//

import SwiftUI

struct WorkoutTypePickerView: View {
    @Binding var selectedWorkoutIDs: [String]
    @State private var searchText = ""

    var body: some View {
        List {
            ForEach(WorkoutCategory.allCases, id: \.self) { category in
                Section {
                    ForEach(category.workouts, id: \.id) { workout in
                        WorkoutTypeRow(
                            workout: workout,
                            isSelected: selectedWorkoutIDs.contains(workout.id)
                        ) {
                            toggleSelection(workout.id)
                        }
                    }
                } header: {
                    HStack {
                        Image(systemName: category.icon)
                        Text(category.rawValue)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search workouts")
        .navigationTitle("Select Workouts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        selectAllInCategory(.cardio)
                    } label: {
                        Label("All Cardio", systemImage: "heart.circle.fill")
                    }

                    Button {
                        selectAllInCategory(.strength)
                    } label: {
                        Label("All Strength", systemImage: "dumbbell.fill")
                    }

                    Button {
                        selectAllInCategory(.sports)
                    } label: {
                        Label("All Sports", systemImage: "sportscourt.fill")
                    }

                    Divider()

                    Button(role: .destructive) {
                        selectedWorkoutIDs.removeAll()
                    } label: {
                        Label("Clear All", systemImage: "xmark.circle")
                    }
                } label: {
                    Label("Quick Select", systemImage: "checklist")
                }
            }
        }
    }

    private func toggleSelection(_ id: String) {
        if let index = selectedWorkoutIDs.firstIndex(of: id) {
            selectedWorkoutIDs.remove(at: index)
        } else {
            selectedWorkoutIDs.append(id)
        }
    }

    private func selectAllInCategory(_ category: WorkoutCategory) {
        let categoryIDs = category.workouts.map(\.id)
        for id in categoryIDs {
            if !selectedWorkoutIDs.contains(id) {
                selectedWorkoutIDs.append(id)
            }
        }
    }
}

struct WorkoutTypeRow: View {
    let workout: HealthKitWorkoutType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: workout.icon)
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .frame(width: 24)

                // Name
                Text(workout.displayName)
                    .foregroundStyle(.primary)

                Spacer()

                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        WorkoutTypePickerView(selectedWorkoutIDs: .constant([
            "workout.running",
            "workout.cycling"
        ]))
    }
}
```

---

## Preset Systems

### Hybrid Athlete System

```swift
//
//  SystemPresets.swift
//  Numu
//
//  Preset system templates with HealthKit integration
//

import Foundation

struct SystemPreset: Identifiable {
    let id = UUID()
    let name: String
    let category: SystemCategory
    let description: String
    let icon: String
    let color: String
    let tasks: [TaskPreset]
    let tests: [TestPreset]

    var hasHealthKitFeatures: Bool {
        tasks.contains { $0.healthKitEnabled } || tests.contains { $0.healthKitEnabled }
    }
}

struct TaskPreset {
    let name: String
    let description: String?
    let frequency: TaskFrequency
    let healthKitEnabled: Bool
    let healthKitMetrics: [String]
    let healthKitMinDuration: Int
    let cue: String?
    let easeStrategy: String?
}

struct TestPreset {
    let name: String
    let unit: String
    let goalDirection: TestGoalDirection
    let trackingFrequency: TestFrequency
    let healthKitEnabled: Bool
    let healthKitIdentifier: String?
}

// MARK: - Preset Definitions

extension SystemPreset {

    /// Hybrid Athlete - Cardio + Strength Training
    static let hybridAthlete = SystemPreset(
        name: "Hybrid Athlete",
        category: .athletics,
        description: "Build both cardiovascular endurance and muscular strength through balanced training",
        icon: "figure.mixed.cardio",
        color: "#FF6B35",
        tasks: [
            TaskPreset(
                name: "Cardio",
                description: "Any cardiovascular exercise",
                frequency: .weeklyTarget(times: 4),
                healthKitEnabled: true,
                healthKitMetrics: [
                    "workout.running",
                    "workout.cycling",
                    "workout.swimming",
                    "workout.rowing",
                    "workout.elliptical",
                    "workout.stairStepper",
                    "workout.hiking",
                    "workout.soccer",
                    "workout.basketball"
                ],
                healthKitMinDuration: 20,
                cue: "After work or early morning before breakfast",
                easeStrategy: "Even 20 minutes counts!"
            ),
            TaskPreset(
                name: "Strength Training",
                description: "Resistance training for muscle growth",
                frequency: .weeklyTarget(times: 4),
                healthKitEnabled: true,
                healthKitMetrics: [
                    "workout.traditionalStrengthTraining",
                    "workout.functionalStrengthTraining",
                    "workout.coreTraining",
                    "workout.crossTraining"
                ],
                healthKitMinDuration: 30,
                cue: "Alternate days with cardio",
                easeStrategy: "Start with bodyweight exercises - pushups, squats, planks"
            ),
            TaskPreset(
                name: "Stretching",
                description: "Flexibility and mobility work",
                frequency: .daily,
                healthKitEnabled: true,
                healthKitMetrics: [
                    "workout.flexibility",
                    "workout.yoga",
                    "workout.pilates"
                ],
                healthKitMinDuration: 10,
                cue: "Before bed to wind down",
                easeStrategy: "5-minute quick stretch routine"
            ),
            TaskPreset(
                name: "Track Nutrition",
                description: "Log meals and macros",
                frequency: .daily,
                healthKitEnabled: false,
                healthKitMetrics: [],
                healthKitMinDuration: 0,
                cue: "After each meal",
                easeStrategy: "Just take a photo of your plate"
            )
        ],
        tests: [
            TestPreset(
                name: "Resting Heart Rate",
                unit: "BPM",
                goalDirection: .lower,
                trackingFrequency: .weekly,
                healthKitEnabled: true,
                healthKitIdentifier: "HKQuantityTypeIdentifierRestingHeartRate"
            ),
            TestPreset(
                name: "VO2 Max",
                unit: "mL/kg/min",
                goalDirection: .higher,
                trackingFrequency: .weeks(2),
                healthKitEnabled: true,
                healthKitIdentifier: "HKQuantityTypeIdentifierVO2Max"
            ),
            TestPreset(
                name: "Body Weight",
                unit: "lbs",
                goalDirection: .lower,
                trackingFrequency: .weekly,
                healthKitEnabled: true,
                healthKitIdentifier: "HKQuantityTypeIdentifierBodyMass"
            ),
            TestPreset(
                name: "Bench Press Max",
                unit: "lbs",
                goalDirection: .higher,
                trackingFrequency: .weeks(4),
                healthKitEnabled: false,
                healthKitIdentifier: nil
            )
        ]
    )

    /// All available presets
    static let allPresets: [SystemPreset] = [
        .hybridAthlete,
        // Add more presets here
    ]
}
```

---

## Implementation Roadmap

### Phase 1: Foundation (Week 1)
**Goal:** Core data models and basic HealthKit setup

**Tasks:**
- [ ] Add HealthKit capability to Xcode project (`Info.plist` + entitlements)
- [ ] Update `HabitTask.swift` with HealthKit fields
- [ ] Update `HabitTaskLog.swift` with source tracking
- [ ] Create `HealthKitWorkoutCategories.swift` with workout definitions
- [ ] Create basic `HealthKitManager.swift` service
- [ ] Test: Create task, enable HealthKit, verify data saves

**Commit Message:** `[HEALTHKIT] Add data models and basic HealthKit service foundation`

---

### Phase 2: UI Components (Week 1-2)
**Goal:** User can configure HealthKit links via UI

**Tasks:**
- [ ] Create `WorkoutTypePickerView.swift`
- [ ] Add "Link to Apple Health" toggle to CreateTaskView
- [ ] Add minimum duration input
- [ ] Add "Auto-complete" vs "Suggest" toggle
- [ ] Add permission request flow
- [ ] Test: Full create task flow with HealthKit configuration

**Commit Message:** `[HEALTHKIT] Add UI for linking tasks to Apple Health workouts`

---

### Phase 3: Auto-Completion Logic (Week 2)
**Goal:** Tasks automatically complete from HealthKit data

**Tasks:**
- [ ] Implement background delivery observer
- [ ] Implement workout processing logic
- [ ] Add deduplication checks
- [ ] Create auto-completion log creation
- [ ] Add local notifications for auto-completions
- [ ] Test: Log workout on watch, verify auto-completion in app

**Commit Message:** `[HEALTHKIT] Implement automatic task completion from workouts`

---

### Phase 4: Task Detail Views (Week 2)
**Goal:** Show completion source in UI

**Tasks:**
- [ ] Update task card to show HealthKit badge
- [ ] Add completion source icon (❤️ vs ✋)
- [ ] Create detailed log view showing workout info
- [ ] Add "View in Health App" button
- [ ] Add "Manage HealthKit Link" settings
- [ ] Test: View completed tasks, see source indicators

**Commit Message:** `[HEALTHKIT] Add completion source indicators and detail views`

---

### Phase 5: Preset System (Week 3)
**Goal:** Users can create "Hybrid Athlete" preset with one tap

**Tasks:**
- [ ] Create `SystemPresets.swift` with Hybrid Athlete definition
- [ ] Add preset system picker to onboarding/create flow
- [ ] Implement preset instantiation logic
- [ ] Add HealthKit permission grouping for presets
- [ ] Test: Create Hybrid Athlete system, verify all tasks configured

**Commit Message:** `[HEALTHKIT] Add Hybrid Athlete preset system with HealthKit integration`

---

### Phase 6: Polish & Edge Cases (Week 3)
**Goal:** Handle all edge cases gracefully

**Tasks:**
- [ ] Handle permission denials with retry flow
- [ ] Add "No data found" empty states
- [ ] Create settings screen for managing all HealthKit links
- [ ] Test with multiple workout apps (Strava, Nike Run Club)
- [ ] Optimize battery usage
- [ ] Add analytics logging

**Commit Message:** `[HEALTHKIT] Polish edge cases and error handling`

---

## Edge Cases & Considerations

### Permission Management
- **Denied on first request:** Show explanation screen with retry button
- **Denied permanently:** Show "Open Settings" button
- **Partial authorization:** Some workout types authorized, others not

### Data Scenarios
- **No Apple Watch:** Clearly communicate which features require Watch
- **Watch syncing delayed:** Don't show duplicate entry UI until sync completes
- **Third-party apps:** Test with Strava, Peloton, Nike Run Club, etc.
- **Multiple workouts per day:** Allow, don't deduplicate if >2 hours apart

### Performance
- **Battery drain:** Use efficient background delivery, don't poll
- **Large workout history:** Only fetch last 24-48 hours on each trigger
- **Memory usage:** Don't load all tasks in memory, use predicates

### User Experience
- **Transparency:** Always show data source clearly
- **Control:** Allow disabling auto-complete per task
- **Manual override:** Never prevent manual entry
- **Undo:** Allow removing auto-completed logs

### CloudKit Sync
- **Array fields:** Ensure `healthKitMetrics` array syncs correctly
- **Optional relationships:** Already handled in current schema
- **Data migration:** V1→V2 already done, new fields have defaults

---

## Privacy & Compliance

### HealthKit Privacy Policy Requirements

**Info.plist Entries:**
```xml
<key>NSHealthShareUsageDescription</key>
<string>Numu uses your workout data to automatically track habit completions, helping you build your ideal identity without manual logging.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>Numu does not write data to Apple Health.</string>
```

### Data Handling
- ✅ All HealthKit data stays on device
- ✅ Only workout metadata synced via CloudKit (not raw HealthKit data)
- ✅ User can revoke permissions anytime in Settings → Health
- ✅ Clear explanation before each permission request

---

## Testing Checklist

### Manual Testing
- [ ] Create task with single workout type
- [ ] Create task with multiple workout types (cardio)
- [ ] Complete workout on Apple Watch
- [ ] Verify auto-completion in app
- [ ] Manually complete task (no watch)
- [ ] Complete workout + manual entry same day (test deduplication)
- [ ] Remove auto-completed log
- [ ] Disable HealthKit link
- [ ] Re-enable HealthKit link
- [ ] Test minimum duration threshold
- [ ] Test with different workout apps

### Edge Case Testing
- [ ] Deny permission → retry flow
- [ ] Workout shorter than minimum duration
- [ ] Multiple workouts same day
- [ ] Workout at midnight (date boundary)
- [ ] Change task HealthKit config mid-week
- [ ] Delete task with HealthKit logs
- [ ] CloudKit sync with HealthKit tasks

### Performance Testing
- [ ] Background delivery battery usage
- [ ] Load time with 100+ tasks
- [ ] Workout processing latency
- [ ] Memory usage during sync

---

## Future Enhancements

### Smart Suggestions
- Analyze existing HealthKit data on first launch
- "We noticed you run 3x/week. Want to create a Runner system?"

### Reverse Sync
- Write meditation task completions back to HealthKit as Mindful Sessions
- Log habit streaks as custom HealthKit categories

### Advanced Metrics
- Heart rate zones during workouts
- Calories burned from workouts
- Distance/pace tracking
- Active energy burned

### Correlations
- "Your sleep improves 15% on cardio days"
- "Resting HR dropped 5 BPM since starting Hybrid Athlete"

### Apple Watch App
- Quick task completion from watch
- Complication showing today's progress
- Workout detection with Numu task selection

---

## Questions & Answers

**Q: What if user doesn't have Apple Watch?**
A: Manual entry always works. HealthKit integration is purely optional enhancement.

**Q: Can one workout count toward multiple tasks?**
A: Yes! If you have "Cardio" and "Run 3x/week" tasks, a running workout can complete both.

**Q: What happens if I log workout on watch but forget phone at home?**
A: Once phone syncs with watch (when you get home), HealthKit delivers data and Numu processes it retroactively.

**Q: Can I still manually log workouts even with HealthKit enabled?**
A: Absolutely! Manual entry is always available. HealthKit just saves you the tap.

**Q: Will this drain my battery?**
A: Minimal impact. We use HealthKit's efficient background delivery system, not continuous polling.

**Q: What about privacy?**
A: All HealthKit data stays on your device. Only your task completion status syncs via CloudKit.

---

## Resources

### Apple Documentation
- [HealthKit Framework](https://developer.apple.com/documentation/healthkit)
- [HKWorkoutActivityType](https://developer.apple.com/documentation/healthkit/hkworkoutactivitytype)
- [Background Delivery](https://developer.apple.com/documentation/healthkit/hkhealthstore/1614175-enablebackgrounddelivery)

### Related Files
- `Numu/Models/Task.swift` - HabitTask model
- `Numu/Models/TaskLog.swift` - HabitTaskLog model
- `Numu/Models/System.swift` - System model
- `Numu/Services/NotificationManager.swift` - Push notifications

---

## Implementation Notes

**Remember:**
- All relationships must be optional for CloudKit compatibility
- Use defensive coding for data access (V1 migration issues)
- Test on physical device (Simulator has limited HealthKit support)
- Request permissions lazily (only when user enables feature)
- Always provide manual fallback

---

**Last Updated:** November 21, 2025
**Status:** Ready for Implementation
**Next Step:** Begin Phase 1 - Foundation
