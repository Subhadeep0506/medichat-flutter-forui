import 'package:flutter/material.dart';

/// Basic app navbar to centralize top appbar look
class AppNavbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  const AppNavbar({super.key, required this.title, this.actions, this.leading});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: leading,
      actions: actions,
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
