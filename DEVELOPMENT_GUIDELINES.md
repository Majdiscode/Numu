# Numu Development Guidelines

## 🎯 Project Vision
A sleek, minimalist iOS habit tracking app based on **Atomic Habits** principles - focusing on identity-based systems rather than goals. Every feature should reinforce the core philosophy: *You don't rise to the level of your goals, you fall to the level of your systems.*

---

## ⚠️ CRITICAL RULES (READ FIRST)

### 1. NEVER Build to Simulator
- **User will run the code themselves**
- Do NOT use `xcodebuild` or any build commands
- Do NOT run the app in simulator
- Only provide code changes - user handles testing

### 2. No Version Folders
- **NO V1, V2, V3 folders** - that's what Git is for
- Keep flat, clean structure
- Models go in `Models/`
- Views go in `Views/`

### 3. Modular & Long-Term Focused
- Every piece of code should be built to last
- Think: "Will this scale?"
- Extract reusable components early
- Keep files focused and under 500 lines

### 4. When Code Doesn't Run - Check Latest Documentation
- **ALWAYS verify against latest Apple documentation**
- Swift/SwiftUI/SwiftData APIs change frequently
- When user reports code not running:
  1. **IMMEDIATELY use context7 MCP** to fetch latest Apple docs
  2. Check for API changes, deprecations, new patterns
  3. Verify syntax against current iOS/Swift version
  4. Update code to match latest best practices
- **Don't rely on training data** - APIs may have changed
- **Context7 is installed and ready to use** - it's the primary tool for Apple documentation

### 5. Before Building New Features - Verify with Documentation
- **ALWAYS check Apple docs BEFORE starting implementation**
- Use context7/WebSearch to verify:
  - Required API patterns
  - Framework capabilities and limitations
  - Best practices for the feature
  - Common pitfalls to avoid
- This minimizes debugging time and ensures correct implementation
- Example: Before adding CloudKit, verify relationship requirements (must be optional)

---

## 📁 File Structure

```
Numu/
├── Models/
│   ├── System.swift
│   ├── Task.swift
│   ├── TaskLog.swift
│   ├── Test.swift
│   └── TestEntry.swift
├── Views/
│   ├── SystemsDashboardView.swift
│   ├── SystemDetailView.swift
│   ├── CreateSystemView.swift
│   └── [other views]
├── Services/
│   └── CloudKitService.swift    (CloudKit sync monitoring)
├── Utilities/
│   ├── Color+Hex.swift
│   └── [extensions & helpers]
├── NumuApp.swift
└── ContentView.swift
```

**Rules:**
- One view per file (with related sub-components marked with `// MARK:`)
- Extensions go in `Utilities/` with clear naming (e.g., `Color+Hex.swift`)
- No "Misc" or "Helpers" - be specific with naming

---

## 🧩 Modularity Principles

**Core Definition:** Everything must be **standalone and reusable**. Write once, use everywhere. Each component should work independently and combine cleanly with others. If you can't drop it in another project and have it work with minimal changes, it's not modular enough.

### 1. Component Extraction Strategy
```swift
// Main view
struct SystemDetailView: View {
    var body: some View { }
}

// MARK: - Supporting Components
struct SystemStatCard: View { }
struct TaskDetailRow: View { }
```

**When to extract:**
- ✅ Used 2+ times in same file → Extract to bottom with `// MARK:`
- ✅ Used across files → Create `Views/Components/ComponentName.swift`
- ❌ Only used once → Keep inline

### 2. File Size Limits
- **Max ~500 lines per file**
- If larger, split into logical sub-views
- Use computed properties for sections (`private var headerSection`)
- Extract sheets/modals to separate views

### 3. Keep Models Pure
- Models = business logic only (computed properties, helpers)
- **NO UI code in models**
- Use extensions for related functionality

---

## 🎨 Design System - The "Sleek" Factor

### Visual Consistency
**Spacing:** Multiples of 4 (4, 8, 12, 16, 24, 32)

**Corner Radius:**
- Cards: `16`
- Buttons: `12`
- Small pills/badges: `8`

**Shadows:** Always subtle
```swift
.shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
```

**Colors:**
- System colors: `.blue`, `.green`, `.red`
- Category colors: `Color(hex: "#FF6B35")`
- Backgrounds: `.opacity(0.15)` for subtle fills
- Secondary text: `.foregroundStyle(.secondary)`

### Typography Scale
```swift
.font(.system(size: 48, weight: .bold, design: .rounded))  // Large numbers/stats
.font(.title)                                               // Page headings
.font(.headline)                                            // Section headings
.font(.subheadline)                                         // Body text
.font(.caption)                                             // Meta info
```

### Icons
- **Always SF Symbols** (never custom unless necessary)
- Match icon to meaning (flame = streak, checkmark = completion)
- Sizing:
  - Large: `.font(.system(size: 44))` or `.font(.title)`
  - Medium: `.font(.title2)` or `.title3`
  - Small: `.font(.caption2)`

---

## 🔧 SwiftUI Patterns

### State Management
```swift
@State private var showSheet = false      // Local UI state
@Query private var systems: [System]      // SwiftData queries
@Environment(\.modelContext) private var modelContext
@Environment(\.dismiss) private var dismiss
```

**Rules:**
- `@State` for UI-only state (sheet visibility, text input)
- `@Query` for SwiftData fetching
- Always `private` on `@State`
- No `@StateObject` or `@ObservableObject` (SwiftData handles this)

### Animations
```swift
withAnimation(.spring(response: 0.3)) {
    // state change
}
```
- Spring animations for interactive elements
- Keep snappy (≤0.3s)

### Forms
```swift
Form {
    Section {
        // inputs
    } header: {
        Label("Title", systemImage: "icon.name")
    } footer: {
        Text("Helpful explanation or examples")
    }
}
```

---

## 🧠 Atomic Habits Philosophy

### Core Principles
1. **Identity-based goals** → Systems, not outcomes
2. **The 4 Laws:**
   - Make it Obvious (Cue)
   - Make it Attractive (Attractiveness)
   - Make it Easy (Ease Strategy)
   - Make it Satisfying (Reward)
3. **Consistency over perfection**
4. **Small habits compound**

### Language & Messaging
✅ **Use:**
- Identity language: "Hybrid Athlete", "Consistent Reader"
- Positive reinforcement: "Keep going!", "Every task reinforces your identity"
- System focus: "Your systems are strong today"

❌ **Avoid:**
- Guilt/shame: Never "You failed" or "You missed"
- Goal focus: Not "Hit your target" - instead "Live your system"

### Feature Filter
**Ask: "Does this reinforce systems thinking?"**
- ✅ Streak tracking (shows consistency)
- ✅ Completion rates (shows system health)
- ✅ Atomic Habits fields (implements the 4 Laws)
- ❌ Leaderboards (competitive, not identity-based)
- ❌ Strict daily goals (too rigid, causes failure feeling)

---

## 🏗️ Long-Term Architecture

### Future-Proofing
**1. Use Enums, Not Hardcoded Strings**
```swift
enum SystemCategory: String, Codable, CaseIterable {
    case athletics = "Athletics"
    // ...
}
```

**2. Relationships Over IDs**
```swift
// ✅ Good
var system: System?

// ❌ Bad
var systemId: UUID
```

**3. Cascade Deletes**
```swift
@Relationship(deleteRule: .cascade, inverse: \Task.system)
var tasks: [Task] = []
```

**4. Optional Fields for Flexibility**
```swift
var taskDescription: String?  // Can add requirements later
var cue: String?              // Atomic Habits fields optional
```

### Scalability Patterns
- **Builder pattern** for multi-step forms (TaskBuilder, TestBuilder)
- **Computed properties** over stored values when possible
- **Extensions** for related functionality (Color+Hex, Date helpers)

---

## ☁️ CloudKit Sync Architecture

### Overview
Numu uses **CloudKit + SwiftData** for automatic sync across all Apple devices.

**Why CloudKit:**
- ✅ Free for users (storage costs covered by Apple)
- ✅ Privacy-first (data in user's private iCloud)
- ✅ Zero backend maintenance
- ✅ Automatic conflict resolution
- ✅ Works offline, syncs when online
- ✅ No separate login UI needed - uses Apple ID

### Authentication & User Accounts

**Important: CloudKit uses Apple ID automatically - NO separate login needed!**

- **Users MUST be signed into iCloud** on their device (Settings → [Name])
- **No username/password fields** - Apple handles all authentication
- **Completely transparent** - users never see a "login" screen for your app
- **Account switching**: If user changes iCloud accounts, local data is cleared and replaced with new account's data

**Check Account Status:**
```swift
@State private var cloudKitService = CloudKitService()

// Shows banner if not signed in
if cloudKitService.syncStatus == .notSignedIn {
    // Display warning to sign into iCloud
}
```

### How Data Storage Works

**Both local AND cloud:**
- **Local storage**: SwiftData ALWAYS stores data locally in SQLite
- **Offline access**: App works fully offline with local data
- **Cloud sync**: When online + signed into iCloud, changes sync automatically
- **Bidirectional**: Changes on any device propagate to all devices

### How It Works
```
iPhone               iCloud               iPad/Mac
   ↓                   ↓                     ↓
SwiftData ←→ CloudKit Container ←→ SwiftData
(local)          (automatic)          (local)
```

### Code Implementation

**CRITICAL Requirements:**
```swift
// 1. All relationships MUST be optional for CloudKit
@Relationship(deleteRule: .cascade, inverse: \Task.system)
var tasks: [Task]?  // ← MUST be optional, not [Task] = []

// 2. Schema must be explicit
let schema = Schema([System.self, Task.self, TaskLog.self])

// 3. Configuration with CloudKit enabled
let configuration = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: false,
    cloudKitDatabase: .automatic
)

// 4. Container initialization
let container = try ModelContainer(
    for: schema,
    configurations: [configuration]
)
```

**That's it!** SwiftData handles:
- Uploading changes to iCloud
- Downloading changes from other devices
- Conflict resolution (last-write-wins)
- Network handling (retries, offline queue)

### Models Are CloudKit-Ready
All models automatically sync because they use:
- `@Model` macro (SwiftData)
- Codable types (String, Int, Date, UUID, Enums)
- **Optional relationships** (required by CloudKit)
- Enums with associated values need explicit Codable implementation

**Important:** Enums with associated values need manual Codable:
```swift
enum TaskFrequency: Codable {
    case daily
    case specificDays([Int])

    // Manual encoding/decoding required
    init(from decoder: Decoder) throws { /* ... */ }
    func encode(to encoder: Encoder) throws { /* ... */ }
}
```

### Monitoring Sync (Optional)
`CloudKitService` provides sync status monitoring:
```swift
@State private var cloudKitService = CloudKitService()

// Check if user is signed into iCloud
if cloudKitService.isSignedIn {
    // Show sync status
}
```

### User Requirements
- Must be signed into **Apple ID/iCloud** on device
- iCloud Drive enabled (usually automatic)
- Free iCloud storage available (habits use ~KB, not GB)

### Testing Sync
1. Run app on Device A (signed into iCloud)
2. Create a system
3. Run app on Device B (same iCloud account)
4. System appears within seconds

**No special testing infrastructure needed!**

### Conflict Handling
CloudKit uses **last-write-wins**:
- User edits Task on iPhone at 2:00 PM
- User edits same Task on iPad at 2:01 PM
- iPad version wins (most recent)

This works well for habits - conflicts are rare.

### Privacy & Security
- Data stored in **user's private iCloud**
- Encrypted in transit and at rest
- Developer **cannot access user data**
- User controls deletion via iCloud settings

### Troubleshooting

**"Store failed to load" errors:**
- Check that all `@Relationship` properties are optional (`[Model]?` not `[Model]`)
- Verify entitlements include CloudKit and iCloud container ID
- Ensure Schema is explicitly created and passed to ModelConfiguration

**Account Status:**
- Show banner when user not signed into iCloud
- Link to Settings app to sign in
- Refresh status when app becomes active

---

## ✅ Code Quality

### Naming Conventions
```swift
// Views: [Noun][Action]View
struct SystemDetailView: View { }
struct CreateSystemView: View { }
struct TaskCheckInView: View { }

// Models: Clear nouns
class System { }
class Task { }
enum TaskFrequency { }

// Properties
var todayCompletionRate: Double  // Descriptive camelCase
var dueTests: [Test]              // Plural for arrays
var isCompleted: Bool             // is/has for booleans
```

### Comments
```swift
// MARK: - Major Section
// MARK: Subsection

/// Public API documentation
var publicProperty: String

// Brief inline comment for complex logic
```

**When to comment:**
- ✅ Complex business logic (streak calculations)
- ✅ Non-obvious SwiftUI workarounds
- ✅ Public model APIs
- ❌ Self-explanatory code

### Error Handling
```swift
do {
    try modelContext.save()
} catch {
    print("Error saving: \(error)")
    // Future: Add proper error UI
}
```

---

## 🚀 Development Workflow

### Before Adding a Feature
1. Does it reinforce Atomic Habits?
2. Does it feel "sleek"?
3. Where does it fit in the structure?
4. Can components be reused?

### While Coding
1. Follow existing patterns
2. Extract components early
3. Use `// MARK:` liberally
4. Keep it simple

### After Coding
1. Check consistency with other views
2. Test edge cases (empty states, long text)
3. Consider accessibility
4. Clean up (remove debug code)

### When Code Doesn't Compile/Run
**User reports: "The code isn't running" or "I'm getting errors"**

1. **Ask for specific error message** - exact text helps identify the issue
2. **IMMEDIATELY use context7 MCP** - Check latest Apple documentation
3. **Common issues to check:**
   - SwiftData API changes (ModelConfiguration, @Model macro)
   - SwiftUI deprecations (onChange, alert syntax changes)
   - CloudKit entitlements (missing capabilities)
   - iOS version mismatches (using iOS 18 APIs on iOS 17)
4. **Verify syntax** against current Swift/iOS version
5. **Update code** to match latest best practices

**Example workflow:**
```
User: "Getting error: 'cloudKitDatabase' is unavailable"
→ Use context7 to check ModelConfiguration docs
→ Find that API changed in iOS 18
→ Update to new syntax: ModelConfiguration(cloudKitContainerIdentifier: "...")
→ Provide corrected code
```

---

## 📦 Reusable Components

### Existing
- `SystemCard` - Dashboard system preview
- `SystemStatCard` - Icon + value + label
- `TaskRow` - Quick task toggle
- `TaskDetailRow` - Detailed task with stats
- `TestCard` - Test display with analytics

### Create As Needed
- Extract after using similar code 2+ times
- Place in same file if single-use
- Create dedicated file if multi-use

---

## 🎯 The "Sleek" Checklist

Before marking a view complete:
- [ ] Consistent spacing (multiples of 4)
- [ ] Proper typography hierarchy
- [ ] Subtle shadows on cards
- [ ] Smooth spring animations
- [ ] SF Symbols for all icons
- [ ] Empty states handled
- [ ] Long text doesn't break layout
- [ ] Matches color system
- [ ] No visual clutter

---

## 🔮 Future Considerations

### Keep in Mind
- Widgets (design views to be widget-friendly)
- iCloud sync (SwiftData ready)
- Apple Watch (keep models pure for sharing)
- iPad multitasking (responsive layouts)

### Never Compromise
1. Performance
2. Data integrity
3. User experience
4. Atomic Habits philosophy

---

## 💡 Core Philosophy

> "Numu is not a habit tracker. It's an identity builder. Every view, every interaction, every word should reinforce that users are becoming who they want to be - not chasing arbitrary goals. The app should feel like a trusted companion: sleek, simple, supportive."

**When in doubt, ask: "Does this help someone live their system?"**
