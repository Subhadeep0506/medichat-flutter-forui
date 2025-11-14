import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/splash_provider.dart';
import '../providers/loading_animation_provider.dart';
import '../screens/splash_screen.dart';
import '../services/toast_service.dart';
import '../config/app_config.dart';
import '../bootstrap_remote.dart';
import '../utils/app_logger.dart';
import 'theme.dart';
import 'router.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<void> _initFuture;
  GoRouter? _router;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.loadPersistedUser();

      final loadingAnimationProvider = context.read<LoadingAnimationProvider>();
      await loadingAnimationProvider.initialize();

      final onboardingProvider = context.read<OnboardingProvider>();
      while (!onboardingProvider.loaded) {
        await Future.delayed(const Duration(milliseconds: 10));
      }

      if (AppConfig.useRemoteAPI) {
        if (AppConfig.enableDebugLogging)
          AppLogger.info('App: Enabling remote API backend');
        try {
          enableRemoteBackend(context);
        } catch (e) {
          if (kDebugMode) AppLogger.error('Error enabling remote backend: $e');
        }
      } else {
        if (AppConfig.enableDebugLogging)
          AppLogger.info('App: Using mock API services with sample data');
      }

      final splashProvider = context.read<SplashProvider>();
      await splashProvider.initialize();
    } catch (e) {
      if (kDebugMode) AppLogger.error('Error initializing app: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ThemeProvider, AuthProvider, SplashProvider>(
      builder: (context, themeProvider, authProvider, splashProvider, child) {
        final isDark = themeProvider.isDark(context);

        final fTheme = buildFTheme(isDark: isDark);
        final ThemeData materialTheme = buildMaterialTheme(fTheme);

        return FutureBuilder(
          future: _initFuture,
          builder: (context, snapshot) {
            final onboardingProvider = context.watch<OnboardingProvider>();

            if (snapshot.hasError ||
                !authProvider.initialized ||
                !onboardingProvider.loaded ||
                snapshot.connectionState == ConnectionState.waiting) {
              return MaterialApp(
                title: 'MediChat',
                scaffoldMessengerKey: ToastService.scaffoldMessengerKey,
                debugShowCheckedModeBanner: false,
                supportedLocales: FLocalizations.supportedLocales,
                localizationsDelegates: const [
                  ...FLocalizations.localizationsDelegates,
                ],
                theme: materialTheme,
                builder: (_, child) => FAnimatedTheme(
                  data: fTheme,
                  child: Builder(
                    builder: (context) {
                      final toasterStyle = context.theme.toasterStyle.copyWith(
                        expandBehavior: FToasterExpandBehavior.always,
                      );
                      return FToaster(
                        style: toasterStyle.call,
                        child: Builder(
                          builder: (context) {
                            ToastService.registerContext(context);
                            return child ?? const SizedBox.shrink();
                          },
                        ),
                      );
                    },
                  ),
                ),
                home: const SplashScreen(),
              );
            }

            try {
              _router ??= buildRouter(
                authProvider,
                onboardingProvider,
                splashProvider,
                _navigatorKey,
              );
              return MaterialApp.router(
                scaffoldMessengerKey: ToastService.scaffoldMessengerKey,
                routerConfig: _router!,
                title: 'MediChat',
                debugShowCheckedModeBanner: false,
                supportedLocales: FLocalizations.supportedLocales,
                localizationsDelegates: const [
                  ...FLocalizations.localizationsDelegates,
                ],
                theme: materialTheme,
                builder: (context, child) {
                  final routedChild =
                      child ??
                      const FScaffold(
                        child: Center(child: CircularProgressIndicator()),
                      );
                  return FAnimatedTheme(
                    data: fTheme,
                    child: Builder(
                      builder: (context) {
                        final toasterStyle = context.theme.toasterStyle
                            .copyWith(
                              expandBehavior: FToasterExpandBehavior.always,
                            );
                        return FToaster(
                          style: toasterStyle.call,
                          child: Builder(
                            builder: (context) {
                              ToastService.registerContext(context);
                              return routedChild;
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            } catch (e) {
              if (kDebugMode) AppLogger.error('Error building router: $e');
              return MaterialApp(
                title: 'MediChat - Error',
                scaffoldMessengerKey: ToastService.scaffoldMessengerKey,
                theme: materialTheme,
                home: FScaffold(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Error initializing app'),
                        const SizedBox(height: 16),
                        Text('Please restart the app'),
                      ],
                    ),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}
