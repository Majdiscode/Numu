# 🎯 Weekly Goals Section - Implementation Plan

## Problem
Weekly frequency tasks (e.g., "Upper body 2x/week") currently show in "Today's Tasks" every day until the weekly target is met. This creates unrealistic expectations when multiple weekly tasks exist in one system.

## Solution
Separate weekly frequency tasks into their own "Weekly Goals" section, giving users full control over when to complete them.

---

## 📋 Implementation Steps

### ✅ Step 1: Update Task Model Logic
**File**: `Numu/Models/Task.swift`
**Time**: 10 min

Change `shouldBeCompletedOn()` to return `false` for weekly frequency tasks:
- Weekly tasks should NEVER show as "due today"
- They are always available but not required on any specific day
- User chooses when to complete them

**Changes**:
```swift
case .weeklyTarget(let times):
    // Weekly tasks are NOT "due" on any specific day
    // They are tracked separately in Weekly Goals section
    return false
```

### ✅ Step 2: Add Weekly Tasks Property to System
**File**: `Numu/Models/System.swift`
**Time**: 5 min

Add computed property to get weekly frequency tasks:
```swift
var weeklyTasks: [HabitTask] {
    tasks?.filter {
        if case .weeklyTarget = $0.frequency {
            return true
        }
        return false
    } ?? []
}
```

Now we have:
- `todaysTasks` → Daily/weekdays/weekends tasks
- `weeklyTasks` → Weekly frequency tasks

### ✅ Step 3: Update SystemsDashboardView UI
**File**: `Numu/Views/SystemsDashboardView.swift`
**Time**: 30 min

**Current Structure**:
```
┌─────────────────────┐
│ System Card         │
│ • All tasks mixed   │
└─────────────────────┘
```

**New Structure**:
```
┌─────────────────────────────┐
│ System Card                 │
│                             │
│ 📅 Today's Tasks           │
│ ○ Meditation               │
│ ○ Read                     │
│                             │
│ 🎯 Weekly Goals            │
│ ○ Lower Body  1/2 this week│
│ ○ Upper Body  0/2 this week│
│ ○ Cardio      3/4 this week│
└─────────────────────────────┘
```

**Changes**:
1. Separate tasks into two sections
2. Add "Today's Tasks" header if `todaysTasks` is not empty
3. Add "Weekly Goals" header if `weeklyTasks` is not empty
4. Show weekly progress for each weekly task
5. Keep interaction the same (tap to complete)

### ✅ Step 4: Update SystemDetailView UI
**File**: `Numu/Views/SystemDetailView.swift`
**Time**: 30 min

Same separation:
- "Today's Tasks" section (with checkboxes)
- "Weekly Goals" section (with progress indicators)

### ✅ Step 5: Test & Polish
**Time**: 15 min

Test scenarios:
- [ ] System with only daily tasks → Only shows "Today's Tasks"
- [ ] System with only weekly tasks → Only shows "Weekly Goals"
- [ ] System with both → Shows both sections
- [ ] Complete weekly task → Progress updates correctly
- [ ] Weekly task never shows in "Today's Tasks"
- [ ] Weekly task shows as grayed out after target met

---

## 🎨 UI Mockups

### Dashboard - System Card with Both Types
```
┌───────────────────────────────────┐
│ 🏋️ Hybrid Athlete           85%  │
│ 2 day streak 🔥                   │
├───────────────────────────────────┤
│ 📅 Today's Tasks                  │
│ ○ Stretching                      │
│ ○ Nutrition tracking              │
│                                   │
│ 🎯 Weekly Goals                   │
│ ✓ Lower Body      2/2 ✅         │
│ ○ Upper Body      1/2 this week  │
│ ○ Cardio          3/4 this week  │
└───────────────────────────────────┘
```

### Dashboard - Weekly Tasks Only System
```
┌───────────────────────────────────┐
│ 🏃 Fitness Goals            75%  │
│ 5 day streak 🔥                   │
├───────────────────────────────────┤
│ 🎯 Weekly Goals                   │
│ ○ Gym Session     2/3 this week  │
│ ○ Yoga            1/2 this week  │
│ ○ Swimming        0/1 this week  │
└───────────────────────────────────┘
```

### Detail View Structure
```
┌─────────────────────────────────────┐
│ ← Hybrid Athlete                    │
├─────────────────────────────────────┤
│ [Progress Charts]                   │
│                                     │
│ 📅 Today's Tasks                    │
│ ┌─────────────────────────────┐   │
│ │ ✓ Stretching           +10XP│   │
│ │ ○ Nutrition tracking        │   │
│ └─────────────────────────────┘   │
│                                     │
│ 🎯 Weekly Goals                     │
│ ┌─────────────────────────────┐   │
│ │ ✓ Lower Body    2/2 ✅      │   │
│ │ ○ Upper Body    1/2         │   │
│ │   1 more this week          │   │
│ │ ○ Cardio        3/4         │   │
│ │   1 more this week          │   │
│ └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

---

## 🚀 Benefits

✅ **Clear separation**: Daily obligations vs weekly goals
✅ **Realistic expectations**: No pressure to do everything today
✅ **Flexibility**: Choose when to work on weekly goals
✅ **Progress visibility**: See weekly progress at a glance
✅ **No confusion**: Users know exactly what's expected today

---

## 📝 Implementation Order

1. **Step 1**: Update Task.swift `shouldBeCompletedOn()` (10 min)
2. **Step 2**: Add `weeklyTasks` to System.swift (5 min)
3. **Step 3**: Update SystemsDashboardView (30 min)
4. **Step 4**: Update SystemDetailView (30 min)
5. **Step 5**: Test thoroughly (15 min)

**Total time**: ~90 minutes

---

## ⏭️ NEXT: Start with Step 1

Ready to implement Step 1: Update Task model logic?
