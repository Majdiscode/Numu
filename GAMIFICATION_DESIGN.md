# 🏆 Numu Gamification System Design

## Overview
Transform habit tracking into an engaging game with achievements, XP, levels, and visual rewards.

---

## 🎖️ Achievement System

### Achievement Categories

#### 1. **Streak Achievements** 🔥
| Achievement | Criteria | XP Reward | Badge |
|-------------|----------|-----------|-------|
| First Steps | Complete 1 day streak | 10 | 🌱 |
| Week Warrior | Complete 7 day streak | 50 | 💪 |
| Month Master | Complete 30 day streak | 200 | ⭐ |
| Century Club | Complete 100 day streak | 1000 | 💎 |
| Year Legend | Complete 365 day streak | 5000 | 👑 |
| Unbreakable | Complete 500 day streak | 10000 | 🏆 |

**Weekly Streak Variants:**
| Achievement | Criteria | XP Reward | Badge |
|-------------|----------|-----------|-------|
| Weekly Habit | Complete 4 weeks of weekly target | 100 | 📅 |
| Consistent Climber | Complete 12 weeks of weekly target | 500 | ⛰️ |

#### 2. **System Achievements** 🎯
| Achievement | Criteria | XP Reward | Badge |
|-------------|----------|-----------|-------|
| System Builder | Create first system | 25 | 🏗️ |
| Multi-Tasker | Create 3 systems | 75 | 🎨 |
| Life Designer | Create 5 systems | 150 | 🌟 |
| Master Architect | Create 10 systems | 500 | 🏛️ |
| Perfect Day | Complete all tasks in a system (1 day) | 50 | ✨ |
| Perfect Week | Complete all tasks in a system (7 days) | 250 | 🌈 |
| System Champion | Reach 90% consistency in any system | 300 | 🥇 |

#### 3. **Task Achievements** ✅
| Achievement | Criteria | XP Reward | Badge |
|-------------|----------|-----------|-------|
| Task Master | Complete 10 tasks total | 20 | ✔️ |
| Century of Tasks | Complete 100 tasks total | 100 | 💯 |
| Thousand Strong | Complete 1000 tasks total | 1000 | 🎯 |
| Early Bird | Complete task before 8am (10 times) | 100 | 🐦 |
| Night Owl | Complete task after 10pm (10 times) | 100 | 🦉 |
| Weekend Warrior | Complete all weekend tasks (4 weeks) | 200 | 🎉 |
| Weekday Champion | Perfect weekdays (4 weeks) | 200 | 💼 |

#### 4. **Performance Test Achievements** 📈
| Achievement | Criteria | XP Reward | Badge |
|-------------|----------|-----------|-------|
| First Test | Complete first performance test | 20 | 🧪 |
| Baseline Builder | Complete 5 performance tests | 75 | 📊 |
| Progress Tracker | Complete same test 3 times | 50 | 📈 |
| Personal Record | Beat your previous best | 100 | 🥇 |
| Improvement Streak | Improve 3 tests in a row | 200 | ⬆️ |
| All-Time Best | Hold 5 personal records | 500 | 👑 |

#### 5. **Consistency Achievements** 📊
| Achievement | Criteria | XP Reward | Badge |
|-------------|----------|-----------|-------|
| Habit Starter | 50% consistency for 1 week | 25 | 🌱 |
| Getting There | 70% consistency for 2 weeks | 75 | 🌿 |
| Solid Foundation | 80% consistency for 1 month | 200 | 🌳 |
| Elite Performer | 90% consistency for 1 month | 500 | 🌲 |
| Perfection | 100% consistency for 1 week | 300 | 💎 |

#### 6. **Special Achievements** 🎁
| Achievement | Criteria | XP Reward | Badge |
|-------------|----------|-----------|-------|
| Comeback Kid | Return after 7+ day break | 50 | 🔄 |
| Habit Breaker | Complete 30 days of negative habit | 300 | 🚫 |
| Time Reducer | Reduce negative habit to target | 500 | ⏰ |
| Atomic Habits | Fill all 4 Laws for a task | 100 | 📚 |
| Organized | Set cue time for 5 tasks | 75 | ⏰ |
| Social Butterfly | Share a system (future) | 50 | 🦋 |

---

## ⚡ XP & Leveling System

### XP Sources
| Action | XP Earned | Notes |
|--------|-----------|-------|
| Complete positive task | 10 XP | Daily task |
| Complete weekly target task | 15 XP | Harder to maintain |
| Stay under limit (negative habit) | 10 XP | Breaking bad habits |
| Complete performance test | 25 XP | Requires effort |
| Beat personal record | 50 XP | Bonus for improvement |
| Maintain streak (per day) | 5 XP | Consistency bonus |
| Complete all daily tasks | 25 XP | Perfect day bonus |
| Unlock achievement | Varies | Based on achievement |

### Level Progression Curve
```
Level 1: 0 XP (Starting)
Level 2: 100 XP
Level 3: 250 XP
Level 4: 500 XP
Level 5: 1,000 XP
Level 10: 5,000 XP
Level 20: 25,000 XP
Level 50: 250,000 XP
Level 100: 1,000,000 XP
```

**Formula**: `XP_for_level_N = 50 * N^1.5`

### Level Tiers & Titles
| Level Range | Tier | Title | Color |
|-------------|------|-------|-------|
| 1-9 | Bronze | Beginner | 🟤 Bronze |
| 10-24 | Silver | Intermediate | ⚪ Silver |
| 25-49 | Gold | Advanced | 🟡 Gold |
| 50-99 | Platinum | Expert | 💠 Platinum |
| 100+ | Diamond | Master | 💎 Diamond |

---

## 🎨 Visual Design Elements

### Achievement Cards
```swift
┌──────────────────────────────┐
│  🔥                          │
│  Week Warrior                │
│  Complete a 7-day streak     │
│                              │
│  ▓▓▓▓▓▓▓░░░ 7/7 days        │
│  +50 XP                      │
└──────────────────────────────┘
   Unlocked! ✨

┌──────────────────────────────┐
│  🔒                          │
│  Month Master                │
│  Complete a 30-day streak    │
│                              │
│  ░░░░░░░░░░ 12/30 days       │
│  +200 XP                     │
└──────────────────────────────┘
   Locked (40% progress)
```

### Level Progress Bar
```
Level 12 - Silver Intermediate ⚪
▓▓▓▓▓▓▓▓░░░░░░░░░░░ 1,250 / 2,500 XP
```

### Achievement Notification
```
┌─────────────────────────────────┐
│         🎉 Achievement!         │
│                                 │
│            🔥                   │
│       Week Warrior              │
│                                 │
│   You completed a 7-day streak! │
│         +50 XP earned           │
└─────────────────────────────────┘
```

---

## 💾 Data Models

### Achievement Model
```swift
@Model
final class Achievement {
    var id: UUID = UUID()
    var identifier: String  // "week_warrior_7"
    var name: String        // "Week Warrior"
    var description: String // "Complete a 7-day streak"
    var category: AchievementCategory
    var criteria: Int       // 7 for week warrior
    var xpReward: Int       // 50
    var badge: String       // "💪"
    var tier: AchievementTier  // bronze/silver/gold/platinum/diamond

    var isUnlocked: Bool = false
    var unlockedAt: Date?
    var progress: Int = 0   // Current progress toward achievement

    enum AchievementCategory: String, Codable {
        case streak, system, task, test, consistency, special
    }

    enum AchievementTier: String, Codable {
        case bronze, silver, gold, platinum, diamond
    }
}
```

### UserProgress Model
```swift
@Model
final class UserProgress {
    var id: UUID = UUID()

    // XP & Levels
    var totalXP: Int = 0
    var currentLevel: Int = 1
    var xpToNextLevel: Int = 100

    // Statistics for achievement tracking
    var totalTasksCompleted: Int = 0
    var totalTestsCompleted: Int = 0
    var longestStreak: Int = 0
    var totalSystemsCreated: Int = 0
    var perfectDaysCount: Int = 0
    var perfectWeeksCount: Int = 0

    // Time-based statistics
    var earlyBirdCount: Int = 0  // Tasks before 8am
    var nightOwlCount: Int = 0   // Tasks after 10pm

    // Achievements
    @Relationship(deleteRule: .cascade)
    var achievements: [Achievement]?

    // Recently unlocked (for displaying notifications)
    var recentlyUnlocked: [UUID] = []

    var levelTier: String {
        switch currentLevel {
        case 1..<10: return "Bronze Beginner"
        case 10..<25: return "Silver Intermediate"
        case 25..<50: return "Gold Advanced"
        case 50..<100: return "Platinum Expert"
        default: return "Diamond Master"
        }
    }

    var tierColor: String {
        switch currentLevel {
        case 1..<10: return "brown"
        case 10..<25: return "gray"
        case 25..<50: return "yellow"
        case 50..<100: return "cyan"
        default: return "purple"
        }
    }
}
```

### XPTransaction Model (Optional - for history)
```swift
@Model
final class XPTransaction {
    var id: UUID = UUID()
    var date: Date = Date()
    var amount: Int  // XP earned
    var source: XPSource
    var description: String  // "Completed task: Run"

    enum XPSource: String, Codable {
        case taskCompletion
        case weeklyTargetMet
        case negativeHabitSuccess
        case performanceTest
        case personalRecord
        case streakBonus
        case perfectDay
        case achievement
    }
}
```

---

## 🔧 Core Systems

### 1. Achievement Manager
```swift
@Observable
class AchievementManager {
    private let modelContext: ModelContext
    private let userProgress: UserProgress

    // Check for newly unlocked achievements
    func checkAchievements(after action: UserAction)

    // Specific achievement checks
    func checkStreakAchievements(currentStreak: Int)
    func checkTaskAchievements(totalCompleted: Int)
    func checkSystemAchievements()
    func checkTestAchievements()

    // Award XP and handle level-ups
    func awardXP(_ amount: Int, source: XPSource, description: String)
    func calculateLevel(from xp: Int) -> Int
    func xpRequiredForLevel(_ level: Int) -> Int
}
```

### 2. Notification System
```swift
struct AchievementNotification: View {
    let achievement: Achievement
    @State private var isPresented = false

    var body: some View {
        // Slide down from top with confetti animation
        // Auto-dismiss after 3 seconds
        // Tap to view in achievements gallery
    }
}

struct LevelUpNotification: View {
    let newLevel: Int
    let tier: String

    var body: some View {
        // Dramatic level-up animation
        // Show new tier unlocked
        // Display level progress
    }
}
```

### 3. Achievement Initialization
```swift
class AchievementSeeder {
    static func createDefaultAchievements(context: ModelContext) {
        // Create all predefined achievements on first launch
        // Save to database for tracking
    }
}
```

---

## 🎯 Implementation Steps

### Phase 1: Foundation (Week 1)
- [x] Design achievement categories and list
- [ ] Create Achievement model
- [ ] Create UserProgress model
- [ ] Create XPTransaction model (optional)
- [ ] Implement AchievementManager
- [ ] Seed default achievements on first launch

### Phase 2: XP System (Week 1-2)
- [ ] Implement XP calculation logic
- [ ] Add XP award triggers to:
  - Task completion (HabitTaskLog creation)
  - Test completion (PerformanceTestEntry creation)
  - Streak maintenance
  - Perfect days
- [ ] Implement level progression calculation
- [ ] Add level-up detection

### Phase 3: Achievement Detection (Week 2)
- [ ] Implement achievement checking logic
- [ ] Hook into task completion flow
- [ ] Hook into test completion flow
- [ ] Hook into streak updates
- [ ] Hook into system creation
- [ ] Track statistics in UserProgress

### Phase 4: UI Components (Week 2-3)
- [ ] Create AchievementsGalleryView
  - Grid layout of all achievements
  - Locked/unlocked states
  - Progress bars for locked achievements
  - Filter by category
  - Search functionality
- [ ] Create AchievementCardView
  - Badge display
  - Progress tracking
  - XP reward shown
  - Unlock animation
- [ ] Create UserProfileView
  - Current level & XP
  - Level progress bar
  - Tier badge
  - Total stats summary
- [ ] Add to Settings tab

### Phase 5: Notifications & Animations (Week 3)
- [ ] Achievement unlock notification
  - Slide-down animation
  - Confetti effect
  - Haptic feedback
  - Auto-dismiss
- [ ] Level-up notification
  - Full-screen animation
  - New tier reveal
  - Particle effects
- [ ] Integrate notifications into app flow

### Phase 6: Integration (Week 3-4)
- [ ] Add XP indicators to task completion
- [ ] Show level badge in navigation bar
- [ ] Display recent achievements on dashboard
- [ ] Add achievement hints ("3/7 days to Week Warrior!")
- [ ] Create achievement progress widget (optional)

---

## 🎨 UI Mockups

### Achievements Gallery
```
┌─────────────────────────────────────┐
│  ← Achievements              Filter │
│                                     │
│  Level 12 - Silver Intermediate    │
│  ▓▓▓▓▓▓▓▓░░░░ 1,250 / 2,500 XP    │
│                                     │
│  🔥 Streaks    🎯 Systems   ✅ Tasks│
│                                     │
│  ┌──────┐  ┌──────┐  ┌──────┐     │
│  │  ✨  │  │  💪  │  │  🔒  │     │
│  │Perfect│  │ Week │  │Month │     │
│  │  Day  │  │Warrior│ │Master│     │
│  │ 15/15 │  │  ✓   │  │12/30 │     │
│  └──────┘  └──────┘  └──────┘     │
│                                     │
│  ┌──────┐  ┌──────┐  ┌──────┐     │
│  │  🔒  │  │  🔒  │  │  🔒  │     │
│  │Century│  │ Year │  │Unbreak│    │
│  │ Club  │  │Legend│  │ able │     │
│  │35/100 │  │ 0/365│  │ 0/500│     │
│  └──────┘  └──────┘  └──────┘     │
└─────────────────────────────────────┘
```

### Profile Stats
```
┌─────────────────────────────────────┐
│              Profile                │
│                                     │
│         ⚪ Level 12                 │
│    Silver Intermediate              │
│                                     │
│  ▓▓▓▓▓▓▓▓░░░░░░░░░░░               │
│     1,250 / 2,500 XP                │
│                                     │
│  📊 Statistics                      │
│  • 247 tasks completed              │
│  • 15 tests completed               │
│  • 45 day longest streak            │
│  • 5 systems created                │
│  • 85% average consistency          │
│                                     │
│  🏆 Achievements: 12 / 45 unlocked  │
│                                     │
│  📜 Recent Achievements             │
│  🔥 Week Warrior - 2 days ago       │
│  ✨ Perfect Day - 5 days ago        │
│  🎯 Task Master - 1 week ago        │
└─────────────────────────────────────┘
```

### In-App XP Feedback
```
┌─────────────────────────────────────┐
│  Today's Tasks                      │
│                                     │
│  ✅ Run                  +10 XP     │
│  ✅ Meditate             +10 XP     │
│  ✅ Read                 +10 XP     │
│  ○  Pushups                         │
│                                     │
│  Bonus: Perfect Day!     +25 XP     │
│                                     │
│  Total earned today: 55 XP          │
└─────────────────────────────────────┘
```

---

## 🚀 Quick Start Implementation

Let's build this step-by-step! Start with:

1. **Create Models** (30 min)
   - Achievement.swift
   - UserProgress.swift

2. **Seed Achievements** (1 hour)
   - Create default achievement list
   - Initialize on first launch

3. **Basic XP System** (2 hours)
   - Award XP on task completion
   - Calculate level from XP
   - Display XP in UI

4. **Simple Achievement Check** (2 hours)
   - Check for Week Warrior achievement
   - Show unlock notification
   - Update achievement status

5. **Achievements Gallery** (3 hours)
   - Grid view of achievements
   - Locked/unlocked states
   - Basic animations

**Total MVP: ~8 hours of focused development**

Ready to start building? Let's begin with the data models!
