import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_settings.dart';
import '../utils/app_logger.dart';

class ChatSettingsProvider with ChangeNotifier {
  static const String _storageKey = 'chat_settings';

  ChatSettings _settings = const ChatSettings();

  ChatSettings get settings => _settings;

  ChatSettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_storageKey);

      if (stored != null) {
        final Map<String, dynamic> json = jsonDecode(stored);
        _settings = ChatSettings.fromJson(json);
        notifyListeners();
      }
    } catch (e) {
      AppLogger.error('Error loading chat settings: $e');
      // Use default settings if loading fails
    }
  }

  Future<void> updateSettings(ChatSettings newSettings) async {
    try {
      _settings = newSettings;
      notifyListeners();

      // Persist to storage
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_settings.toJson());
      await prefs.setString(_storageKey, json);
    } catch (e) {
      AppLogger.error('Error saving chat settings: $e');
    }
  }

  Future<void> resetToDefaults() async {
    await updateSettings(const ChatSettings());
  }

  // Helper methods for common adjustments
  Future<void> setModel(String model) async {
    await updateSettings(_settings.copyWith(model: model));
  }

  Future<void> setModelProvider(String provider) async {
    await updateSettings(_settings.copyWith(modelProvider: provider));
  }

  Future<void> setTemperature(double temperature) async {
    await updateSettings(_settings.copyWith(temperature: temperature));
  }

  Future<void> setTopP(double topP) async {
    await updateSettings(_settings.copyWith(topP: topP));
  }

  Future<void> setMaxTokens(int maxTokens) async {
    await updateSettings(_settings.copyWith(maxTokens: maxTokens));
  }

  Future<void> setDebug(bool debug) async {
    await updateSettings(_settings.copyWith(debug: debug));
  }
}
