# MediChat Flutter

A medical chat application with AI assistance for radiology and clinical consultations.

## Features

### Chat Settings
The chat interface includes configurable settings to control AI response quality and behavior:

- **Settings Button**: Located beside the chat input field with a gear icon
- **Visual Indicator**: Shows a blue dot when custom settings are applied
- **Persistent Storage**: Settings are saved and persist across app sessions

#### Available Settings:

1. **Model Configuration**
   - **Model Provider**: Choose between 'groq' or 'local'
   - **Model**: Select from available AI models (qwen3-32b, deepseek-r1, llama variants, etc.)

2. **Response Quality Controls**
   - **Temperature** (0.0 - 2.0): Controls randomness. Lower values = more focused responses
   - **Top P** (0.1 - 1.0): Nucleus sampling probability for token diversity
   - **Max Tokens** (1 - 8192): Maximum response length

3. **Debug Options**
   - **Debug Mode**: Use mock responses for testing instead of calling the actual model

#### Usage:
1. Click the settings button (gear icon) next to the message input
2. Adjust desired parameters in the settings dialog
3. Click "Save Settings" to apply changes
4. Settings are automatically included in all subsequent chat requests

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
