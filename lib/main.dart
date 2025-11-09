import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/patient_provider.dart';
import 'providers/case_provider.dart';
import 'providers/session_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/chat_settings_provider.dart';
import 'providers/user_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/current_patient_provider.dart';
import 'providers/current_case_provider.dart';
import 'providers/loading_animation_provider.dart';

import 'services/api_service.dart';
import 'screens/dashboard.dart';
import 'screens/login.dart';
import 'screens/register.dart';
import 'screens/patient_detail.dart';
import 'screens/case_detail.dart';
import 'screens/chat_session.dart';
import 'screens/case_chat_wrapper.dart';
import 'screens/add_patient.dart';
import 'screens/add_case.dart';
import 'screens/onboard_screen.dart';
import 'bootstrap_remote.dart';
import 'config/app_config.dart';
import 'services/toast_service.dart';
import 'services/global_token_expiration_service.dart';
import 'widgets/app_loading_widget.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(AuthApiService())),
        ChangeNotifierProvider(
          create: (_) => PatientProvider(PatientApiService()),
        ),
        ChangeNotifierProvider(create: (_) => CaseProvider(CaseApiService())),
        ChangeNotifierProvider(
          create: (_) => SessionProvider(SessionApiService()),
        ),
        ChangeNotifierProvider(create: (_) => ChatProvider(ChatApiService())),
        ChangeNotifierProvider(create: (_) => ChatSettingsProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => CurrentPatientProvider()),
        ChangeNotifierProvider(create: (_) => CurrentCaseProvider()),
        ChangeNotifierProvider(create: (_) => LoadingAnimationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

GoRouter _buildRouter(AuthProvider auth, OnboardingProvider onboarding) {
  // Create a new navigator key for GoRouter
  final navigatorKey = GlobalKey<NavigatorState>();

  // Set it in the GlobalTokenExpirationService for token handling
  GlobalTokenExpirationService.setNavigatorKey(navigatorKey);

  return GoRouter(
    navigatorKey: navigatorKey,
    refreshListenable: Listenable.merge([
      auth,
      onboarding,
    ]), // Listen to both auth and onboarding changes
    // Use preserved location during hot reloads, fallback to root
    initialLocation: _MyAppState._lastKnownLocation ?? '/',
    errorBuilder: (context, state) {
      debugPrint('Router error: ${state.error}');
      return const FScaffold(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Page not found'),
              SizedBox(height: 16),
              Text('Please try again or go back to home.'),
            ],
          ),
        ),
      );
    },
    redirect: (context, state) {
      try {
        final location = state.matchedLocation;
        final loggingIn = location == '/login' || location == '/register';
        final onOnboard = location == '/onboard';
        final seen = onboarding.hasSeen;

        debugPrint(
          'Router redirect: location=$location, auth=${auth.isAuthenticated}, loading=${auth.isLoading}, onboarding=${onboarding.loaded}',
        );

        // Still loading onboarding state: don't redirect yet.
        if (!onboarding.loaded) {
          debugPrint('Router: onboarding not loaded, no redirect');
          return null;
        }

        // If authentication is in progress, don't redirect to prevent interruption
        if (auth.isLoading) {
          debugPrint('Router: auth loading, no redirect');
          return null;
        }
        if (loggingIn || onOnboard) {
          if (auth.isAuthenticated) {
            // Redirect authenticated users off auth pages to last known location or dashboard
            final redirect = _MyAppState._lastKnownLocation ?? '/?tab=0';
            debugPrint(
              'Router: authenticated on auth page, redirecting to $redirect',
            );
            return redirect;
          }
          debugPrint('Router: on auth page but not authenticated, staying');
          return null;
        }

        // Track the current location for hot reload preservation (but not auth pages)
        if (auth.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _MyAppState._lastKnownLocation = location;
          });
        }

        // If user is authenticated, always allow access to protected routes
        // Don't redirect authenticated users to onboarding or login pages
        if (auth.isAuthenticated) {
          return null;
        }

        // For unauthenticated users: check onboarding status
        if (!seen && !onOnboard) {
          return '/onboard';
        }

        // For any other protected route, check authentication
        if (!auth.isAuthenticated && !auth.isLoading) {
          // Clear preserved location when redirecting to auth pages
          _MyAppState._lastKnownLocation = null;
          // If they've seen onboarding, go to login, otherwise go to onboarding
          final redirectTo = seen ? '/login' : '/onboard';
          return redirectTo;
        }
        return null;
      } catch (e) {
        debugPrint('Router redirect error: $e');
        return null;
      }
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) =>
            const DashboardScreen(),
      ),
      GoRoute(
        path: '/add-patient',
        builder: (context, state) => const AddPatientScreen(),
      ),
      GoRoute(
        path: '/patients/:pid',
        builder: (context, state) {
          final pid = state.pathParameters['pid'];
          if (pid == null) {
            return const FScaffold(
              child: Center(child: Text('Patient ID required')),
            );
          }
          return PatientDetailScreen(patientId: pid);
        },
      ),
      GoRoute(
        path: '/patients/:pid/add-case',
        builder: (context, state) {
          final pid = state.pathParameters['pid'];
          if (pid == null) {
            return const FScaffold(
              child: Center(child: Text('Patient ID required')),
            );
          }
          return AddCaseScreen(patientId: pid);
        },
      ),
      GoRoute(
        path: '/patients/:pid/cases/:cid',
        builder: (context, state) {
          final pid = state.pathParameters['pid'];
          final cid = state.pathParameters['cid'];
          if (pid == null || cid == null) {
            return const FScaffold(
              child: Center(child: Text('Invalid parameters')),
            );
          }
          return CaseDetailScreen(patientId: pid, caseId: cid);
        },
      ),
      GoRoute(
        path: '/patients/:pid/cases/:cid/chat',
        builder: (context, state) {
          final pid = state.pathParameters['pid'];
          final cid = state.pathParameters['cid'];
          if (pid == null || cid == null) {
            return const FScaffold(
              child: Center(child: Text('Invalid parameters')),
            );
          }
          return CaseChatWrapperScreen(patientId: pid, caseId: cid);
        },
      ),
      GoRoute(
        path: '/patients/:pid/cases/:cid/sessions/:sid',
        builder: (context, state) {
          final pid = state.pathParameters['pid'];
          final cid = state.pathParameters['cid'];
          final sid = state.pathParameters['sid'];
          if (pid == null || cid == null || sid == null) {
            return const FScaffold(
              child: Center(child: Text('Invalid parameters')),
            );
          }
          return ChatSessionScreen(patientId: pid, caseId: cid, sessionId: sid);
        },
      ),
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) {
          try {
            return const LoginScreen();
          } catch (e) {
            debugPrint('Error building LoginScreen: $e');
            return const FScaffold(
              child: Center(child: Text('Error loading login screen')),
            );
          }
        },
      ),
      GoRoute(
        path: '/register',
        builder: (BuildContext context, GoRouterState state) {
          try {
            return const RegisterScreen();
          } catch (e) {
            debugPrint('Error building RegisterScreen: $e');
            return const FScaffold(
              child: Center(child: Text('Error loading register screen')),
            );
          }
        },
      ),
      GoRoute(
        path: '/profile',
        redirect: (context, state) => '/?tab=2',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/onboard',
        builder: (BuildContext context, GoRouterState state) {
          try {
            return const OnboardScreen();
          } catch (e) {
            debugPrint('Error building OnboardScreen: $e');
            return const FScaffold(
              child: Center(child: Text('Error loading onboarding screen')),
            );
          }
        },
      ),
      // Additional nested routes for patients/cases/sessions/chat can be added here.
    ],
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<void> _initFuture;
  GoRouter? _router;
  static String? _lastKnownLocation;

  @override
  void initState() {
    super.initState();

    // Initialize all providers
    _initFuture = _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize auth provider first
      final authProvider = context.read<AuthProvider>();
      await authProvider.loadPersistedUser();

      // Initialize loading animation provider
      final loadingAnimationProvider = context.read<LoadingAnimationProvider>();
      await loadingAnimationProvider.initialize();

      // Wait for onboarding provider to load
      final onboardingProvider = context.read<OnboardingProvider>();
      while (!onboardingProvider.loaded) {
        await Future.delayed(const Duration(milliseconds: 10));
      }

      if (AppConfig.useRemoteAPI) {
        if (AppConfig.enableDebugLogging) {
          print('App: Enabling remote API backend');
        }
        try {
          // Enable remote services immediately using the available BuildContext.
          enableRemoteBackend(context);
        } catch (e) {
          debugPrint('Error enabling remote backend: $e');
        }
      } else {
        if (AppConfig.enableDebugLogging) {
          print('App: Using mock API services with sample data');
        }
      }
    } catch (e) {
      debugPrint('Error initializing app: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, AuthProvider>(
      builder: (context, themeProvider, authProvider, child) {
        final isDark = themeProvider.isDark(context);
        final baseTheme = isDark ? FThemes.zinc.dark : FThemes.zinc.light;

        final fTheme = baseTheme.copyWith(
          // typography: baseTheme.typography.copyWith(
          //   xs: GoogleFonts.ibmPlexSans(
          //     textStyle: baseTheme.typography.xs.copyWith(
          //       decoration: TextDecoration.none,
          //     ),
          //   ),
          //   sm: GoogleFonts.ibmPlexSans(
          //     textStyle: baseTheme.typography.sm.copyWith(
          //       decoration: TextDecoration.none,
          //     ),
          //   ),
          //   base: GoogleFonts.ibmPlexSans(
          //     textStyle: baseTheme.typography.base.copyWith(
          //       decoration: TextDecoration.none,
          //     ),
          //   ),
          //   lg: GoogleFonts.ibmPlexSans(
          //     textStyle: baseTheme.typography.lg.copyWith(
          //       decoration: TextDecoration.none,
          //     ),
          //   ),
          //   xl: GoogleFonts.ibmPlexSans(
          //     textStyle: baseTheme.typography.xl.copyWith(
          //       decoration: TextDecoration.none,
          //     ),
          //   ),
          //   xl2: GoogleFonts.ibmPlexSans(
          //     textStyle: baseTheme.typography.xl2.copyWith(
          //       decoration: TextDecoration.none,
          //     ),
          //   ),
          //   xl3: GoogleFonts.ibmPlexSans(
          //     textStyle: baseTheme.typography.xl3.copyWith(
          //       decoration: TextDecoration.none,
          //     ),
          //   ),
          //   xl4: GoogleFonts.ibmPlexSans(
          //     textStyle: baseTheme.typography.xl4.copyWith(
          //       decoration: TextDecoration.none,
          //     ),
          //   ),
          //   xl5: GoogleFonts.ibmPlexSans(
          //     textStyle: baseTheme.typography.xl5.copyWith(
          //       decoration: TextDecoration.none,
          //     ),
          //   ),
          //   xl6: GoogleFonts.ibmPlexSans(
          //     textStyle: baseTheme.typography.xl6.copyWith(
          //       decoration: TextDecoration.none,
          //     ),
          //   ),
          //   xl7: GoogleFonts.ibmPlexSans(
          //     textStyle: baseTheme.typography.xl7.copyWith(
          //       decoration: TextDecoration.none,
          //     ),
          //   ),
          //   xl8: GoogleFonts.ibmPlexSans(
          //     textStyle: baseTheme.typography.xl8.copyWith(
          //       decoration: TextDecoration.none,
          //     ),
          //   ),
          // ),
          colors: baseTheme.colors.copyWith(primaryForeground: Colors.white),
        );

        // Convert ForUI theme to a Material ThemeData and apply a global AppBarTheme
        final ThemeData materialTheme = fTheme
            .toApproximateMaterialTheme()
            .copyWith(
              appBarTheme: AppBarTheme(
                centerTitle: true,
                elevation: 0,
                titleTextStyle: GoogleFonts.ibmPlexSans(
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            );

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
                builder: (_, child) => child != null
                    ? FAnimatedTheme(data: fTheme, child: child)
                    : const SizedBox.shrink(),
                home: FScaffold(
                  child: Consumer<LoadingAnimationProvider>(
                    builder: (context, provider, child) => Center(
                      child: provider.initialized
                          ? const AppLoadingWidget.large()
                          : const CircularProgressIndicator(),
                    ),
                  ),
                ),
              );
            }

            try {
              // Create router only once to prevent rebuilding on theme changes
              _router ??= _buildRouter(authProvider, onboardingProvider);
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
                  return child != null
                      ? FAnimatedTheme(
                          data: fTheme,
                          child: Builder(
                            builder: (context) {
                              // Wrap in an error boundary
                              return child;
                            },
                          ),
                        )
                      : const FScaffold(
                          child: Center(child: CircularProgressIndicator()),
                        );
                },
              );
            } catch (e) {
              debugPrint('Error building router: $e');
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
