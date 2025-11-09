import 'package:flutter/material.dart';
import 'package:forui_assets/forui_assets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import '../providers/theme_provider.dart';

/// Central app bottom navigation bar.
/// Tabs:
/// 0 - Patients (Dashboard root)
/// 1 - Settings (Inline within dashboard via index or dedicated route optional)
/// 2 - Profile
///
/// The settings tab also reflects current theme via icon color overlay
/// and supports a long press to toggle theme quickly.
class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const AppBottomNavigation({super.key, this.currentIndex = 0, this.onTap});

  void _defaultNavigate(BuildContext context, int idx) {
    switch (idx) {
      case 0:
        context.go('/?tab=0');
        break;
      case 1:
        // Settings lives inside DashboardScreen (index 1)
        context.go('/?tab=1');
        break;
      case 2:
        context.go('/?tab=2');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    final items = <Widget>[
      const Icon(FIcons.users, size: 28),
      GestureDetector(
        onLongPress: () => themeProvider.toggleTheme(),
        child: Icon(
          currentIndex == 1 ? FIcons.settings2 : FIcons.settings,
          size: 28,
        ),
      ),
      const Icon(FIcons.idCard, size: 28),
    ];

    final Color barColor = Theme.of(context).colorScheme.primary;
    final Color iconColor = Theme.of(context).colorScheme.onPrimary;

    return Theme(
      // Override icon theme inside curved bar
      data: Theme.of(context).copyWith(
        iconTheme: Theme.of(context).iconTheme.copyWith(color: iconColor),
      ),
      child: CurvedNavigationBar(
        index: currentIndex,
        backgroundColor:
            Colors.transparent, // underlying scaffold shows through
        color: barColor,
        buttonBackgroundColor: barColor.withValues(alpha: 0.9),
        height: 60,
        animationCurve: Curves.easeOutCubic,
        animationDuration: const Duration(milliseconds: 400),
        items: items,
        onTap: (idx) {
          if (onTap != null) {
            onTap!(idx);
          } else {
            _defaultNavigate(context, idx);
          }
        },
        letIndexChange: (i) => true,
      ),
    );
  }
}
