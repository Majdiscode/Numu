# HealthKit Setup Instructions - Phase 1 Complete!

## ✅ What's Been Implemented

I've successfully completed Phase 1 (Foundation) of the HealthKit integration:

### Files Created:
1. **Numu/Models/HealthKitMetricType.swift** - Enum definitions for 16 HealthKit metrics
2. **Numu/Services/HealthKitService.swift** - Core service with authorization and query methods

### Files Modified:
1. **Numu/Models/Task.swift** - Added HealthKit mapping properties (CloudKit-compatible)
2. **Numu/Models/TaskLog.swift** - Added HealthKit metadata for synced completions
3. **Numu/NumuApp.swift** - Initialized HealthKitService and added sync on app launch

---

## ⚠️ Manual Steps Required (Xcode-Only)

The following steps MUST be done in Xcode - I cannot automate these:

### Step 1: Add HealthKit Capability

1. Open **Numu.xcodeproj** in Xcode
2. Select the **Numu** target in the project navigator
3. Go to the **Signing & Capabilities** tab
4. Click the **+ Capability** button
5. Search for and add **HealthKit**
6. This will automatically:
   - Update `Numu.entitlements` with HealthKit key
   - Enable HealthKit in your app capabilities

**Expected Result:** You should see "HealthKit" appear under the list of capabilities with a checkmark.

---

### Step 2: Update Info.plist

1. In Xcode, open **Info.plist** (in the Numu folder)
2. Add the following keys:

**Method A: Using the Info.plist editor (recommended):**
- Right-click in the Info.plist editor → "Add Row"
- Add key: `Privacy - Health Share Usage Description`
- Value: `Numu uses HealthKit to automatically complete tasks based on your activity and health data.`

**Method B: Using Source Code (if you prefer XML):**
Open Info.plist as source code and add:

```xml
<key>NSHealthShareUsageDescription</key>
<string>Numu uses HealthKit to automatically complete tasks based on your activity and health data.</string>
```

**Why this is required:** iOS will reject the app if you request HealthKit permissions without this description.

---

### Step 3: Build and Test on Device

**IMPORTANT:** HealthKit does NOT work in the iOS Simulator for most metrics!

1. Connect a real iPhone or iPad
2. Select your device in Xcode (top toolbar)
3. Click **Run** (⌘R) to build and install

**On first launch**, the app will:
1. Request HealthKit authorization automatically
2. Show the iOS HealthKit permission dialog
3. Sync any tasks with HealthKit mapping (none yet - we'll add UI in Phase 7)

---

## 🧪 How to Test Phase 1

### Test 1: Authorization Works

1. Launch the app on your device
2. Watch the Xcode console for these logs:

```
✅ [HealthKit] Authorization request successful
✅ [HealthKit] Authorized
```

If you see:
```
❌ [HealthKit] Error requesting authorization: ...
```
→ Go back to Step 1 and verify HealthKit capability was added

### Test 2: Query Works (Manual Test via Console)

For now, we don't have UI yet, but the service is ready. In Phase 7, we'll add:
- Settings section to show authorization status
- Manual sync button
- Task mapping UI

---

## 📊 What Works Now (Phase 1 Complete)

✅ **HealthKitService** is initialized on app launch
✅ **Authorization flow** requests permissions automatically
✅ **Query methods** can fetch Steps, Distance, Active Energy, Exercise Minutes
✅ **Data models** are ready for HealthKit mapping
✅ **Auto-completion logic** will trigger on app launch (when tasks are mapped)

---

## 🚫 What's NOT Implemented Yet

❌ **No UI** - Can't map tasks to HealthKit yet (Phase 7)
❌ **No manual sync button** - Only syncs on app launch (Phase 3 will add this)
❌ **No visual indicators** - Can't see which tasks are HealthKit-enabled (Phase 7)
❌ **Only 4 metrics** - Steps, Distance, Active Energy, Exercise Minutes (Phase 5-6 will add more)

---

## 🔜 Next Steps: Phase 2-3

Once you've completed the manual Xcode steps and verified HealthKit works:

**Phase 2-3: Add Manual Sync + UI**
- Settings section showing HealthKit status
- Manual "Sync Now" button
- Test with real step count data

Let me know when you've completed the Xcode steps and I'll continue with Phase 2-3!

---

## ⚠️ Troubleshooting

### "No such module 'HealthKit'" error
**Solution:** Make sure you added the HealthKit capability in Xcode (Step 1)

### "This app has crashed because it attempted to access privacy-sensitive data..."
**Solution:** Add the `NSHealthShareUsageDescription` to Info.plist (Step 2)

### "Authorization status shows 'Denied'"
**Solution:** Go to Settings → Health → Data Access & Devices → Numu → Turn All Categories On

### No logs appear in console
**Solution:** Make sure you're running on a REAL DEVICE, not the simulator

---

## 📋 Checklist

Before moving to Phase 2-3, verify:
- [ ] HealthKit capability added in Xcode
- [ ] Info.plist has `NSHealthShareUsageDescription`
- [ ] App builds successfully on device
- [ ] Console shows HealthKit authorization request
- [ ] You granted permissions in the iOS dialog

Once all checked, you're ready for Phase 2-3! 🎉
