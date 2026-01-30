# 🚀 Deploy Backend to Render NOW!

## ✅ Backend Tested Locally - Working Perfect!

Your backend is ready to deploy. Follow these steps:

---

## Quick Deploy Steps

### 1. Go to Render
👉 **https://render.com**

### 2. Sign Up / Login
- Click "Get Started for Free"
- Sign up with GitHub (easiest way)

### 3. Create Web Service
1. Click **"New +"** → **"Web Service"**
2. Connect GitHub → Select **`2024frank/life`** repository
3. Click **"Connect"**

### 4. Configure Settings

**IMPORTANT SETTINGS:**
- **Name**: `knowbest-backend`
- **Root Directory**: `backend` ⚠️ **MUST SET THIS!**
- **Build Command**: `npm install`
- **Start Command**: `npm start`
- **Environment**: `Node`

### 5. Add Environment Variables

Click **"Advanced"** → **"Add Environment Variable"**

Add these **3 variables**:

#### Variable 1: JWT_SECRET
```
Key: JWT_SECRET
Value: ++k1/5SKa4v81lewk2tAgIhNL4I1Yb/QjiWsag33DH0=
```

#### Variable 2: NODE_ENV
```
Key: NODE_ENV
Value: production
```

#### Variable 3: ELEVENLABS_API_KEY
```
Key: ELEVENLABS_API_KEY
Value: 4fa9cd17455dcfb60218e0a5f0b91cedfdfe03d5c14e611fd8508909533eea8c
```

### 6. Deploy!
Click **"Create Web Service"** and wait 2-5 minutes

### 7. Get Your URL
Once deployed, you'll get a URL like:
```
https://knowbest-backend.onrender.com
```

### 8. Test It!
```bash
curl https://your-app-name.onrender.com/health
```

Should return: `{"status":"ok","timestamp":"..."}`

---

## 🎯 What You'll Get

✅ Backend API running 24/7  
✅ User authentication  
✅ Todo sync endpoints  
✅ Ready for iOS app integration  

---

## 📝 Full Guide

See `backend/RENDER_DEPLOY.md` for detailed instructions.

---

## ⚠️ Important Notes

- **Free tier spins down after 15 min inactivity** (first request takes ~30 sec)
- **Root Directory MUST be `backend`** or deployment will fail
- **Environment variables are case-sensitive**

---

## 🆘 Need Help?

Check `backend/RENDER_DEPLOY.md` for troubleshooting!
