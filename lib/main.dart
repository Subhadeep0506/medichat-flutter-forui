import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

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

import 'app/app.dart';
import 'services/api_service.dart';
import 'utils/app_logger.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set up error handlers for logging
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

