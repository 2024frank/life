# Quick Start Guide

Get your backend running in 5 minutes!

## 1. Install Dependencies

```bash
cd backend
npm install
```

## 2. Set Up Environment

Create a `.env` file:

```bash
cp .env.example .env
```

Edit `.env` and set a secure JWT_SECRET:

```bash
# Generate a random secret
openssl rand -base64 32
```

Then update `.env`:
```
JWT_SECRET=<paste-your-generated-secret>
```

## 3. Start the Server

```bash
# Development mode (auto-reload)
npm run dev

# Production mode
npm start
```

Server runs on `http://localhost:3000`

## 4. Test It

Open another terminal and test:

```bash
# Health check
curl http://localhost:3000/health

# Register a user
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Login (save the token from register response)
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Get todos (replace TOKEN with actual token)
curl http://localhost:3000/api/todos \
  -H "Authorization: Bearer TOKEN"
```

## 5. Deploy Online

See `DEPLOYMENT.md` for detailed instructions. Quick options:

### Railway (Easiest)
1. Go to [railway.app](https://railway.app)
2. New Project → Deploy from GitHub
3. Select your repo, set root to `backend`
4. Add environment variables
5. Deploy!

### Render (Free Tier)
1. Go to [render.com](https://render.com)
2. New Web Service → Connect GitHub
3. Set root directory to `backend`
4. Add environment variables
5. Deploy!

## That's It! 🎉

Your backend is ready. Next step: Update your iOS app to sync with the backend.
