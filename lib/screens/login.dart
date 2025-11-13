import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/patient_provider.dart';
import '../providers/case_provider.dart';
import '../providers/session_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/styled_icon_button.dart';
import '../widgets/ui/app_text_field.dart';
import '../widgets/ui/app_button.dart';
import '../services/remote_api_service.dart';
import '../services/http_client_service.dart';
import '../services/toast_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  static const _persistEmailKey = 'login_email_draft';
  static const _persistPasswordKey = 'login_password_draft';

  bool _loadedDraft = false;
  bool _obscurePassword = true;
  bool _isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    _restoreDraft();
    _emailController.addListener(_persistDraft);
    _passwordController.addListener(_persistDraft);
  }

  @override
  void dispose() {
    _emailController.removeListener(_persistDraft);
    _passwordController.removeListener(_persistDraft);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _restoreDraft() async {
    // Load saved field values (if any) so errors don't wipe user input
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _emailController.text =
          prefs.getString(_persistEmailKey) ?? _emailController.text;
      _passwordController.text =
          prefs.getString(_persistPasswordKey) ?? _passwordController.text;
      _loadedDraft = true;
    });
  }

  Future<void> _persistDraft() async {
    if (!_loadedDraft) return; // avoid writing during initial load frame
    if (!mounted) return; // don't persist if widget is disposed
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      await prefs.setString(_persistEmailKey, _emailController.text);
      await prefs.setString(_persistPasswordKey, _passwordController.text);
    }
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_persistEmailKey);
    await prefs.remove(_persistPasswordKey);
  }

  Future<void> _login() async {
    final auth = context.read<AuthProvider>();
    // Switch to remote services before login
    final client = HttpClientService.instance;
    auth.enableRemote(RemoteAuthService(client));

    // Set manual loading state for the entire process
    setState(() {
      _isLoggingIn = true;
    });

    try {
      // Step 1: Authenticate user (stay on login screen during this)
      final user = await auth.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Check if there was an error during login
      if (auth.error != null || user == null) {
        // Error toast is already shown by AuthProvider, just return
        return; // Stay on login screen
      }

      // Step 2: Verify user details (still on login screen)
      String tokenProvider() => user.accessToken ?? '';
      final remoteUserService = RemoteUserService(
        client,
        tokenProvider,
        () => auth.relogin(showToasts: false),
      );

      // Verify user details with the backend
      final userDetails = await remoteUserService.getCurrentUser();

      // Step 3: Enable remote services for other providers
      if (mounted) {
        context.read<PatientProvider>().enableRemote(
          RemotePatientService(
            client,
            tokenProvider,
            () => auth.relogin(showToasts: false),
          ),
        );
        context.read<CaseProvider>().enableRemote(
          RemoteCaseService(
            client,
            tokenProvider,
            () => auth.relogin(showToasts: false),
          ),
        );
        context.read<SessionProvider>().enableRemote(
          RemoteSessionService(
            client,
            tokenProvider,
            () => auth.relogin(showToasts: false),
          ),
        );
        context.read<ChatProvider>().enableRemote(
          RemoteChatService(
            client,
            tokenProvider,
            () => auth.relogin(showToasts: false),
          ),
        );
        // Enable user service for profile management
        context.read<UserProvider>().enableRemote(remoteUserService);
      }

      // Step 4: Set the user as authenticated
      await auth.setAuthenticatedUser(user);

      // Step 5: Success! Clear login form and navigate to dashboard
      await _clearDraft();
      if (mounted) {
        _emailController.clear();
        _passwordController.clear();
        // Show success toast
        ToastService.showSuccess(
          'Login successful! Welcome back, ${userDetails.name}!',
          context: context,
        );
        // Explicitly navigate to dashboard after successful login
        context.go('/?tab=0');
      }
    } catch (e) {
      // Step 5: Handle any errors and stay on login screen
      if (mounted) {
        ToastService.showError(
          'Failed to verify user details: ${e.toString()}',
          context: context,
        );
        await auth.logout(); // Clear potentially invalid session
      }
      // Don't navigate anywhere - stay on login screen
    } finally {
      // Always clear loading state
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  void _goToRegister() {
    context.go('/register');
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return FScaffold(
      header: FHeader(
        style: (style) => style.copyWith(
          titleTextStyle: style.titleTextStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StyledIconButton(
              icon: FIcons.arrowLeft,
              tooltip: 'Back to Onboarding',
              margin: const EdgeInsets.all(8),
              onPressed: () => context.go('/onboard'),
            ),
            const SizedBox(width: 8),
            Text('Login', style: TextStyle(color: theme.colors.foreground)),
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset(
                    "assets/images/banner.png",
                    height: 200,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(FIcons.triangleAlert, size: 200),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Welcome back!',
                  style: theme.typography.xl2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colors.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Let's login for explore continues",
                  style: theme.typography.lg.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _emailController,
                  hintText: 'enter your email',
                  label: const Text('Email'),
                  prefixIcon: const Icon(FIcons.mail),
                ),
                const SizedBox(height: 4),
                AppTextField(
                  controller: _passwordController,
                  hintText: 'password',
                  label: const Text('Password'),
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(FIcons.lock),
                  suffixIcon: StyledIconButton(
                    padding: EdgeInsets.all(8),
                    icon: _obscurePassword ? FIcons.eye : FIcons.eyeClosed,
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButton(
                    label: 'Forgot password? Press Here',
                    onPressed: () {
                      // TODO: Implement forgot password
                    },
                    style: FButtonStyle.ghost(),
                    fontSize: 12.0, // Small text size
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Sign In',
                    onPressed: _isLoggingIn ? null : _login,
                    isLoading: _isLoggingIn,
                    expand: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: theme.typography.sm.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colors.foreground,
                      ),
                    ),
                    AppButton(
                      label: 'Sign Up here',
                      onPressed: _goToRegister,
                      style: FButtonStyle.ghost(),
                      fontSize: 14.0, // Small text size
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
