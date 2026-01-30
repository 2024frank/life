# Deploy Backend to Production

Your code is now on GitHub: https://github.com/2024frank/life

## 🚂 Deploy with Railway (Recommended - Easiest)

1. **Go to Railway**: https://railway.app
2. **Sign up/Login** (can use GitHub account)
3. **New Project** → Click "Deploy from GitHub repo"
4. **Select Repository**: Choose `2024frank/life`
5. **Configure**:
   - **Root Directory**: Set to `backend`
   - Railway will auto-detect Node.js
6. **Add Environment Variables** (in Variables tab):
   ```
   JWT_SECRET=<generate-a-random-secret>
   NODE_ENV=production
   ```
   Generate secret: `openssl rand -base64 32`
7. **Deploy**: Railway will automatically deploy!
8. **Get URL**: Copy your app URL (e.g., `https://your-app.up.railway.app`)

**Cost**: Free tier available, then $5/month

---

## 🎨 Deploy with Render (Free Tier Available)

1. **Go to Render**: https://render.com
2. **Sign up/Login** (can use GitHub account)
3. **New** → **Web Service**
4. **Connect Repository**: Select `2024frank/life`
5. **Configure**:
   - **Name**: `knowbest-backend`
   - **Root Directory**: `backend`
   - **Environment**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
6. **Environment Variables**:
   ```
   JWT_SECRET=<your-secret-key>
   NODE_ENV=production
   ```
7. **Create Web Service**
8. **Your URL**: `https://knowbest-backend.onrender.com`

**Cost**: Free (spins down after inactivity), $7/month for always-on

---

## 🔵 Deploy with Fly.io (Global Edge)

1. **Install CLI**: `npm install -g flyctl`
2. **Login**: `flyctl auth login`
3. **Initialize**: 
   ```bash
   cd backend
   flyctl launch
   ```
4. **Set Secret**:
   ```bash
   flyctl secrets set JWT_SECRET=<your-secret-key>
   ```
5. **Deploy**: `flyctl deploy`

**Cost**: Free tier available

---

## Generate Secure JWT Secret

```bash
# Using OpenSSL
openssl rand -base64 32

# Or using Node.js
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

## Test Your Deployment

After deployment, test your API:

```bash
# Health check
curl https://your-app-url.com/health

# Should return: {"status":"ok","timestamp":"..."}
```

## Next Steps

1. ✅ Backend deployed
2. 📱 Update iOS app with backend URL
3. 🔄 Implement sync in iOS app
4. 🧪 Test end-to-end

## Update iOS App

Once deployed, update your iOS app to connect to the backend:

1. Create `APIService.swift` in `knowbest/Managers/`
2. Set `baseURL` to your deployed backend URL
3. Implement authentication and sync

See `backend/README.md` for API documentation.
