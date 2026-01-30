# API Keys Setup Guide

This guide will help you set up OpenAI and Eleven Labs API keys for the best voice assistant experience.

## Why You Need API Keys

- **OpenAI API Key**: Makes the voice assistant understand natural language much better
- **Eleven Labs API Key**: Provides natural, human-like voice responses (instead of robotic system voice)

**Note**: The app works without API keys, but with limited functionality:
- Without OpenAI: Uses basic rule-based parsing (less accurate)
- Without Eleven Labs: Uses iOS system text-to-speech (less natural)

---

## Step 1: Get OpenAI API Key

### 1.1 Sign Up / Login
1. Go to **https://platform.openai.com/api-keys**
2. Sign up or log in to your OpenAI account

### 1.2 Create API Key
1. Click **"Create new secret key"**
2. Give it a name (e.g., "KnowBest App")
3. **Copy the key immediately** - it starts with `sk-` and looks like:
   ```
   sk-proj-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```
   ⚠️ **Important**: You won't be able to see it again!

### 1.3 Add Credits (If Needed)
- OpenAI charges per API call (very affordable)
- Go to **Billing** → **Add payment method**
- Start with $5-10 credit for testing
- GPT-4o-mini is very cheap (~$0.15 per 1M tokens)

---

## Step 2: Get Eleven Labs API Key

### 2.1 Sign Up / Login
1. Go to **https://elevenlabs.io/app/api-keys**
2. Sign up or log in to your Eleven Labs account

### 2.2 Create API Key
1. Click **"Create API Key"**
2. Give it a name (e.g., "KnowBest Voice")
3. **Copy the key** - it looks like:
   ```
   xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```
   ⚠️ **Important**: Save it securely!

### 2.3 Free Tier
- Eleven Labs offers **10,000 characters/month free**
- Perfect for personal use
- Upgrade if you need more

---

## Step 3: Add Keys to iOS App

### Method 1: Through Voice Assistant (Built-in)

1. **Open the app** on your iPhone/iPad
2. **Tap the waveform icon** (top-left) → **"Voice Assistant"**
3. **Tap the gear icon** (⚙️) in the top-left
4. **Enter your API keys**:
   - Paste OpenAI key in "OpenAI API Key" field
   - Paste Eleven Labs key in "Eleven Labs API Key" field
5. **Tap "Save"**

### Method 2: Through Settings (If Available)

1. Open the app
2. Go to Settings (if available)
3. Find "API Keys" section
4. Enter and save your keys

---

## Step 4: Test Your Setup

1. **Open Voice Assistant** in the app
2. **Say "Hey Assistant"**
3. **Try a command** like:
   - "Remind me to call the dentist tomorrow at 2pm"
4. **Listen for the response** - should sound natural with Eleven Labs

---

## Troubleshooting

### OpenAI Key Not Working

**Symptoms**: Assistant doesn't understand complex requests

**Solutions**:
- ✅ Check key starts with `sk-`
- ✅ Verify key is copied correctly (no extra spaces)
- ✅ Check OpenAI account has credits
- ✅ Check internet connection
- ✅ Try regenerating key if expired

### Eleven Labs Key Not Working

**Symptoms**: Voice sounds robotic (using system voice)

**Solutions**:
- ✅ Check key is copied correctly
- ✅ Verify you haven't exceeded free tier limit
- ✅ Check internet connection
- ✅ App will fallback to system voice if key invalid

### Keys Not Saving

**Solutions**:
- ✅ Make sure you tap "Save" button
- ✅ Close and reopen app
- ✅ Check app has storage permissions

---

## Security Best Practices

1. ✅ **Never share your API keys**
2. ✅ **Don't commit keys to Git**
3. ✅ **Use different keys for development/production**
4. ✅ **Rotate keys periodically**
5. ✅ **Monitor usage** in OpenAI/Eleven Labs dashboards

---

## Cost Estimates

### OpenAI (GPT-4o-mini)
- **Very affordable**: ~$0.15 per 1M input tokens
- **Typical request**: ~500 tokens = $0.000075
- **1000 requests**: ~$0.075 (less than 10 cents!)
- **Monthly estimate**: $1-5 for personal use

### Eleven Labs
- **Free tier**: 10,000 characters/month
- **Typical response**: ~100 characters
- **Free tier**: ~100 responses/month
- **Paid**: $5/month for 30,000 characters

---

## Quick Links

- **OpenAI API Keys**: https://platform.openai.com/api-keys
- **OpenAI Pricing**: https://openai.com/pricing
- **Eleven Labs API Keys**: https://elevenlabs.io/app/api-keys
- **Eleven Labs Pricing**: https://elevenlabs.io/pricing

---

## Alternative: Use Without API Keys

The app works without API keys:
- ✅ Basic voice recognition
- ✅ Simple todo parsing
- ✅ System text-to-speech
- ✅ All core features

API keys just make it **much better**! 🚀
