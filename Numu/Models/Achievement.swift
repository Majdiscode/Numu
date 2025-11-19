//
//  Achievement.swift
//  Numu
//
//  Created by Claude Code
//

import Foundation
import SwiftData

/// Represents an unlockable achievement that rewards user progress and behavior
@Model
final class Achievement {
    var id: UUID = UUID()
    var identifier: String = ""  // Unique ID like "week_warrior_7"
    var name: String = ""         // Display name like "Week Warrior"
    var achievementDescription: String = ""  // "Complete a 7-day streak"
    var category: String = "streak"  // Stored as string for SwiftData compatibility
    var criteria: Int = 0         // Target value (e.g., 7 for week warrior)
    var xpReward: Int = 0         // XP earned when unlocked
    var badge: String = ""        // Emoji badge like "💪"
    var tier: String = "bronze"   // bronze/silver/gold/platinum/diamond

    // Progress tracking
    var isUnlocked: Bool = false
    var unlockedAt: Date?
    var progress: Int = 0         // Current progress toward achievement

    // Inverse relationship to UserProgress (required for CloudKit)
    var userProgress: UserProgress?

    init(
        identifier: String,
        name: String,
        description: String,
        category: AchievementCategory,
        criteria: Int,
        xpReward: Int,
        badge: String,
        tier: AchievementTier
    ) {
        self.id = UUID()
        self.identifier = identifier
        self.name = name
        self.achievementDescription = description
        self.category = category.rawValue
        self.criteria = criteria
        self.xpReward = xpReward
        self.badge = badge
        self.tier = tier.rawValue
    }

    // MARK: - Computed Properties

    var categoryEnum: AchievementCategory {
        AchievementCategory(rawValue: category) ?? .streak
    }

    var tierEnum: AchievementTier {
        AchievementTier(rawValue: tier) ?? .bronze
    }

    var progressPercentage: Double {
        guard criteria > 0 else { return 0.0 }
        return min(1.0, Double(progress) / Double(criteria))
    }

    var progressText: String {
        "\(progress) / \(criteria)"
    }

    var tierColor: String {
        switch tierEnum {
        case .bronze: return "brown"
        case .silver: return "gray"
        case .gold: return "yellow"
        case .platinum: return "cyan"
        case .diamond: return "purple"
        }
    }
}

// MARK: - Achievement Category

enum AchievementCategory: String, Codable, CaseIterable {
    case streak = "streak"
    case system = "system"
    case task = "task"
    case test = "test"
    case consistency = "consistency"
    case special = "special"

    var displayName: String {
        switch self {
        case .streak: return "Streaks"
        case .system: return "Systems"
        case .task: return "Tasks"
        case .test: return "Tests"
        case .consistency: return "Consistency"
        case .special: return "Special"
        }
    }

    var icon: String {
        switch self {
        case .streak: return "flame.fill"
        case .system: return "square.grid.2x2.fill"
        case .task: return "checkmark.circle.fill"
        case .test: return "chart.bar.fill"
        case .consistency: return "chart.line.uptrend.xyaxis"
        case .special: return "star.fill"
        }
    }
}

// MARK: - Achievement Tier

enum AchievementTier: String, Codable, CaseIterable {
    case bronze = "bronze"
    case silver = "silver"
    case gold = "gold"
    case platinum = "platinum"
    case diamond = "diamond"

    var displayName: String {
        rawValue.capitalized
    }

    var color: String {
        switch self {
        case .bronze: return "brown"
        case .silver: return "gray"
        case .gold: return "yellow"
        case .platinum: return "cyan"
        case .diamond: return "purple"
        }
    }

    var emoji: String {
        switch self {
        case .bronze: return "🟤"
        case .silver: return "⚪"
        case .gold: return "🟡"
        case .platinum: return "💠"
        case .diamond: return "💎"
        }
    }
}
