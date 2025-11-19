# 🎮 Gamification Implementation Plan - Step by Step

## Overview
Implement gamification system incrementally, testing each step before moving forward.

---

## 📋 Phase 1: Foundation (Models & Database)

### ✅ Task 1.1: Create Achievement Model
**Time**: 15 min
**Files**: `Numu/Models/Achievement.swift`
- [x] Create Achievement.swift file
- [x] Define Achievement @Model class
- [x] Add properties: id, identifier, name, description, category, criteria, xpReward, badge, tier
- [x] Add progress tracking: isUnlocked, unlockedAt, progress
- [x] Add enums: AchievementCategory, AchievementTier
- [x] Add computed properties: progressPercentage, tierColor
**Deliverable**: Achievement model ready for database

### ✅ Task 1.2: Create UserProgress Model
**Time**: 15 min
**Files**: `Numu/Models/UserProgress.swift`
- [x] Create UserProgress.swift file
- [x] Define UserProgress @Model class
- [x] Add XP & level properties: totalXP, currentLevel
- [x] Add statistics: totalTasksCompleted, totalTestsCompleted, etc.
- [x] Add relationship to achievements
- [x] Implement level calculation logic: calculateLevel(), xpRequiredForLevel()
- [x] Add computed properties: levelProgress, levelTier, tierEmoji
**Deliverable**: UserProgress model with XP/level math

### ✅ Task 1.3: Create AchievementSeeder
**Time**: 20 min
**Files**: `Numu/Services/AchievementSeeder.swift`
- [x] Create AchievementSeeder.swift file
- [x] Implement seedAchievements() static method
- [x] Create all 40+ default achievements
- [x] Organize by category (Streaks, Systems, Tasks, Tests, Consistency, Special)
**Deliverable**: Seeder that creates all achievements

### ⏳ Task 1.4: Register Models in Schema
**Time**: 10 min
**Files**: `Numu/NumuApp.swift`
- [ ] Import Achievement and UserProgress
- [ ] Add to Schema definition
- [ ] Test app builds successfully
**Deliverable**: Models registered, app compiles

### ⏳ Task 1.5: Initialize UserProgress on First Launch
**Time**: 20 min
**Files**: `Numu/NumuApp.swift`
- [ ] Check if UserProgress exists in database
- [ ] If not, create new UserProgress instance
- [ ] Call AchievementSeeder to create achievements
- [ ] Link achievements to UserProgress
- [ ] Save to ModelContext
**Deliverable**: UserProgress + achievements created on first launch

### ⏳ Task 1.6: Test Database Setup
**Time**: 10 min
**Files**: N/A
- [ ] Delete app from simulator
- [ ] Run app fresh
- [ ] Verify UserProgress is created
- [ ] Verify 40+ achievements exist in database
- [ ] Check console logs for confirmation
**Deliverable**: Database properly initialized

---

## 📋 Phase 2: Basic XP System

### ⏳ Task 2.1: Create AchievementManager Service
**Time**: 30 min
**Files**: `Numu/Services/AchievementManager.swift`
- [ ] Create @Observable class AchievementManager
- [ ] Add ModelContext property
- [ ] Add UserProgress property
- [ ] Implement awardXP() method
- [ ] Detect level-ups and return new level
- [ ] Add logging for debugging
**Deliverable**: Service that can award XP

### ⏳ Task 2.2: Hook XP into Task Completion
**Time**: 20 min
**Files**: `Numu/Views/SystemsDashboardView.swift`, `Numu/Views/SystemDetailView.swift`
- [ ] Import AchievementManager
- [ ] Find task completion logic (toggleCompletion)
- [ ] Award 10 XP when task is completed
- [ ] Update UserProgress.totalTasksCompleted
- [ ] Save ModelContext
- [ ] Test by completing tasks
**Deliverable**: Tasks award XP when completed

### ⏳ Task 2.3: Display XP in UI (Simple)
**Time**: 15 min
**Files**: `Numu/Views/MainTabView.swift`
- [ ] Fetch UserProgress from ModelContext
- [ ] Add XP badge to navigation bar (e.g., "1,250 XP")
- [ ] Add level badge (e.g., "Lvl 12")
- [ ] Style with accent color
**Deliverable**: User can see their XP/level in app

### ⏳ Task 2.4: Test XP System
**Time**: 10 min
**Files**: N/A
- [ ] Complete several tasks
- [ ] Verify XP increases
- [ ] Complete enough tasks to level up
- [ ] Verify level increases
- [ ] Check console logs
**Deliverable**: XP system working end-to-end

---

## 📋 Phase 3: Achievement Detection

### ⏳ Task 3.1: Implement Streak Achievement Checking
**Time**: 30 min
**Files**: `Numu/Services/AchievementManager.swift`
- [ ] Add checkStreakAchievements(streak: Int) method
- [ ] Fetch relevant achievements (first_steps, week_warrior, etc.)
- [ ] Update progress for each
- [ ] Check if criteria met
- [ ] Mark as unlocked if met
- [ ] Award XP bonus
- [ ] Return list of newly unlocked achievements
**Deliverable**: Streak achievements can be unlocked

### ⏳ Task 3.2: Hook Streak Checking into App
**Time**: 20 min
**Files**: `Numu/Views/SystemsDashboardView.swift`, `Numu/Views/SystemDetailView.swift`
- [ ] After task completion, get user's current streak
- [ ] Call achievementManager.checkStreakAchievements()
- [ ] Store newly unlocked achievements
**Deliverable**: Streak achievements unlock automatically

### ⏳ Task 3.3: Implement Task Count Achievement Checking
**Time**: 20 min
**Files**: `Numu/Services/AchievementManager.swift`
- [ ] Add checkTaskAchievements(totalTasks: Int) method
- [ ] Check task_master, century_of_tasks, thousand_strong
- [ ] Update progress and unlock logic
**Deliverable**: Task count achievements work

### ⏳ Task 3.4: Implement System Achievement Checking
**Time**: 30 min
**Files**: `Numu/Services/AchievementManager.swift`, `Numu/Views/CreateSystemView.swift`
- [ ] Add checkSystemAchievements(totalSystems: Int) method
- [ ] Hook into system creation
- [ ] Update UserProgress.totalSystemsCreated
- [ ] Check system_builder, multi_tasker, etc.
**Deliverable**: System achievements unlock on creation

### ⏳ Task 3.5: Test Achievement Unlocking
**Time**: 15 min
**Files**: N/A
- [ ] Complete 1 task → should unlock "First Steps"
- [ ] Complete 7-day streak → should unlock "Week Warrior"
- [ ] Create system → should unlock "System Builder"
- [ ] Verify achievements marked as unlocked in database
**Deliverable**: Achievements unlock correctly

---

## 📋 Phase 4: Achievements Gallery UI

### ⏳ Task 4.1: Create AchievementCardView Component
**Time**: 45 min
**Files**: `Numu/Views/Components/AchievementCardView.swift`
- [ ] Create SwiftUI view for achievement card
- [ ] Show badge emoji
- [ ] Show name and description
- [ ] Show progress bar (if locked)
- [ ] Show "Unlocked!" badge (if unlocked)
- [ ] Show XP reward
- [ ] Style with tier color
- [ ] Add locked/unlocked states
**Deliverable**: Reusable achievement card component

### ⏳ Task 4.2: Create AchievementsGalleryView
**Time**: 1 hour
**Files**: `Numu/Views/AchievementsGalleryView.swift`
- [ ] Create main gallery view
- [ ] Fetch all achievements from UserProgress
- [ ] Add category filter tabs (All, Streaks, Systems, etc.)
- [ ] Create grid layout (2 columns)
- [ ] Sort: unlocked first, then by progress
- [ ] Add search bar
- [ ] Show stats header (X/40 unlocked)
**Deliverable**: Full achievements gallery screen

### ⏳ Task 4.3: Add Achievements to Settings Tab
**Time**: 15 min
**Files**: `Numu/Views/MainTabView.swift` or create `SettingsView.swift`
- [ ] Add navigation link to AchievementsGalleryView
- [ ] Add icon (trophy icon)
- [ ] Add badge showing unlocked count
**Deliverable**: User can navigate to achievements

### ⏳ Task 4.4: Test Gallery UI
**Time**: 10 min
**Files**: N/A
- [ ] Navigate to achievements gallery
- [ ] Verify all achievements shown
- [ ] Test category filtering
- [ ] Verify locked/unlocked states display correctly
- [ ] Test search functionality
**Deliverable**: Gallery UI working smoothly

---

## 📋 Phase 5: Profile & Stats Display

### ⏳ Task 5.1: Create UserProfileView
**Time**: 1 hour
**Files**: `Numu/Views/UserProfileView.swift`
- [ ] Create profile header with level badge
- [ ] Show tier (Bronze Beginner, Silver Intermediate, etc.)
- [ ] Display XP progress bar to next level
- [ ] Show statistics (tasks completed, tests, streaks, etc.)
- [ ] Show achievement count (12/40 unlocked)
- [ ] List recent achievements (last 5)
**Deliverable**: Profile screen showing all stats

### ⏳ Task 5.2: Add Profile to Settings Tab
**Time**: 10 min
**Files**: `Numu/Views/MainTabView.swift` or `SettingsView.swift`
- [ ] Add navigation to UserProfileView
- [ ] Add user icon
**Deliverable**: Profile accessible from app

### ⏳ Task 5.3: Display Level Badge in Navigation
**Time**: 20 min
**Files**: `Numu/Views/SystemsDashboardView.swift`
- [ ] Add level badge to navigation bar
- [ ] Show tier emoji + level number
- [ ] Make tappable → navigates to profile
- [ ] Add subtle animation
**Deliverable**: Level always visible in app

---

## 📋 Phase 6: Notifications & Animations

### ⏳ Task 6.1: Create Achievement Unlock Notification
**Time**: 1 hour
**Files**: `Numu/Views/Components/AchievementUnlockNotification.swift`
- [ ] Create slide-down notification view
- [ ] Show achievement badge, name, XP reward
- [ ] Add appear/disappear animations
- [ ] Auto-dismiss after 3 seconds
- [ ] Add haptic feedback
- [ ] Make tappable → navigates to achievements
**Deliverable**: Beautiful unlock notification

### ⏳ Task 6.2: Create Level-Up Notification
**Time**: 45 min
**Files**: `Numu/Views/Components/LevelUpNotification.swift`
- [ ] Create full-screen/large notification
- [ ] Show new level and tier
- [ ] Add particle/confetti animation
- [ ] Play celebration sound (optional)
- [ ] Show XP progress bar
**Deliverable**: Epic level-up notification

### ⏳ Task 6.3: Integrate Notifications into App
**Time**: 30 min
**Files**: `Numu/Views/SystemsDashboardView.swift`, `AchievementManager.swift`
- [ ] After achievement unlocks, show notification
- [ ] After level-up, show notification
- [ ] Queue multiple notifications if needed
- [ ] Track shown notifications (don't show twice)
**Deliverable**: Notifications appear when unlocking

### ⏳ Task 6.4: Add Confetti Animation
**Time**: 30 min
**Files**: `Numu/Views/Components/ConfettiView.swift`
- [ ] Create confetti particle effect
- [ ] Trigger on milestone achievements
- [ ] Add to level-up notification
**Deliverable**: Celebratory visual effects

---

## 📋 Phase 7: Integration & Polish

### ⏳ Task 7.1: Show XP Earned on Task Completion
**Time**: 20 min
**Files**: `Numu/Views/SystemsDashboardView.swift`
- [ ] After task completion, show "+10 XP" toast
- [ ] Animate number appearing
- [ ] Fade out after 1 second
**Deliverable**: Visual feedback for XP earning

### ⏳ Task 7.2: Add Achievement Progress Hints
**Time**: 30 min
**Files**: `Numu/Views/SystemsDashboardView.swift`
- [ ] On dashboard, show "Next achievement: Week Warrior (5/7 days)"
- [ ] Show closest achievement to unlocking
- [ ] Make tappable → navigates to achievements
**Deliverable**: Users know what to aim for

### ⏳ Task 7.3: Perfect Day Bonus Detection
**Time**: 30 min
**Files**: `Numu/Services/AchievementManager.swift`
- [ ] After task completion, check if all tasks in system are complete
- [ ] Award "Perfect Day" bonus XP
- [ ] Show special notification
**Deliverable**: Perfect day bonus working

### ⏳ Task 7.4: Time-Based Achievement Tracking
**Time**: 30 min
**Files**: `Numu/Services/AchievementManager.swift`
- [ ] Check task completion time
- [ ] If before 8am, increment earlyBirdCount
- [ ] If after 10pm, increment nightOwlCount
- [ ] Check early_bird and night_owl achievements
**Deliverable**: Time-based achievements work

### ⏳ Task 7.5: Performance Test Achievement Tracking
**Time**: 30 min
**Files**: `Numu/Views/SystemDetailView.swift` (wherever tests are logged)
- [ ] On test completion, award XP
- [ ] Increment totalTestsCompleted
- [ ] Check if new personal record
- [ ] Award bonus XP for PR
- [ ] Check test achievements
**Deliverable**: Test achievements unlockable

---

## 📋 Phase 8: Testing & Bug Fixes

### ⏳ Task 8.1: End-to-End Testing
**Time**: 1 hour
**Files**: N/A
- [ ] Delete app and start fresh
- [ ] Create system → verify system_builder unlocks
- [ ] Complete task → verify XP awarded
- [ ] Complete 7 tasks → verify week_warrior unlocks
- [ ] Level up → verify notification shows
- [ ] Check all UI screens work
**Deliverable**: Full flow tested

### ⏳ Task 8.2: Edge Case Testing
**Time**: 30 min
**Files**: N/A
- [ ] Test with 0 tasks completed
- [ ] Test with very high XP (level 50+)
- [ ] Test unlocking multiple achievements at once
- [ ] Test CloudKit sync with achievements
**Deliverable**: Edge cases handled

### ⏳ Task 8.3: Performance Testing
**Time**: 20 min
**Files**: N/A
- [ ] Test with 100+ task completions
- [ ] Verify achievement checking is fast
- [ ] Verify UI remains responsive
**Deliverable**: No performance issues

### ⏳ Task 8.4: Bug Fixes
**Time**: Variable
**Files**: Various
- [ ] Fix any bugs found during testing
- [ ] Polish animations
- [ ] Adjust XP values if needed
**Deliverable**: Polished, bug-free gamification

---

## 📊 Summary

**Total Tasks**: 39 tasks across 8 phases
**Estimated Time**: 18-20 hours
**Current Status**: Phase 1 - Tasks 1.1, 1.2, 1.3 complete ✅

---

## ⏭️ NEXT IMMEDIATE TASK

**Task 1.4: Register Models in Schema**
- Files to modify: `Numu/NumuApp.swift`
- Import Achievement and UserProgress
- Add to Schema definition
- Test that app builds

Let's implement this task now! 🚀
