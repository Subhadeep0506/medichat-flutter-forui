import 'dart:math';
import 'dart:ui' show ImageFilter;

import 'package:MediChat/widgets/ui/app_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../utils/app_logger.dart';

/// Centralized toast service with ForUI styling.
class ToastService {
  static final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  static GlobalKey<ScaffoldMessengerState> get scaffoldMessengerKey =>
      _scaffoldMessengerKey;

  static GlobalKey<NavigatorState>? _navigatorKey;
  static Element? _registeredContext;

  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  static void registerContext(BuildContext context) {
    if (context is Element) {
      _registeredContext = context;
    }
  }

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final effectiveContext = _resolveContext(context);

      if (effectiveContext != null) {
        try {
          showRawFToast(
            context: effectiveContext,
            alignment: FToastAlignment.topCenter,
            duration: _defaultToastDuration,
            builder: (toastContext, entry) {
              final theme = Theme.of(toastContext);
              final colorScheme = theme.colorScheme;
              final accentColor = isError
                  ? colorScheme.error
                  : colorScheme.primary;
              final brightness = theme.brightness;
              final surfaceTint = brightness == Brightness.dark
                  ? colorScheme.surface.withValues(alpha:0.28)
                  : Colors.white.withValues(alpha:0.72);
              final borderColor = brightness == Brightness.dark
                  ? Colors.white.withValues(alpha:0.18)
                  : colorScheme.onSurface.withValues(alpha:0.12);
              final borderRadius = BorderRadius.circular(12);
              final shadowColor = theme.shadowColor.withValues(alpha:0.25);

              return FractionallySizedBox(
                widthFactor: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Material(
                    elevation: 8,
                    color: Colors.transparent,
                    shadowColor: shadowColor,
                    shape: RoundedRectangleBorder(borderRadius: borderRadius),
                    child: ClipRRect(
                      borderRadius: borderRadius,
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          Positioned.fill(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: borderRadius,
                                  color: surfaceTint,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withValues(alpha:
                                        brightness == Brightness.dark
                                            ? 0.04
                                            : 0.28,
                                      ),
                                      surfaceTint,
                                    ],
                                  ),
                                  border: Border.all(
                                    color: borderColor,
                                    width: 1.2,
                                  ),
                                ),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ),
                          const Positioned.fill(child: _GrainOverlay()),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: accentColor.withValues(alpha:0.12),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    icon,
                                    color: accentColor,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        title,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: accentColor,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        message,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                AppIconButton(
                                  icon: FIcons.x,
                                  onPressed: entry.dismiss,
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
          return;
        } catch (e) {
          AppLogger.debug('ForUI toast failed: $e');
        }
      }

      AppLogger.debug('Toast skipped - no valid context available: $message');
    });
  }

  static BuildContext? _resolveContext(BuildContext? providedContext) {
    if (providedContext is Element && providedContext.mounted) {
      return providedContext;
    }

    final navigatorContext = _navigatorKey?.currentContext;
    if (navigatorContext is Element && navigatorContext.mounted) {
      return navigatorContext;
    }

    if (_registeredContext != null && _registeredContext!.mounted) {
      return _registeredContext;
    }

    return null;
  }
}

class _GrainOverlay extends StatelessWidget {
  const _GrainOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(painter: const _GrainPainter(), isComplex: true),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter();

  static const int _seed = 1337;
  static const double _intensity = 0.045;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final random = Random(_seed);
    final particleCount = (size.width * size.height / 45)
        .clamp(120.0, 320.0)
        .toInt();
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < particleCount; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final baseOpacity = _intensity * (0.5 + random.nextDouble() * 0.5);
      paint.color = Colors.white.withValues(alpha:baseOpacity.clamp(0.01, 0.08));
      final radius = 0.4 + random.nextDouble() * 0.9;
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
