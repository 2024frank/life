const express = require('express');
const OpenAI = require('openai');
const { authenticateToken } = require('./auth');

const router = express.Router();

// Initialize OpenAI client
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

// All routes require authentication
router.use(authenticateToken);

// Parse natural language to todos
router.post('/parse', async (req, res) => {
  try {
    const { text, conversationHistory = [] } = req.body;
    
    if (!text) {
      return res.status(400).json({ error: 'Text is required' });
    }
    
    // Check if OpenAI API key is configured
    if (!process.env.OPENAI_API_KEY) {
      return res.status(500).json({ error: 'OpenAI API key not configured' });
    }
    
    const messages = [
      {
        role: 'system',
        content: `You are a helpful todo assistant. Parse user input and extract todos.
Return a JSON object with this structure:
{
    "todos": [
        {
            "title": "Task title",
            "description": "Optional description",
            "dueDate": "ISO8601 date string or null",
            "reminderDate": "ISO8601 date string (30min before dueDate) or null",
            "priority": "low|medium|high|urgent or null",
            "category": "Work|Personal|Health|Shopping|Bills|Family|General or null",
            "isRecurring": true/false or null,
            "recurrencePattern": "daily|weekly|monthly|yearly or null"
        }
    ],
    "questions": ["Question 1", "Question 2"] or null,
    "needsClarification": true/false,
    "response": "Natural language response to speak back to the user"
}

Ask questions if:
- Task might be recurring (ask "Should this be a recurring task?")
- Time is ambiguous (ask "What time should I remind you?")
- Priority is unclear (ask "Is this urgent or can it wait?")

Extract dates from natural language:
- "tomorrow at 2pm" -> dueDate: tomorrow 14:00
- "today at 5pm" -> dueDate: today 17:00
- "next Monday" -> dueDate: next Monday
- "in 2 hours" -> dueDate: now + 2 hours

Always set reminderDate to 30 minutes before dueDate if dueDate exists.
Always include a friendly, Siri-like "response" that can be spoken back to the user.
Current date/time: ${new Date().toISOString()}`
      }
    ];
    
    // Add conversation history
    for (let i = 0; i < conversationHistory.length; i++) {
      if (i % 2 === 0) {
        messages.push({ role: 'user', content: conversationHistory[i] });
      } else {
        messages.push({ role: 'assistant', content: conversationHistory[i] });
      }
    }
    
    messages.push({ role: 'user', content: text });
    
    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: messages,
      temperature: 0.7,
      response_format: { type: 'json_object' }
    });
    
    const content = completion.choices[0]?.message?.content || '{}';
    const parsed = JSON.parse(content);
    
    res.json(parsed);
    
  } catch (error) {
    console.error('OpenAI API error:', error);
    res.status(500).json({ 
      error: 'Failed to parse with AI',
      details: error.message 
    });
  }
});

// Text-to-speech endpoint (optional - uses OpenAI TTS)
router.post('/speak', async (req, res) => {
  try {
    const { text } = req.body;
    
    if (!text) {
      return res.status(400).json({ error: 'Text is required' });
    }
    
    if (!process.env.OPENAI_API_KEY) {
      return res.status(500).json({ error: 'OpenAI API key not configured' });
    }
    
    const mp3 = await openai.audio.speech.create({
      model: 'tts-1',
      voice: 'nova', // Options: alloy, echo, fable, onyx, nova, shimmer
      input: text
    });
    
    const buffer = Buffer.from(await mp3.arrayBuffer());
    
    res.set({
      'Content-Type': 'audio/mpeg',
      'Content-Length': buffer.length
    });
    
    res.send(buffer);
    
  } catch (error) {
    console.error('OpenAI TTS error:', error);
    res.status(500).json({ error: 'Failed to generate speech' });
  }
});

module.exports = router;
