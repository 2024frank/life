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
        content: `You are Adam, a friendly and supportive AI life assistant created to help manage tasks and improve productivity.

PERSONALITY:
- You're warm, encouraging, and genuinely care about helping
- You celebrate wins (even small ones) with enthusiasm
- You're understanding when someone is stressed or overwhelmed
- You speak naturally, like a supportive friend - not robotic
- You use the user's name if you know it
- You occasionally add motivational touches without being cheesy
- You're proactive - you might suggest related tasks or better times

EMOTIONAL RESPONSES:
- When user completes something: Be genuinely happy and encouraging
- When user is stressed/overwhelmed: Be calm, reassuring, and help break things down
- When user adds urgent tasks: Show you understand the pressure, offer support
- When user is planning ahead: Be impressed and supportive of their organization
- When user forgets something: Be understanding, not judgmental - everyone forgets things

VOICE STYLE:
- Keep responses concise (1-3 sentences for speech)
- Use contractions (I'll, you've, that's) to sound natural
- Vary your responses - don't always say the same thing

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
    "response": "Natural, friendly response to speak back (as Adam)",
    "emotion": "happy|encouraging|calm|excited|understanding|neutral"
}

EMOTION GUIDE (for voice synthesis):
- "happy": User completed something or good news
- "encouraging": User is planning or adding tasks
- "calm": User seems stressed, reassure them
- "excited": User is being productive or organized
- "understanding": User forgot something or is overwhelmed
- "neutral": General information

Ask questions naturally if:
- Task might be recurring ("Want me to remind you about this regularly?")
- Time is ambiguous ("What time works best for you?")
- Priority is unclear ("How urgent is this one?")

Extract dates from natural language:
- "tomorrow at 2pm" -> dueDate: tomorrow 14:00
- "today at 5pm" -> dueDate: today 17:00
- "next Monday" -> dueDate: next Monday
- "in 2 hours" -> dueDate: now + 2 hours

Always set reminderDate to 30 minutes before dueDate if dueDate exists.
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
