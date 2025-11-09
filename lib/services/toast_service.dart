import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Centralized toast service with ForUI styling.
class ToastService {
  static final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  static GlobalKey<ScaffoldMessengerState> get scaffoldMessengerKey =>
      _scaffoldMessengerKey;

  static const Duration _defaultToastDuration = Duration(seconds: 5);

  static void showSuccess(String message, {BuildContext? context}) {
    _show(
      message,
      context: context,
      isError: false,
      title: 'Success',
      icon: Icons.check_circle,
    );
  }

  static void showError(String message, {BuildContext? context}) {
    _show(
      message,
      context: context,
      isError: true,
      title: 'Error',
      icon: Icons.error,
    );
  }

  static void showInfo(String message, {BuildContext? context}) {
    _show(
      message,
      context: context,
      isError: false,
      title: 'Info',
      icon: Icons.info,
    );
  }

  static void showWarning(String message, {BuildContext? context}) {
    _show(
      message,
      context: context,
      isError: false,
      title: 'Warning',
      icon: Icons.warning,
    );
  }

  static void _show(
    String message, {
    BuildContext? context,
    required bool isError,
    required String title,
    required IconData icon,
  }) {
    // Delay the toast to ensure the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only use ForUI toast if a context is available.
      if (context != null && context.mounted) {
        try {
          showFToast(
            context: context,
            alignment: FToastAlignment.topCenter,
            duration: _defaultToastDuration,
            icon: Icon(icon),
            title: Text(title),
            description: Text(message),
          );
        } catch (e) {
          debugPrint('ForUI toast failed: $e');
        }
      } else {
        debugPrint('Toast skipped - no valid context available: $message');
      }
    });
  }
}
