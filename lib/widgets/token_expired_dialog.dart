import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:forui/forui.dart';
import '../providers/auth_provider.dart';

/// Dialog shown when the user's access token has expired
/// Provides options to relogin using refresh token or logout completely
class TokenExpiredDialog extends StatefulWidget {
  const TokenExpiredDialog({super.key});

  @override
  State<TokenExpiredDialog> createState() => _TokenExpiredDialogState();
}

class _TokenExpiredDialogState extends State<TokenExpiredDialog> {
  bool _isRelogining = false;

  Future<void> _handleRelogin() async {
    setState(() => _isRelogining = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.relogin(showToasts: true);

    if (mounted) {
      setState(() => _isRelogining = false);

      if (success) {
        // Close dialog and let user continue
        Navigator.of(context).pop(true);
      } else {
        // Relogin failed, show error message
        // The error is already shown by the AuthProvider via ToastService
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false, // Prevent dismissing by back button
      child: FDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                FIcons.shieldAlert,
                color: theme.colorScheme.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Session Expired',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your session needs to be refreshed',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your session has expired after 30 minutes of inactivity. You can refresh your session to continue using the app.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      FIcons.info,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Click "Refresh Session" to continue',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          FButton(
            onPress: _isRelogining ? null : _handleRelogin,
            child: const Text('Refresh Session'),
          ),
        ],
      ),
    );
  }
}
