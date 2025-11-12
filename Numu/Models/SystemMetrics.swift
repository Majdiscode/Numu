//
//  SystemMetrics.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//

import Foundation
import SwiftData

@Model
final class SystemMetrics {
    var id: UUID
    var date: Date

    // Daily system metrics (focus on process, not outcomes)
    var totalHabitsCompleted: Int
    var totalHabitsAvailable: Int
    var systemStrength: Double  // Completion rate for the day

    // XP and Gamification
    var xpEarned: Int
    var currentLevel: Int
    var totalXP: Int

    // Identity reinforcement
    var identityScore: Double  // How aligned are you with your identity?

    // Streaks
    var activeStreaks: Int  // Number of habits with active streaks

    init(date: Date = Date()) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.totalHabitsCompleted = 0
        self.totalHabitsAvailable = 0
        self.systemStrength = 0.0
        self.xpEarned = 0
        self.currentLevel = 1
        self.totalXP = 0
        self.identityScore = 0.0
        self.activeStreaks = 0
    }

    // Calculate XP based on consistency, not volume
    static func calculateXP(for habit: Habit, streak: Int) -> Int {
        let baseXP = 10
        let streakBonus = min(streak * 2, 100)  // Cap at 100 bonus XP
        return baseXP + streakBonus
    }

    // Calculate level from total XP
    static func calculateLevel(from totalXP: Int) -> Int {
        // Each level requires 100 * level XP
        // Level 1: 0-100, Level 2: 100-300, Level 3: 300-600, etc.
        var level = 1
        var xpRequired = 0

        while totalXP >= xpRequired {
            level += 1
            xpRequired += level * 100
        }

        return max(1, level - 1)
    }
}
