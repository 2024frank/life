# Voice Assistant Setup Guide

## Features

Your life management app now includes a **Voice Assistant** with "Hey Assistant" activation, just like Siri!

### Capabilities:
- 🎤 **Voice Activation**: Say "Hey Assistant" to activate
- 🧠 **OpenAI Integration**: Advanced natural language understanding
- 🔊 **Eleven Labs Voice**: Natural voice synthesis (falls back to system voice)
- 💬 **Conversational**: Asks clarifying questions (e.g., "Should this be recurring?")
- 📅 **Smart Parsing**: Understands dates, times, priorities, and categories
- 🔄 **Recurring Tasks**: Supports daily, weekly, monthly, yearly repetition

## Setup Instructions

### 1. Add Required Permissions

Add these keys to your `Info.plist` (or in Xcode under Target > Info > Custom iOS Target Properties):

```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>We need speech recognition to understand your voice commands</string>

<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access to listen for "Hey Assistant" and your voice commands</string>
```

**In Xcode:**
1. Select your project target
2. Go to **Info** tab
3. Add these keys:
   - `Privacy - Speech Recognition Usage Description`: "We need speech recognition to understand your voice commands"
   - `Privacy - Microphone Usage Description`: "We need microphone access to listen for 'Hey Assistant' and your voice commands"

### 2. Get API Keys (Optional but Recommended)

#### OpenAI API Key (for better understanding):
1. Go to https://platform.openai.com/api-keys
2. Sign up/login and create an API key
3. In the app, tap the ⚙️ gear icon in Voice Assistant
4. Enter your OpenAI API key
5. The app will use GPT-4o-mini for natural language understanding

#### Eleven Labs API Key (for natural voice):
1. Go to https://elevenlabs.io/app/api-keys
2. Sign up/login and create an API key
3. In the app, tap the ⚙️ gear icon in Voice Assistant
4. Enter your Eleven Labs API key
5. The app will use Eleven Labs for voice synthesis

**Note:** The app works without API keys but will use:
- Local rule-based parsing (less accurate)
- System text-to-speech (less natural)

### 3. How to Use

1. **Open Voice Assistant**: Tap the waveform icon (top-left) → "Voice Assistant"
2. **Say "Hey Assistant"**: The app will listen for this wake word
3. **Speak your request**: Examples:
   - "Remind me to call the dentist tomorrow at 2pm"
   - "Can you remind me to buy groceries today at 5pm?"
   - "I need to finish the project report urgent"
4. **Answer questions**: If the assistant asks a question (like "Should this be recurring?"), just speak your answer
5. **Confirmation**: The assistant will confirm what it created and speak it back to you

### 4. Example Conversations

**User:** "Hey Assistant, remind me to call the dentist tomorrow at 2pm"

**Assistant:** "I've created 1 todo for you. 1. Call the dentist scheduled for [date] 2:00 PM."

---

**User:** "Hey Assistant, remind me to water the plants every day"

**Assistant:** "Should this be a recurring task?"

**User:** "Yes, daily"

**Assistant:** "I've created 1 todo for you. 1. Water the plants scheduled as a daily recurring task."

---

**User:** "Hey Assistant, can you remind me that I should go get groceries at 10am tomorrow and also call mom at 3pm"

**Assistant:** "I've created 2 todos for you. 1. Get groceries scheduled for [date] 10:00 AM. 2. Call mom scheduled for [date] 3:00 PM."

## Technical Details

### Voice Activation
- Uses iOS Speech Recognition framework
- Continuously listens for "Hey Assistant" wake word
- Activates when wake word detected
- Stops listening after processing your request

### Natural Language Processing
- With OpenAI: Uses GPT-4o-mini for understanding
- Without OpenAI: Uses rule-based parsing
- Extracts: title, description, due date, reminder time, priority, category, recurrence

### Voice Synthesis
- With Eleven Labs: Natural, human-like voice
- Without Eleven Labs: iOS AVSpeechSynthesizer
- Speaks confirmations and questions

### Recurring Tasks
- Supports: Daily, Weekly, Monthly, Yearly
- Stored in TodoItem model
- Can be set via voice or manually

## Troubleshooting

**"Hey Assistant" not working:**
- Check microphone permissions in Settings > Privacy > Microphone
- Check speech recognition permissions in Settings > Privacy > Speech Recognition
- Make sure you're speaking clearly

**API not working:**
- Check your API keys in Settings (gear icon)
- Verify API keys are correct
- Check internet connection
- App will fall back to local parsing if API fails

**Voice not speaking:**
- Check device volume
- Try setting Eleven Labs API key for better voice
- System voice should work without API key

## Privacy

- Speech recognition happens on-device for wake word detection
- With OpenAI: Your requests are sent to OpenAI API (check their privacy policy)
- With Eleven Labs: Text is sent to Eleven Labs for voice synthesis
- All todos are stored locally on your device
- No data is shared with third parties except API providers you configure
