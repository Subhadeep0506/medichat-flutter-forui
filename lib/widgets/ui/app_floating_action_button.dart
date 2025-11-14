import 'package:flutter/material.dart';
import '../app_loading_widget.dart';

/// Enhanced floating action button with gradient and animation
class AppFloatingActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final String? label;
  final bool isLoading;
  final Color? customColor;

  const AppFloatingActionButton({
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
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        icon: fabContent,
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Text(
            label!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
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
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed,
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Center(child: fabContent),
          ),
        ),
      ),
    );
  }
}
