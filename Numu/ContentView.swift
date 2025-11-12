//
//  ContentView.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        // V2 Architecture: System -> Tasks -> Tests
        SystemsDashboardView()

        // V1 (Legacy): Uncomment to use old Habit-based view
        // DashboardView()
    }
}

