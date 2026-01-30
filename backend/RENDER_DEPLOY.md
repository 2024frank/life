# Deploy to Render - Step by Step Guide

## Prerequisites
✅ Backend code is ready  
✅ GitHub repository: https://github.com/2024frank/life  
✅ Node.js dependencies installed  

---

## Step 1: Create Render Account

1. Go to **https://render.com**
2. Click **"Get Started for Free"**
3. Sign up with **GitHub** (recommended - easier to connect repo)

---

## Step 2: Create New Web Service

1. In Render dashboard, click **"New +"** button
2. Select **"Web Service"**
3. Click **"Connect account"** if you haven't connected GitHub yet
4. Select your GitHub account
5. Find and select repository: **`2024frank/life`**
6. Click **"Connect"**

---

## Step 3: Configure Service

Fill in these settings:

### Basic Settings
- **Name**: `knowbest-backend` (or any name you like)
- **Region**: Choose closest to you (e.g., `Oregon (US West)`)
- **Branch**: `main`
- **Root Directory**: `backend` ⚠️ **IMPORTANT!**

### Build & Deploy
- **Runtime**: `Node`
- **Build Command**: `npm install`
- **Start Command**: `npm start`

### Environment
- **Environment**: `Node`

---

## Step 4: Add Environment Variables

Click **"Advanced"** → **"Add Environment Variable"**

Add these variables:

### Required Variables:

1. **JWT_SECRET**
   - Key: `JWT_SECRET`
   - Value: `++k1/5SKa4v81lewk2tAgIhNL4I1Yb/QjiWsag33DH0=` (or generate new one)
   - Generate new: `openssl rand -base64 32`

2. **NODE_ENV**
   - Key: `NODE_ENV`
   - Value: `production`

3. **ELEVENLABS_API_KEY** (Optional but recommended)
   - Key: `ELEVENLABS_API_KEY`
   - Value: `4fa9cd17455dcfb60218e0a5f0b91cedfdfe03d5c14e611fd8508909533eea8c`

### Optional Variables:

4. **PORT** (usually auto-set by Render, but you can set it)
   - Key: `PORT`
   - Value: `3000`

---

## Step 5: Deploy

1. Click **"Create Web Service"**
2. Render will:
   - Clone your repository
   - Install dependencies (`npm install`)
   - Start the server (`npm start`)
3. Wait for deployment (usually 2-5 minutes)
4. You'll see build logs in real-time

---

## Step 6: Get Your URL

Once deployed:
1. Your service will have a URL like: `https://knowbest-backend.onrender.com`
2. Copy this URL - you'll need it for your iOS app!

---

## Step 7: Test Your Deployment

### Test Health Endpoint:
```bash
curl https://your-app-name.onrender.com/health
```

Should return:
```json
{"status":"ok","timestamp":"2026-01-31T..."}
```

### Test Registration:
```bash
curl -X POST https://your-app-name.onrender.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

Should return:
```json
{
  "message": "User created successfully",
  "token": "...",
  "user": {...}
}
```

---

## Troubleshooting

### Build Fails
- ✅ Check Root Directory is set to `backend`
- ✅ Check Build Command is `npm install`
- ✅ Check Start Command is `npm start`
- ✅ Check Node version in package.json

### Server Won't Start
- ✅ Check logs in Render dashboard
- ✅ Verify PORT environment variable
- ✅ Check JWT_SECRET is set

### 502 Bad Gateway
- ✅ Wait a few minutes (free tier spins down after inactivity)
- ✅ Check server logs
- ✅ Verify database initialization

### Environment Variables Not Working
- ✅ Make sure variables are added in Render dashboard
- ✅ Redeploy after adding variables
- ✅ Check variable names match exactly (case-sensitive)

---

## Free Tier Limitations

- ⚠️ **Spins down after 15 minutes of inactivity**
- ⚠️ **First request after spin-down takes ~30 seconds**
- ⚠️ **512 MB RAM limit**
- ✅ **Perfect for testing and small apps**

---

## Upgrade to Always-On

If you want 24/7 uptime:
1. Go to your service settings
2. Click **"Change Plan"**
3. Select **"Starter"** ($7/month)
4. Your app will never spin down

---

## Next Steps

1. ✅ Backend deployed
2. 📱 Update iOS app with backend URL
3. 🔄 Implement sync in iOS app
4. 🧪 Test end-to-end

---

## Quick Reference

**Your Backend URL**: `https://your-app-name.onrender.com`

**API Endpoints**:
- Health: `GET /health`
- Register: `POST /api/auth/register`
- Login: `POST /api/auth/login`
- Todos: `GET /api/todos` (requires auth)

**Environment Variables Needed**:
- `JWT_SECRET` ✅
- `NODE_ENV=production` ✅
- `ELEVENLABS_API_KEY` (optional) ✅
