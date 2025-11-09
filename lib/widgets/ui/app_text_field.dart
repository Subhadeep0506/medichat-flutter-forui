import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// AppTextField: lightweight wrapper to ensure consistent spacing and to make
/// swapping text-field implementations easy across the app.
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final int? maxLines;
  final Widget? label;

  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.label,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    // Use the Forui-provided FTextField so theme is consistent with main app
    return FTextField(
      controller: controller,
      hint: hintText ?? '',
      label: label,
      maxLines: maxLines ?? 1,
      obscureText: obscureText,
      keyboardType: keyboardType,
      prefixBuilder: prefixIcon != null
          ? (c, s, st) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: prefixIcon,
            )
          : null,
      suffixBuilder: suffixIcon != null
          ? (c, s, st) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: suffixIcon,
            )
          : null,
    );
  }
}
