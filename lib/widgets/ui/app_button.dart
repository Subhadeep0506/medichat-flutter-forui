import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../app_loading_widget.dart';

/// Primary app button wrapper. Keeps a single shape/style and supports a
/// loading state so callers don't need to handle child swapping.
/// Supports custom text styling through fontSize and fontWeight parameters.
/// Supports custom padding through the padding parameter.
class AppButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? leading;
  final String label;
  final bool isLoading;
  final dynamic style;
  final bool expand;
  final double? fontSize;
  final FontWeight? fontWeight;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leading,
    this.isLoading = false,
    this.style,
    this.expand = false,
    this.fontSize,
    this.fontWeight,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    // Prefer Forui's FButton which integrates with the app theme and
    // supports prefix content (icons/progress) and disabled/loading states.
    final prefixWidget = isLoading
        ? AppLoadingWidget(size: 12, color: theme.colors.primaryForeground)
        : leading;

    // Create text widget with custom styling if provided
    Widget textWidget = Text(label);
    if (fontSize != null || fontWeight != null) {
      // Use a custom text style that only modifies size and weight, not color
      // This allows ForUI to handle colors automatically based on button type
      textWidget = Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          // Explicitly don't set color - let ForUI handle it
        ),
      );
    }

    // Handle padding by modifying the button style if needed
    if (padding != null) {
      // When padding is provided, we need to create a custom style
      // Get the base style to modify
      FButtonStyle baseStyle;

      if (style != null && style is FButtonStyle) {
        // Direct FButtonStyle instance
        baseStyle = style;
      } else {
        baseStyle = theme.buttonStyles.primary; // Safe default
      }

      // Create modified style with custom padding
      final customStyle = baseStyle.copyWith(
        contentStyle: (contentStyle) => contentStyle.copyWith(padding: padding),
      );

      final button = FButton(
        prefix: prefixWidget,
        onPress: isLoading ? null : onPressed,
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        style: customStyle.call,
        child: textWidget,
      );

      // Apply custom border radius if provided
      if (borderRadius != null) {
        return Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          child: button,
        );
      }

      return button;
    }

    // If border radius is provided, create custom styled button
    if (borderRadius != null) {
      return _buildCustomRoundedButton(
        context,
        theme,
        prefixWidget,
        textWidget,
      );
    }

    // Create the button widget with default ForUI styling
    if (style != null) {
      return FButton(
        prefix: prefixWidget,
        onPress: isLoading ? null : onPressed,
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        style: style,
        child: textWidget,
      );
    } else {
      // No style specified, use FButton default
      return FButton(
        prefix: prefixWidget,
        onPress: isLoading ? null : onPressed,
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        child: textWidget,
      );
    }
  }

  Widget _buildCustomRoundedButton(
    BuildContext context,
    FThemeData themeData,
    Widget? prefixWidget,
    Widget textWidget,
  ) {
    // Determine colors based on style
    Color backgroundColor;
    Color borderColor;

    // Simple style detection - check if it's outline or primary
    final isOutline =
        style?.toString().toLowerCase().contains('outline') == true;

    if (isOutline) {
      backgroundColor = Colors.transparent;
      borderColor = themeData.colors.border;
    } else {
      // Default to primary style
      backgroundColor = themeData.colors.primary;
      borderColor = themeData.colors.primary;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: borderRadius,
        child: Container(
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (prefixWidget != null) ...[
                prefixWidget,
                const SizedBox(width: 8),
              ],
              DefaultTextStyle(
                style: TextStyle(
                  color: isOutline
                      ? themeData.colors.foreground
                      : themeData.colors.primaryForeground,
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                ),
                child: textWidget,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
