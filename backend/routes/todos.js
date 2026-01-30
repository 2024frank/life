const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { getDatabase } = require('../database/db');
const { authenticateToken } = require('./auth');

const router = express.Router();

// All routes require authentication
router.use(authenticateToken);

// Get all todos for user
router.get('/', (req, res) => {
  const db = getDatabase();
  const userId = req.user.userId;
  
  db.all(
    `SELECT * FROM todos WHERE user_id = ? ORDER BY created_at DESC`,
    [userId],
    (err, rows) => {
      if (err) {
        return res.status(500).json({ error: 'Failed to fetch todos' });
      }
      
      const todos = rows.map(row => ({
        id: row.id,
        title: row.title,
        description: row.description || '',
        isCompleted: row.is_completed === 1,
        priority: row.priority,
        dueDate: row.due_date,
        reminderDate: row.reminder_date,
        category: row.category,
        isRecurring: row.is_recurring === 1,
        recurrencePattern: row.recurrence_pattern,
        createdAt: row.created_at,
        updatedAt: row.updated_at
      }));
      
      res.json({ todos });
    }
  );
});

// Get single todo
router.get('/:id', (req, res) => {
  const db = getDatabase();
  const userId = req.user.userId;
  const todoId = req.params.id;
  
  db.get(
    'SELECT * FROM todos WHERE id = ? AND user_id = ?',
    [todoId, userId],
    (err, row) => {
      if (err) {
        return res.status(500).json({ error: 'Failed to fetch todo' });
      }
      
      if (!row) {
        return res.status(404).json({ error: 'Todo not found' });
      }
      
      res.json({
        id: row.id,
        title: row.title,
        description: row.description || '',
        isCompleted: row.is_completed === 1,
        priority: row.priority,
        dueDate: row.due_date,
        reminderDate: row.reminder_date,
        category: row.category,
        isRecurring: row.is_recurring === 1,
        recurrencePattern: row.recurrence_pattern,
        createdAt: row.created_at,
        updatedAt: row.updated_at
      });
    }
  );
});

// Create todo
router.post('/', (req, res) => {
  const db = getDatabase();
  const userId = req.user.userId;
  const {
    title,
    description = '',
    isCompleted = false,
    priority = 'medium',
    dueDate = null,
    reminderDate = null,
    category = 'General',
    isRecurring = false,
    recurrencePattern = null
  } = req.body;
  
  if (!title) {
    return res.status(400).json({ error: 'Title is required' });
  }
  
  const todoId = uuidv4();
  const now = new Date().toISOString();
  
  db.run(
    `INSERT INTO todos (
      id, user_id, title, description, is_completed, priority,
      due_date, reminder_date, category, is_recurring, recurrence_pattern,
      created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      todoId, userId, title, description, isCompleted ? 1 : 0, priority,
      dueDate, reminderDate, category, isRecurring ? 1 : 0, recurrencePattern,
      now, now
    ],
    function(err) {
      if (err) {
        return res.status(500).json({ error: 'Failed to create todo' });
      }
      
      // Fetch the created todo
      db.get(
        'SELECT * FROM todos WHERE id = ?',
        [todoId],
        (err, row) => {
          if (err || !row) {
            return res.status(500).json({ error: 'Failed to fetch created todo' });
          }
          
          res.status(201).json({
            id: row.id,
            title: row.title,
            description: row.description || '',
            isCompleted: row.is_completed === 1,
            priority: row.priority,
            dueDate: row.due_date,
            reminderDate: row.reminder_date,
            category: row.category,
            isRecurring: row.is_recurring === 1,
            recurrencePattern: row.recurrence_pattern,
            createdAt: row.created_at,
            updatedAt: row.updated_at
          });
        }
      );
    }
  );
});

// Update todo
router.put('/:id', (req, res) => {
  const db = getDatabase();
  const userId = req.user.userId;
  const todoId = req.params.id;
  const {
    title,
    description,
    isCompleted,
    priority,
    dueDate,
    reminderDate,
    category,
    isRecurring,
    recurrencePattern
  } = req.body;
  
  // Build update query dynamically
  const updates = [];
  const values = [];
  
  if (title !== undefined) {
    updates.push('title = ?');
    values.push(title);
  }
  if (description !== undefined) {
    updates.push('description = ?');
    values.push(description);
  }
  if (isCompleted !== undefined) {
    updates.push('is_completed = ?');
    values.push(isCompleted ? 1 : 0);
  }
  if (priority !== undefined) {
    updates.push('priority = ?');
    values.push(priority);
  }
  if (dueDate !== undefined) {
    updates.push('due_date = ?');
    values.push(dueDate);
  }
  if (reminderDate !== undefined) {
    updates.push('reminder_date = ?');
    values.push(reminderDate);
  }
  if (category !== undefined) {
    updates.push('category = ?');
    values.push(category);
  }
  if (isRecurring !== undefined) {
    updates.push('is_recurring = ?');
    values.push(isRecurring ? 1 : 0);
  }
  if (recurrencePattern !== undefined) {
    updates.push('recurrence_pattern = ?');
    values.push(recurrencePattern);
  }
  
  if (updates.length === 0) {
    return res.status(400).json({ error: 'No fields to update' });
  }
  
  updates.push('updated_at = ?');
  values.push(new Date().toISOString());
  values.push(todoId, userId);
  
  db.run(
    `UPDATE todos SET ${updates.join(', ')} WHERE id = ? AND user_id = ?`,
    values,
    function(err) {
      if (err) {
        return res.status(500).json({ error: 'Failed to update todo' });
      }
      
      if (this.changes === 0) {
        return res.status(404).json({ error: 'Todo not found' });
      }
      
      // Fetch updated todo
      db.get(
        'SELECT * FROM todos WHERE id = ?',
        [todoId],
        (err, row) => {
          if (err || !row) {
            return res.status(500).json({ error: 'Failed to fetch updated todo' });
          }
          
          res.json({
            id: row.id,
            title: row.title,
            description: row.description || '',
            isCompleted: row.is_completed === 1,
            priority: row.priority,
            dueDate: row.due_date,
            reminderDate: row.reminder_date,
            category: row.category,
            isRecurring: row.is_recurring === 1,
            recurrencePattern: row.recurrence_pattern,
            createdAt: row.created_at,
            updatedAt: row.updated_at
          });
        }
      );
    }
  );
});

// Delete todo
router.delete('/:id', (req, res) => {
  const db = getDatabase();
  const userId = req.user.userId;
  const todoId = req.params.id;
  
  db.run(
    'DELETE FROM todos WHERE id = ? AND user_id = ?',
    [todoId, userId],
    function(err) {
      if (err) {
        return res.status(500).json({ error: 'Failed to delete todo' });
      }
      
      if (this.changes === 0) {
        return res.status(404).json({ error: 'Todo not found' });
      }
      
      res.json({ message: 'Todo deleted successfully' });
    }
  );
});

// Sync todos (bulk create/update)
router.post('/sync', (req, res) => {
  const db = getDatabase();
  const userId = req.user.userId;
  const { todos } = req.body;
  
  if (!Array.isArray(todos)) {
    return res.status(400).json({ error: 'Todos must be an array' });
  }
  
  const results = {
    created: [],
    updated: [],
    errors: []
  };
  
  let processed = 0;
  const total = todos.length;
  
  if (total === 0) {
    return res.json(results);
  }
  
  todos.forEach(todo => {
    const {
      id, title, description = '', isCompleted = false,
      priority = 'medium', dueDate = null, reminderDate = null,
      category = 'General', isRecurring = false, recurrencePattern = null
    } = todo;
    
    if (!id || !title) {
      results.errors.push({ todo, error: 'Missing id or title' });
      processed++;
      if (processed === total) {
        res.json(results);
      }
      return;
    }
    
    const now = new Date().toISOString();
    
    // Check if todo exists
    db.get(
      'SELECT id FROM todos WHERE id = ? AND user_id = ?',
      [id, userId],
      (err, existing) => {
        if (err) {
          results.errors.push({ todo, error: err.message });
          processed++;
          if (processed === total) {
            res.json(results);
          }
          return;
        }
        
        if (existing) {
          // Update existing
          db.run(
            `UPDATE todos SET
              title = ?, description = ?, is_completed = ?, priority = ?,
              due_date = ?, reminder_date = ?, category = ?,
              is_recurring = ?, recurrence_pattern = ?, updated_at = ?
            WHERE id = ? AND user_id = ?`,
            [
              title, description, isCompleted ? 1 : 0, priority,
              dueDate, reminderDate, category,
              isRecurring ? 1 : 0, recurrencePattern, now,
              id, userId
            ],
            (err) => {
              if (err) {
                results.errors.push({ todo, error: err.message });
              } else {
                results.updated.push(id);
              }
              processed++;
              if (processed === total) {
                res.json(results);
              }
            }
          );
        } else {
          // Create new
          db.run(
            `INSERT INTO todos (
              id, user_id, title, description, is_completed, priority,
              due_date, reminder_date, category, is_recurring, recurrence_pattern,
              created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [
              id, userId, title, description, isCompleted ? 1 : 0, priority,
              dueDate, reminderDate, category, isRecurring ? 1 : 0, recurrencePattern,
              now, now
            ],
            (err) => {
              if (err) {
                results.errors.push({ todo, error: err.message });
              } else {
                results.created.push(id);
              }
              processed++;
              if (processed === total) {
                res.json(results);
              }
            }
          );
        }
      }
    );
  });
});

module.exports = router;
