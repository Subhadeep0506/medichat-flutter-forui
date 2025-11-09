import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';
import '../widgets/ui/app_button.dart';
import '../providers/onboarding_provider.dart';

/// Redesigned onboarding experience based on provided markdown specification.
/// Always shown on app start (router initialLocation set to /onboard).
class OnboardScreen extends StatefulWidget {
  const OnboardScreen({super.key});

  @override
  State<OnboardScreen> createState() => _OnboardScreenState();
}

class _OnboardScreenState extends State<OnboardScreen> {
  Future<void> _proceed(BuildContext context, String route) async {
    try {
      // Navigate first then mark seen to avoid redirect race conditions
      // (router redirect may fire between await calls and push user to login).
      if (!mounted || !context.mounted) return;

      // Get the onboarding provider before navigation
      final onboarding = context.read<OnboardingProvider>();

      // Navigate to the route
      context.go(route);

      // Mark as seen after navigation to avoid redirect race conditions
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onboarding.markSeen();
      });
    } catch (e) {
      debugPrint('Error in onboard navigation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final theme = FTheme.of(context);
      return FScaffold(
        // no visible header required, toolbarHeight was 0
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 8),
                // Brand / Logo
                Text(
                  'Mindful Chat',
                  style: theme.typography.xl2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colors.foreground,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Let's get started on your journey to mindfulness.",
                  style: theme.typography.base.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'assets/images/banner.png',
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Understand Your Emotions',
                        style: theme.typography.xl.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colors.foreground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Track your mood and gain insights into your mental health.',
                        style: theme.typography.base.copyWith(
                          height: 1.4,
                          color: theme.colors.mutedForeground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Login',
                        onPressed: () => _proceed(context, '/login'),
                        style: FButtonStyle.outline(),
                        expand: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppButton(
                        label: 'Register',
                        onPressed: () => _proceed(context, '/register'),
                        style: FButtonStyle.primary(),
                        expand: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error building onboard screen: $e');
      return const FScaffold(
        child: Center(child: Text('Error loading onboarding screen')),
      );
    }
  }
}
