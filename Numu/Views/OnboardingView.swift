//
//  OnboardingView.swift
//  Numu
//
//  Created by Claude Code
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var currentPage = 0

    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            TabView(selection: $currentPage) {
                // Page 1: Welcome
                WelcomePage()
                    .tag(0)

                // Page 2: Systems Explained
                SystemsExplainedPage()
                    .tag(1)

                // Page 3: Identity-Based
                IdentityBasedPage()
                    .tag(2)

                // Page 4: Get Started
                GetStartedPage(onComplete: completeOnboarding)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .interactiveDismissDisabled()
    }

    private func completeOnboarding() {
        withAnimation(.spring(response: 0.3)) {
            hasCompletedOnboarding = true
            dismiss()
        }
    }
}

// MARK: - Welcome Page
struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App Icon/Logo
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "gearshape.2.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
            }

            VStack(spacing: 16) {
                Text("Welcome to Numu")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                Text("Build systems, not goals.\nBecome who you want to be.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()

            // Swipe hint
            VStack(spacing: 8) {
                Image(systemName: "chevron.right.2")
                    .font(.title2)
                    .foregroundStyle(.blue)

                Text("Swipe to continue")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 32)
        }
        .padding(32)
    }
}

// MARK: - Systems Explained Page
struct SystemsExplainedPage: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 24) {
                // Icon
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.purple)

                // Heading
                Text("What are Systems?")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                // Explanation
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(
                        icon: "person.fill",
                        color: .blue,
                        title: "Identity First",
                        description: "\"I am a Hybrid Athlete\" not \"I want to run more\""
                    )

                    FeatureRow(
                        icon: "checkmark.circle.fill",
                        color: .green,
                        title: "Daily Tasks",
                        description: "Small consistent actions that reinforce your identity"
                    )

                    FeatureRow(
                        icon: "chart.line.uptrend.xyaxis",
                        color: .orange,
                        title: "Progress Tests",
                        description: "Measure improvements: mile time, max pushups, etc."
                    )
                }
            }

            Spacer()
        }
        .padding(32)
    }
}

// MARK: - Identity-Based Page
struct IdentityBasedPage: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 24) {
                // Icon
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundStyle(.yellow)

                // Heading
                Text("Identity Over Goals")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                // Quote
                VStack(spacing: 16) {
                    Text("\"You don't rise to the level of your goals,\nyou fall to the level of your systems.\"")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)

                    Text("— James Clear, Atomic Habits")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(24)
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(16)

                // Key Insight
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                        Text("Every action is a vote for the person you want to become")
                            .font(.callout)
                            .fontWeight(.medium)
                    }
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .padding(32)
    }
}

// MARK: - Get Started Page
struct GetStartedPage: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 24) {
                // Icon
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)

                // Heading
                Text("Ready to Build\nYour Systems?")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                // Features list
                VStack(alignment: .leading, spacing: 16) {
                    CheckRow(text: "Track daily habits")
                    CheckRow(text: "Measure progress with tests")
                    CheckRow(text: "Build streak momentum")
                    CheckRow(text: "Sync across all devices")
                }
                .padding(.top, 8)
            }

            Spacer()

            // Get Started Button
            Button {
                onComplete()
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.bottom, 32)
        }
        .padding(32)
    }
}

// MARK: - Supporting Components
struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
            }
        }
    }
}

struct CheckRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.green)

            Text(text)
                .font(.callout)
        }
    }
}

#Preview {
    OnboardingView()
}
