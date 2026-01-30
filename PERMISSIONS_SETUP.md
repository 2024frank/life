# Permissions Setup Guide

## ⚠️ CRITICAL: Add Info.plist Keys in Xcode

The app **WILL CRASH** without these keys. Follow these exact steps:

### Step 1: Open Xcode Project Settings

1. Open `knowbest.xcodeproj` in Xcode
2. Click **knowbest** (blue project icon) in left sidebar
3. Select **knowbest** under **TARGETS**
4. Click **Info** tab (not General, not Build Settings)

### Step 2: Add Privacy Keys

Click the **+** button at the bottom left, then add these **EXACT** keys:

| Key (Type Exactly) | Type | Value |
|-------------------|------|-------|
| `NSMicrophoneUsageDescription` | String | `Adam needs microphone access for voice commands` |
| `NSSpeechRecognitionUsageDescription` | String | `Adam uses speech recognition to understand you` |
| `NSCalendarsUsageDescription` | String | `Adam adds your tasks to your calendar` |
| `NSSiriUsageDescription` | String | `Talk to Adam using Siri` |

### Step 3: Verify

After adding, you should see all 4 keys in the Info tab.

### Step 4: Clean & Build

1. **Clean**: `Cmd + Shift + K`
2. **Build**: `Cmd + B`
3. **Run**: `Cmd + R`

---

## Testing Permissions

### Test Flow:

1. **First Launch**: Should show onboarding screen
2. **Tap "Enable All Permissions"**: iOS will show permission dialogs
3. **Grant Permissions**: Tap "Allow" for each
4. **Check Status**: Cards should show green checkmarks
5. **Tap "Get Started"**: Should go to main app

### If App Crashes:

- **Error**: "NSMicrophoneUsageDescription key missing"
- **Fix**: Go back to Step 2 above and add the keys
- **Important**: Keys must be added in Xcode Info tab, not in a separate file

---

## Permission Flow

```
App Launch
    ↓
Onboarding Screen (first time only)
    ↓
User taps "Enable All Permissions"
    ↓
iOS shows permission dialogs
    ↓
User grants/denies
    ↓
App continues
```

---

## Troubleshooting

### "App crashed - NSMicrophoneUsageDescription missing"
- **Cause**: Info.plist key not added
- **Fix**: Add key in Xcode Info tab (see Step 2)

### "Permissions not showing in onboarding"
- **Cause**: PermissionManager not initialized
- **Fix**: Check that ContentView uses `@StateObject` for PermissionManager

### "Can't find Info tab"
- **Cause**: Wrong tab selected
- **Fix**: Make sure you're in **Info** tab, not General or Build Settings

---

## Quick Checklist

- [ ] Opened Xcode project
- [ ] Selected knowbest target
- [ ] Went to Info tab
- [ ] Added NSMicrophoneUsageDescription
- [ ] Added NSSpeechRecognitionUsageDescription
- [ ] Added NSCalendarsUsageDescription
- [ ] Added NSSiriUsageDescription
- [ ] Cleaned build folder
- [ ] Built project
- [ ] Ran app
- [ ] Tested permissions

---

**Once all keys are added, the app will work perfectly!** 🎉
