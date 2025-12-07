//
//  HapticManager.swift
//  Numu
//
//  Created by Claude Code
//

import SwiftUI
import UIKit

@Observable
class HapticManager {
    // MARK: - Haptic Generators

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let successNotification = UINotificationFeedbackGenerator()

    init() {
        // Prepare generators for better performance
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        rigidImpact.prepare()
        successNotification.prepare()
    }

    // MARK: - Public Methods

    /// Light haptic for single task completion
    func taskCompleted() {
        lightImpact.impactOccurred()
        lightImpact.prepare()
    }

    /// Medium haptic for completing all tasks in a system
    func systemCompleted() {
        mediumImpact.impactOccurred()
        mediumImpact.prepare()
    }

    /// Heavy haptic for completing all daily tasks
    func dailyGoalCompleted() {
        heavyImpact.impactOccurred()
        heavyImpact.prepare()
    }

    /// Rigid haptic for completing weekly goals
    func weeklyGoalCompleted() {
        rigidImpact.impactOccurred()
        rigidImpact.prepare()
    }

    /// Success notification haptic for completing BOTH daily and weekly goals
    func perfectDayCompleted() {
        // Double tap for extra celebration
        successNotification.notificationOccurred(.success)

        // Add a second tap after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.successNotification.notificationOccurred(.success)
            self?.successNotification.prepare()
        }
    }

    /// Selection haptic for UI interactions (optional - for buttons, toggles, etc.)
    func selection() {
        let selection = UISelectionFeedbackGenerator()
        selection.selectionChanged()
    }
}
