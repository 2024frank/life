# Adding API Keys in Xcode Build Settings

**IMPORTANT:** API keys are stored locally and NEVER pushed to git.

---

## Method 1: Xcode Build Settings (Recommended)

### Step 1: Add Build Setting

1. Open Xcode
2. Click **knowbest** project (blue icon)
3. Select **knowbest** target
4. Go to **Build Settings** tab
5. Click **+** → **Add User-Defined Setting**
6. Add these settings:

| Name | Value |
|------|-------|
| `ELEVENLABS_API_KEY` | `your-actual-elevenlabs-key-here` |

### Step 2: Export to Environment

1. Still in **Build Settings**
2. Search for "Preprocessor Macros" or "Other Swift Flags"
3. Find **Info.plist Preprocessor** section
4. Add: `ELEVENLABS_API_KEY=$(ELEVENLABS_API_KEY)`

**OR** simpler - add to Info.plist:

1. Go to **Info** tab
2. Click **+**
3. Add key: `ELEVENLABS_API_KEY`
4. Type: String
5. Value: `your-key-here`

---

## Method 2: Environment Variables (For Development)

### In Xcode Scheme:

1. **Product** → **Scheme** → **Edit Scheme**
2. Go to **Run** → **Arguments**
3. Under **Environment Variables**, click **+**
4. Add:
   - Name: `ELEVENLABS_API_KEY`
   - Value: `your-key-here`

---

## Method 3: In-App Settings (Current)

The app already has a Settings screen where you can add your Eleven Labs key:
1. Open app
2. Tap **Settings** (gear icon)
3. Enter your Eleven Labs API key
4. Tap **Save**

This stores it in UserDefaults (local only).

---

## Verify It Works

1. Build and run
2. Open Voice Assistant
3. Say something
4. Check console - should NOT see "No color named 'orange'" errors
5. Voice should work with Eleven Labs if key is set

---

## Security Notes

✅ **DO:**
- Add keys in Xcode build settings
- Use environment variables
- Store in UserDefaults (in-app)
- Add to `.gitignore` (already done)

❌ **DON'T:**
- Commit API keys to git
- Hardcode keys in source files
- Share your keys publicly

---

## Current Setup

The app checks for API keys in this order:
1. **UserDefaults** (set in app Settings)
2. **Environment variable** (`ELEVENLABS_API_KEY`)
3. **Info.plist** (`ELEVENLABS_API_KEY` key)

All methods work! Choose what's easiest for you.
