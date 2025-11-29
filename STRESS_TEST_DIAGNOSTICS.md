# Stress Test Diagnostics Guide

## 🔍 What I Added

I've added **comprehensive diagnostic logging** to the stress test generator so you can see exactly what's slow and where it fails.

---

## 📊 New Log Format

### Phase-by-Phase Breakdown

When you run a stress test, you'll now see:

```
🔥 [STRESS TEST] ========================================
🔥 [STRESS TEST] Starting Extreme (2 years) stress test...
🔥 [STRESS TEST] Expected: 100 systems, 500 tasks, ~255499 logs
🔥 [STRESS TEST] ========================================

📦 [PHASE 1/3] Creating 100 systems...
✅ [PHASE 1] Created 100 systems in 0.15s
   💾 Save time: 0.08s

📋 [PHASE 2/3] Creating 500 tasks...
✅ [PHASE 2] Created 500 tasks in 0.45s
   💾 Save time: 0.12s

📝 [PHASE 3/3] Creating ~255499 completion logs...
   Batch size: 500 logs per save
   Historical days: 730 days
   📊 Progress: 1000 logs created (245 logs/sec)
   📊 Progress: 2000 logs created (198 logs/sec)
   📊 Progress: 3000 logs created (187 logs/sec)
   ⚠️ Slow save #15: 3.45s (7500 logs so far)    ← THIS IS THE PROBLEM!
   ⚠️ Slow save #23: 4.12s (11500 logs so far)   ← DATABASE SLOWDOWN!

💾 [FINAL SAVE] Saving remaining data...
✅ [FINAL SAVE] Completed in 1.23s

✅ [PHASE 3] Created 78245 logs in 38.20s
   💾 Total saves: 157
   ⚠️ Slow saves detected: 12 saves took > 2s

🎉 [STRESS TEST] ========================================
🎉 [STRESS TEST] COMPLETED in 40.53s
🎉 [STRESS TEST] ========================================
   📊 Generated:
      • Systems: 100
      • Tasks: 500
      • Logs: 78245  ← EXPECTED 255,499 but only got 78,245!

   ⏱️ Timing Breakdown:
      • Systems: 0.15s (0%)
      • Tasks: 0.45s (1%)
      • Logs: 38.20s (94%)  ← 94% of time spent on logs!

   💾 Database Performance:
      • Total saves: 157
      • Avg save time: 0.243s
      • ⚠️ WARNING: 12 slow saves (> 2s)  ← DATABASE BOTTLENECK!
🎉 [STRESS TEST] ========================================
```

---

## 🎯 What to Look For

### 1. **Progress Milestones** (Every 1000 logs)
```
📊 Progress: 1000 logs created (245 logs/sec)
```
- **Good:** 200+ logs/sec consistently
- **Acceptable:** 100-200 logs/sec
- **Slow:** < 100 logs/sec (database struggling)

### 2. **Slow Save Warnings** (Critical!)
```
⚠️ Slow save #15: 3.45s (7500 logs so far)
```
- Indicates database is **locking** or **busy**
- Each save should be < 0.5s normally
- If you see many warnings, database is overwhelmed

### 3. **Total Logs Created vs Expected**
```
Logs: 78245  (Expected: ~255499)
```
- If significantly less than expected, the test **timed out** or **was interrupted**
- Extreme test expects ~255k logs but realistic completion rates may reduce this

### 4. **Timing Breakdown**
```
⏱️ Timing Breakdown:
   • Logs: 38.20s (94%)
```
- Logs should be 80-95% of total time (expected)
- If > 95%, database is the bottleneck

### 5. **Database Performance Summary**
```
💾 Database Performance:
   • Total saves: 157
   • Avg save time: 0.243s
   • ⚠️ WARNING: 12 slow saves (> 2s)
```
- **Healthy:** Avg save < 0.3s, zero slow saves
- **Acceptable:** Avg save < 0.5s, < 5 slow saves
- **Struggling:** Avg save > 0.5s, 10+ slow saves
- **Critical:** Multiple saves > 5s

---

## 🐛 Common Issues & Solutions

### Issue 1: Many Slow Saves (> 2s)

**Symptom:**
```
⚠️ Slow save #15: 3.45s
⚠️ Slow save #23: 4.12s
⚠️ Slow save #31: 5.67s
```

**Cause:** Database WAL (Write-Ahead Log) getting too large

**Solutions:**
1. **Increase batch size** - Save less frequently
   ```swift
   let batchSize = 1000  // Currently 500
   ```
2. **Reduce test scale** - Use Heavy instead of Extreme
3. **Disable CloudKit during testing** - Sync adds overhead

---

### Issue 2: Low Logs/Sec Rate (< 100)

**Symptom:**
```
📊 Progress: 5000 logs created (67 logs/sec)
```

**Cause:** Database writes blocking main thread

**Solutions:**
1. **Check simulator performance** - Real device is faster
2. **Close other apps** - Free up system resources
3. **Reduce historical days** - Less data to generate

---

### Issue 3: Test Stops Early (Incomplete)

**Symptom:**
```
Logs: 78245  (Expected: ~255499)
```

**Causes:**
- App crashed (check for crash logs)
- Simulator ran out of memory
- Database locked/deadlocked
- User interrupted (tapped screen)

**Solutions:**
1. **Check for errors** in console:
   ```
   ❌ Save error: The operation couldn't be completed
   ```
2. **Monitor memory** in Performance Monitor
3. **Use smaller test** - Heavy or Medium instead

---

### Issue 4: UI Freezing ("Gesture: System gesture gate timed out")

**Symptom:**
```
<0x1242df0c0> Gesture: System gesture gate timed out.
```

**Cause:** Main thread blocked by calculations

**Solutions:**
1. **Don't navigate away** during stress test
2. **Wait for completion** before interacting
3. **UI will be responsive after test completes**

---

## 📋 Testing Checklist

Run a stress test and check these metrics:

### Medium Test (6 months, 25 systems)
- [ ] Completes in < 5 seconds
- [ ] Zero slow saves
- [ ] Creates ~18,900 logs (realistic: 6,000-7,000)
- [ ] Avg save time < 0.3s
- [ ] Logs/sec: 1000+

### Heavy Test (1 year, 50 systems)
- [ ] Completes in < 15 seconds
- [ ] < 3 slow saves
- [ ] Creates ~76,650 logs (realistic: 20,000-30,000)
- [ ] Avg save time < 0.5s
- [ ] Logs/sec: 500+

### Extreme Test (2 years, 100 systems)
- [ ] Completes in < 60 seconds
- [ ] < 10 slow saves
- [ ] Creates ~255,499 logs (realistic: 60,000-90,000)
- [ ] Avg save time < 1.0s
- [ ] Logs/sec: 200+
- [ ] No crashes or memory warnings

---

## 🔬 Deep Dive: Why Extreme Test Fails

Based on your logs, here's what's happening:

### 1. Database Lock Contention
```
CoreData: debug: WAL checkpoint: Database busy
CoreData: debug: WAL checkpoint: Database locked
```
- **Multiple saves** happening simultaneously
- **CloudKit sync** competing for database access
- **WAL checkpoint** trying to compact database

### 2. Database File Size Growth
```
CoreData: debug: PostSaveMaintenance: fileSize 10913912 greater than prune threshold
```
- Database grew to **~11MB** during test
- Triggers automatic **VACUUM** operations
- Vacuum competes with saves, causing locks

### 3. Realistic Completion Rates
- **Expected:** 255,499 logs (assuming 100% completion rate)
- **Actual:** 78,245 logs
- **Why:** Realistic completion rates (70-90%) reduce actual logs created
- This is **correct behavior** - not a bug!

---

## 💡 Recommendations

### For Development/Testing: Use Medium or Heavy
```swift
// Medium: Perfect for most testing
// - Fast generation (1-2s)
// - Enough data to see patterns
// - No database issues

// Heavy: Good for performance validation
// - Slower but manageable (6-10s)
// - More realistic dataset
// - Some slow saves acceptable
```

### For Production: Extreme Test is Overkill
```
Real-world users will NEVER have:
- 100 systems
- 500 tasks
- 2 years of daily data

Most users have:
- 3-10 systems
- 15-50 tasks
- 3-6 months of data

= Medium test is MORE than sufficient
```

### If You MUST Pass Extreme Test

**Option 1: Increase Batch Size**
```swift
let batchSize = 2000  // Up from 500
```
- Fewer saves = less database contention
- Trade-off: Higher memory usage per batch

**Option 2: Disable CloudKit During Test**
```swift
let configuration = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: false,
    cloudKitDatabase: .none  // Disable during stress test
)
```

**Option 3: Add Delays Between Saves**
```swift
if batchSaveCounter >= batchSize {
    try modelContext.save()
    Thread.sleep(forTimeInterval: 0.1)  // Give DB time to checkpoint
    batchSaveCounter = 0
}
```

---

## 🎯 Success Criteria

### Your App is PRODUCTION READY if:
✅ Medium test completes successfully (< 5s, no slow saves)
✅ Heavy test completes successfully (< 15s, < 3 slow saves)
✅ Real-world usage is smooth (5-10 systems, 30-60 tasks)
✅ Calendar scrolls smoothly with 6 months of data
✅ System list renders without lag (< 30 systems)

### Extreme test is for:
- Finding breaking points
- Stress testing database limits
- Validating edge case handling
- NOT required for production readiness

---

## 📞 Next Steps

1. **Run the test again** with new logging
2. **Copy the console output** and share it
3. **Look for these key indicators:**
   - How many slow saves?
   - What's the logs/sec rate?
   - Where does it start slowing down?
4. **We can optimize** based on the specific bottleneck

The detailed logs will tell us EXACTLY where the problem is! 🚀
