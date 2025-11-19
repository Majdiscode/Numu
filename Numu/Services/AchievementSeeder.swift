//
//  AchievementSeeder.swift
//  Numu
//
//  Created by Claude Code
//

import Foundation
import SwiftData

/// Seeds default achievements into the database on first launch
class AchievementSeeder {

    /// Create all default achievements and add them to UserProgress
    static func seedAchievements(userProgress: UserProgress, context: ModelContext) {
        print("🌱 [AchievementSeeder] Seeding default achievements...")

        var achievements: [Achievement] = []

        // MARK: - Streak Achievements 🔥

        achievements.append(Achievement(
            identifier: "first_steps",
            name: "First Steps",
            description: "Complete a 1-day streak",
            category: .streak,
            criteria: 1,
            xpReward: 10,
            badge: "🌱",
            tier: .bronze
        ))

        achievements.append(Achievement(
            identifier: "week_warrior",
            name: "Week Warrior",
            description: "Complete a 7-day streak",
            category: .streak,
            criteria: 7,
            xpReward: 50,
            badge: "💪",
            tier: .bronze
        ))

        achievements.append(Achievement(
            identifier: "month_master",
            name: "Month Master",
            description: "Complete a 30-day streak",
            category: .streak,
            criteria: 30,
            xpReward: 200,
            badge: "⭐",
            tier: .silver
        ))

        achievements.append(Achievement(
            identifier: "century_club",
            name: "Century Club",
            description: "Complete a 100-day streak",
            category: .streak,
            criteria: 100,
            xpReward: 1000,
            badge: "💎",
            tier: .gold
        ))

        achievements.append(Achievement(
            identifier: "year_legend",
            name: "Year Legend",
            description: "Complete a 365-day streak",
            category: .streak,
            criteria: 365,
            xpReward: 5000,
            badge: "👑",
            tier: .platinum
        ))

        achievements.append(Achievement(
            identifier: "unbreakable",
            name: "Unbreakable",
            description: "Complete a 500-day streak",
            category: .streak,
            criteria: 500,
            xpReward: 10000,
            badge: "🏆",
            tier: .diamond
        ))

        achievements.append(Achievement(
            identifier: "weekly_habit",
            name: "Weekly Habit",
            description: "Complete 4 weeks of weekly target",
            category: .streak,
            criteria: 4,
            xpReward: 100,
            badge: "📅",
            tier: .bronze
        ))

        achievements.append(Achievement(
            identifier: "consistent_climber",
            name: "Consistent Climber",
            description: "Complete 12 weeks of weekly target",
            category: .streak,
            criteria: 12,
            xpReward: 500,
            badge: "⛰️",
            tier: .gold
        ))

        // MARK: - System Achievements 🎯

        achievements.append(Achievement(
            identifier: "system_builder",
            name: "System Builder",
            description: "Create your first system",
            category: .system,
            criteria: 1,
            xpReward: 25,
            badge: "🏗️",
            tier: .bronze
        ))

        achievements.append(Achievement(
            identifier: "multi_tasker",
            name: "Multi-Tasker",
            description: "Create 3 systems",
            category: .system,
            criteria: 3,
            xpReward: 75,
            badge: "🎨",
            tier: .bronze
        ))

        achievements.append(Achievement(
            identifier: "life_designer",
            name: "Life Designer",
            description: "Create 5 systems",
            category: .system,
            criteria: 5,
            xpReward: 150,
            badge: "🌟",
            tier: .silver
        ))

        achievements.append(Achievement(
            identifier: "master_architect",
            name: "Master Architect",
            description: "Create 10 systems",
            category: .system,
            criteria: 10,
            xpReward: 500,
            badge: "🏛️",
            tier: .gold
        ))

        achievements.append(Achievement(
            identifier: "perfect_day",
            name: "Perfect Day",
            description: "Complete all tasks in a system for 1 day",
            category: .system,
            criteria: 1,
            xpReward: 50,
            badge: "✨",
            tier: .bronze
        ))

        achievements.append(Achievement(
            identifier: "perfect_week",
            name: "Perfect Week",
            description: "Complete all tasks in a system for 7 days",
            category: .system,
            criteria: 7,
            xpReward: 250,
            badge: "🌈",
            tier: .silver
        ))

        achievements.append(Achievement(
            identifier: "system_champion",
            name: "System Champion",
            description: "Reach 90% consistency in any system",
            category: .system,
            criteria: 90,
            xpReward: 300,
            badge: "🥇",
            tier: .gold
        ))

        // MARK: - Task Achievements ✅

        achievements.append(Achievement(
            identifier: "task_master",
            name: "Task Master",
            description: "Complete 10 tasks total",
            category: .task,
            criteria: 10,
            xpReward: 20,
            badge: "✔️",
            tier: .bronze
        ))

        achievements.append(Achievement(
            identifier: "century_of_tasks",
            name: "Century of Tasks",
            description: "Complete 100 tasks total",
            category: .task,
            criteria: 100,
            xpReward: 100,
            badge: "💯",
            tier: .silver
        ))

        achievements.append(Achievement(
            identifier: "thousand_strong",
            name: "Thousand Strong",
            description: "Complete 1000 tasks total",
            category: .task,
            criteria: 1000,
            xpReward: 1000,
            badge: "🎯",
            tier: .platinum
        ))

        achievements.append(Achievement(
            identifier: "early_bird",
            name: "Early Bird",
            description: "Complete tasks before 8am (10 times)",
            category: .task,
            criteria: 10,
            xpReward: 100,
            badge: "🐦",
            tier: .silver
        ))

        achievements.append(Achievement(
            identifier: "night_owl",
            name: "Night Owl",
            description: "Complete tasks after 10pm (10 times)",
            category: .task,
            criteria: 10,
            xpReward: 100,
            badge: "🦉",
            tier: .silver
        ))

        achievements.append(Achievement(
            identifier: "weekend_warrior",
            name: "Weekend Warrior",
            description: "Complete all weekend tasks for 4 weeks",
            category: .task,
            criteria: 4,
            xpReward: 200,
            badge: "🎉",
            tier: .gold
        ))

        achievements.append(Achievement(
            identifier: "weekday_champion",
            name: "Weekday Champion",
            description: "Perfect weekdays for 4 weeks",
            category: .task,
            criteria: 4,
            xpReward: 200,
            badge: "💼",
            tier: .gold
        ))

        // MARK: - Performance Test Achievements 📈

        achievements.append(Achievement(
            identifier: "first_test",
            name: "First Test",
            description: "Complete your first performance test",
            category: .test,
            criteria: 1,
            xpReward: 20,
            badge: "🧪",
            tier: .bronze
        ))

        achievements.append(Achievement(
            identifier: "baseline_builder",
            name: "Baseline Builder",
            description: "Complete 5 performance tests",
            category: .test,
            criteria: 5,
            xpReward: 75,
            badge: "📊",
            tier: .bronze
        ))

        achievements.append(Achievement(
            identifier: "progress_tracker",
            name: "Progress Tracker",
            description: "Complete the same test 3 times",
            category: .test,
            criteria: 3,
            xpReward: 50,
            badge: "📈",
            tier: .silver
        ))

        achievements.append(Achievement(
            identifier: "personal_record",
            name: "Personal Record",
            description: "Beat your previous best on any test",
            category: .test,
            criteria: 1,
            xpReward: 100,
            badge: "🥇",
            tier: .silver
        ))

        achievements.append(Achievement(
            identifier: "improvement_streak",
            name: "Improvement Streak",
            description: "Improve 3 tests in a row",
            category: .test,
            criteria: 3,
            xpReward: 200,
            badge: "⬆️",
            tier: .gold
        ))

        achievements.append(Achievement(
            identifier: "all_time_best",
            name: "All-Time Best",
            description: "Hold 5 personal records",
            category: .test,
            criteria: 5,
            xpReward: 500,
            badge: "👑",
            tier: .platinum
        ))

        // MARK: - Consistency Achievements 📊

        achievements.append(Achievement(
            identifier: "habit_starter",
            name: "Habit Starter",
            description: "Reach 50% consistency for 1 week",
            category: .consistency,
            criteria: 50,
            xpReward: 25,
            badge: "🌱",
            tier: .bronze
        ))

        achievements.append(Achievement(
            identifier: "getting_there",
            name: "Getting There",
            description: "Reach 70% consistency for 2 weeks",
            category: .consistency,
            criteria: 70,
            xpReward: 75,
            badge: "🌿",
            tier: .bronze
        ))

        achievements.append(Achievement(
            identifier: "solid_foundation",
            name: "Solid Foundation",
            description: "Reach 80% consistency for 1 month",
            category: .consistency,
            criteria: 80,
            xpReward: 200,
            badge: "🌳",
            tier: .silver
        ))

        achievements.append(Achievement(
            identifier: "elite_performer",
            name: "Elite Performer",
            description: "Reach 90% consistency for 1 month",
            category: .consistency,
            criteria: 90,
            xpReward: 500,
            badge: "🌲",
            tier: .gold
        ))

        achievements.append(Achievement(
            identifier: "perfection",
            name: "Perfection",
            description: "Reach 100% consistency for 1 week",
            category: .consistency,
            criteria: 100,
            xpReward: 300,
            badge: "💎",
            tier: .platinum
        ))

        // MARK: - Special Achievements 🎁

        achievements.append(Achievement(
            identifier: "comeback_kid",
            name: "Comeback Kid",
            description: "Return after a 7+ day break",
            category: .special,
            criteria: 1,
            xpReward: 50,
            badge: "🔄",
            tier: .bronze
        ))

        achievements.append(Achievement(
            identifier: "habit_breaker",
            name: "Habit Breaker",
            description: "Complete 30 days of a negative habit reduction",
            category: .special,
            criteria: 30,
            xpReward: 300,
            badge: "🚫",
            tier: .silver
        ))

        achievements.append(Achievement(
            identifier: "time_reducer",
            name: "Time Reducer",
            description: "Reduce a negative habit to target limit",
            category: .special,
            criteria: 1,
            xpReward: 500,
            badge: "⏰",
            tier: .gold
        ))

        achievements.append(Achievement(
            identifier: "atomic_habits",
            name: "Atomic Habits",
            description: "Fill all 4 Laws for a task",
            category: .special,
            criteria: 1,
            xpReward: 100,
            badge: "📚",
            tier: .silver
        ))

        achievements.append(Achievement(
            identifier: "organized",
            name: "Organized",
            description: "Set cue time for 5 tasks",
            category: .special,
            criteria: 5,
            xpReward: 75,
            badge: "⏰",
            tier: .bronze
        ))

        // Insert all achievements into context
        for achievement in achievements {
            context.insert(achievement)
        }

        // Link achievements to user progress
        userProgress.achievements = achievements

        print("✅ [AchievementSeeder] Seeded \(achievements.count) achievements")
    }
}
