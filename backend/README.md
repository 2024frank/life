# KnowBest Backend API

REST API server for the KnowBest life management iOS app. Provides user authentication and todo synchronization across devices.

## Features

- 🔐 User authentication (JWT-based)
- 📝 Todo CRUD operations
- 🔄 Bulk sync endpoint for efficient data synchronization
- 🗄️ SQLite database (easily switchable to PostgreSQL/MySQL)
- 🔒 Secure password hashing with bcrypt
- 🌐 CORS enabled for iOS app

## Quick Start

### Prerequisites

- Node.js 18+ and npm

### Installation

```bash
cd backend
npm install
```

### Configuration

1. Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

2. Edit `.env` and set your `JWT_SECRET`:
```
JWT_SECRET=your-super-secret-random-string-here
```

### Run Locally

```bash
# Development mode (with auto-reload)
npm run dev

# Production mode
npm start
```

Server will start on `http://localhost:3000`

## API Endpoints

### Authentication

#### Register
```
POST /api/auth/register
Body: { "email": "user@example.com", "password": "password123" }
Response: { "token": "...", "user": {...} }
```

#### Login
```
POST /api/auth/login
Body: { "email": "user@example.com", "password": "password123" }
Response: { "token": "...", "user": {...} }
```

#### Verify Token
```
GET /api/auth/verify
Headers: { "Authorization": "Bearer <token>" }
Response: { "valid": true, "user": {...} }
```

### Todos

All todo endpoints require authentication header: `Authorization: Bearer <token>`

#### Get All Todos
```
GET /api/todos
Response: { "todos": [...] }
```

#### Get Single Todo
```
GET /api/todos/:id
Response: { "id": "...", "title": "...", ... }
```

#### Create Todo
```
POST /api/todos
Body: {
  "title": "Task title",
  "description": "Optional description",
  "priority": "medium",
  "dueDate": "2026-02-01T14:00:00Z",
  "reminderDate": "2026-02-01T13:30:00Z",
  "category": "General",
  "isRecurring": false,
  "recurrencePattern": null
}
```

#### Update Todo
```
PUT /api/todos/:id
Body: { "title": "Updated title", ... }
```

#### Delete Todo
```
DELETE /api/todos/:id
```

#### Sync Todos (Bulk)
```
POST /api/todos/sync
Body: { "todos": [{...}, {...}] }
Response: { "created": [...], "updated": [...], "errors": [...] }
```

## Deployment

### Option 1: Railway (Recommended)

1. Install Railway CLI:
```bash
npm i -g @railway/cli
```

2. Login and create project:
```bash
railway login
railway init
```

3. Set environment variables:
```bash
railway variables set JWT_SECRET=your-secret-key
railway variables set NODE_ENV=production
```

4. Deploy:
```bash
railway up
```

### Option 2: Render

1. Create a new Web Service on Render
2. Connect your GitHub repository
3. Set build command: `npm install`
4. Set start command: `npm start`
5. Add environment variables:
   - `JWT_SECRET` (generate a random string)
   - `NODE_ENV=production`
   - `PORT` (Render will set this automatically)

### Option 3: Heroku

1. Install Heroku CLI
2. Create app:
```bash
heroku create your-app-name
```

3. Set environment variables:
```bash
heroku config:set JWT_SECRET=your-secret-key
heroku config:set NODE_ENV=production
```

4. Deploy:
```bash
git push heroku main
```

### Option 4: DigitalOcean App Platform

1. Create a new App in DigitalOcean
2. Connect your repository
3. Set build command: `npm install`
4. Set run command: `npm start`
5. Add environment variables in the App Settings

### Option 5: Vercel (Serverless)

1. Install Vercel CLI:
```bash
npm i -g vercel
```

2. Deploy:
```bash
vercel
```

Note: Vercel requires serverless functions. You may need to restructure the app.

### Option 6: AWS/Google Cloud/Azure

For production at scale, consider:
- **AWS**: EC2, Elastic Beanstalk, or Lambda
- **Google Cloud**: Cloud Run or App Engine
- **Azure**: App Service or Functions

## Database

Currently uses SQLite for simplicity. For production, consider:

### PostgreSQL (Recommended for Production)

1. Install `pg` package:
```bash
npm install pg
```

2. Update `database/db.js` to use PostgreSQL connection pool
3. Set `DATABASE_URL` environment variable

### MySQL

1. Install `mysql2` package:
```bash
npm install mysql2
```

2. Update database connection in `database/db.js`

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | `3000` |
| `NODE_ENV` | Environment (development/production) | `development` |
| `JWT_SECRET` | Secret key for JWT tokens | **Required** |
| `DB_PATH` | SQLite database file path | `./data/knowbest.db` |

## Security Notes

- ⚠️ **Change JWT_SECRET** in production
- Use HTTPS in production
- Consider rate limiting for API endpoints
- Add input validation middleware
- Use environment variables for sensitive data
- Consider switching to PostgreSQL for production

## Testing

Test endpoints with curl or Postman:

```bash
# Register
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Get todos (replace TOKEN with actual token)
curl http://localhost:3000/api/todos \
  -H "Authorization: Bearer TOKEN"
```

## License

MIT
