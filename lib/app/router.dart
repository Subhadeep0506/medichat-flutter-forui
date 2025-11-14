import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/splash_provider.dart';
import '../services/global_token_expiration_service.dart';
import '../services/toast_service.dart';
import '../screens/splash_screen.dart';
import '../screens/dashboard.dart';
import '../screens/add_patient.dart';
import '../screens/patient_detail.dart';
import '../screens/add_case.dart';
import '../screens/case_detail.dart';
import '../screens/case_chat_wrapper.dart';
import '../screens/chat_session.dart';
import '../screens/login.dart';
import '../screens/register.dart';
import '../screens/onboard_screen.dart';
import '../utils/app_logger.dart';

GoRouter buildRouter(
  AuthProvider auth,
  OnboardingProvider onboarding,
  SplashProvider splash,
  GlobalKey<NavigatorState> navigatorKey,
) {
  GlobalTokenExpirationService.setNavigatorKey(navigatorKey);
  ToastService.setNavigatorKey(navigatorKey);

  return GoRouter(
    navigatorKey: navigatorKey,
    refreshListenable: Listenable.merge([auth, onboarding, splash]),
    initialLocation: _RouterState.lastKnownLocation ?? '/splash',
    errorBuilder: (context, state) {
      if (kDebugMode) AppLogger.error('Router error: ${state.error}');
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

        if (splash.showSplash && !onSplash) return '/splash';

        if (!splash.showSplash && onSplash) {
          if (!onboarding.loaded) return null;
          if (!auth.isAuthenticated && !seen) return '/onboard';
          if (!auth.isAuthenticated) return '/login';
          return _RouterState.lastKnownLocation ?? '/?tab=0';
        }

        if (!onboarding.loaded) return null;
        if (auth.isLoading) return null;

        if (loggingIn || onOnboard) {
          if (auth.isAuthenticated) {
            return _RouterState.lastKnownLocation ?? '/?tab=0';
          }
          return null;
        }

        if (auth.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _RouterState.lastKnownLocation = location;
          });
          return null;
        }

        if (!seen && !onOnboard) return '/onboard';

        if (!auth.isAuthenticated && !auth.isLoading) {
          _RouterState.lastKnownLocation = null;
          final redirectTo = seen ? '/login' : '/onboard';
          return redirectTo;
        }

        return null;
      } catch (e) {
        if (kDebugMode) AppLogger.error('Router redirect error: $e');
        return null;
      }
    },
    routes: <RouteBase>[
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/', builder: (c, s) => const DashboardScreen()),
      GoRoute(
        path: '/add-patient',
        builder: (c, s) => const AddPatientScreen(),
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
        builder: (context, state) {
          try {
            return const LoginScreen();
          } catch (e) {
            if (kDebugMode) AppLogger.error('Error building LoginScreen: $e');
            return const FScaffold(
              child: Center(child: Text('Error loading login screen')),
            );
          }
        },
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) {
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
        redirect: (c, s) => '/?tab=2',
        builder: (c, s) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/onboard',
        builder: (context, state) {
          try {
            return const OnboardScreen();
          } catch (e) {
            if (kDebugMode) AppLogger.error('Error building OnboardScreen: $e');
            return const FScaffold(
              child: Center(child: Text('Error loading onboarding screen')),
            );
          }
        },
      ),
    ],
  );
}

class _RouterState {
  static String? lastKnownLocation;
}
