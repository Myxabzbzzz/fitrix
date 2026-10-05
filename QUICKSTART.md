# FITRIX Quick Start Guide

Complete guide to running your FITRIX AI fitness app with Ollama backend.

## ✅ What's Already Done

- ✅ Flutter app with 5 screens (Intro, Language, Sign-In, Profile, Chat)
- ✅ Node.js backend server
- ✅ Ollama integration
- ✅ macOS and web support enabled
- ✅ All dependencies installed

## 🚀 How to Run Everything

### Option 1: Quick Start (3 commands in 3 terminals)

**Terminal 1 - Ollama:**
```bash
ollama serve
```

**Terminal 2 - Backend:**
```bash
cd ~/fitrix/backend
npm start
```

**Terminal 3 - Flutter App:**
```bash
cd ~/fitrix
~/flutter/bin/flutter run -d macos
```

### Option 2: Using the Startup Script

**Terminal 1 - Ollama:**
```bash
ollama serve
```

**Terminal 2 - Backend:**
```bash
cd ~/fitrix/backend
./start.sh
```

**Terminal 3 - Flutter App:**
```bash
cd ~/fitrix
~/flutter/bin/flutter run -d macos
```

## 📱 App Flow

1. **Intro Screen** → Click "Start your journey"
2. **Language Selection** → Choose language → Click "Continue"
3. **Sign In** → Enter any email → Click "Continue"
4. **Profile** → Fill in your details → Click "Continue"
5. **Chat with Felix** → Start chatting with your AI fitness coach!

## 🧪 Testing the Backend

Test if backend is working:
```bash
# Health check
curl http://localhost:3000/health

# Send a test message
printf '{"message":"Hello","conversationId":"test"}' | \
  curl -X POST http://localhost:3000/chat \
  -H "Content-Type: application/json" -d @-
```

## 🔧 Troubleshooting

### Backend won't start - Port 3000 in use

```bash
# Find what's using port 3000
lsof -i :3000

# Kill the process (replace PID)
kill -9 <PID>

# Or use a different port
PORT=3001 npm start
```

Then update Flutter app:
```dart
// lib/core/constants/app_constants.dart
static const String apiBaseUrl = 'http://localhost:3001';
```

### Ollama not responding

```bash
# Make sure Ollama is running
ollama serve

# Check if it's accessible
curl http://localhost:11434/api/tags

# Make sure you have a model
ollama pull llama3.2
```

### Flutter app won't run

```bash
# Make sure you're in the right directory
cd ~/fitrix

# Use full path to flutter
~/flutter/bin/flutter run -d macos

# Or add Flutter to your PATH
export PATH="$HOME/flutter/bin:$PATH"
flutter run -d macos
```

### Chat responses are slow

This is normal - Ollama is generating responses on your CPU. First response takes longer.

To make it faster:
- Use a smaller model: `ollama pull llama3.2` (3.2B parameters)
- Or if you have GPU: responses will be much faster

### App shows mock responses instead of real AI

Make sure:
1. ✅ Ollama is running (`ollama serve`)
2. ✅ Backend is running (`npm start` in backend/)
3. ✅ Backend URL is correct in `app_constants.dart`

## 🎯 Features to Try

### In the Chat:
- "I want to build muscle"
- "Help me lose weight"
- "Create a workout plan"
- "I'm a beginner, where do I start?"

### Quick Reply Chips:
- Select your fitness goals
- Choose activities you enjoy
- Set your experience level

## 📊 Monitoring

### View Backend Logs:
The backend shows all requests:
```
[test-123] User: Hello
[test-123] Felix: Hello! Welcome to FITRIX!
```

### View Ollama Logs:
Ollama terminal shows model loading and inference.

## 🔄 Resetting Data

### Clear Chat History:
```bash
# On macOS:
rm ~/Library/Containers/com.example.fitrix/Data/Library/Preferences/\
   com.example.fitrix.plist

# Or reset from within app (coming soon)
```

### Reset Backend Conversations:
```bash
# Restart the backend server
# Conversations are stored in memory
```

## 🚀 Next Steps

1. **Customize Felix's personality**
   - Edit `backend/server.js` lines 41-57
   - Change the system prompt

2. **Use a different Ollama model**
   - Edit `backend/server.js` line 69
   - Change `llama3.2` to `mistral`, `llama2`, etc.

3. **Add Flutter to your PATH** (optional)
   ```bash
   echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.zshrc
   source ~/.zshrc
   flutter --version
   ```

4. **Deploy to iOS/Android**
   ```bash
   flutter run -d ios
   flutter run -d android
   ```

5. **Build for production**
   ```bash
   flutter build macos --release
   flutter build ios --release
   flutter build apk --release
   ```

## 📞 Need Help?

Check the detailed READMEs:
- `/README.md` - Main Flutter app documentation
- `/backend/README.md` - Backend server documentation

## ⚡ Quick Reference

| Component | Port | Command |
|-----------|------|---------|
| Ollama | 11434 | `ollama serve` |
| Backend | 3000 | `npm start` |
| Flutter | - | `flutter run -d macos` |

All done! Enjoy your AI fitness coach! 🏋️💪
