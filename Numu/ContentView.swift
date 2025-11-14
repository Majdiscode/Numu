//
//  ContentView.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        // STAGES 2-3: CloudKit enabled, testing initialization
        VStack(spacing: 16) {
            Text("STAGES 2-3")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("CloudKit Integration")
                .font(.title2)
                .foregroundStyle(.secondary)

            Image(systemName: "icloud.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Testing SwiftData + CloudKit sync")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()

        // V1 (Legacy): Will use this for baseline testing
        // DashboardView()

        // V2 Architecture: System -> Tasks -> Tests
        // SystemsDashboardView()  // Will enable in Stage 4
    }
}

