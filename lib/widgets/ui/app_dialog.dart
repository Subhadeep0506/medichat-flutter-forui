import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Simple app dialog builder for consistent dialog style using ForUI
class AppDialog {
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    return showFDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx, style, animation) {
        final ftheme = FTheme.of(ctx);
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: FDialog(
            style: style.call,
            animation: animation,
            direction: Axis.horizontal,
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: ftheme.typography.lg.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ftheme.colors.foreground,
                    ),
                  ),
                ),
                FButton.icon(
                  style: FButtonStyle.ghost(),
                  onPress: () => Navigator.of(ctx).pop(),
                  child: const Icon(FIcons.x),
                ),
              ],
            ),
            body: content,
            actions: actions ?? [],
          ),
        );
      },
    );
  }
}
