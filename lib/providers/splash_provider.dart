import 'package:flutter/foundation.dart';

class SplashProvider extends ChangeNotifier {
  bool _showSplash = true;
  bool _initialized = false;
  DateTime? _startTime;

  bool get showSplash => _showSplash;
  bool get initialized => _initialized;

  SplashProvider() {
    // Record when the app started
    _startTime = DateTime.now();
  }

  Future<void> initialize() async {
    if (_initialized) return;

    // Calculate how much time has passed since app start
    final elapsed = DateTime.now().difference(_startTime!);
    final minimumDuration = const Duration(seconds: 5);

    // If less than minimum duration has passed, wait for the remainder
    if (elapsed < minimumDuration) {
      final remaining = minimumDuration - elapsed;
      await Future.delayed(remaining);
    }

    _showSplash = false;
    _initialized = true;
    notifyListeners();
  }

  void reset() {
    _showSplash = true;
    _initialized = false;
    _startTime = DateTime.now();
    notifyListeners();
  }
}
