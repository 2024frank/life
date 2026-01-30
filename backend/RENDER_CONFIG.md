# Render Configuration - No OpenAI Needed ✅

## Current Settings (What You See)

Based on your screenshot, here's what to configure:

### ✅ Correct Settings:

1. **Service Name**: `knowbest-backend` ✅ (correct!)

2. **Runtime**: `Node` ✅ (correct!)

3. **Branch**: `main` ✅ (correct!)

4. **Region**: `Virginia (US East)` ✅ (any region works)

### ⚠️ IMPORTANT - Change These:

5. **Root Directory**: 
   - Currently: Empty (shows "e.g. src")
   - **Change to**: `backend` ⚠️ **CRITICAL!**

6. **Build Command**: 
   - Currently: `$ yarn`
   - **Change to**: `npm install` ⚠️ **IMPORTANT!**

7. **Start Command**: 
   - Add this field if not visible
   - **Set to**: `npm start`

---

## Environment Variables (After Creating Service)

Click **"Advanced"** → **"Add Environment Variable"**

Add these **2 variables only** (NO OpenAI needed):

### Variable 1: JWT_SECRET
```
Key: JWT_SECRET
Value: ++k1/5SKa4v81lewk2tAgIhNL4I1Yb/QjiWsag33DH0=
```

### Variable 2: NODE_ENV
```
Key: NODE_ENV
Value: production
```

### Variable 3: ELEVENLABS_API_KEY (Optional)
```
Key: ELEVENLABS_API_KEY
Value: 4fa9cd17455dcfb60218e0a5f0b91cedfdfe03d5c14e611fd8508909533eea8c
```

**Note**: The backend works fine without OpenAI API - it uses fallback parsing!

---

## Summary

**What to Change:**
- ✅ Root Directory: `backend`
- ✅ Build Command: `npm install`
- ✅ Start Command: `npm start`

**Environment Variables:**
- ✅ JWT_SECRET (required)
- ✅ NODE_ENV=production (required)
- ✅ ELEVENLABS_API_KEY (optional)

**No OpenAI API needed!** 🎉
