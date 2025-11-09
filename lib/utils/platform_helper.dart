import 'package:flutter/foundation.dart';

// Platform detection utility that works across all Flutter platforms
class PlatformHelper {
  // Web detection
  static bool get isWeb => kIsWeb;

  // Mobile platform detection
  static bool get isMobile {
    if (kIsWeb) return false;
    // Use defaultTargetPlatform from Flutter framework
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  // Desktop platform detection
  static bool get isDesktop {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  // Specific platform checks
  static bool get isAndroid {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android;
  }

  static bool get isIOS {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS;
  }

  static bool get isWindows {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows;
  }

  static bool get isMacOS {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.macOS;
  }

  static bool get isLinux {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.linux;
  }

  // Get platform name as string
  static String get platformName {
    if (kIsWeb) return 'Web';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.linux:
        return 'Linux';
      case TargetPlatform.fuchsia:
        return 'Fuchsia';
    }
  }
}
