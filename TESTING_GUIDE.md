# Numu App - Comprehensive Testing Guide

This guide walks you through testing your app like a real user while also validating performance and stability.

---

## Build Configuration

### Which Scheme to Use?

**Use the DEBUG scheme** (this is the default when running from Xcode)

**Why?**
- All stress testing tools are only available in DEBUG builds (`#if DEBUG`)
- Performance monitoring is enabled
- You get detailed console logs for debugging
- Debug menu is accessible

**How to verify:**
1. In Xcode, click the scheme selector (next to the Run/Stop buttons)
2. Should say "Numu" with a DEBUG configuration
3. When you run the app, you'll see detailed logs in the console

---

## Testing Strategy Overview

We'll use a **3-phase approach**:

### Phase 1: Quick Validation (15 minutes)
Basic smoke test to ensure core features work

### Phase 2: Realistic User Simulation (30-60 minutes)
Act like a real user over several weeks/months

### Phase 3: Stress & Performance Testing (30 minutes)
Push the app to its limits

---

## PHASE 1: Quick Validation (Smoke Test)

**Goal:** Verify all core features work before detailed testing

### 1.1 Build & Launch
```bash
# In terminal, from your project directory:
xcodebuild -scheme Numu -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build
```

Or simply **⌘R in Xcode** to run on simulator.

### 1.2 Check App Launch
- ✅ App launches without crashes
- ✅ Console shows initialization logs:
  ```
  🚀 [NUMU] App initialization started
  ✅ [SUCCESS] ModelContainer initialized!
  ```
- ✅ Main tab view loads with 4 tabs: Systems, Analytics, Calendar, Settings

### 1.3 Quick Feature Check

**Systems Tab:**
- [ ] Tap "+" to create a new system
- [ ] Fill in name, category, color, icon
- [ ] Add at least one task
- [ ] Complete the task (check button should work)
- [ ] View system detail

**Calendar Tab:**
- [ ] Calendar loads without errors
- [ ] Can navigate between months
- [ ] Heat map displays (even if empty initially)

**Analytics Tab:**
- [ ] Charts render (may be empty if no data)
- [ ] No crashes when opening

**Settings Tab:**
- [ ] Can access debug menu (should be visible in DEBUG)
- [ ] Settings load properly

**If all items above work, proceed to Phase 2.**

---

## PHASE 2: Realistic User Simulation

**Goal:** Test the app as a real user would use it over time

### 2.1 Generate Test Data Foundation

This gives you realistic historical data to work with:

1. **Open Debug Menu:**
   - Go to Settings tab
   - Tap "Debug Menu"

2. **Generate Basic Test Data:**
   - Tap "Generate Test Data"
   - Wait for completion
   - Exit back to Systems tab

3. **What this creates:**
   - 5 systems with different patterns
   - Mix of daily, weekly, and flexible tasks
   - Historical data showing streaks, misses, recoveries
   - Calendar heat map with green/yellow/red weeks

### 2.2 Navigate & Interact Like a Real User

**Test Navigation Flow:**
1. Systems Tab → Tap a system → View details
2. Scroll through tasks
3. Tap a task → Complete it
4. Go to Calendar → Look at today
5. Go back to Systems
6. Create a new system from scratch
7. Add multiple tasks to it

**Test Task Completion Workflow:**
1. Find "🧪 Perfect Athlete" system
2. Complete all tasks (they should all be incomplete today)
3. **Expected:** 🎉 celebration when 100% complete
4. Check if streak updates correctly

**Test "Never Miss Twice" Logic:**
1. Find "🧪 Never Miss Twice Demo" system
2. Look for tasks with ⚠️ (at-risk streak)
3. Complete the at-risk task
4. **Expected:** Streak should recover (no longer at-risk)
5. Leave one at-risk task incomplete for a day
6. **Expected:** Streak breaks after second consecutive miss

**Test Weekly Goals:**
1. Find "🧪 Weekly Goals" system
2. Complete one weekly task (e.g., "🏋️ Gym Session" - shows "2/3 this week")
3. **Expected:** Progress updates to "3/3 this week"
4. **Expected:** 🏆 celebration when weekly target is met

**Test Calendar Heat Map:**
1. Go to Calendar tab
2. Navigate to previous months
3. **Expected:**
   - Green weeks (80-100% completion)
   - Yellow weeks (50-79% completion)
   - Red weeks (0-49% completion)
4. Tap on a day → Should show tasks for that day
5. Tap on a week → Should show weekly summary

**Test Analytics:**
1. Go to Analytics tab
2. View streak charts
3. View completion rate trends
4. View system consistency
5. **Expected:** Charts render smoothly with test data

### 2.3 Create Your Own Realistic System

Now act like a real user setting up their habit tracking:

**Scenario: "Morning Routine" System**

1. **Create System:**
   - Name: "Early Riser"
   - Category: Lifestyle
   - Add description: "Morning routine to start the day right"
   - Choose color and icon

2. **Add Tasks:**
   - "Wake up at 6am" (Daily)
   - "Meditate 10min" (Daily)
   - "Gym" (Weekly target: 3x)
   - "Meal prep" (Specific days: Sun, Wed)

3. **Complete Tasks Today:**
   - Mark "Wake up at 6am" as complete
   - Mark "Meditate 10min" as complete
   - Add notes/satisfaction ratings

4. **Go Back Tomorrow (Simulate Time Passing):**
   - You can't actually change the date, but note:
   - What would happen if you missed "Wake up at 6am" tomorrow?
   - The streak logic should handle it gracefully

### 2.4 Test Edge Cases Manually

**Rapid Completions:**
- Complete the same task multiple times rapidly
- **Expected:** UI updates smoothly, no crashes

**Delete While Viewing:**
- Open a task detail view
- Delete the task
- **Expected:** Graceful handling, no crash

**System Deletion:**
- Delete a system with many tasks
- **Expected:** All related tasks and logs deleted (cascade)

**Empty States:**
- Create a brand new system with no tasks
- **Expected:** Proper empty state UI

---

## PHASE 3: Stress & Performance Testing

**Goal:** Validate app performance under extreme conditions

### 3.1 Start Performance Monitoring

1. **Open Debug Menu**
2. **Navigate to Performance Monitor:**
   - Tap "Performance Monitor"
3. **Start Monitoring:**
   - Tap "Start" to begin real-time tracking
4. **Leave it running** during all stress tests

### 3.2 Run Performance Benchmark (Baseline)

**Before adding heavy data, get a baseline:**

1. In Debug Menu → Performance section
2. Tap "Run Performance Benchmark"
3. **Record the results:**
   - Streak Calculation: _____ ms
   - Completion Rate: _____ ms
   - Weekly Completions: _____ ms
   - System Consistency: _____ ms
   - Query Performance: _____ ms
   - **Grade:** _____

**Expected baseline (with test data only):**
- All operations < 50ms
- Grade: A+ or A

### 3.3 Run Automated Stress Tests

**Test 1: Light Stress Test (1 month of data)**

1. In Debug Menu → Stress Testing section
2. Select "Light (1 month)"
3. Tap "Run Stress Test"
4. **Watch progress bar** (should complete in 10-30 seconds)
5. **Verify:**
   - Console shows completion message
   - Systems tab now has 10 new systems (marked with 🔥)
   - App remains responsive

**Test 2: Medium Stress Test (6 months of data)**

1. Select "Medium (6 months)"
2. Expected: ~25 systems, ~150 tasks, ~3,000 logs
3. This will take **1-3 minutes**
4. **While running:**
   - Check Performance Monitor for memory spikes
   - Verify frame rate stays > 50 FPS
5. **After completion:**
   - Navigate to Calendar tab
   - Scroll through 6 months of data
   - **Expected:** Smooth scrolling, no lag

**Test 3: Heavy Stress Test (1 year of data)** ⚠️

1. Select "Heavy (1 year)"
2. Expected: ~50 systems, ~300 tasks, ~15,000 logs
3. This will take **5-10 minutes**
4. **Monitor:**
   - Memory usage (should stay < 300MB)
   - App responsiveness
   - No crashes
5. **After completion:**
   - Run Performance Benchmark again
   - Compare to baseline
   - **Acceptable:** 2-3x slower than baseline
   - **Concerning:** 10x+ slower than baseline

**Test 4: Extreme Stress Test (2 years)** ⚠️ ONLY IF NEEDED

1. Select "Extreme (2 years)"
2. Expected: ~100 systems, ~500 tasks, ~50,000 logs
3. This will take **15-30 minutes**
4. **Warning:** This simulates a user who has been tracking obsessively for 2 years
5. Use this to find breaking points

### 3.4 Edge Case Stress Tests

**Rapid Operations Test:**
1. In Debug Menu → Stress Testing
2. Tap "Test Rapid Operations"
3. **Expected:**
   - Creates 50 tasks instantly
   - Completes all 50 tasks instantly
   - No crashes or UI freezes
4. **Check console** for any errors

**Week Boundary Test:**
1. Tap "Test Week Boundaries"
2. **Expected:**
   - Creates tasks with completions on week boundaries
   - Streak calculations handle Sunday/Monday transitions correctly
3. **Verify:** Check console output for streak count

**Streak Edge Cases Test:**
1. Tap "Test Streak Edge Cases"
2. **Expected:** Creates 3 tasks:
   - Alternating misses (streak ~5)
   - Grace day test (streak ~20)
   - Broken streak (streak 0-3)
3. **Verify in Systems tab:**
   - Find "🔥 Streak Test System"
   - Check each task's streak matches expectations

### 3.5 Performance Validation

**Run Health Check:**
1. Go to Performance Monitor
2. Tap "Run System Health Check"
3. **Review results:**
   - Overall Health: Should be ✅ Healthy or ⚠️ Moderate
   - Memory Status: < 200MB = healthy
   - Frame Rate: > 50 FPS = healthy
   - Slow Operations: < 3 = healthy
   - Performance Grade: B or higher = acceptable

**Review Performance Logs:**
1. Scroll to "Performance Logs" section
2. Look for operations > 100ms (red)
3. **Common slow operations:**
   - System consistency calculations (acceptable if < 200ms)
   - Large query fetches (acceptable if < 100ms)

**Test UI Rendering Under Load:**
1. With heavy stress data loaded:
   - Go to Systems tab
   - Scroll rapidly up and down
   - **Expected:** Smooth 60fps scrolling
2. Go to Calendar tab
   - Swipe between months rapidly
   - **Expected:** No lag, smooth transitions
3. Go to Analytics tab
   - Charts should render within 1-2 seconds

---

## PHASE 4: CloudKit Sync Testing (Optional)

If you want to test CloudKit sync:

### 4.1 Setup
1. Run app on two devices (or simulator + device)
2. Sign in with same iCloud account on both

### 4.2 Test Sync
1. **Device 1:** Create a system and tasks
2. **Wait 10-30 seconds** for CloudKit to sync
3. **Device 2:** Pull to refresh or relaunch app
4. **Expected:** New system appears on Device 2

### 4.3 Test Conflict Resolution
1. **Turn off WiFi on both devices**
2. **Device 1:** Create "System A"
3. **Device 2:** Create "System B"
4. **Turn WiFi back on**
5. **Expected:** Both systems appear on both devices (no data loss)

---

## What to Look For (Red Flags)

### Critical Issues (Must Fix)
- ❌ **App crashes** at any point
- ❌ **Data loss** (deleted items reappear or vice versa)
- ❌ **Incorrect calculations** (streaks, completion rates wildly wrong)
- ❌ **Memory leaks** (memory usage keeps growing without bound)
- ❌ **Complete UI freeze** (app becomes unresponsive for > 5 seconds)

### Performance Issues (Should Fix)
- ⚠️ **Frame rate < 30 FPS** consistently
- ⚠️ **Memory usage > 500MB** on moderate data
- ⚠️ **Slow operations > 500ms** for basic calculations
- ⚠️ **Slow scrolling** or laggy animations
- ⚠️ **Long load times** (> 3 seconds to open a view)

### Minor Issues (Nice to Fix)
- 🔸 **Occasional frame drops** (< 50 FPS briefly)
- 🔸 **Memory spikes** during data generation (temporary)
- 🔸 **UI quirks** (misaligned elements, wrong colors)
- 🔸 **Console warnings** (non-critical)

---

## Cleanup After Testing

### Clear Stress Test Data
1. Open Debug Menu
2. Tap "Clear Stress Test Data" (removes 🔥 systems)
3. Confirm deletion
4. **Note:** This keeps your real data and 🧪 test data

### Clear All Test Data
1. Tap "Clear All Test Data" (removes 🧪 systems)
2. Confirm deletion
3. **Note:** This keeps your real systems

### Complete Reset (Start Fresh)
If you want to wipe everything:
1. Delete app from simulator/device
2. Reinstall
3. Fresh start with no data

---

## Testing Checklist

Print this out and check off as you go:

### Phase 1: Smoke Test
- [ ] App builds and launches
- [ ] Can create a system
- [ ] Can add tasks
- [ ] Can complete tasks
- [ ] All 4 tabs load

### Phase 2: User Simulation
- [ ] Generated basic test data
- [ ] Tested task completion workflow
- [ ] Verified 100% celebration
- [ ] Tested "Never Miss Twice" logic
- [ ] Tested weekly goals
- [ ] Calendar heat map works
- [ ] Analytics charts render
- [ ] Created custom system
- [ ] Tested edge cases (delete, rapid actions)

### Phase 3: Stress Testing
- [ ] Started performance monitoring
- [ ] Ran baseline benchmark (Grade: ____)
- [ ] Light stress test passed
- [ ] Medium stress test passed
- [ ] Heavy stress test passed (optional)
- [ ] Extreme stress test passed (optional)
- [ ] Rapid operations test passed
- [ ] Week boundary test passed
- [ ] Streak edge cases test passed
- [ ] Health check results acceptable
- [ ] UI remains responsive under load

### Phase 4: CloudKit (Optional)
- [ ] Data syncs between devices
- [ ] Conflict resolution works
- [ ] No data loss during sync

### Final Validation
- [ ] No critical issues found
- [ ] Performance acceptable
- [ ] App ready for real use

---

## Interpreting Results

### Performance Grades Explained

**Benchmark Results:**
- **A+ (< 100ms total):** Excellent - production ready
- **A (100-250ms):** Great - very usable
- **B (250-500ms):** Good - acceptable for most users
- **C (500-1000ms):** Fair - may feel sluggish
- **D (> 1000ms):** Needs optimization

**Health Check Grades:**
- **A+ (Excellent):** Perfect, no issues
- **A (Great):** Minor issues, nothing concerning
- **B (Good):** Some performance degradation under load
- **C (Fair):** Noticeable slowdowns, should optimize
- **D (Needs Improvement):** Significant performance problems

### Data Scale Reference

**Real-world usage estimates:**
- **Light user (1-3 months):** ~500-1,500 logs
- **Regular user (6-12 months):** ~3,000-15,000 logs
- **Power user (1-2 years):** ~15,000-50,000 logs
- **Extreme user (2+ years):** 50,000+ logs

Most users will be in the "Regular" category.

---

## Next Steps After Testing

### If Everything Passed ✅
1. Clear test data
2. Start using the app with real systems
3. Monitor performance in production
4. Collect user feedback

### If Issues Found ⚠️
1. Document the issue (screenshot, console logs)
2. Note which test caused it
3. Note the data scale (how many systems/tasks/logs)
4. Create a GitHub issue or fix it
5. Re-test after fixing

---

## Questions?

Common questions:

**Q: How long should testing take?**
A: 1-2 hours for comprehensive testing. 15 min for smoke test only.

**Q: Can I run this on a real device?**
A: Yes! Performance will likely be better than simulator.

**Q: What if memory usage is high?**
A: iOS will manage memory. Only worry if app crashes or exceeds 500MB consistently.

**Q: Should I test in Release mode too?**
A: Yes, eventually. Release builds are faster. But DEBUG is better for testing since you get logs and debug tools.

**Q: How often should I stress test?**
A: After major changes, or before releasing a new version.

---

Good luck with testing! 🚀
