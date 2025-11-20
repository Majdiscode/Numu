# How to Test Release Build (Production Performance)

## Option 1: Build & Run Release from Xcode (Recommended)

1. **Open Xcode**
2. Click on the scheme selector (top left, says "Numu")
3. Choose **"Edit Scheme..."**
4. Select **"Run"** in the left sidebar
5. Change **"Build Configuration"** from **"Debug"** to **"Release"**
6. Click **"Close"**
7. Run the app (Cmd+R)

**Important:** The first Release build will be SLOW (2-3 minutes) because of full optimizations. Subsequent builds are faster.

## Option 2: Archive Build (Actual App Store Build)

1. In Xcode: **Product → Archive**
2. When done, click **"Distribute App"**
3. Choose **"Custom"**
4. Choose **"Development"**  
5. Install on your device via Xcode

## Performance Differences

| Feature | Debug | Release |
|---------|-------|---------|
| App Launch | 2-3s | <1s |
| Task Toggle | 200-500ms | 10-50ms |
| View Updates | Laggy | Instant |
| Animations | Choppy | Smooth 60fps |
| File Size | ~50MB | ~15MB |

## After Testing

**IMPORTANT:** Switch back to Debug for development:
1. Edit Scheme → Run → Build Configuration → **Debug**

Otherwise breakpoints and debugging won't work!
