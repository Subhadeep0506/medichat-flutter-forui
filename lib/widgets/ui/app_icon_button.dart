import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Small icon button wrapper used for consistent sizing and hit target
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final EdgeInsetsGeometry padding;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 20,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    // Use FButton.icon for a Forui-styled icon-only button. Fall back to
    // IconButton if FButton.icon is not suitable in a particular place.
    return FButton.icon(
      style: FButtonStyle.ghost(),
      onPress: onPressed,
      child: Icon(icon, size: size),
    );
  }
}
