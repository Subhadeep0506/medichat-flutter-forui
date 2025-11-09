import 'package:flutter/material.dart';

/// Simple card wrapper with consistent padding and elevation
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double elevation;
  final BorderRadiusGeometry borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.elevation = 2,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: Padding(padding: padding, child: child),
    );
  }
}
