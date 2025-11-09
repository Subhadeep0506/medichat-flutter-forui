import 'package:flutter/material.dart';

/// Small helper to show a popup menu at a given context
class AppPopup {
  /// Shows a popup menu at the provided position.
  ///
  /// Named differently to avoid colliding with Flutter's top-level `showMenu`.
  static Future<T?> showPopupMenu<T>(
    BuildContext context, {
    required RelativeRect position,
    required List<PopupMenuEntry<T>> items,
  }) {
    return showMenu<T>(context: context, position: position, items: items);
  }
}
