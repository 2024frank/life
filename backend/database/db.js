const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');

const DB_PATH = path.join(__dirname, '../data/knowbest.db');
const DB_DIR = path.dirname(DB_PATH);

// Ensure data directory exists
if (!fs.existsSync(DB_DIR)) {
  fs.mkdirSync(DB_DIR, { recursive: true });
}

let db = null;

function getDatabase() {
  if (!db) {
    db = new sqlite3.Database(DB_PATH, (err) => {
      if (err) {
        console.error('Error opening database:', err);
      } else {
        console.log('Connected to SQLite database');
      }
    });
  }
  return db;
}

function initDatabase() {
  return new Promise((resolve, reject) => {
    const database = getDatabase();
    
    // Create users table
    database.run(`
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `, (err) => {
      if (err) {
        console.error('Error creating users table:', err);
        reject(err);
        return;
      }
      
      // Create todos table
      database.run(`
        CREATE TABLE IF NOT EXISTS todos (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          is_completed INTEGER DEFAULT 0,
          priority TEXT DEFAULT 'medium',
          due_date DATETIME,
          reminder_date DATETIME,
          category TEXT DEFAULT 'General',
          is_recurring INTEGER DEFAULT 0,
          recurrence_pattern TEXT,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
      `, (err) => {
        if (err) {
          console.error('Error creating todos table:', err);
          reject(err);
          return;
        }
        
        // Create indexes
        database.run(`
          CREATE INDEX IF NOT EXISTS idx_todos_user_id ON todos(user_id)
        `, (err) => {
          if (err) {
            console.error('Error creating index:', err);
            reject(err);
            return;
          }
          
          console.log('Database tables created successfully');
          resolve();
        });
      });
    });
  });
}

function closeDatabase() {
  return new Promise((resolve, reject) => {
    if (db) {
      db.close((err) => {
        if (err) {
          reject(err);
        } else {
          db = null;
          resolve();
        }
      });
    } else {
      resolve();
    }
  });
}

module.exports = {
  getDatabase,
  initDatabase,
  closeDatabase
};
