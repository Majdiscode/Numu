//
//  HealthKitMetricType.swift
//  Numu
//
//  Created by Claude Code
//

import Foundation
import HealthKit

/// Category grouping for HealthKit metrics
enum HealthKitCategory: String, Codable, CaseIterable {
    case activity = "Activity & Workouts"
    case mindfulness = "Mindfulness & Sleep"
    case nutrition = "Nutrition & Hydration"
    case bodyMeasurements = "Body Measurements"

    var icon: String {
        switch self {
        case .activity: return "figure.run"
        case .mindfulness: return "brain.head.profile"
        case .nutrition: return "fork.knife"
        case .bodyMeasurements: return "heart.text.square"
        }
    }
}

/// HealthKit metric types supported for task mapping
enum HealthKitMetricType: String, Codable, CaseIterable {
    // Activity & Workouts - General
    case stepCount = "HKQuantityTypeIdentifierStepCount"
    case distance = "HKQuantityTypeIdentifierDistanceWalkingRunning"  // Combined (for backwards compatibility)
    case activeEnergy = "HKQuantityTypeIdentifierActiveEnergyBurned"
    case exerciseMinutes = "HKQuantityTypeIdentifierAppleExerciseTime"

    // Activity & Workouts - Specific Activities (using HKWorkout activity types)
    case walkingDistance = "HKWorkoutActivityTypeWalking"
    case runningDistance = "HKWorkoutActivityTypeRunning"
    case cyclingDistance = "HKWorkoutActivityTypeCycling"
    case swimmingDistance = "HKWorkoutActivityTypeSwimming"
    case hikingDistance = "HKWorkoutActivityTypeHiking"
    case ellipticalDistance = "HKWorkoutActivityTypeElliptical"
    case rowingDistance = "HKWorkoutActivityTypeRowing"
    case stairClimbingDistance = "HKWorkoutActivityTypeStairClimbing"

    // Strength Training Workouts
    case traditionalStrengthTraining = "HKWorkoutActivityTypeTraditionalStrengthTraining"
    case functionalStrengthTraining = "HKWorkoutActivityTypeFunctionalStrengthTraining"
    case coreTraining = "HKWorkoutActivityTypeCoreTraining"

    // Mindfulness & Sleep
    case mindfulMinutes = "HKCategoryTypeIdentifierMindfulSession"
    case sleepAnalysis = "HKCategoryTypeIdentifierSleepAnalysis"

    // Nutrition & Hydration
    case waterIntake = "HKQuantityTypeIdentifierDietaryWater"
    case proteinIntake = "HKQuantityTypeIdentifierDietaryProtein"
    case calorieIntake = "HKQuantityTypeIdentifierDietaryEnergyConsumed"

    // Body Measurements
    case heartRate = "HKQuantityTypeIdentifierHeartRate"
    case bodyWeight = "HKQuantityTypeIdentifierBodyMass"
    case bodyFat = "HKQuantityTypeIdentifierBodyFatPercentage"
    case bloodPressureSystolic = "HKQuantityTypeIdentifierBloodPressureSystolic"
    case bloodPressureDiastolic = "HKQuantityTypeIdentifierBloodPressureDiastolic"
    case bloodGlucose = "HKQuantityTypeIdentifierBloodGlucose"
    case restingHeartRate = "HKQuantityTypeIdentifierRestingHeartRate"

    var displayName: String {
        switch self {
        // Activity & Workouts - General
        case .stepCount: return "Step Count"
        case .distance: return "Walking + Running Distance"
        case .activeEnergy: return "Active Energy Burned"
        case .exerciseMinutes: return "Exercise Minutes"

        // Activity & Workouts - Specific Activities
        case .walkingDistance: return "Walking Distance"
        case .runningDistance: return "Running Distance"
        case .cyclingDistance: return "Cycling Distance"
        case .swimmingDistance: return "Swimming Distance"
        case .hikingDistance: return "Hiking Distance"
        case .ellipticalDistance: return "Elliptical Distance"
        case .rowingDistance: return "Rowing Distance"
        case .stairClimbingDistance: return "Stair Climbing Distance"

        // Strength Training Workouts
        case .traditionalStrengthTraining: return "Strength Training"
        case .functionalStrengthTraining: return "Functional Strength"
        case .coreTraining: return "Core Training"

        // Mindfulness & Sleep
        case .mindfulMinutes: return "Mindful Minutes"
        case .sleepAnalysis: return "Sleep Duration"

        // Nutrition & Hydration
        case .waterIntake: return "Water Intake"
        case .proteinIntake: return "Protein Intake"
        case .calorieIntake: return "Calorie Intake"

        // Body Measurements
        case .heartRate: return "Heart Rate"
        case .bodyWeight: return "Body Weight"
        case .bodyFat: return "Body Fat Percentage"
        case .bloodPressureSystolic: return "Blood Pressure (Systolic)"
        case .bloodPressureDiastolic: return "Blood Pressure (Diastolic)"
        case .bloodGlucose: return "Blood Glucose"
        case .restingHeartRate: return "Resting Heart Rate"
        }
    }

    var unit: String {
        switch self {
        // Activity & Workouts - General
        case .stepCount: return "steps"
        case .distance: return "km"
        case .activeEnergy: return "kcal"
        case .exerciseMinutes: return "min"

        // Activity & Workouts - Specific Activities
        case .walkingDistance, .runningDistance, .cyclingDistance,
             .swimmingDistance, .hikingDistance, .ellipticalDistance,
             .rowingDistance, .stairClimbingDistance:
            return "km"

        // Strength Training Workouts (just checking if workout exists, no unit)
        case .traditionalStrengthTraining, .functionalStrengthTraining, .coreTraining:
            return "workout"

        // Mindfulness & Sleep
        case .mindfulMinutes: return "min"
        case .sleepAnalysis: return "hr"

        // Nutrition & Hydration
        case .waterIntake: return "mL"
        case .proteinIntake: return "g"
        case .calorieIntake: return "kcal"

        // Body Measurements
        case .heartRate: return "bpm"
        case .bodyWeight: return "kg"
        case .bodyFat: return "%"
        case .bloodPressureSystolic: return "mmHg"
        case .bloodPressureDiastolic: return "mmHg"
        case .bloodGlucose: return "mg/dL"
        case .restingHeartRate: return "bpm"
        }
    }

    var category: HealthKitCategory {
        switch self {
        case .stepCount, .distance, .activeEnergy, .exerciseMinutes,
             .walkingDistance, .runningDistance, .cyclingDistance,
             .swimmingDistance, .hikingDistance, .ellipticalDistance,
             .rowingDistance, .stairClimbingDistance,
             .traditionalStrengthTraining, .functionalStrengthTraining, .coreTraining:
            return .activity
        case .mindfulMinutes, .sleepAnalysis:
            return .mindfulness
        case .waterIntake, .proteinIntake, .calorieIntake:
            return .nutrition
        case .heartRate, .bodyWeight, .bodyFat, .bloodPressureSystolic,
             .bloodPressureDiastolic, .bloodGlucose, .restingHeartRate:
            return .bodyMeasurements
        }
    }

    var icon: String {
        switch self {
        // Activity & Workouts - General
        case .stepCount: return "figure.walk"
        case .distance: return "figure.run"
        case .activeEnergy: return "flame.fill"
        case .exerciseMinutes: return "figure.strengthtraining.traditional"

        // Activity & Workouts - Specific Activities
        case .walkingDistance: return "figure.walk"
        case .runningDistance: return "figure.run"
        case .cyclingDistance: return "bicycle"
        case .swimmingDistance: return "figure.pool.swim"
        case .hikingDistance: return "figure.hiking"
        case .ellipticalDistance: return "figure.elliptical"
        case .rowingDistance: return "figure.rower"
        case .stairClimbingDistance: return "figure.stairs"

        // Strength Training Workouts
        case .traditionalStrengthTraining: return "dumbbell.fill"
        case .functionalStrengthTraining: return "figure.strengthtraining.functional"
        case .coreTraining: return "figure.core.training"

        // Mindfulness & Sleep
        case .mindfulMinutes: return "brain.head.profile"
        case .sleepAnalysis: return "bed.double.fill"

        // Nutrition & Hydration
        case .waterIntake: return "drop.fill"
        case .proteinIntake: return "fish.fill"
        case .calorieIntake: return "fork.knife"

        // Body Measurements
        case .heartRate: return "heart.fill"
        case .bodyWeight: return "scalemass.fill"
        case .bodyFat: return "percent"
        case .bloodPressureSystolic: return "waveform.path.ecg"
        case .bloodPressureDiastolic: return "waveform.path.ecg"
        case .bloodGlucose: return "cross.vial"
        case .restingHeartRate: return "heart.circle"
        }
    }

    /// Get the HKQuantityType or HKCategoryType for this metric
    /// Note: Activity-specific metrics (walking, running, etc.) use HKWorkout queries
    func getHealthKitType() -> HKSampleType? {
        switch self {
        // Workout-based activity types (use HKWorkoutType for authorization)
        case .walkingDistance, .runningDistance, .cyclingDistance,
             .swimmingDistance, .hikingDistance, .ellipticalDistance,
             .rowingDistance, .stairClimbingDistance,
             .traditionalStrengthTraining, .functionalStrengthTraining, .coreTraining:
            return HKWorkoutType.workoutType()

        // Quantity types
        case .stepCount, .distance, .activeEnergy, .exerciseMinutes,
             .waterIntake, .proteinIntake, .calorieIntake,
             .heartRate, .bodyWeight, .bodyFat,
             .bloodPressureSystolic, .bloodPressureDiastolic,
             .bloodGlucose, .restingHeartRate:
            return HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: self.rawValue))

        // Category types
        case .mindfulMinutes, .sleepAnalysis:
            return HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: self.rawValue))
        }
    }

    /// Get the appropriate HKUnit for this metric
    func getHealthKitUnit() -> HKUnit? {
        switch self {
        case .stepCount: return HKUnit.count()
        case .distance: return HKUnit.meter()
        case .walkingDistance, .runningDistance, .cyclingDistance,
             .swimmingDistance, .hikingDistance, .ellipticalDistance,
             .rowingDistance, .stairClimbingDistance:
            return HKUnit.meter()  // All activity distances use meters
        case .traditionalStrengthTraining, .functionalStrengthTraining, .coreTraining:
            return HKUnit.count()  // Just counting if workout exists (will return 1 or 0)
        case .activeEnergy, .calorieIntake: return HKUnit.kilocalorie()
        case .exerciseMinutes, .mindfulMinutes: return HKUnit.minute()
        case .sleepAnalysis: return HKUnit.hour()
        case .waterIntake: return HKUnit.literUnit(with: .milli)
        case .proteinIntake: return HKUnit.gram()
        case .heartRate, .restingHeartRate: return HKUnit.count().unitDivided(by: .minute())
        case .bodyWeight: return HKUnit.gramUnit(with: .kilo)
        case .bodyFat: return HKUnit.percent()
        case .bloodPressureSystolic, .bloodPressureDiastolic: return HKUnit.millimeterOfMercury()
        case .bloodGlucose: return HKUnit.gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci))
        }
    }

    /// Get the HKWorkoutActivityType for activity-specific metrics
    func getWorkoutActivityType() -> HKWorkoutActivityType? {
        switch self {
        case .walkingDistance: return .walking
        case .runningDistance: return .running
        case .cyclingDistance: return .cycling
        case .swimmingDistance: return .swimming
        case .hikingDistance: return .hiking
        case .ellipticalDistance: return .elliptical
        case .rowingDistance: return .rowing
        case .stairClimbingDistance: return .stairs
        case .traditionalStrengthTraining: return .traditionalStrengthTraining
        case .functionalStrengthTraining: return .functionalStrengthTraining
        case .coreTraining: return .coreTraining
        default: return nil
        }
    }

    /// Check if this metric is workout-based (requires HKWorkout queries)
    var isWorkoutBased: Bool {
        getWorkoutActivityType() != nil
    }

    /// Whether this metric is a priority (Steps, Distance, Exercise)
    var isPriority: Bool {
        switch self {
        case .stepCount, .distance, .activeEnergy, .exerciseMinutes:
            return true
        default:
            return false
        }
    }
}

/// Comparison type for evaluating HealthKit thresholds
enum ComparisonType: String, Codable, CaseIterable {
    case greaterThanOrEqual = "≥"
    case lessThanOrEqual = "≤"
    case equal = "="

    var displayName: String {
        switch self {
        case .greaterThanOrEqual: return "At least (≥)"
        case .lessThanOrEqual: return "At most (≤)"
        case .equal: return "Exactly (=)"
        }
    }

    /// Evaluate if a value meets the threshold with this comparison
    func evaluate(value: Double, threshold: Double) -> Bool {
        switch self {
        case .greaterThanOrEqual:
            return value >= threshold
        case .lessThanOrEqual:
            return value <= threshold
        case .equal:
            return abs(value - threshold) < 0.01  // Floating point tolerance
        }
    }
}

/// Activity groups for flexible habit tracking (e.g., "Any Cardio" includes running, cycling, etc.)
enum ActivityGroup: String, Codable, CaseIterable {
    case anyCardio = "Any Cardio Workout"
    case anyStrength = "Any Strength Workout"
    case anyMindfulness = "Any Mindfulness Activity"
    case specificActivity = "Specific Activity"

    var icon: String {
        switch self {
        case .anyCardio: return "figure.run"
        case .anyStrength: return "dumbbell.fill"
        case .anyMindfulness: return "brain.head.profile"
        case .specificActivity: return "figure.mixed.cardio"
        }
    }

    var description: String {
        switch self {
        case .anyCardio:
            return "Running, Cycling, Swimming, Walking, Hiking, Elliptical, Rowing, Stairs"
        case .anyStrength:
            return "Traditional Strength Training, Functional Strength, Core Training (e.g., workouts from Hevy, Strong, etc.)"
        case .anyMindfulness:
            return "Meditation, Yoga, Mindful Sessions"
        case .specificActivity:
            return "Choose one specific activity"
        }
    }

    /// Get all HealthKit metrics included in this group
    var includedActivities: [HealthKitMetricType] {
        switch self {
        case .anyCardio:
            return [.runningDistance, .cyclingDistance, .swimmingDistance,
                    .walkingDistance, .hikingDistance, .ellipticalDistance,
                    .rowingDistance, .stairClimbingDistance]
        case .anyStrength:
            return [.traditionalStrengthTraining, .functionalStrengthTraining, .coreTraining]
        case .anyMindfulness:
            return [.mindfulMinutes]
        case .specificActivity:
            return []  // User picks a specific one
        }
    }
}

/// Extension to group metrics by category
extension HealthKitMetricType {
    static var metricsByCategory: [HealthKitCategory: [HealthKitMetricType]] {
        var result: [HealthKitCategory: [HealthKitMetricType]] = [:]

        for category in HealthKitCategory.allCases {
            result[category] = HealthKitMetricType.allCases.filter { $0.category == category }
        }

        return result
    }

    static var priorityMetrics: [HealthKitMetricType] {
        return allCases.filter { $0.isPriority }
    }
}
