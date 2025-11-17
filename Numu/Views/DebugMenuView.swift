//
//  DebugMenuView.swift
//  Numu
//
//  Debug menu for testing features with generated data
//  Only available in DEBUG builds
//

import SwiftUI
import SwiftData

#if DEBUG

struct DebugMenuView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Binding var isDeletingTestData: Bool

    @State private var showClearConfirmation = false
    @State private var generatingData = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("⚠️ This menu is only available in debug builds")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Label("Debug Mode", systemImage: "exclamationmark.triangle")
                }

                Section {
                    Button {
                        generateBasicTestData()
                    } label: {
                        Label("Generate Test System (30 days)", systemImage: "testtube.2")
                    }
                    .disabled(generatingData)

                    Button {
                        generateMultipleTestSystems()
                    } label: {
                        Label("Generate Multiple Systems", systemImage: "square.stack.3d.up")
                    }
                    .disabled(generatingData)

                    Button {
                        generate7DaysData()
                    } label: {
                        Label("Generate 7 Days (Quick Test)", systemImage: "calendar")
                    }
                    .disabled(generatingData)
                } header: {
                    Label("Generate Test Data", systemImage: "wand.and.stars")
                } footer: {
                    Text("Creates fake systems with 🧪 emoji for testing analytics and features")
                }

                Section {
                    Button(role: .destructive) {
                        showClearConfirmation = true
                    } label: {
                        Label("Clear All Test Data", systemImage: "trash")
                    }
                } header: {
                    Label("Clear Data", systemImage: "eraser")
                } footer: {
                    Text("Removes all systems marked with 🧪 emoji. Your real data is safe.")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Test data is marked with 🧪")
                            .font(.caption)
                        Text("• Analytics charts will show historical trends")
                            .font(.caption)
                        Text("• Performance tests will show improvement")
                            .font(.caption)
                        Text("• Clear test data anytime")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                } header: {
                    Label("How It Works", systemImage: "info.circle")
                }
            }
            .navigationTitle("Debug Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Clear Test Data?", isPresented: $showClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    clearTestData()
                }
            } message: {
                Text("This will delete all systems marked with 🧪. Your real data will not be affected.")
            }
        }
    }

    // MARK: - Actions

    private func generateBasicTestData() {
        generatingData = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let generator = TestDataGenerator(modelContext: modelContext)
            generator.generateTestSystem(daysOfHistory: 30)

            generatingData = false
        }
    }

    private func generateMultipleTestSystems() {
        generatingData = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let generator = TestDataGenerator(modelContext: modelContext)
            generator.generateMultipleTestSystems()

            generatingData = false
        }
    }

    private func generate7DaysData() {
        generatingData = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let generator = TestDataGenerator(modelContext: modelContext)
            generator.generateTestSystem(daysOfHistory: 7)

            generatingData = false
        }
    }

    private func clearTestData() {
        // Capture context before dismissing
        let context = modelContext

        // Show loading overlay on parent view
        isDeletingTestData = true

        // Dismiss this sheet
        dismiss()

        // Delete after sheet animation completes (0.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let generator = TestDataGenerator(modelContext: context)
            generator.clearTestData()

            // Hide loading overlay after deletion completes (give @Query time to update)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isDeletingTestData = false
            }
        }
    }
}

#Preview {
    DebugMenuView(isDeletingTestData: .constant(false))
}

#endif
