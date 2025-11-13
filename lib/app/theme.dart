import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

// Returns a ForUI theme configured for light or dark mode.
dynamic buildFTheme({required bool isDark}) {
  final baseTheme = isDark ? FThemes.zinc.dark : FThemes.zinc.light;

  return baseTheme.copyWith(
    colors: baseTheme.colors.copyWith(primaryForeground: Colors.white),
  );
}

// Convert an FTheme-like object to a Material `ThemeData` and apply app-wide tweaks.
ThemeData buildMaterialTheme(dynamic fTheme) {
  final theme = fTheme.toApproximateMaterialTheme();
  return theme.copyWith(
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.none,
      ),
    ),
  );
}
