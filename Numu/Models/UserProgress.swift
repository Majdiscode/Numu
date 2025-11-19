//
//  UserProgress.swift
//  Numu
//
//  Created by Claude Code
//

import Foundation
import SwiftData

/// Tracks user's overall gamification progress, XP, levels, and statistics
@Model
final class UserProgress {
    var id: UUID = UUID()
    var createdAt: Date = Date()

    // MARK: - XP & Leveling

    var totalXP: Int = 0
    var currentLevel: Int = 1

    // MARK: - Statistics (for achievement tracking)

    var totalTasksCompleted: Int = 0
    var totalTestsCompleted: Int = 0
    var longestStreak: Int = 0
    var totalSystemsCreated: Int = 0
    var perfectDaysCount: Int = 0
    var perfectWeeksCount: Int = 0
    var personalRecordsCount: Int = 0

    // Time-based statistics
    var earlyBirdCount: Int = 0   // Tasks completed before 8am
    var nightOwlCount: Int = 0    // Tasks completed after 10pm

    // Negative habit success
    var negativeHabitSuccessDays: Int = 0

    // MARK: - Recently Unlocked

    var recentlyUnlockedIDs: [String] = []  // Achievement identifiers

    // MARK: - Relationships

    @Relationship(deleteRule: .cascade, inverse: \Achievement.userProgress)
    var achievements: [Achievement]?

    init() {
        self.id = UUID()
        self.createdAt = Date()
    }

    // MARK: - Computed Properties

    /// XP required to reach next level
    var xpToNextLevel: Int {
        xpRequiredForLevel(currentLevel + 1) - totalXP
    }

    /// Current level progress (0.0 to 1.0)
    var levelProgress: Double {
        let currentLevelXP = xpRequiredForLevel(currentLevel)
        let nextLevelXP = xpRequiredForLevel(currentLevel + 1)
        let progressXP = totalXP - currentLevelXP

        guard nextLevelXP > currentLevelXP else { return 1.0 }
        return Double(progressXP) / Double(nextLevelXP - currentLevelXP)
    }

    /// XP earned in current level
    var xpInCurrentLevel: Int {
        totalXP - xpRequiredForLevel(currentLevel)
    }

    /// Total XP needed for current level
    var xpNeededForCurrentLevel: Int {
        xpRequiredForLevel(currentLevel + 1) - xpRequiredForLevel(currentLevel)
    }

    /// User's tier based on level
    var levelTier: String {
        switch currentLevel {
        case 1..<10:
            return "Bronze Beginner"
        case 10..<25:
            return "Silver Intermediate"
        case 25..<50:
            return "Gold Advanced"
        case 50..<100:
            return "Platinum Expert"
        default:
            return "Diamond Master"
        }
    }

    /// Tier color for UI
    var tierColor: String {
        switch currentLevel {
        case 1..<10: return "brown"
        case 10..<25: return "gray"
        case 25..<50: return "yellow"
        case 50..<100: return "cyan"
        default: return "purple"
        }
    }

    /// Tier emoji
    var tierEmoji: String {
        switch currentLevel {
        case 1..<10: return "🟤"
        case 10..<25: return "⚪"
        case 25..<50: return "🟡"
        case 50..<100: return "💠"
        default: return "💎"
        }
    }

    /// Count of unlocked achievements
    var unlockedAchievementsCount: Int {
        achievements?.filter { $0.isUnlocked }.count ?? 0
    }

    /// Total achievements available
    var totalAchievementsCount: Int {
        achievements?.count ?? 0
    }

    // MARK: - Level Calculation

    /// Calculate what level corresponds to given XP
    /// Formula: XP_for_level_N = 50 * N^1.5
    func calculateLevel(from xp: Int) -> Int {
        var level = 1
        while xpRequiredForLevel(level + 1) <= xp {
            level += 1
        }
        return level
    }

    /// Calculate XP required to reach a specific level
    /// Formula: XP_for_level_N = 50 * N^1.5
    func xpRequiredForLevel(_ level: Int) -> Int {
        guard level > 1 else { return 0 }
        return Int(50.0 * pow(Double(level), 1.5))
    }

    // MARK: - XP Management

    /// Award XP and check for level up
    /// Returns the new level if leveled up, nil otherwise
    func awardXP(_ amount: Int) -> Int? {
        let oldLevel = currentLevel
        totalXP += amount

        // Recalculate level
        currentLevel = calculateLevel(from: totalXP)

        // Return new level if leveled up
        return currentLevel > oldLevel ? currentLevel : nil
    }

    // MARK: - Achievement Management

    /// Mark achievement as recently unlocked
    func markRecentlyUnlocked(_ achievementID: String) {
        if !recentlyUnlockedIDs.contains(achievementID) {
            recentlyUnlockedIDs.append(achievementID)
        }
    }

    /// Clear recently unlocked achievements (after showing notifications)
    func clearRecentlyUnlocked() {
        recentlyUnlockedIDs.removeAll()
    }
}
