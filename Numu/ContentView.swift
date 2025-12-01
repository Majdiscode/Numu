//
//  ContentView.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            // Main app
            SystemsDashboardView()
        } else {
            // Onboarding flow
            OnboardingView()
        }
    }
}

