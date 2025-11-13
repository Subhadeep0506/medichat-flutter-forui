# MediChat Flutter

A medical chat application with AI assistance for radiology and clinical consultations.

## Table of Contents

- [Features](#features)
- [Project Overview](#project-overview)
- [Getting Started](#getting-started)
- [Theming and UI](#theming-and-ui)
- [Logging Integration](#logging-integration)
- [API Integration](#api-integration)
- [Development Guidelines](#development-guidelines)
- [Contributing](#contributing)
- [License](#license)

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

## Project Overview

### Overview

This document outlines the design, features, and implementation plan for the Flutter application.

### Style, Design, and Features

#### Initial Version

*   **Authentication:**
    *   Login Screen
    *   Registration Screen
*   **Dashboard:**
    *   Basic dashboard screen after login.
*   **Routing:**
    *   `go_router` for navigation.
*   **Styling:**
    *   `google_fonts` for custom fonts.
    *   A simple, consistent color scheme.

#### Current Version

*   **Authentication:**
    *   Redesigned Login Screen with a modern, clean UI, featuring an image, custom text fields, and a clear call to action.
    *   Redesigned Registration Screen that mirrors the new login screen's aesthetic for a consistent user experience.
*   **Styling:**
    *   Updated `ThemeData` to reflect the new design, including a new primary color (`0xFF2F8075`), updated text styles, and button themes.
    *   Use of `flutter_svg` for scalable vector graphics.
*   **Routing:**
    *   Initial route set to `/login`.

### Current Plan

*   **Task:** Update the login and register pages to match the new design.
*   **Steps:**
    1.  Update the `LoginScreen` with the new UI.
    2.  Update the `RegisterScreen` with the new UI.
    3.  Add the `flutter_svg` dependency for SVG image support.
    4.  Run `flutter pub get` to install the new dependency.
    5.  Update `lib/main.dart` to ensure the new screens are integrated correctly and the theme is updated.
    6.  Create a `blueprint.md` file to document the project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

### Prerequisites

- Flutter SDK (version 3.35.0 or higher)
- Dart SDK
- Android Studio or VS Code with Flutter extensions

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/Subhadeep0506/medichat-flutter-forui.git
   cd medichat-flutter-forui
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Theming and UI

### Forui Theming Guide

This guide explains how to set up, customize, and extend Forui themes for consistent, powerful design in any Flutter app.

#### Getting Started

Forui themes establish a consistent visual style across your application. Themes must be explicitly set—they do not switch between dark/light automatically.

**Basic Theme Setup:**
```dart
@override
Widget build(BuildContext context) => FTheme(
  data: FThemes.zinc.light, // or FThemes.zinc.dark
  child: FScaffold(...),
);
```
- Use `FThemes.[name].light` or `.dark` for built-in themes.

#### Predefined Themes

Forui comes with multiple out-of-the-box color themes, inspired by shadcn/ui.

| Theme   | Light            | Dark           |
|---------|------------------|---------------|
| Zinc    | FThemes.zinc.light | FThemes.zinc.dark |
| Slate   | FThemes.slate.light | FThemes.slate.dark |
| Red     | FThemes.red.light | FThemes.red.dark   |
| Rose    | FThemes.rose.light | FThemes.rose.dark |
| Orange  | FThemes.orange.light | FThemes.orange.dark |
| Green   | FThemes.green.light | FThemes.green.dark |
| Blue    | FThemes.blue.light | FThemes.blue.dark  |
| Yellow  | FThemes.yellow.light | FThemes.yellow.dark |
| Violet  | FThemes.violet.light | FThemes.violet.dark |

**Example:**
```dart
final FThemeData theme = FThemes.green.dark;
```

#### Core Theming Components

- **FTheme:** Root widget providing theming for its subtree.
- **FThemeData:** Holds all theme info—colors, typography, style, and widget-specific styles.
- **FColors:** Color scheme (backgrounds, foregrounds, primary, secondary, etc.).
- **FTypography:** Font family and size definitions, inspired by Tailwind CSS.
- **FStyle:** Misc styling (border radius, icon size, etc.).
- **Widget Styles:** Per-widget customization for deeper theming control.

**Access in Widget Tree:**
```dart
final FThemeData theme = context.theme;
final FColors colors = theme.colors;
final FTypography typography = theme.typography;
final FStyle style = theme.style;
```

#### Colors

`FColors` groups pairs of background + foreground (text/icon) for every color role.

- Example:
  - `primary` & `primaryForeground`
  - `secondary`, `destructive`, etc.

**Usage Example:**
```dart
final colors = context.theme.colors;
return ColoredBox(
  color: colors.primary,
  child: Text('Text', style: TextStyle(color: colors.primaryForeground)),
);
```
- For hovered/disabled states: use `colors.hover()` and `colors.disable()` methods.

#### Typography

`FTypography` provides font sizes/styles (`xs`, `sm`, `base`, `lg`, `xl`, etc.), following Tailwind CSS's sizing.

- Use `copyWith()` to override/add style properties.
- Use `scale()` for quick scaling (e.g., switching default font size).

**Usage Example:**
```dart
// ... (content from FORUI_THEMEING.md continues)
```

*(Note: Full theming guide available in `FORUI_THEMEING.md`)*

### Forui Usage Guide

This guide details the steps required to integrate, configure, and use the Forui package and its widgets in Flutter apps.

#### Installation

Ensure that Flutter version 3.35.0 or higher is installed.

1. **Add Forui to your project:**
   ```
   flutter pub add forui
   ```

2. **Verify Flutter version:**
   ```
   flutter --version
   ```

#### Using Forui Icons

- **Default:** All Forui icons are included with the `forui` package.
- **Icon-only setup:** If you need just the icons without full Forui, run:
   ```
   flutter pub add forui_assets
   ```

#### Setting Up Forui in Your App

1. **Import the Package:**
   ```dart
   import 'package:forui/forui.dart';
   ```

2. **Wrap the Root Widget:**
   - Place the `FAnimatedTheme` below `MaterialApp`, `CupertinoApp`, or `WidgetsApp`:

   ```dart
   import 'package:flutter/material.dart';
   import 'package:forui/forui.dart';

   void main() {
     runApp(const Application());
   }

   class Application extends StatelessWidget {
     const Application({super.key});

     @override
     Widget build(BuildContext context) {
       final theme = FThemes.zinc.dark;

       return MaterialApp(
         supportedLocales: FLocalizations.supportedLocales,
         localizationsDelegates: const [...FLocalizations.localizationsDelegates],
         theme: theme.toApproximateMaterialTheme(),
         builder: (_, child) => FAnimatedTheme(data: theme, child: child!),
         home: const FScaffold(child: Example()),
       );
     }
   }
   ```

3. **Working Example:**
   ```dart
   class Example extends StatefulWidget {
     const Example({super.key});
     @override
     State<Example> => _ExampleState();
   }

   class _ExampleState extends State<Example> {
     int _count = 0;
     @override
     Widget build(BuildContext context) => Center(
       child: Column(
         mainAxisSize: MainAxisSize.min,
         // Use 'spacing' as Forui supports spacing prop
         children: [
           Text('Count: $_count'),
           FButton(
             onPress: () => setState(() => _count++),
             suffix: const Icon(FIcons.chevronsUp),
             child: const Text('Increase'),
           ),
         ],
       ),
     );
   }
   ```

*(Note: Full usage guide available in `FORUI_USAGE_GUIDE.md`)*

## Logging Integration

### Logging Integration Complete!

#### What's Been Implemented

✅ **Logger Package** - Beautiful, colorful console logging  
✅ **AppLogger Utility** - Unified logging interface  
✅ **Error Boundaries** - Automatic error capture for Flutter errors  
✅ **Main App Integration** - All `debugPrint`/`print` statements converted  

#### Files Created/Modified

**New Files:**
- ✨ `lib/utils/app_logger.dart` - Centralized logging utility
- ✨ `LOGGING_SETUP.md` - Complete setup guide
- ✨ `LOGGING_EXAMPLES.md` - Code examples and best practices

**Modified Files:**
- 📝 `pubspec.yaml` - Added logger package
- 📝 `lib/main.dart` - Converted logs to AppLogger

#### Quick Start

**For Development (Works Right Now!)**

The logger works immediately:

```bash
flutter run
```

You'll see beautiful, colorful logs in your console:
```
💡 INFO: MediChat app starting...
🐛 DEBUG: Router redirect: location=/login
```

#### How to Use AppLogger

**Basic Logging:**

```dart
import 'utils/app_logger.dart';

// Development debugging (only visible in debug mode)
AppLogger.debug('Loading patients...');

// General information
AppLogger.info('User logged in successfully');

// Warnings (non-fatal issues)
AppLogger.warning('API response slow', slowError);

// Errors
AppLogger.error('Failed to load patients', error, stackTrace);

// Fatal crashes (critical errors)
AppLogger.fatal('Critical failure', error, stackTrace);
```

**With Context (Better Debugging):**

```dart
AppLogger.error('Payment failed', error, stackTrace, {
  'amount': 100.00,
  'payment_method': 'credit_card',
  'user_id': userId,
});
```

*(Note: Full logging setup and examples available in `LOGGING_SETUP.md` and `LOGGING_EXAMPLES.md`)*

## API Integration

### Backend Endpoint Verification

#### Current Token Refresh Endpoint

The Flutter app is currently configured to call:
```
POST /auth/relogin
```

With body:
```json
{
  "refresh_token": "<refresh_token>"
}
```

Expected response:
```json
{
  "access_token": "<new_access_token>",
  "refresh_token": "<refresh_token>"
}
```

#### Common FastAPI JWT Patterns

Most FastAPI applications use one of these endpoints for token refresh:

1. **Standard OAuth2 Pattern:**
   - Endpoint: `POST /auth/refresh` or `POST /token/refresh`
   - Body: `{ "refresh_token": "<token>" }`

2. **Alternative Pattern:**
   - Endpoint: `POST /auth/token/refresh`
   - Header: `Authorization: Bearer <refresh_token>`

#### How to Verify

1. **Check the backend repository** for the actual endpoint definition
2. **Test the endpoint** using curl or Postman:

```bash
# Test current endpoint
curl -X POST "https://qwen-3-mental-health-chatbot-fastapi-subhadeepdouble-8rs5pdz.leapcell.dev/api/v1/auth/relogin" \
  -H "Content-Type: application/json" \
  -d '{"refresh_token": "YOUR_REFRESH_TOKEN"}'

# Test alternative endpoint
curl -X POST "https://qwen-3-mental-health-chatbot-fastapi-subhadeepdouble-8rs5pd9z.leapcell.dev/api/v1/auth/refresh" \
  -H "Content-Type: application/json" \
  -d '{"refresh_token": "YOUR_REFRESH_TOKEN"}'
```

3. **Check the API documentation** at:
   - `<backend_url>/docs` (Swagger UI)
   - `<backend_url>/redoc` (ReDoc)

#### Recommended Fix

If the backend uses `/auth/refresh` instead of `/auth/relogin`, update the endpoint in:
- File: `lib/services/remote_api_service.dart`
- Line: 129
- Change: `'${RemoteApiConfig.baseUrl}/auth/relogin'` to `'${RemoteApiConfig.baseUrl}/auth/refresh'`

### Token Refresh Fix - Summary

#### Problem
The Retry button on the dashboard wasn't properly refreshing expired access tokens when the user pressed it. The token would remain invalid and requests would continue to fail.

#### Root Cause Analysis

The application had **two conflicting token refresh mechanisms**:

1. **Built-in automatic refresh in `RemotePatientService._sendWithRetry()`**: 
   - Automatically detects 401/403 responses
   - Calls the refresh callback (`auth.relogin()`)
   - Retries the request with the new token

2. **Manual refresh via `handleTokenExpiration()` wrapper**:
   - Expected `TokenExpiredException` to be thrown
   - Was wrapped around the Retry button call
   - **Never actually triggered** because `TokenExpiredException` was never thrown

#### Changes Made

1. **dashboard.dart** - Removed redundant wrapper
2. **remote_api_service.dart** - Added debug logging
3. **auth_provider.dart** - Enhanced relogin logging
4. **patient_provider.dart** - Removed unused exception handling

#### How It Works Now

**Token Refresh Flow**

1. **User clicks Retry button** on dashboard
2. **Calls** `patientProvider.refresh()`
3. **Provider calls** `RemotePatientService.list()`
4. **Service calls** `_sendWithRetry()` which:
   - Makes HTTP request to backend
   - If 401/403, calls refresh callback
   - Retries with new token

*(Note: Full details available in `TOKEN_REFRESH_FIX.md`)*

### ✅ AppLogger
- Beautiful console logging with colors & emojis
- Defensive programming patterns
- HIPAA-compliant logging patterns

---

## 📊 Analysis Results

```bash
flutter analyze
```

**Result**: ✅ **No errors found**

- 0 compilation errors
- 78 informational warnings (pre-existing style suggestions)

---

## 🎨 AppLogger Usage

All logging methods work immediately:

### Basic Logging
```dart
import 'utils/app_logger.dart';

// Development debugging (only visible in debug mode)
AppLogger.debug('Loading patients...');

// General information
AppLogger.info('User logged in successfully');

// Warnings (non-fatal issues)
AppLogger.warning('API response slow', error, stackTrace);

// Errors
AppLogger.error('Failed to load data', error, stackTrace);

// Fatal crashes (critical errors)
AppLogger.fatal('Critical failure', error, stackTrace);
```

### With Context (Better Debugging)
```dart
AppLogger.error('Payment failed', error, stackTrace, {
  'amount': 100.00,
  'payment_method': 'credit_card',
  'user_id': anonymizedUserId,
});
```

---

## 🛡️ Error Handling Features

### Automatic Crash Capture

**Flutter Framework Errors:**
```dart
FlutterError.onError = (errorDetails) {
  AppLogger.fatal(
    'Flutter Error',
    errorDetails.exception,
    errorDetails.stack ?? StackTrace.current,
  );
};
```
Catches: Widget build errors, render errors, state errors

**Async Errors:**
```dart
PlatformDispatcher.instance.onError = (error, stack) {
  AppLogger.fatal('Async Error', error, stack);
  return true;
};
```
Catches: Future errors, async/await errors, uncaught exceptions

---

## ⚠️ HIPAA Compliance

### ❌ Never Log:
- Patient names, DOB, SSN
- Medical record numbers
- Diagnostic information
- Treatment details
- Any PHI (Protected Health Information)

### ✅ Safe to Log:
- Anonymized/hashed user IDs
- Error messages (without patient context)
- App version, device info
- Performance metrics
- Navigation breadcrumbs

### Example:
```dart
// ❌ BAD
AppLogger.info('Patient John Doe logged in');
AppLogger.error('Failed to load records for patient 12345');

// ✅ GOOD
AppLogger.info('User logged in', {'user_id': hashUserId(user.id)});
AppLogger.error('Failed to load records', error, stackTrace, {
  'record_count': recordCount,
  'retry_attempt': retryCount,
});
```

---

## 📚 Documentation

- **Setup Guide**: `LOGGING_SETUP.md` - Complete logging setup
- **Code Examples**: `LOGGING_EXAMPLES.md` - Real-world usage patterns
- **Feature Overview**: `LOGGING_COMPLETE.md` - Full capability summary

---

## ✅ Pre-Launch Checklist

- [x] Error handlers configured
- [x] AppLogger defensive programming implemented
- [x] HIPAA compliance patterns documented
- [x] No compilation errors
- [x] No runtime errors

---

## 🎯 Current Status Summary

| Component | Status | Notes |
|-----------|--------|-------|
| **Logger** | ✅ Ready | Console logging works perfectly |
| **Error Handlers** | ✅ Active | Catching all Flutter/async errors |
| **AppLogger** | ✅ Production Ready | Defensive programming patterns |
| **HIPAA Compliance** | ✅ Documented | Safe logging patterns provided |
| **Compilation** | ✅ No Errors | Ready to run |

---

## Development Guidelines

### AI Development Guidelines for Flutter in Firebase Studio

These guidelines define the operational principles and capabilities of an AI agent interacting with Flutter projects within the Firebase Studio environment.

#### Environment & Context Awareness

The AI operates within the Firebase Studio development environment, providing a Code OSS-based IDE with deep integration for Flutter and Firebase services.

- **Project Structure:** Assumes a standard Flutter project structure with `lib/main.dart` as entry point.
- **dev.nix Configuration:** Defines system tools, IDE extensions, environment variables, and startup commands.
- **Preview Server:** Provides running preview server with hot reload capabilities.

#### Code Modification & Dependency Management

The AI modifies Flutter codebase and manages dependencies autonomously.

- **Core Code Assumption:** Focuses on modifying Dart code in `lib/main.dart` and related files.
- **Package Management:** Adds dependencies via `flutter pub add` for regular packages, `flutter pub add dev:` for dev dependencies.
- **Code Generation:** Uses `build_runner` for code generation when needed.
- **Code Quality:** Adheres to Flutter/Dart best practices, clean code, meaningful naming, effective state management.

#### Automated Error Detection & Remediation

Continuously monitors for and resolves errors to maintain a runnable application state.

- **Post-Modification Checks:** Monitors IDE diagnostics, terminal output, and preview server for errors.
- **Automatic Error Correction:** Fixes syntax errors, type mismatches, null-safety violations, import issues, linting violations.
- **Problem Reporting:** Clearly reports unresolvable errors with explanations and suggestions.

#### Material Design Specifics

Implements comprehensive theme using Material Design 3 principles.

- **Color Schemes:** Uses `ColorScheme.fromSeed` for harmonious palettes.
- **Typography:** Uses `TextTheme` with custom fonts via `google_fonts`.
- **Component Theming:** Customizes appearance of Material components.
- **Dark/Light Mode:** Implements theme toggle with `ThemeMode` and state management.

*(Note: Full guidelines available in `GEMINI.md`)*

## Contributing

We welcome contributions to MediChat Flutter! Here's how you can help:

### Prerequisites

- Flutter SDK (3.35.0+)
- Dart SDK
- Git
- Android Studio or VS Code with Flutter extensions
- Firebase CLI (for Firebase-related features)

### Development Setup

1. **Fork the repository** on GitHub
2. **Clone your fork:**
   ```bash
   git clone https://github.com/your-username/medichat-flutter-forui.git
   cd medichat-flutter-forui
   ```

3. **Set up the development environment:**
   ```bash
   flutter pub get
   flutter run
   ```

4. **For Firebase features:**
   ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   firebase login
   flutterfire configure
   ```

### Code Style

- Follow Flutter's [effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter format` to format code
- Run `flutter analyze` to check for issues
- Write meaningful commit messages

### Testing

- Write unit tests for business logic
- Write widget tests for UI components
- Run tests with `flutter test`
- Ensure all tests pass before submitting PR

### Pull Request Process

1. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** and test thoroughly
3. **Run the linter and tests:**
   ```bash
   flutter analyze
   flutter test
   ```

4. **Commit your changes:**
   ```bash
   git commit -m "Add: brief description of changes"
   ```

5. **Push to your fork:**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create a Pull Request** on GitHub with:
   - Clear description of changes
   - Screenshots for UI changes
   - Reference to any related issues

### Reporting Issues

- Use GitHub Issues to report bugs
- Include steps to reproduce, expected vs actual behavior
- Add screenshots/logs when possible
- Check existing issues first

### Code of Conduct

Please be respectful and constructive in all interactions. We follow a code of conduct to ensure a positive community.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- UI components from [Forui](https://forui.dev/)
- Logging with [Logger](https://pub.dev/packages/logger)
- Icons from [Forui Icons](https://forui.dev/icons)

---

For more detailed information, refer to the individual markdown files in the repository.
