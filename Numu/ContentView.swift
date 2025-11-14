//
//  ContentView.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        // STAGE 1: Using V1 baseline - DashboardView
        Text("STAGE 1: V1 Baseline")
            .font(.largeTitle)
            .padding()

        // V1 (Legacy): Will use this for baseline testing
        // DashboardView()

        // V2 Architecture: System -> Tasks -> Tests
        // SystemsDashboardView()  // Will enable in later stages
    }
}

