# Deployment Guide

This guide covers deploying the KnowBest backend to various platforms.

## Quick Deploy Options

### 🚂 Railway (Easiest - Recommended)

1. **Sign up**: Go to [railway.app](https://railway.app) and sign up
2. **New Project**: Click "New Project" → "Deploy from GitHub repo"
3. **Select Repo**: Choose your `knowbest` repository
4. **Set Root Directory**: Set to `backend` folder
5. **Environment Variables**: Add these in Settings → Variables:
   ```
   JWT_SECRET=your-random-secret-key-here
   NODE_ENV=production
   PORT=3000
   ```
6. **Deploy**: Railway will automatically deploy
7. **Get URL**: Copy your app URL (e.g., `https://your-app.railway.app`)

**Cost**: Free tier available, then $5/month

---

### 🎨 Render (Simple & Free)

1. **Sign up**: Go to [render.com](https://render.com) and sign up
2. **New Web Service**: Click "New" → "Web Service"
3. **Connect Repo**: Connect your GitHub repository
4. **Configure**:
   - **Name**: `knowbest-backend`
   - **Root Directory**: `backend`
   - **Environment**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
5. **Environment Variables**: Add in Environment section:
   ```
   JWT_SECRET=your-random-secret-key-here
   NODE_ENV=production
   ```
6. **Deploy**: Click "Create Web Service"
7. **Get URL**: Your app will be at `https://knowbest-backend.onrender.com`

**Cost**: Free tier available (spins down after inactivity), $7/month for always-on

---

### 🟣 Heroku (Classic)

1. **Install CLI**: `npm install -g heroku-cli`
2. **Login**: `heroku login`
3. **Create App**: `heroku create knowbest-backend`
4. **Set Config**:
   ```bash
   heroku config:set JWT_SECRET=your-random-secret-key
   heroku config:set NODE_ENV=production
   ```
5. **Deploy**: `git push heroku main`
6. **Open**: `heroku open`

**Cost**: No free tier anymore, starts at $5/month

---

### ☁️ DigitalOcean App Platform

1. **Sign up**: Go to [digitalocean.com](https://digitalocean.com)
2. **Create App**: Click "Create" → "Apps" → "GitHub"
3. **Select Repo**: Choose your repository
4. **Configure**:
   - **Root Directory**: `backend`
   - **Build Command**: `npm install`
   - **Run Command**: `npm start`
5. **Environment Variables**: Add in App Settings
6. **Deploy**: Click "Create Resources"

**Cost**: Starts at $5/month

---

### 🔵 Fly.io (Global Edge)

1. **Install CLI**: `npm install -g flyctl`
2. **Login**: `flyctl auth login`
3. **Init**: `cd backend && flyctl launch`
4. **Set Secrets**:
   ```bash
   flyctl secrets set JWT_SECRET=your-random-secret-key
   ```
5. **Deploy**: `flyctl deploy`

**Cost**: Free tier available, then pay-as-you-go

---

## Environment Variables

All platforms require these environment variables:

```bash
JWT_SECRET=your-random-secret-key-here  # REQUIRED - Generate with: openssl rand -base64 32
NODE_ENV=production
PORT=3000  # Usually set automatically by platform
```

## Generate Secure JWT Secret

```bash
# Using OpenSSL
openssl rand -base64 32

# Using Node.js
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

## Testing Your Deployment

After deployment, test your API:

```bash
# Health check
curl https://your-app-url.com/health

# Register a user
curl -X POST https://your-app-url.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

## Updating iOS App

After deploying, update your iOS app's API base URL:

1. Open `knowbest/Managers/APIService.swift` (you'll need to create this)
2. Set `baseURL` to your deployed backend URL
3. Update authentication to use JWT tokens

## Database Considerations

### SQLite (Current)
- ✅ Simple, no setup needed
- ❌ Not ideal for production
- ❌ File-based, can be lost
- ✅ Good for testing/small apps

### PostgreSQL (Recommended for Production)
- ✅ Production-ready
- ✅ Better performance
- ✅ Can use managed services (Railway, Render, etc.)
- ⚠️ Requires migration

### Migration to PostgreSQL

1. Install `pg` package:
   ```bash
   npm install pg
   ```

2. Update `database/db.js` to use PostgreSQL
3. Set `DATABASE_URL` environment variable
4. Most platforms provide PostgreSQL add-ons

## Monitoring & Logs

### Railway
- Logs: Available in dashboard
- Metrics: Built-in monitoring

### Render
- Logs: Available in dashboard
- Metrics: Basic monitoring

### Heroku
- Logs: `heroku logs --tail`
- Add-ons: New Relic, Papertrail

## SSL/HTTPS

All platforms provide HTTPS automatically:
- Railway: ✅ Automatic
- Render: ✅ Automatic
- Heroku: ✅ Automatic
- DigitalOcean: ✅ Automatic
- Fly.io: ✅ Automatic

## Scaling

For high traffic:
1. **Database**: Switch to PostgreSQL
2. **Caching**: Add Redis
3. **Load Balancing**: Use platform's load balancer
4. **CDN**: For static assets (if any)
5. **Rate Limiting**: Add rate limiting middleware

## Backup

### SQLite
- Backup the `data/knowbest.db` file regularly
- Most platforms provide volume persistence

### PostgreSQL
- Use platform's automated backups
- Or set up manual backups

## Troubleshooting

### App won't start
- Check logs in platform dashboard
- Verify environment variables are set
- Ensure `PORT` is set correctly

### Database errors
- Verify database file permissions
- Check disk space
- For SQLite: ensure write permissions

### CORS errors
- Update CORS origin in `server.js` to your iOS app's domain
- Or use wildcard `*` for development (not recommended for production)

## Next Steps

1. ✅ Deploy backend
2. ✅ Test API endpoints
3. ✅ Update iOS app with backend URL
4. ✅ Implement sync in iOS app
5. ✅ Test end-to-end

## Support

For issues:
- Check platform documentation
- Review server logs
- Test locally first
- Verify environment variables
