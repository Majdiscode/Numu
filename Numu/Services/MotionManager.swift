//
//  MotionManager.swift
//  Numu
//
//  Created by Claude Code
//

import SwiftUI
import CoreMotion

@Observable
class MotionManager {
    // MARK: - Properties

    private let motionManager = CMMotionManager()
    private(set) var lightAngle: Angle = .degrees(135) // Default light from top-left
    private(set) var lightOffset: CGPoint = .zero // Offset for gradient position

    // MARK: - Initialization

    init() {
        startMotionUpdates()
    }

    deinit {
        stopMotionUpdates()
    }

    // MARK: - Motion Updates

    func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("⚠️ [Motion] Device motion not available")
            return
        }

        // Update at 60fps for smooth shimmer
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0

        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let motion = motion, error == nil else {
                if let error = error {
                    print("❌ [Motion] Error: \(error.localizedDescription)")
                }
                return
            }

            self?.updateLightPosition(from: motion)
        }

        print("✅ [Motion] Motion updates started")
    }

    func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
        print("🛑 [Motion] Motion updates stopped")
    }

    // MARK: - Private Methods

    private func updateLightPosition(from motion: CMDeviceMotion) {
        let attitude = motion.attitude

        // Get pitch (forward/backward tilt) and roll (left/right tilt)
        let pitch = attitude.pitch // Range: -π to π
        let roll = attitude.roll   // Range: -π to π

        // Convert to degrees and normalize
        // When phone tilts down (toward you), pitch is positive
        // When phone tilts right, roll is positive

        // Map pitch and roll to light angle (0° = right, 90° = bottom, 180° = left, 270° = top)
        // Invert pitch so tilting phone down moves light down
        let angleFromMotion = atan2(-pitch, roll) * 180.0 / .pi

        // Convert to 0-360 range
        let normalizedAngle = angleFromMotion < 0 ? angleFromMotion + 360 : angleFromMotion

        // Update light angle
        lightAngle = .degrees(normalizedAngle)

        // Calculate light offset for gradient positioning
        // Map pitch/roll to offset values (-1 to 1 range)
        let maxTilt = Double.pi / 4 // 45 degrees max tilt for full offset
        let normalizedPitch = max(-1, min(1, -pitch / maxTilt))
        let normalizedRoll = max(-1, min(1, roll / maxTilt))

        // Scale offset (0.3 max offset for subtle effect)
        lightOffset = CGPoint(
            x: normalizedRoll * 0.3,
            y: normalizedPitch * 0.3
        )
    }
}
