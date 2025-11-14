import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../providers/loading_animation_provider.dart';
import '../utils/loading_animation_style.dart';

class AppLoadingWidget extends StatelessWidget {
  /// The size of the loading animation
  final double size;

  /// Optional custom color (overrides theme and provider settings)
  final Color? color;

  /// Whether to show a subtle background circle
  final bool showBackground;

  /// Background color for the optional background circle
  final Color? backgroundColor;

  /// Creates a loading widget with the specified size
  const AppLoadingWidget({
    super.key,
    this.size = 40,
    this.color,
    this.showBackground = false,
    this.backgroundColor,
  });

  const AppLoadingWidget.extraSmall({
    super.key,
    this.color,
    this.showBackground = false,
    this.backgroundColor,
  }) : size = 10;

  /// Creates a small loading widget (24px)
  const AppLoadingWidget.small({
    super.key,
    this.color,
    this.showBackground = false,
    this.backgroundColor,
  }) : size = 24;

  /// Creates a medium loading widget (32px)
  const AppLoadingWidget.medium({
    super.key,
    this.color,
    this.showBackground = false,
    this.backgroundColor,
  }) : size = 32;

  /// Creates a large loading widget (56px)
  const AppLoadingWidget.large({
    super.key,
    this.color,
    this.showBackground = false,
    this.backgroundColor,
  }) : size = 56;

  /// Creates an extra large loading widget (80px)
  const AppLoadingWidget.extraLarge({
    super.key,
    this.color,
    this.showBackground = false,
    this.backgroundColor,
  }) : size = 80;

  @override
  Widget build(BuildContext context) {
    return Consumer<LoadingAnimationProvider>(
      builder: (context, provider, child) {
        // Determine the color to use
        Color effectiveColor;
        if (color != null) {
          effectiveColor = color!;
        } else if (provider.useThemeColor) {
          // Prefer ForUI theme colors for consistency
          effectiveColor = FTheme.of(context).colors.primary;
        } else {
          effectiveColor = Color(provider.customColorValue);
        }

        // Build the animation widget
        Widget animation = _buildAnimation(
          provider.currentStyle,
          effectiveColor,
        );

        // Add background if requested
        if (showBackground) {
          final bg =
              backgroundColor ??
              FTheme.of(context).colors.background.withValues(alpha: 0.06);
          animation = Container(
            width: size + 16,
            height: size + 16,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular((size + 16) / 2),
            ),
            child: Center(child: animation),
          );
        }

        return animation;
      },
    );
  }

  /// Builds the specific animation widget based on the selected style
  Widget _buildAnimation(LoadingAnimationStyle style, Color effectiveColor) {
    switch (style) {
      case LoadingAnimationStyle.pulsatingDot:
        return LoadingAnimationWidget.beat(color: effectiveColor, size: size);

      case LoadingAnimationStyle.progressiveRing:
        return LoadingAnimationWidget.progressiveDots(
          color: effectiveColor,
          size: size,
        );

      case LoadingAnimationStyle.bouncingBall:
        return LoadingAnimationWidget.bouncingBall(
          color: effectiveColor,
          size: size,
        );

      case LoadingAnimationStyle.twoRotatingArc:
        return LoadingAnimationWidget.twoRotatingArc(
          color: effectiveColor,
          size: size,
        );

      case LoadingAnimationStyle.waveDots:
        return LoadingAnimationWidget.waveDots(
          color: effectiveColor,
          size: size,
        );

      case LoadingAnimationStyle.fourRotatingDots:
        return LoadingAnimationWidget.fourRotatingDots(
          color: effectiveColor,
          size: size,
        );

      case LoadingAnimationStyle.threeArchedCircle:
        return LoadingAnimationWidget.threeArchedCircle(
          color: effectiveColor,
          size: size,
        );

      case LoadingAnimationStyle.hexagonDots:
        return LoadingAnimationWidget.hexagonDots(
          color: effectiveColor,
          size: size,
        );

      case LoadingAnimationStyle.beat:
        return LoadingAnimationWidget.beat(color: effectiveColor, size: size);

      case LoadingAnimationStyle.inkDrop:
        return LoadingAnimationWidget.inkDrop(
          color: effectiveColor,
          size: size,
        );

      case LoadingAnimationStyle.staggeredDotsWave:
        return LoadingAnimationWidget.staggeredDotsWave(
          color: effectiveColor,
          size: size,
        );

      case LoadingAnimationStyle.fallingDot:
        return LoadingAnimationWidget.fallingDot(
          color: effectiveColor,
          size: size,
        );
    }
  }
}

/// A specialized loading widget for buttons that shows either an icon or loading animation
///
/// This is particularly useful for buttons that need to show loading state
/// while maintaining consistent sizing and appearance.
class AppButtonLoadingWidget extends StatelessWidget {
  /// Whether to show loading animation or the normal icon
  final bool isLoading;

  /// The icon to show when not loading
  final IconData icon;

  /// The size of both the icon and loading animation
  final double size;

  /// Optional custom color
  final Color? color;

  const AppButtonLoadingWidget({
    super.key,
    required this.isLoading,
    required this.icon,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: size,
        height: size,
        child: AppLoadingWidget(size: size, color: color),
      );
    }

    return Icon(icon, size: size, color: color);
  }
}

/// A specialized loading overlay that can be placed over content
///
/// This creates a semi-transparent overlay with a centered loading animation,
/// perfect for showing loading states over existing content.
class AppLoadingOverlay extends StatelessWidget {
  /// Whether the overlay should be visible
  final bool isLoading;

  /// The child widget to show when not loading
  final Widget child;

  /// Optional loading message to show below the animation
  final String? loadingMessage;

  /// The opacity of the overlay background
  final double overlayOpacity;

  /// The size of the loading animation
  final double animationSize;

  const AppLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingMessage,
    this.overlayOpacity = 0.8,
    this.animationSize = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: FTheme.of(
                context,
              ).colors.background.withValues(alpha: overlayOpacity),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppLoadingWidget(size: animationSize, showBackground: true),
                    if (loadingMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        loadingMessage!,
                        style: FTheme.of(context).typography.base.copyWith(
                          color: FTheme.of(context).colors.foreground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
