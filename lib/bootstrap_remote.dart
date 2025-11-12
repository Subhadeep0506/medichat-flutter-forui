import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/remote_api_service.dart';
import 'services/http_client_service.dart';
import 'providers/auth_provider.dart';
import 'providers/patient_provider.dart';
import 'providers/case_provider.dart';
import 'providers/session_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/user_provider.dart';
import 'config/app_config.dart';
import 'utils/app_logger.dart';

void enableRemoteBackend(BuildContext context, {String? baseUrl}) {
  if (AppConfig.enableDebugLogging) {
    AppLogger.info(
      'Bootstrap: Enabling remote backend with base URL: ${baseUrl ?? AppConfig.backendBaseUrl}',
    );
    if (baseUrl != null) {
      AppLogger.warning(
        'Warning: baseUrl parameter is ignored. Update AppConfig.backendBaseUrl instead.',
      );
    }
  }

  final client = HttpClientService.instance;
  final auth = context.read<AuthProvider>();
  auth.enableRemote(RemoteAuthService(client));

  final patient = context.read<PatientProvider>();
  patient.enableRemote(
    RemotePatientService(
      client,
      () => auth.user?.accessToken ?? '',
      () => auth.relogin(showToasts: false),
    ),
  );
  if (AppConfig.enableDebugLogging) {
    AppLogger.info('Bootstrap: PatientProvider remote enabled');
  }

  final cases = context.read<CaseProvider>();
  cases.enableRemote(
    RemoteCaseService(
      client,
      () => auth.user?.accessToken ?? '',
      () => auth.relogin(showToasts: false),
    ),
  );

  final sessions = context.read<SessionProvider>();
  sessions.enableRemote(
    RemoteSessionService(
      client,
      () => auth.user?.accessToken ?? '',
      () => auth.relogin(showToasts: false),
    ),
  );

  final chat = context.read<ChatProvider>();
  chat.enableRemote(
    RemoteChatService(
      client,
      () => auth.user?.accessToken ?? '',
      () => auth.relogin(showToasts: false),
    ),
  );

  final user = context.read<UserProvider>();
  user.enableRemote(
    RemoteUserService(
      client,
      () => auth.user?.accessToken ?? '',
      () => auth.relogin(showToasts: false),
    ),
  );

  if (AppConfig.enableDebugLogging) {
    AppLogger.info('Bootstrap: All remote services enabled');
  }
}
