import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
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
import 'providers/splash_provider.dart';

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
import 'screens/splash_screen.dart';
import 'bootstrap_remote.dart';
import 'config/app_config.dart';
import 'services/toast_service.dart';
import 'services/global_token_expiration_service.dart';
import 'utils/app_logger.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize AppLogger and Crashlytics
  await AppLogger.initCrashlytics();

  // Only set up Crashlytics error handlers if it's properly initialized
  if (AppLogger.isCrashlyticsEnabled) {
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // Pass all uncaught asynchronous errors to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } else {
    // Fallback error handlers when Crashlytics is not available
    FlutterError.onError = (errorDetails) {
      AppLogger.error(
        'Flutter Error',
        errorDetails.exception,
        errorDetails.stack ?? StackTrace.current,
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.error('Async Error', error, stack);
      return true;
    };
  }

  AppLogger.info('MediChat app starting...');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SplashProvider()),
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

GoRouter _buildRouter(
  AuthProvider auth,
  OnboardingProvider onboarding,
  SplashProvider splash,
) {
  // Create a new navigator key for GoRouter
  final navigatorKey = GlobalKey<NavigatorState>();

  // Set it in the GlobalTokenExpirationService for token handling
  GlobalTokenExpirationService.setNavigatorKey(navigatorKey);

  ToastService.setNavigatorKey(navigatorKey);

  return GoRouter(
    navigatorKey: navigatorKey,
    refreshListenable: Listenable.merge([
      auth,
      onboarding,
      splash,
    ]), // Listen to auth, onboarding, and splash changes
    // Use preserved location during hot reloads, fallback to splash
    initialLocation: _MyAppState._lastKnownLocation ?? '/splash',
    errorBuilder: (context, state) {
      // Don't log errors here to avoid Crashlytics initialization issues
      if (kDebugMode) {
        AppLogger.error('Router error: ${state.error}');
      }
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
        final onSplash = location == '/splash';
        final loggingIn = location == '/login' || location == '/register';
        final onOnboard = location == '/onboard';
        final seen = onboarding.hasSeen;

        if (kDebugMode) {
          AppLogger.debug(
            'Router redirect: location=$location, auth=${auth.isAuthenticated}, loading=${auth.isLoading}, onboarding loaded=${onboarding.loaded}, hasSeen=${onboarding.hasSeen}, splash=${splash.showSplash}',
          );
        }

        // Show splash screen on initial load
        if (splash.showSplash && !onSplash) {
          if (kDebugMode) {
            AppLogger.debug('Router: showing splash screen');
          }
          return '/splash';
        }

        // If splash is done and we're on splash screen, redirect based on state
        if (!splash.showSplash && onSplash) {
          if (!onboarding.loaded) {
            if (kDebugMode) {
              AppLogger.debug(
                'Router: splash done, waiting for onboarding to load',
              );
            }
            return null;
          }

          if (!auth.isAuthenticated && !seen) {
            if (kDebugMode) {
              AppLogger.debug('Router: splash done, going to onboarding');
            }
            return '/onboard';
          }

          if (!auth.isAuthenticated) {
            if (kDebugMode) {
              AppLogger.debug('Router: splash done, going to login');
            }
            return '/login';
          }

          if (kDebugMode) {
            AppLogger.debug('Router: splash done, going to dashboard');
          }
          return _MyAppState._lastKnownLocation ?? '/?tab=0';
        }

        // Still loading onboarding state: don't redirect yet.
        if (!onboarding.loaded) {
          if (kDebugMode) {
            AppLogger.debug(
              'Router: onboarding not loaded, staying at $location',
            );
          }
          // Stay on current location until loaded
          return null;
        }

        // If authentication is in progress, don't redirect to prevent interruption
        if (auth.isLoading) {
          if (kDebugMode) {
            AppLogger.debug('Router: auth loading, no redirect');
          }
          return null;
        }
        if (loggingIn || onOnboard) {
          if (auth.isAuthenticated) {
            // Redirect authenticated users off auth pages to last known location or dashboard
            final redirect = _MyAppState._lastKnownLocation ?? '/?tab=0';
            if (kDebugMode) {
              AppLogger.debug(
                'Router: authenticated on auth page, redirecting to $redirect',
              );
            }
            return redirect;
          }
          if (kDebugMode) {
            AppLogger.debug(
              'Router: on auth page but not authenticated, staying',
            );
          }
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
          if (kDebugMode) {
            AppLogger.debug(
              'Router: user has not seen onboarding, redirecting to /onboard',
            );
          }
          return '/onboard';
        }

        // For any other protected route, check authentication
        if (!auth.isAuthenticated && !auth.isLoading) {
          // Clear preserved location when redirecting to auth pages
          _MyAppState._lastKnownLocation = null;
          // If they've seen onboarding, go to login, otherwise go to onboarding
          final redirectTo = seen ? '/login' : '/onboard';
          if (kDebugMode) {
            AppLogger.debug(
              'Router: user not authenticated, redirecting to $redirectTo',
            );
          }
          return redirectTo;
        }

        if (kDebugMode) {
          AppLogger.debug('Router: no redirect needed, staying at $location');
        }
        return null;
      } catch (e) {
        if (kDebugMode) {
          AppLogger.error('Router redirect error: $e');
        }
        return null;
      }
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/splash',
        builder: (BuildContext context, GoRouterState state) =>
            const SplashScreen(),
      ),
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
            if (kDebugMode) {
              AppLogger.error('Error building LoginScreen: $e');
            }
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
            if (kDebugMode) {
              AppLogger.error('Error building RegisterScreen: $e');
            }
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
            if (kDebugMode) {
              AppLogger.error('Error building OnboardScreen: $e');
            }
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
          AppLogger.info('App: Enabling remote API backend');
        }
        try {
          // Enable remote services immediately using the available BuildContext.
          enableRemoteBackend(context);
        } catch (e) {
          if (kDebugMode) {
            AppLogger.error('Error enabling remote backend: $e');
          }
        }
      } else {
        if (AppConfig.enableDebugLogging) {
          AppLogger.info('App: Using mock API services with sample data');
        }
      }

      // Initialize splash - this ensures minimum 2 seconds from app start
      final splashProvider = context.read<SplashProvider>();
      await splashProvider.initialize();
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('Error initializing app: $e');
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ThemeProvider, AuthProvider, SplashProvider>(
      builder: (context, themeProvider, authProvider, splashProvider, child) {
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
                titleTextStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
            );

        return FutureBuilder(
          future: _initFuture,
          builder: (context, snapshot) {
            final onboardingProvider = context.watch<OnboardingProvider>();

            // Show splash screen during initialization
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
                home:
                    const SplashScreen(), // Show splash screen during initialization
              );
            }

            try {
              // Create router only once to prevent rebuilding on theme changes
              _router ??= _buildRouter(
                authProvider,
                onboardingProvider,
                splashProvider,
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
                              // Wrap in an error boundary
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
              if (kDebugMode) {
                AppLogger.error('Error building router: $e');
              }
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
