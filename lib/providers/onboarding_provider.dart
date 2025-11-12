import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

/// Manages whether the user has already seen the onboarding screen.
class OnboardingProvider with ChangeNotifier {
  static const _key = 'has_seen_onboarding';
  bool _hasSeen = false;
  bool _loaded = false;

  bool get hasSeen => _hasSeen;
  bool get loaded => _loaded;

  OnboardingProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasSeen = prefs.getBool(_key) ?? false;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('OnboardingProvider init error: $e');
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> markSeen() async {
    if (_hasSeen) return; // Already marked
    _hasSeen = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('Failed to persist onboarding flag: $e');
      }
    }
    notifyListeners();
  }
}
