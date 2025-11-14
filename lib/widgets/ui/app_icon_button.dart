import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Small icon button wrapper used for consistent sizing and hit target
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 20,
    this.padding = const EdgeInsets.all(8),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FButton.icon(
      style: FButtonStyle.ghost(),
      onPress: onPressed,
      child: Icon(icon, size: size, color: color),
    );
  }
}
