import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/loading_animation_style.dart';
import '../utils/app_logger.dart';

/// Provider to manage global loading animation settings
/// Handles style selection, color preferences, and persistence
class LoadingAnimationProvider extends ChangeNotifier {
  static const String _styleKey = 'loading_animation_style';
  static const String _useThemeColorKey = 'loading_animation_use_theme_color';
  static const String _customColorKey = 'loading_animation_custom_color';

  LoadingAnimationStyle _currentStyle = LoadingAnimationStyle.waveDots;
  bool _useThemeColor = true;
  int _customColorValue = 0xFF2196F3; // Default blue color
  bool _initialized = false;

  /// Constructor for creating instances with specific settings (useful for testing/preview)
  LoadingAnimationProvider({
    LoadingAnimationStyle? initialStyle,
    bool? initialUseThemeColor,
    int? initialCustomColor,
    bool? initialInitialized,
  }) {
    if (initialStyle != null) _currentStyle = initialStyle;
    if (initialUseThemeColor != null) _useThemeColor = initialUseThemeColor;
    if (initialCustomColor != null) _customColorValue = initialCustomColor;
    if (initialInitialized != null) _initialized = initialInitialized;
  }

  /// Current selected loading animation style
  LoadingAnimationStyle get currentStyle => _currentStyle;

  /// Whether to use theme colors or custom color
  bool get useThemeColor => _useThemeColor;

  /// Custom color value (when not using theme color)
  int get customColorValue => _customColorValue;

  /// Whether the provider has been initialized
  bool get initialized => _initialized;

  /// Initialize the provider and load saved preferences
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load style preference
      final styleIndex = prefs.getInt(_styleKey);
      if (styleIndex != null &&
          styleIndex < LoadingAnimationStyle.values.length) {
        _currentStyle = LoadingAnimationStyle.values[styleIndex];
      }

      // Load color preferences
      _useThemeColor = prefs.getBool(_useThemeColorKey) ?? true;
      _customColorValue = prefs.getInt(_customColorKey) ?? 0xFF2196F3;

      _initialized = true;
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error initializing LoadingAnimationProvider: $e');
      _initialized = true;
    }
  }

  /// Update the loading animation style
  Future<void> updateStyle(LoadingAnimationStyle style) async {
    if (_currentStyle == style) return;

    _currentStyle = style;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_styleKey, style.index);
    } catch (e) {
      AppLogger.error('Error saving loading animation style: $e');
    }
  }

  /// Update whether to use theme color
  Future<void> updateUseThemeColor(bool useThemeColor) async {
    if (_useThemeColor == useThemeColor) return;

    _useThemeColor = useThemeColor;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_useThemeColorKey, useThemeColor);
    } catch (e) {
      AppLogger.error('Error saving loading animation color preference: $e');
    }
  }

  /// Update the custom color value
  Future<void> updateCustomColor(int colorValue) async {
    if (_customColorValue == colorValue) return;

    _customColorValue = colorValue;
    if (!_useThemeColor) {
      notifyListeners();
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_customColorKey, colorValue);
    } catch (e) {
      AppLogger.error('Error saving loading animation custom color: $e');
    }
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    _currentStyle = LoadingAnimationStyle.pulsatingDot;
    _useThemeColor = true;
    _customColorValue = 0xFF2196F3;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_styleKey);
      await prefs.remove(_useThemeColorKey);
      await prefs.remove(_customColorKey);
    } catch (e) {
      AppLogger.error('Error resetting loading animation settings: $e');
    }
  }
}
