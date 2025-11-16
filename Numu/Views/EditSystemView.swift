//
//  EditSystemView.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//

import SwiftUI
import SwiftData

struct EditSystemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let system: System

    // System details
    @State private var systemName: String = ""
    @State private var systemDescription: String = ""
    @State private var selectedCategory: SystemCategory = .athletics

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - System Identity (Coming in Stage 2)
                Section {
                    Text("System editing coming in Stage 2")
                        .foregroundStyle(.secondary)
                } header: {
                    Label("System Identity", systemImage: "gearshape.2")
                }

                // MARK: - Daily Tasks (Coming in Stage 3)
                Section {
                    Text("Add tasks coming in Stage 3")
                        .foregroundStyle(.secondary)
                } header: {
                    Label("Daily Tasks", systemImage: "checkmark.square")
                }

                // MARK: - Periodic Tests (Coming in Stage 4)
                Section {
                    Text("Add/remove tests coming in Stage 4")
                        .foregroundStyle(.secondary)
                } header: {
                    Label("Periodic Tests", systemImage: "chart.bar")
                }
            }
            .navigationTitle("Edit System")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            // Initialize with current system values
            systemName = system.name
            systemDescription = system.systemDescription ?? ""
            selectedCategory = system.category
        }
    }

    private func saveChanges() {
        // Will implement in Stage 2
        dismiss()
    }
}
