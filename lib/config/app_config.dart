import 'package:flutter/foundation.dart';
import '../utils/platform_helper.dart';

class AppConfig {
  // Set to true to use the remote backend API, false to use mock data
  static const bool useRemoteAPI = true;

  // Environment detection (web-safe)
  static bool get isWeb => PlatformHelper.isWeb;

  static bool get isMobile => PlatformHelper.isMobile;

  static bool get isDesktop => PlatformHelper.isDesktop;

  static bool get isLocal => kDebugMode && isDesktop;

  // Backend URL configuration
  static String get backendBaseUrl {
    // Always use the single remote production URL for all platforms and builds.
    // Change this value if you need to point the app to a different remote host.
    const String productionUrl =
        'https://qwen-3-mental-health-chatbot-fastapi-subhadeepdouble-8rs5pd9z.leapcell.dev/api/v1';

    if (enableDebugLogging) {
      print(
        'AppConfig: Using single remote URL for all builds: $productionUrl',
      );
    }

    return productionUrl;
  }

  // Debug logging
  static bool get enableDebugLogging => kDebugMode;

  // Network timeout configuration
  static const Duration networkTimeout = Duration(seconds: 30);
}
