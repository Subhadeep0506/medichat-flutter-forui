import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Widget icon;
  final bool obscureText;
  final Widget? suffixIcon;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    // Use Forui's FTextField so the input matches the Forui theme and styles.
    return FTextField(
      controller: controller,
      hint: hintText,
      obscureText: obscureText,
      // Map the simple icon widget into Forui's prefix/suffix builders and
      // add horizontal padding so icons aren't flush against the input edge.
      prefixBuilder: (context, style, states) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: icon,
      ),
      suffixBuilder: suffixIcon != null
          ? (context, style, states) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: suffixIcon!,
            )
          : null,
    );
  }
}
