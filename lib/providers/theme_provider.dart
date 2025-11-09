import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  /// Returns true if the app should render in dark mode given current
  /// [themeMode] and platform brightness.
  bool isDark(BuildContext context) {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    // System: derive from platform brightness.
    final brightness = MediaQuery.maybePlatformBrightnessOf(context);
    return brightness == Brightness.dark;
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  void setSystemTheme() {
    _themeMode = ThemeMode.light;
    notifyListeners();
  }

  /// Explicit setter should you need to assign directly from UI selections.
  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }
}
