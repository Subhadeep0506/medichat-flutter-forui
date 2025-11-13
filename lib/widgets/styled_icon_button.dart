import 'package:flutter/material.dart';
import 'app_loading_widget.dart';

/// A styled icon button that matches the chat screen design
class StyledIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double iconSize;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? customColor;
  final bool isExpanded;
  final double borderRadius;

  const StyledIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.iconSize = 18,
    this.padding = const EdgeInsets.all(6),
    this.margin,
    this.customColor,
    this.isExpanded = false,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget button = Container(
      decoration: BoxDecoration(
        color: isExpanded
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: AnimatedRotation(
          turns: isExpanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 300),
          child: Padding(
            padding: padding,
            child: Icon(
              icon,
              color: isExpanded
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              size: iconSize,
            ),
          ),
        ),
        iconSize: iconSize,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: tooltip,
      ),
    );

    if (margin != null) {
      button = Container(margin: margin, child: button);
    }

    return button;
  }
}

/// A rectangular styled button for app bars and toolbars
class StyledRectButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool isActive;
  final bool isLoading;
  final double width;
  final double height;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? customColor;

  const StyledRectButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.isActive = false,
    this.isLoading = false,
    this.width = 48,
    this.height = 48,
    this.margin,
    this.padding,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive
                ? (customColor ??
                          Theme.of(context).colorScheme.primaryContainer)
                      .withValues(alpha: 0.7)
                : Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? (customColor ?? Theme.of(context).colorScheme.primary)
                        .withValues(alpha: 0.3)
                  : Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: isLoading
              ? Center(
                  child: AppButtonLoadingWidget(
                    isLoading: true,
                    icon: icon,
                    size: 20,
                    color: isActive
                        ? (customColor ?? Theme.of(context).colorScheme.primary)
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                )
              : Icon(
                  icon,
                  size: 20,
                  color: isActive
                      ? (customColor ?? Theme.of(context).colorScheme.primary)
                      : Theme.of(context).colorScheme.onSurface,
                ),
        ),
      ),
    );

    if (margin != null) {
      button = Container(margin: margin, child: button);
    }

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}

/// Enhanced floating action button with gradient and animation
class StyledFloatingActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final String? label;
  final bool isLoading;
  final Color? customColor;

  const StyledFloatingActionButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.label,
    this.isLoading = false,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget fabContent = AppButtonLoadingWidget(
      isLoading: isLoading,
      icon: icon,
      size: 24,
      color: Theme.of(context).colorScheme.secondary,
    );

    if (label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        tooltip: tooltip,
        backgroundColor: customColor ?? Theme.of(context).colorScheme.primary,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        icon: fabContent,
        label: Text(
          label!,
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (customColor ?? Theme.of(context).colorScheme.primary)
                .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onPressed,
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Center(child: fabContent),
          ),
        ),
      ),
    );
  }
}

/// A styled icon button that supports animated rotation
class StyledRotatingIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double iconSize;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? customColor;
  final bool isExpanded;

  const StyledRotatingIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.iconSize = 18,
    this.padding = const EdgeInsets.all(6),
    this.margin,
    this.customColor,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget button = Container(
      decoration: BoxDecoration(
        color: isExpanded
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: AnimatedRotation(
          turns: isExpanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 300),
          child: Padding(
            padding: padding,
            child: Icon(
              icon,
              color: isExpanded
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              size: iconSize,
            ),
          ),
        ),
        iconSize: iconSize,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: tooltip,
      ),
    );

    if (margin != null) {
      button = Container(margin: margin, child: button);
    }

    return button;
  }
}
