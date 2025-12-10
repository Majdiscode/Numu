//
//  SystemsDashboardView.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/12/25.
//

import SwiftUI
import SwiftData

struct SystemsDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(HapticManager.self) private var hapticManager
    @Environment(MotionManager.self) private var motionManager
    @Query private var systems: [System]

    @Namespace private var progressCardNamespace

    @State private var showCreateSystem = false
    @State private var cloudKitService = CloudKitService()
    @State private var isDeletingTestData = false
    @State private var showCelebration = false
    @State private var showWeeklyCelebration = false
    @State private var previousCompletionRate: Double = 0
    @State private var previousWeeklyCompletionRate: Double = 0
    @State private var shouldScrollToTop = false
    @State private var isAnimatingCompletion = false
    @State private var isInitialLoad = true
    @State private var isMorphingCards = false
    @State private var isSheetDismissing = false

    // MARK: - Animated Percentages for Counting Effect
    @State private var animatedDailyPercentage: Double = 0.0
    @State private var animatedWeeklyPercentage: Double = 0.0

    // MARK: - Animated Gauge Values for Smooth Fill
    @State private var animatedDailyGaugeValue: Double = 0.0
    @State private var animatedWeeklyGaugeValue: Double = 0.0
    @State private var dailyGaugeFillTimer: Timer?
    @State private var weeklyGaugeFillTimer: Timer?

    // MARK: - Performance Optimization: Cached Stats
    @State private var cachedOverallCompletionRate: Double = 0.0
    @State private var cachedTotalActiveSystems: Int = 0
    @State private var cachedOverallWeeklyCompletionRate: Double = 0.0
    @State private var cachedTotalWeeklyTasks: Int = 0
    @State private var cachedTotalCompletedWeeklyTasks: Int = 0
    @State private var cachedTotalWeeklyCompletions: Int = 0
    @State private var cachedTotalWeeklyTarget: Int = 0
    @State private var cachedTotalTodaysTasks: Int = 0
    @State private var cachedTotalCompletedTasks: Int = 0
    @State private var statsNeedRefresh: Bool = true

    #if DEBUG
    @State private var showDebugMenu = false
    @State private var debugTapCount = 0
    @State private var showLiquidGlassDemo = false
    #endif

    // MARK: - Optimized Computed Properties (Use Cached Values)

    var overallCompletionRate: Double {
        guard !isDeletingTestData else { return 0.0 }
        return cachedOverallCompletionRate
    }

    var totalActiveSystems: Int {
        guard !isDeletingTestData else { return 0 }
        return cachedTotalActiveSystems
    }

    var overallWeeklyCompletionRate: Double {
        guard !isDeletingTestData else { return 0.0 }
        return cachedOverallWeeklyCompletionRate
    }

    var totalWeeklyTasks: Int {
        guard !isDeletingTestData else { return 0 }
        return cachedTotalWeeklyTasks
    }

    var totalCompletedWeeklyTasks: Int {
        guard !isDeletingTestData else { return 0 }
        return cachedTotalCompletedWeeklyTasks
    }

    var totalWeeklyCompletions: Int {
        guard !isDeletingTestData else { return 0 }
        return cachedTotalWeeklyCompletions
    }

    var totalWeeklyTarget: Int {
        guard !isDeletingTestData else { return 0 }
        return cachedTotalWeeklyTarget
    }

    // MARK: - Batch Stats Calculation (Optimized)

    /// Calculate all dashboard stats in a single pass for optimal performance
    private func refreshDashboardStats() {
        let startTime = CFAbsoluteTimeGetCurrent()
        print("📊 [PERF] refreshDashboardStats START")

        guard !isDeletingTestData else { return }
        guard !systems.isEmpty else {
            resetCachedStats()
            return
        }

        // Single-pass calculation for all stats
        var tempTotalTodaysTasks = 0
        var tempTotalCompletedTasks = 0
        var tempActiveSystems = 0
        var tempTotalWeeklyTasks = 0
        var tempCompletedWeeklyTasks = 0
        var tempTotalWeeklyCompletions = 0
        var tempTotalWeeklyTarget = 0

        for system in systems {
            let todaysTasks = system.todaysTasks
            let todaysCompleted = system.completedTodayCount

            tempTotalTodaysTasks += todaysTasks.count
            tempTotalCompletedTasks += todaysCompleted

            if !todaysTasks.isEmpty {
                tempActiveSystems += 1
            }

            tempTotalWeeklyTasks += system.weeklyTasks.count
            tempCompletedWeeklyTasks += system.completedWeeklyCount
            tempTotalWeeklyCompletions += system.totalWeeklyCompletions
            tempTotalWeeklyTarget += system.totalWeeklyTarget
        }

        // Calculate new rates
        let newDailyRate = tempTotalTodaysTasks > 0
            ? Double(tempTotalCompletedTasks) / Double(tempTotalTodaysTasks)
            : 0.0

        let newWeeklyRate = tempTotalWeeklyTarget > 0
            ? min(1.0, max(0.0, Double(tempTotalWeeklyCompletions) / Double(tempTotalWeeklyTarget)))
            : 0.0

        // Check if we're reaching 100% from a lower value (but not on initial load)
        let reachingDailyCompletion = !isInitialLoad && newDailyRate == 1.0 && cachedOverallCompletionRate < 1.0 && !systems.isEmpty
        let reachingWeeklyCompletion = !isInitialLoad && newWeeklyRate == 1.0 && cachedOverallWeeklyCompletionRate < 1.0 && tempTotalWeeklyTasks > 0

        if reachingDailyCompletion || reachingWeeklyCompletion {
            // Update stats with animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                updateCachedStats(
                    todaysTasks: tempTotalTodaysTasks,
                    completedTasks: tempTotalCompletedTasks,
                    activeSystems: tempActiveSystems,
                    weeklyTasks: tempTotalWeeklyTasks,
                    completedWeeklyTasks: tempCompletedWeeklyTasks,
                    weeklyCompletions: tempTotalWeeklyCompletions,
                    weeklyTarget: tempTotalWeeklyTarget,
                    dailyRate: newDailyRate,
                    weeklyRate: newWeeklyRate
                )
            }

            // Trigger celebration and haptics after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                // Big completion haptic
                if reachingDailyCompletion && reachingWeeklyCompletion {
                    hapticManager.perfectDayCompleted()
                } else if reachingDailyCompletion {
                    hapticManager.dailyGoalCompleted()
                } else if reachingWeeklyCompletion {
                    hapticManager.weeklyGoalCompleted()
                }

                if reachingDailyCompletion {
                    triggerCelebration(isWeekly: false)
                }
                if reachingWeeklyCompletion {
                    triggerCelebration(isWeekly: true)
                }
            }
        } else {
            // Normal update without delays
            if isInitialLoad {
                // No animation on initial load to prevent weekly card from animating in
                updateCachedStats(
                    todaysTasks: tempTotalTodaysTasks,
                    completedTasks: tempTotalCompletedTasks,
                    activeSystems: tempActiveSystems,
                    weeklyTasks: tempTotalWeeklyTasks,
                    completedWeeklyTasks: tempCompletedWeeklyTasks,
                    weeklyCompletions: tempTotalWeeklyCompletions,
                    weeklyTarget: tempTotalWeeklyTarget,
                    dailyRate: newDailyRate,
                    weeklyRate: newWeeklyRate
                )
                isInitialLoad = false
            } else {
                // Check if card layout is changing (1 card ↔ 2 cards)
                let oldHasDaily = cachedTotalTodaysTasks > 0
                let oldHasWeekly = cachedTotalWeeklyTarget > 0
                let oldCardCount = (oldHasDaily ? 1 : 0) + (oldHasWeekly ? 1 : 0)

                let newHasDaily = tempTotalTodaysTasks > 0
                let newHasWeekly = tempTotalWeeklyTarget > 0
                let newCardCount = (newHasDaily ? 1 : 0) + (newHasWeekly ? 1 : 0)

                let isCardLayoutChanging = oldCardCount != newCardCount

                if isCardLayoutChanging {
                    print("🔄 [PERF] Card layout changing (\(oldCardCount) → \(newCardCount) cards)")
                    print("🎬 [PERF] Starting morph animation NOW")

                    // Spring animation with extra bounce for dramatic morph effect
                    withAnimation(.spring(response: 1.2, dampingFraction: 0.6)) {
                        self.updateCachedStats(
                            todaysTasks: tempTotalTodaysTasks,
                            completedTasks: tempTotalCompletedTasks,
                            activeSystems: tempActiveSystems,
                            weeklyTasks: tempTotalWeeklyTasks,
                            completedWeeklyTasks: tempCompletedWeeklyTasks,
                            weeklyCompletions: tempTotalWeeklyCompletions,
                            weeklyTarget: tempTotalWeeklyTarget,
                            dailyRate: newDailyRate,
                            weeklyRate: newWeeklyRate
                        )
                    }
                } else {
                    // Normal quick animation for progress updates
                    withAnimation(.easeInOut(duration: 0.2)) {
                        updateCachedStats(
                            todaysTasks: tempTotalTodaysTasks,
                            completedTasks: tempTotalCompletedTasks,
                            activeSystems: tempActiveSystems,
                            weeklyTasks: tempTotalWeeklyTasks,
                            completedWeeklyTasks: tempCompletedWeeklyTasks,
                            weeklyCompletions: tempTotalWeeklyCompletions,
                            weeklyTarget: tempTotalWeeklyTarget,
                            dailyRate: newDailyRate,
                            weeklyRate: newWeeklyRate
                        )
                    }
                }
            }
        }

        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("📊 [PERF] refreshDashboardStats END - took \(String(format: "%.3f", timeElapsed))s")
    }

    private func updateCachedStats(
        todaysTasks: Int,
        completedTasks: Int,
        activeSystems: Int,
        weeklyTasks: Int,
        completedWeeklyTasks: Int,
        weeklyCompletions: Int,
        weeklyTarget: Int,
        dailyRate: Double,
        weeklyRate: Double
    ) {
        cachedTotalTodaysTasks = todaysTasks
        cachedTotalCompletedTasks = completedTasks
        cachedTotalActiveSystems = activeSystems
        cachedTotalWeeklyTasks = weeklyTasks
        cachedTotalCompletedWeeklyTasks = completedWeeklyTasks
        cachedTotalWeeklyCompletions = weeklyCompletions
        cachedTotalWeeklyTarget = weeklyTarget

        // Animate percentage changes
        let oldDailyPercent = cachedOverallCompletionRate * 100
        let newDailyPercent = dailyRate * 100
        let oldWeeklyPercent = cachedOverallWeeklyCompletionRate * 100
        let newWeeklyPercent = weeklyRate * 100

        // Store old gauge values before updating rates
        let oldDailyGaugeValue = cachedOverallCompletionRate
        let oldWeeklyGaugeValue = cachedOverallWeeklyCompletionRate

        // Update the actual rates
        cachedOverallCompletionRate = dailyRate
        cachedOverallWeeklyCompletionRate = weeklyRate

        // Animate the displayed percentages
        animatePercentage(from: oldDailyPercent, to: newDailyPercent, isWeekly: false)
        animatePercentage(from: oldWeeklyPercent, to: newWeeklyPercent, isWeekly: true)

        // Trigger slow fill animation for gauges if values changed significantly
        if abs(dailyRate - oldDailyGaugeValue) > 0.01 {
            slowFillDailyGauge(to: dailyRate)
        }

        if abs(weeklyRate - oldWeeklyGaugeValue) > 0.01 {
            slowFillWeeklyGauge(to: weeklyRate)
        }

        statsNeedRefresh = false
    }

    private func animatePercentage(from oldValue: Double, to newValue: Double, isWeekly: Bool) {
        let difference = abs(newValue - oldValue)

        // Skip animation if no change
        guard difference > 0.1 else {
            if isWeekly {
                animatedWeeklyPercentage = newValue
            } else {
                animatedDailyPercentage = newValue
            }
            return
        }

        // Duration scales with difference: 0.03s per percentage point for visible counting
        // Examples: 33% change = 1.0s, 50% change = 1.5s, 100% change = 2.0s (capped)
        let duration = min(2.0, difference * 0.03)

        // Use spring animation for smoother counting effect
        withAnimation(.spring(response: duration, dampingFraction: 1.0)) {
            if isWeekly {
                animatedWeeklyPercentage = newValue
            } else {
                animatedDailyPercentage = newValue
            }
        }
    }

    // MARK: - Slow Fill Animations for Gauges

    private func slowFillDailyGauge(to target: Double, duration: Double = 1.0) {
        // Stop any existing animation
        dailyGaugeFillTimer?.invalidate()

        let startValue = animatedDailyGaugeValue

        // Calculate how many steps we need (60 fps)
        // Fixed 1 second duration means bigger changes fill visually faster
        let steps = duration * 60
        let totalChange = target - startValue
        let increment = totalChange / steps
        let interval = duration / steps

        var currentStep = 0.0

        dailyGaugeFillTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            currentStep += 1

            if currentStep >= steps {
                self.animatedDailyGaugeValue = target
                timer.invalidate()
            } else {
                self.animatedDailyGaugeValue += increment
            }
        }
    }

    private func slowFillWeeklyGauge(to target: Double, duration: Double = 1.0) {
        // Stop any existing animation
        weeklyGaugeFillTimer?.invalidate()

        let startValue = animatedWeeklyGaugeValue

        // Calculate how many steps we need (60 fps)
        // Fixed 1 second duration means bigger changes fill visually faster
        let steps = duration * 60
        let totalChange = target - startValue
        let increment = totalChange / steps
        let interval = duration / steps

        var currentStep = 0.0

        weeklyGaugeFillTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            currentStep += 1

            if currentStep >= steps {
                self.animatedWeeklyGaugeValue = target
                timer.invalidate()
            } else {
                self.animatedWeeklyGaugeValue += increment
            }
        }
    }

    private func resetCachedStats() {
        cachedOverallCompletionRate = 0.0
        cachedTotalActiveSystems = 0
        cachedOverallWeeklyCompletionRate = 0.0
        cachedTotalWeeklyTasks = 0
        cachedTotalCompletedWeeklyTasks = 0
        cachedTotalWeeklyCompletions = 0
        cachedTotalWeeklyTarget = 0
        cachedTotalTodaysTasks = 0
        cachedTotalCompletedTasks = 0
        animatedDailyPercentage = 0.0
        animatedWeeklyPercentage = 0.0
        animatedDailyGaugeValue = 0.0
        animatedWeeklyGaugeValue = 0.0
        dailyGaugeFillTimer?.invalidate()
        weeklyGaugeFillTimer?.invalidate()
        isInitialLoad = true
    }

    // MARK: - Haptic Feedback

    /// Creates a pulsing haptic pattern during progress bar fill
    private func startProgressFillHaptics() {
        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
        impactGenerator.prepare()

        // Create 6 pulses over 1.0 second to match progress animation (one every ~0.167s)
        let pulseInterval: TimeInterval = 0.167
        for i in 0..<6 {
            DispatchQueue.main.asyncAfter(deadline: .now() + (pulseInterval * Double(i))) {
                impactGenerator.impactOccurred(intensity: 0.5)
            }
        }
    }

    // MARK: - Celebration
    private func triggerCelebration(isWeekly: Bool = false) {
        // Show confetti animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            if isWeekly {
                showWeeklyCelebration = true
            } else {
                showCelebration = true
            }
        }

        // Hide after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation {
                if isWeekly {
                    showWeeklyCelebration = false
                } else {
                    showCelebration = false
                }
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Simple system background
                Color(UIColor { traitCollection in
                    traitCollection.userInterfaceStyle == .dark
                        ? UIColor(white: 0.1, alpha: 1.0)
                        : UIColor(white: 0.92, alpha: 1.0)
                })
                .ignoresSafeArea()

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            // MARK: - Header with Progress Title
                            HStack {
                                Text("Progress")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                Spacer()
                            }
                            .padding(.top, 4)

                            // MARK: - CloudKit Status Banner
                            if cloudKitService.syncStatus == .notSignedIn {
                                cloudKitStatusBanner
                            }

                            // MARK: - Progress Cards
                            if !systems.isEmpty || totalWeeklyTasks > 0 {
                                let hasDaily = !systems.isEmpty
                                let hasWeekly = totalWeeklyTasks > 0

                                GlassEffectContainer(spacing: 12.0) {
                                    HStack(spacing: 12) {
                                        if hasDaily && hasWeekly {
                                            // Two cards: both use circular rings
                                            dailyCircularCard
                                                .glassEffectID("dailyCard", in: progressCardNamespace)

                                            weeklyCircularCard
                                                .glassEffectID("weeklyCard", in: progressCardNamespace)
                                        } else if hasDaily {
                                            // Single daily card: use horizontal bar
                                            dailyLinearProgressCard
                                                .glassEffectID("dailyCard", in: progressCardNamespace)
                                        } else if hasWeekly {
                                            // Single weekly card: use horizontal bar
                                            singleWeeklyProgressCard
                                                .glassEffectID("weeklyCard", in: progressCardNamespace)
                                        }
                                    }
                                }
                                .glassEffectTransition(.matchedGeometry)
                            }

                        // MARK: - Systems List
                        systemsList(proxy: proxy)

                        // MARK: - Empty State
                        if systems.isEmpty {
                            emptyState
                        }
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                        .padding(.bottom)
                    }
                    .onChange(of: shouldScrollToTop) { _, newValue in
                        if newValue {
                            withAnimation(.spring(response: 0.6)) {
                                proxy.scrollTo("progressCards", anchor: .top)
                            }
                            // Reset after scrolling
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                shouldScrollToTop = false
                            }
                        }
                    }
                }
                .blur(radius: isDeletingTestData ? 10 : 0)

                // Loading overlay during deletion
                if isDeletingTestData {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)

                        Text("Clearing test data...")
                            .foregroundStyle(.primary)
                            .font(.headline)
                    }
                }

                // Celebration overlays
                if showCelebration {
                    CelebrationView(isWeekly: false)
                        .allowsHitTesting(false)
                }

                if showWeeklyCelebration {
                    CelebrationView(isWeekly: true)
                        .allowsHitTesting(false)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    #if DEBUG
                    Button {
                        createTestWeeklySystem()
                    } label: {
                        Image(systemName: "plus.square.on.square")
                    }

                    Button {
                        deleteAllWeeklySystems()
                    } label: {
                        Image(systemName: "trash")
                    }

                    Button {
                        handleDebugTap()
                    } label: {
                        Image(systemName: "ant")
                    }

                    Button {
                        showLiquidGlassDemo = true
                    } label: {
                        Image(systemName: "sparkles")
                    }
                    #endif

                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        showCreateSystem = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateSystem) {
                CreateSystemView()
            }
            #if DEBUG
            .sheet(isPresented: $showDebugMenu) {
                DebugMenuView(isDeletingTestData: $isDeletingTestData)
            }
            .sheet(isPresented: $showLiquidGlassDemo) {
                LiquidGlassDemoView()
            }
            #endif
            .onAppear {
                cloudKitService.checkAccountStatus()
                // Initialize gauge values to current cached values on first appear
                animatedDailyGaugeValue = cachedOverallCompletionRate
                animatedWeeklyGaugeValue = cachedOverallWeeklyCompletionRate
                refreshDashboardStats()
            }
            .onChange(of: showCreateSystem) { _, isShowing in
                if !isShowing {
                    print("📋 [SHEET] CreateSystem sheet dismissed")
                    print("⏳ [SHEET] Waiting 0.5s for sheet animation to complete...")
                    isSheetDismissing = true

                    // Delay stats refresh until sheet dismissal animation is complete
                    // This prevents the morph animation from competing with the sheet slide-down
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        print("✅ [SHEET] Sheet animation complete, refreshing stats")
                        isSheetDismissing = false
                        refreshDashboardStats()
                    }
                }
            }
            .onChange(of: systems.count) { oldCount, newCount in
                print("📊 [SYSTEMS] Count changed: \(oldCount) → \(newCount)")

                // Skip refresh if sheet is dismissing - the delayed handler will do it
                guard !isSheetDismissing else {
                    print("⏭️  [SYSTEMS] Skipping refresh - sheet is dismissing")
                    return
                }

                refreshDashboardStats()
            }
            .onChange(of: isDeletingTestData) { _, newValue in
                if !newValue {
                    refreshDashboardStats()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Refresh when app returns from background
                refreshDashboardStats()
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("TaskCompletionChanged"))) { _ in
                // Refresh when a task is completed/uncompleted
                refreshDashboardStats()
            }
        }
    }

    #if DEBUG
    private func handleDebugTap() {
        showDebugMenu = true
    }

    private func createTestWeeklySystem() {
        print("🔵 [DEBUG] Creating test weekly system via hotkey")
        let testSystem = System(
            name: "Test Weekly System",
            category: .athletics,
            color: "3B82F6",
            icon: "figure.run"
        )
        modelContext.insert(testSystem)

        // Add a weekly task
        let weeklyTask = HabitTask(
            name: "Weekly Workout",
            frequency: .weeklyTarget(times: 3),
            habitType: .positive
        )
        weeklyTask.system = testSystem
        modelContext.insert(weeklyTask)

        try? modelContext.save()
        print("🔵 [DEBUG] Test system saved, waiting 0.5s for view preparation...")

        // Add same delay as manual creation for consistent smooth animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("🔵 [DEBUG] Calling refreshDashboardStats")
            refreshDashboardStats()
        }
    }

    private func deleteAllWeeklySystems() {
        // Find all systems that have weekly tasks
        let systemsToDelete = systems.filter { system in
            guard let tasks = system.tasks else { return false }
            return tasks.contains { task in
                if case .weeklyTarget = task.frequency {
                    return true
                }
                return false
            }
        }

        // Delete them
        for system in systemsToDelete {
            modelContext.delete(system)
        }

        try? modelContext.save()
        refreshDashboardStats()
    }
    #endif

    // MARK: - CloudKit Status Banner
    private var cloudKitStatusBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: cloudKitService.syncStatus.icon)
                .font(.title3)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("iCloud Sync Disabled")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Sign into iCloud in Settings to sync across devices")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                if let url = URL(string: "App-prefs:APPLE_ACCOUNT") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Settings")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .elevation(.level1)
    }

    // MARK: - Daily Linear Progress Card (Horizontal Bar)
    private var dailyLinearProgressCard: some View {
        Button(action: {}) {
            VStack(spacing: 16) {
                HStack(alignment: .center) {
                    HStack(spacing: 4) {
                        Text("Daily")
                            .font(.title3)
                            .fontWeight(.bold)

                        Text("\(Int(animatedDailyGaugeValue * 100))%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .monospacedDigit()
                            .contentTransition(.numericText(countsDown: false))
                    }

                    Spacer()

                    Text("\(totalCompletedTasks) / \(totalTodaysTasks)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Custom Horizontal Progress Bar with Gradient
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        Capsule()
                            .fill(Color.primary.opacity(0.1))

                        // Filled portion with gradient (blue to pink)
                        Capsule()
                            .fill(LinearGradient(
                                colors: [
                                    Color(red: 0.0, green: 0.5, blue: 1.0),  // Bright electric blue
                                    Color(red: 0.6, green: 0.3, blue: 1.0),  // Vivid purple
                                    Color(red: 1.0, green: 0.2, blue: 0.6)   // Hot pink
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: geometry.size.width * max(0, min(1, animatedDailyGaugeValue)))
                    }
                }
                .frame(height: 12)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 22)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glass)
    }

    // MARK: - Single Weekly Progress Card (Horizontal Bar)
    private var singleWeeklyProgressCard: some View {
        Button(action: {}) {
            VStack(spacing: 12) {
                HStack(alignment: .center) {
                    HStack(spacing: 4) {
                        Text("Weekly")
                            .font(.title3)
                            .fontWeight(.bold)

                        Text("\(Int(min(100, max(0, animatedWeeklyGaugeValue * 100))))%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .monospacedDigit()
                            .contentTransition(.numericText(countsDown: false))
                    }

                    Spacer()

                    Text("\(max(0, totalWeeklyCompletions)) / \(max(0, totalWeeklyTarget))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Custom Horizontal Progress Bar with Gradient
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        Capsule()
                            .fill(Color.primary.opacity(0.1))

                        // Filled portion with gradient
                        Capsule()
                            .fill(LinearGradient(
                                colors: [
                                    Color(red: 0.2, green: 0.8, blue: 0.3),  // Bright green
                                    Color(red: 0.5, green: 0.9, blue: 0.2),  // Yellow-green
                                    Color(red: 1.0, green: 0.8, blue: 0.0)   // Golden yellow
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: geometry.size.width * max(0, min(1, animatedWeeklyGaugeValue)))
                    }
                }
                .frame(height: 12)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glass)
    }

    // MARK: - Daily Circular Card (for dual card layout)
    private var dailyCircularCard: some View {
        Button(action: {}) {
            VStack(spacing: 8) {
                Text("Daily")
                    .font(.caption)
                    .fontWeight(.semibold)

                // Circular Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.1), lineWidth: 9)

                    Circle()
                        .trim(from: 0, to: max(0, min(1, animatedDailyGaugeValue)))
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.0, green: 0.5, blue: 1.0),  // Bright electric blue
                                    Color(red: 0.6, green: 0.3, blue: 1.0),  // Vivid purple
                                    Color(red: 1.0, green: 0.2, blue: 0.6)   // Hot pink
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 9, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(animatedDailyGaugeValue * 100))%")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: false))
                }
                .frame(width: 90, height: 90)

                Text("\(totalCompletedTasks) / \(totalTodaysTasks)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .buttonStyle(.glass)
    }

    // MARK: - Weekly Circular Card (for dual card layout)
    private var weeklyCircularCard: some View {
        Button(action: {}) {
            VStack(spacing: 8) {
                Text("Weekly")
                    .font(.caption)
                    .fontWeight(.semibold)

                // Circular Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.1), lineWidth: 9)

                    Circle()
                        .trim(from: 0, to: max(0, min(1, animatedWeeklyGaugeValue)))
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.2, green: 0.8, blue: 0.3),  // Bright green
                                    Color(red: 0.5, green: 0.9, blue: 0.2),  // Yellow-green
                                    Color(red: 1.0, green: 0.8, blue: 0.0)   // Golden yellow
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 9, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(min(100, max(0, animatedWeeklyGaugeValue * 100))))%")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: false))
                }
                .frame(width: 90, height: 90)

                Text("\(totalWeeklyCompletions) / \(totalWeeklyTarget)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .buttonStyle(.glass)
    }

    private var totalTodaysTasks: Int {
        guard !isDeletingTestData else { return 0 }
        return cachedTotalTodaysTasks
    }

    private var totalCompletedTasks: Int {
        guard !isDeletingTestData else { return 0 }
        return cachedTotalCompletedTasks
    }

    private var motivationalMessage: String {
        // Don't access systems during deletion to avoid accessing deleted objects
        guard !isDeletingTestData else { return "Clearing test data..." }

        if systems.isEmpty {
            return "Create your first system to begin"
        } else if overallCompletionRate == 1.0 {
            return "Perfect! All systems running smoothly"
        } else if overallCompletionRate >= 0.75 {
            return "Excellent work today"
        } else if overallCompletionRate >= 0.5 {
            return "Keep going, you're doing great"
        } else if totalCompletedTasks == 0 {
            return "Start fresh, one task at a time"
        } else {
            return "Progress, not perfection"
        }
    }

    // Smooth gradient that flows from blue to pink
    private var progressBarGradient: LinearGradient {
        let brightBlue = Color(red: 0.0, green: 0.5, blue: 1.0)        // Bright electric blue
        let vividPurple = Color(red: 0.6, green: 0.3, blue: 1.0)       // Vivid purple
        let hotPink = Color(red: 1.0, green: 0.2, blue: 0.6)           // Hot pink

        return LinearGradient(
            colors: [brightBlue, vividPurple, hotPink],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var weeklyMotivationalMessage: String {
        // Don't access systems during deletion to avoid accessing deleted objects
        guard !isDeletingTestData else { return "Clearing test data..." }

        if totalWeeklyTasks == 0 {
            return "No weekly goals set yet"
        } else if overallWeeklyCompletionRate == 1.0 {
            return "All weekly goals completed! Outstanding!"
        } else if overallWeeklyCompletionRate >= 0.75 {
            return "Nearly there, finish strong this week"
        } else if overallWeeklyCompletionRate >= 0.5 {
            return "Solid progress, keep the momentum going"
        } else if totalWeeklyCompletions == 0 {
            return "Plenty of time left this week"
        } else {
            return "Every rep counts, keep going"
        }
    }

    // MARK: - Systems Grid (Widget Layout)
    private func systemsList(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Don't render systems during deletion to avoid accessing deleted objects
            if !isDeletingTestData && !systems.isEmpty {
                HStack {
                    Text("Systems")
                        .font(.title)
                        .fontWeight(.bold)

                    Spacer()

                    Text("\(systems.count)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }

                // Full-width stacked layout for better readability
                VStack(spacing: 12) {
                    ForEach(systems) { system in
                        NavigationLink(destination: SystemDetailView(system: system)) {
                            SystemWidgetCard(system: system, modelContext: modelContext, scrollProxy: proxy)
                                .id("system-\(system.id)")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "gearshape.2")
                .font(.largeTitle)
                .imageScale(.large)
                .foregroundStyle(.blue)

            Text("Build Your Systems")
                .font(.title2)
                .fontWeight(.bold)

            Text("Create systems with daily tasks and periodic tests.\nExample: Hybrid Athlete with running + workouts")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showCreateSystem = true
            } label: {
                Text("Create Your First System")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 8)
        }
        .padding(32)
    }

    // MARK: - Motion-Reactive Shimmer Helper

    /// Computes gradient start and end points from light angle
    /// Light angle represents where light comes from (0° = right, 90° = bottom, 180° = left, 270° = top)
    private func motionGradientPoints() -> (start: UnitPoint, end: UnitPoint) {
        let angle = motionManager.lightAngle.radians

        // Calculate the light source position (where light comes from)
        let lightX = (cos(angle) + 1.0) / 2.0  // Map -1...1 to 0...1
        let lightY = (sin(angle) + 1.0) / 2.0  // Map -1...1 to 0...1

        // Start point is where light originates (bright)
        let startPoint = UnitPoint(x: lightX, y: lightY)

        // End point is opposite side (dim)
        let endX = 1.0 - lightX
        let endY = 1.0 - lightY
        let endPoint = UnitPoint(x: endX, y: endY)

        return (startPoint, endPoint)
    }
}

// MARK: - System Widget Card (Compact 2-Column Layout)
struct SystemWidgetCard: View {
    let system: System
    let modelContext: ModelContext
    let scrollProxy: ScrollViewProxy

    @Environment(HapticManager.self) private var hapticManager
    @Environment(MotionManager.self) private var motionManager

    // Performance optimization: Cache expensive calculations
    @State private var cachedTodaysTasks: [HabitTask] = []
    @State private var cachedWeeklyTasks: [HabitTask] = []
    @State private var cachedDueTests: [PerformanceTest] = []
    @State private var cachedCompletionRate: Double = 0.0
    @State private var animatedCompletionRate: Double = 0.0
    @State private var isExpanded: Bool = false
    @State private var fillTimer: Timer?

    private func refreshCache() {
        cachedTodaysTasks = system.todaysTasks
        cachedWeeklyTasks = system.weeklyTasks
        cachedDueTests = system.dueTests

        // Calculate completion rate including both daily and weekly tasks
        let dailyTasks = cachedTodaysTasks
        let weeklyTasks = cachedWeeklyTasks

        let oldRate = cachedCompletionRate

        if dailyTasks.isEmpty && weeklyTasks.isEmpty {
            cachedCompletionRate = 0.0
        } else if dailyTasks.isEmpty {
            // Only weekly tasks - show average weekly progress (e.g., 1/3 = 33%)
            var totalProgress: Double = 0.0
            for task in weeklyTasks {
                if case .weeklyTarget(let times) = task.frequency {
                    let completions = task.completionsThisWeek()
                    let progress = min(1.0, Double(completions) / Double(times))
                    totalProgress += progress
                }
            }
            cachedCompletionRate = weeklyTasks.isEmpty ? 0.0 : totalProgress / Double(weeklyTasks.count)
        } else if weeklyTasks.isEmpty {
            // Only daily tasks - use today's completion
            cachedCompletionRate = system.todayCompletionRate
        } else {
            // Both daily and weekly - combine them proportionally
            let dailyProgress = Double(dailyTasks.filter { $0.isCompletedToday() }.count)
            var weeklyProgress: Double = 0.0
            for task in weeklyTasks {
                if case .weeklyTarget(let times) = task.frequency {
                    let completions = task.completionsThisWeek()
                    weeklyProgress += min(1.0, Double(completions) / Double(times))
                }
            }
            let totalTasks = dailyTasks.count + weeklyTasks.count
            cachedCompletionRate = (dailyProgress + weeklyProgress) / Double(totalTasks)
        }

        // Trigger slow fill animation if completion changed
        if abs(cachedCompletionRate - oldRate) > 0.01 {
            slowFillTo(cachedCompletionRate, duration: 1.0)
        }
    }

    private func slowFillTo(_ target: Double, duration: Double) {
        // Stop any existing animation
        fillTimer?.invalidate()

        let startValue = animatedCompletionRate

        // Calculate how many steps we need (60 fps)
        // Fixed duration means bigger changes fill visually faster
        let steps = duration * 60
        let totalChange = target - startValue
        let increment = totalChange / steps
        let interval = duration / steps

        var currentStep = 0.0

        fillTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            currentStep += 1

            if currentStep >= steps {
                animatedCompletionRate = target
                timer.invalidate()
            } else {
                animatedCompletionRate += increment
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Compact Widget Header
            HStack(spacing: 12) {
                // System Name
                Text(system.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                // Icon (smaller, to the right of name)
                ZStack {
                    Circle()
                        .fill(Color(hex: system.color).opacity(0.15))
                        .frame(width: 32, height: 32)

                    Image(systemName: system.icon)
                        .font(.callout)
                        .foregroundStyle(Color(hex: system.color))
                }

                Spacer()

                // Completion circle with gradient
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.1), lineWidth: 6)

                    Circle()
                        .trim(from: 0, to: max(0, min(1, animatedCompletionRate)))
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: system.color).opacity(0.4),
                                    Color(hex: system.color),
                                    Color(hex: system.color).opacity(0.9)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(max(0, min(100, animatedCompletionRate * 100))))")
                        .font(.system(size: 12, weight: .bold))
                }
                .frame(width: 50, height: 50)
            }
            .padding(16)
            .frame(maxWidth: .infinity)

            // Expandable Tasks Dropdown
            if !cachedTodaysTasks.isEmpty || !cachedWeeklyTasks.isEmpty {
                VStack(spacing: 0) {
                    Button {
                        // More noticeable haptic for expansion
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()

                        // Capture current state before toggling
                        let willExpand = !isExpanded

                        // Toggle expansion with animation
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isExpanded.toggle()
                        }

                        // Auto-scroll when expanding to ensure full card is visible
                        if willExpand {
                            // Wait for expansion animation to complete, then scroll
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    scrollProxy.scrollTo("system-\(system.id)", anchor: .top)
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(isExpanded ? "Hide Tasks" : "Show Tasks")
                                .font(.callout)
                                .fontWeight(.semibold)

                            Spacer()

                            Image(systemName: "chevron.down")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        }
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    // Expanded Tasks
                    if isExpanded {
                        VStack(spacing: 0) {
                            // Today's Tasks
                            if !cachedTodaysTasks.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Today")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 16)
                                        .padding(.top, 12)

                                    ForEach(cachedTodaysTasks) { task in
                                        CompactTaskRow(task: task, modelContext: modelContext)
                                    }
                                }
                            }

                            // Weekly Goals
                            if !cachedWeeklyTasks.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Weekly")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 16)
                                        .padding(.top, cachedTodaysTasks.isEmpty ? 12 : 16)

                                    ForEach(cachedWeeklyTasks) { task in
                                        CompactTaskRow(task: task, modelContext: modelContext)
                                    }
                                }
                                .padding(.bottom, 12)
                            }
                        }
                    }
                }
            }
        }
        .glassEffect(in: RoundedRectangle(cornerRadius: 25))
        .onAppear {
            refreshCache()
            // Initialize animated value to current value on first load (no animation)
            animatedCompletionRate = cachedCompletionRate
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("TaskCompletionChanged"))) { _ in
            refreshCache()
        }
    }

    // MARK: - Motion-Reactive Shimmer Helper

    private func motionGradientPoints() -> (start: UnitPoint, end: UnitPoint) {
        let angle = motionManager.lightAngle.radians

        let lightX = (cos(angle) + 1.0) / 2.0
        let lightY = (sin(angle) + 1.0) / 2.0

        let startPoint = UnitPoint(x: lightX, y: lightY)

        let endX = 1.0 - lightX
        let endY = 1.0 - lightY
        let endPoint = UnitPoint(x: endX, y: endY)

        return (startPoint, endPoint)
    }
}

// MARK: - Compact Task Row (For Widget Cards)
struct CompactTaskRow: View {
    let task: HabitTask
    let modelContext: ModelContext

    @Environment(HapticManager.self) private var hapticManager
    @Query private var allSystems: [System]

    @State private var isCompleted: Bool = false
    @State private var showCheckIn: Bool = false

    private func refreshCompletion() {
        isCompleted = task.isCompletedToday()
    }

    var body: some View {
        HStack(spacing: 10) {
            Button {
                toggleCompletion()
            } label: {
                let completionColor: Color = task.habitType == .positive ? .green : .orange
                Image(systemName: isCompleted ? task.habitType.icon : "circle")
                    .font(.title3)
                    .foregroundStyle(isCompleted ? completionColor : .gray.opacity(0.3))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.name)
                    .font(.subheadline)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                    .lineLimit(1)

                if let progressText = task.weeklyProgressText() {
                    Text(progressText)
                        .font(.caption2)
                        .foregroundStyle(task.weeklyTargetMet() ? .green : .blue)
                }
            }

            Spacer()

            if task.currentStreak > 0 {
                if task.isStreakAtRisk {
                    HStack(spacing: 3) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                        Text("\(task.currentStreak)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.yellow)
                } else {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                        Text("\(task.currentStreak)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(streakGradient)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .onAppear {
            refreshCompletion()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("TaskCompletionChanged"))) { _ in
            refreshCompletion()
        }
    }

    private var streakGradient: LinearGradient {
        let brightElectricBlue = Color(red: 0.0, green: 0.6, blue: 1.0) // Bright electric blue
        let deepBlue = Color(red: 0.0, green: 0.3, blue: 0.8)            // Deep saturated blue

        return LinearGradient(
            colors: [brightElectricBlue, deepBlue],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func toggleCompletion() {
        withAnimation(.spring(response: 0.3)) {
            let wasCompleted = isCompleted

            if isCompleted {
                if let todayLog = task.logs?.first(where: { Calendar.current.isDateInToday($0.date) }) {
                    modelContext.delete(todayLog)
                }
            } else {
                let log = HabitTaskLog()
                log.task = task
                modelContext.insert(log)
            }

            do {
                try modelContext.save()
                isCompleted.toggle()

                // Trigger haptics
                if !wasCompleted {
                    // Completing a task - use appropriate celebration haptic
                    triggerAppropriateHaptic()
                } else {
                    // Unchecking a task - use light haptic
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred(intensity: 0.4)
                }

                NotificationCenter.default.post(name: Notification.Name("TaskCompletionChanged"), object: nil)
            } catch {
                print("Error toggling task: \(error)")
            }
        }
    }

    private func triggerAppropriateHaptic() {
        // Check completion levels and trigger appropriate haptic
        let dailyStats = calculateDailyCompletion()
        let weeklyStats = calculateWeeklyCompletion()
        let systemStats = calculateSystemCompletion()

        // Level 5: Perfect day (both daily and weekly at 100%)
        if dailyStats.rate == 1.0 && weeklyStats.rate == 1.0 {
            hapticManager.perfectDayCompleted()
        }
        // Level 4: Both goals completed (but check daily first, then weekly)
        else if dailyStats.rate == 1.0 && weeklyStats.rate == 1.0 {
            hapticManager.dailyGoalCompleted()
        }
        // Level 3: Daily goal completed
        else if dailyStats.rate == 1.0 {
            hapticManager.dailyGoalCompleted()
        }
        // Level 3: Weekly goal completed
        else if weeklyStats.rate == 1.0 {
            hapticManager.weeklyGoalCompleted()
        }
        // Level 2: System completed
        else if systemStats.rate == 1.0 {
            hapticManager.systemCompleted()
        }
        // Level 1: Single task completed
        else {
            hapticManager.taskCompleted()
        }
    }

    private func calculateSystemCompletion() -> (completed: Int, total: Int, rate: Double) {
        guard let system = task.system, let tasks = system.tasks else {
            return (0, 0, 0.0)
        }

        let today = Calendar.current.startOfDay(for: Date())
        var completed = 0
        var total = 0

        for t in tasks {
            if t.shouldBeCompletedOn(date: today) {
                total += 1
                if t.wasCompletedOn(date: today) {
                    completed += 1
                }
            }
        }

        let rate = total > 0 ? Double(completed) / Double(total) : 0.0
        return (completed, total, rate)
    }

    private func calculateDailyCompletion() -> (completed: Int, total: Int, rate: Double) {
        let today = Calendar.current.startOfDay(for: Date())
        var completed = 0
        var total = 0

        for system in allSystems {
            guard let tasks = system.tasks else { continue }
            for task in tasks {
                if task.shouldBeCompletedOn(date: today) {
                    total += 1
                    if task.wasCompletedOn(date: today) {
                        completed += 1
                    }
                }
            }
        }

        let rate = total > 0 ? Double(completed) / Double(total) : 0.0
        return (completed, total, rate)
    }

    private func calculateWeeklyCompletion() -> (completed: Int, total: Int, rate: Double) {
        let today = Date()
        var completedWeekly = 0
        var totalWeekly = 0

        for system in allSystems {
            guard let tasks = system.tasks else { continue }
            for task in tasks {
                if case .weeklyTarget(let times) = task.frequency {
                    totalWeekly += times
                    let completions = task.completionsInWeek(containing: today)
                    completedWeekly += min(completions, times)
                }
            }
        }

        let rate = totalWeekly > 0 ? Double(completedWeekly) / Double(totalWeekly) : 0.0
        return (completedWeekly, totalWeekly, rate)
    }
}

// MARK: - Task Row Component
struct TaskRow: View {
    let task: HabitTask
    let modelContext: ModelContext

    @Environment(HapticManager.self) private var hapticManager
    @Query private var allSystems: [System]

    @State private var isCompleted: Bool = false
    @State private var showCheckIn: Bool = false
    @State private var cachedWeeklyProgressText: String? = nil
    @State private var cachedCurrentStreak: Int = 0
    @State private var cachedIsStreakAtRisk: Bool = false
    @State private var cachedIsOverTarget: Bool = false

    var isTimeBased: Bool {
        task.habitType == .negative && task.hasTimeLimit
    }

    private var streakGradient: LinearGradient {
        let brightElectricBlue = Color(red: 0.0, green: 0.6, blue: 1.0) // Bright electric blue
        let deepBlue = Color(red: 0.0, green: 0.3, blue: 0.8)            // Deep saturated blue

        return LinearGradient(
            colors: [brightElectricBlue, deepBlue],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func refreshTaskCache() {
        isCompleted = task.isCompletedToday()
        cachedWeeklyProgressText = task.weeklyProgressText()
        cachedCurrentStreak = task.currentStreak
        cachedIsStreakAtRisk = task.isStreakAtRisk
        cachedIsOverTarget = task.isOverWeeklyTarget()
    }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                handleTaskTap()
            } label: {
                let completionColor: Color = task.habitType == .positive ? .green : .orange
                Image(systemName: isCompleted || cachedIsOverTarget ? task.habitType.icon : "circle")
                    .font(.title3)
                    .foregroundStyle((isCompleted || cachedIsOverTarget) ? completionColor.opacity(cachedIsOverTarget && !isCompleted ? 0.5 : 1.0) : .gray.opacity(0.3))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(task.name)
                        .font(.subheadline)
                        .foregroundStyle(isCompleted ? .secondary : .primary)

                    if task.habitType == .negative {
                        Text("Break")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.orange.opacity(0.8))
                            .clipShape(Capsule())
                    }
                }

                // Show weekly progress for weekly targets (cached)
                if let progressText = cachedWeeklyProgressText {
                    Text(progressText)
                        .font(.caption2)
                        .foregroundStyle(task.weeklyTargetMet() ? .green : .blue)
                }
            }

            Spacer()

            if cachedCurrentStreak > 0 {
                if cachedIsStreakAtRisk {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                        if case .weeklyTarget = task.frequency {
                            Text("\(cachedCurrentStreak)w")
                                .font(.caption2)
                        } else {
                            Text("\(cachedCurrentStreak)")
                                .font(.caption2)
                        }
                    }
                    .foregroundStyle(.yellow)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                        if case .weeklyTarget = task.frequency {
                            Text("\(cachedCurrentStreak)w")
                                .font(.caption2)
                        } else {
                            Text("\(cachedCurrentStreak)")
                                .font(.caption2)
                        }
                    }
                    .foregroundStyle(streakGradient)
                }
            }
        }
        .onAppear {
            refreshTaskCache()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("TaskCompletionChanged"))) { _ in
            refreshTaskCache()
        }
        .sheet(isPresented: $showCheckIn) {
            TaskCheckInView(task: task)
                .onDisappear {
                    refreshTaskCache()
                }
        }
    }

    private func handleTaskTap() {
        if isTimeBased {
            // Time-based negative habits MUST use check-in for time input
            if isCompleted {
                // Allow unchecking by removing log
                toggleCompletion()
            } else {
                // Force check-in sheet for time input
                showCheckIn = true
            }
        } else {
            // Regular tasks can quick toggle
            toggleCompletion()
        }
    }

    private func toggleCompletion() {
        withAnimation(.spring(response: 0.3)) {
            let wasCompleted = isCompleted

            if isCompleted {
                // Remove today's log
                if let todayLog = task.logs?.first(where: { Calendar.current.isDateInToday($0.date) }) {
                    modelContext.delete(todayLog)
                }
            } else {
                // Add today's log
                let log = HabitTaskLog()
                log.task = task
                modelContext.insert(log)
            }

            do {
                try modelContext.save()
                isCompleted.toggle()

                // Trigger haptics
                if !wasCompleted {
                    // Completing a task - use appropriate celebration haptic
                    triggerAppropriateHaptic()
                } else {
                    // Unchecking a task - use light haptic
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred(intensity: 0.4)
                }

                // Notify dashboard to refresh stats
                NotificationCenter.default.post(name: Notification.Name("TaskCompletionChanged"), object: nil)

                // Refresh local cache
                refreshTaskCache()
            } catch {
                print("Error toggling task: \(error)")
            }
        }
    }

    private func triggerAppropriateHaptic() {
        // Check completion levels and trigger appropriate haptic
        let dailyStats = calculateDailyCompletion()
        let weeklyStats = calculateWeeklyCompletion()
        let systemStats = calculateSystemCompletion()

        // Level 5: Perfect day (both daily and weekly at 100%)
        if dailyStats.rate == 1.0 && weeklyStats.rate == 1.0 {
            hapticManager.perfectDayCompleted()
        }
        // Level 3: Daily goal completed
        else if dailyStats.rate == 1.0 {
            hapticManager.dailyGoalCompleted()
        }
        // Level 3: Weekly goal completed
        else if weeklyStats.rate == 1.0 {
            hapticManager.weeklyGoalCompleted()
        }
        // Level 2: System completed
        else if systemStats.rate == 1.0 {
            hapticManager.systemCompleted()
        }
        // Level 1: Single task completed
        else {
            hapticManager.taskCompleted()
        }
    }

    private func calculateSystemCompletion() -> (completed: Int, total: Int, rate: Double) {
        guard let system = task.system, let tasks = system.tasks else {
            return (0, 0, 0.0)
        }

        let today = Calendar.current.startOfDay(for: Date())
        var completed = 0
        var total = 0

        for t in tasks {
            if t.shouldBeCompletedOn(date: today) {
                total += 1
                if t.wasCompletedOn(date: today) {
                    completed += 1
                }
            }
        }

        let rate = total > 0 ? Double(completed) / Double(total) : 0.0
        return (completed, total, rate)
    }

    private func calculateDailyCompletion() -> (completed: Int, total: Int, rate: Double) {
        let today = Calendar.current.startOfDay(for: Date())
        var completed = 0
        var total = 0

        for system in allSystems {
            guard let tasks = system.tasks else { continue }
            for task in tasks {
                if task.shouldBeCompletedOn(date: today) {
                    total += 1
                    if task.wasCompletedOn(date: today) {
                        completed += 1
                    }
                }
            }
        }

        let rate = total > 0 ? Double(completed) / Double(total) : 0.0
        return (completed, total, rate)
    }

    private func calculateWeeklyCompletion() -> (completed: Int, total: Int, rate: Double) {
        let today = Date()
        var completedWeekly = 0
        var totalWeekly = 0

        for system in allSystems {
            guard let tasks = system.tasks else { continue }
            for task in tasks {
                if case .weeklyTarget(let times) = task.frequency {
                    totalWeekly += times
                    let completions = task.completionsInWeek(containing: today)
                    completedWeekly += min(completions, times)
                }
            }
        }

        let rate = totalWeekly > 0 ? Double(completedWeekly) / Double(totalWeekly) : 0.0
        return (completedWeekly, totalWeekly, rate)
    }
}

// MARK: - Celebration View
struct CelebrationView: View {
    let isWeekly: Bool
    @State private var isAnimating = false
    @Environment(MotionManager.self) private var motionManager

    private var celebrationEmoji: String {
        isWeekly ? "🏆" : "🎉"
    }

    private var celebrationTitle: String {
        isWeekly ? "Week Complete!" : "All Done!"
    }

    private var celebrationMessage: String {
        isWeekly ? "You crushed all your weekly goals!" : "You completed all your tasks today!"
    }

    var body: some View {
        ZStack {
            ForEach(0..<30, id: \.self) { index in
                ConfettiPiece(index: index)
            }

            // Success message
            VStack(spacing: 16) {
                Text(celebrationEmoji)
                    .font(.system(size: 80))
                    .scaleEffect(isAnimating ? 1.2 : 0.5)
                    .opacity(isAnimating ? 1.0 : 0.0)

                Text(celebrationTitle)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .opacity(isAnimating ? 1.0 : 0.0)

                Text(celebrationMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(isAnimating ? 1.0 : 0.0)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.5),
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: motionGradientPoints().start,
                            endPoint: motionGradientPoints().end
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
    }

    // MARK: - Motion-Reactive Shimmer Helper

    private func motionGradientPoints() -> (start: UnitPoint, end: UnitPoint) {
        let angle = motionManager.lightAngle.radians

        let lightX = (cos(angle) + 1.0) / 2.0
        let lightY = (sin(angle) + 1.0) / 2.0

        let startPoint = UnitPoint(x: lightX, y: lightY)

        let endX = 1.0 - lightX
        let endY = 1.0 - lightY
        let endPoint = UnitPoint(x: endX, y: endY)

        return (startPoint, endPoint)
    }
}

struct ConfettiPiece: View {
    let index: Int
    @State private var animate = false

    private var randomX: CGFloat {
        CGFloat.random(in: -200...200)
    }

    private var randomRotation: Double {
        Double.random(in: 0...360)
    }

    private var randomDelay: Double {
        Double.random(in: 0...0.3)
    }

    private var confettiColors: [Color] {
        [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    }

    private var randomColor: Color {
        confettiColors.randomElement() ?? .blue
    }

    var body: some View {
        Circle()
            .fill(randomColor)
            .frame(width: 10, height: 10)
            .offset(x: animate ? randomX : 0, y: animate ? 800 : -100)
            .rotationEffect(.degrees(animate ? randomRotation * 4 : randomRotation))
            .opacity(animate ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 2.5).delay(randomDelay)) {
                    animate = true
                }
            }
    }
}