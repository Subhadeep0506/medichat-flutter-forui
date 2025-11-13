import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import 'package:forui/forui.dart';
import '../widgets/styled_icon_button.dart';
import '../widgets/ui/app_text_field.dart';
import '../widgets/ui/app_button.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/remote_api_service.dart';
import '../services/http_client_service.dart';
import '../services/toast_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  static const _persistNameKey = 'register_name_draft';
  static const _persistEmailKey = 'register_email_draft';
  static const _persistPasswordKey = 'register_password_draft';
  static const _persistConfirmPasswordKey = 'register_confirm_password_draft';

  bool _loadedDraft = false;
  bool _obscurePassword = true;
  final bool _obscureConfirmPassword = true;
  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();
    _restoreDraft();
    _fullNameController.addListener(_persistDraft);
    _emailController.addListener(_persistDraft);
    _passwordController.addListener(_persistDraft);
    _confirmPasswordController.addListener(_persistDraft);
  }

  @override
  void dispose() {
    _fullNameController.removeListener(_persistDraft);
    _emailController.removeListener(_persistDraft);
    _passwordController.removeListener(_persistDraft);
    _confirmPasswordController.removeListener(_persistDraft);
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _restoreDraft() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _fullNameController.text =
          prefs.getString(_persistNameKey) ?? _fullNameController.text;
      _emailController.text =
          prefs.getString(_persistEmailKey) ?? _emailController.text;
      _passwordController.text =
          prefs.getString(_persistPasswordKey) ?? _passwordController.text;
      _confirmPasswordController.text =
          prefs.getString(_persistConfirmPasswordKey) ??
          _confirmPasswordController.text;
      _loadedDraft = true;
    });
  }

  Future<void> _persistDraft() async {
    if (!_loadedDraft) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_persistNameKey, _fullNameController.text);
    await prefs.setString(_persistEmailKey, _emailController.text);
    await prefs.setString(_persistPasswordKey, _passwordController.text);
    await prefs.setString(
      _persistConfirmPasswordKey,
      _confirmPasswordController.text,
    );
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_persistNameKey);
    await prefs.remove(_persistEmailKey);
    await prefs.remove(_persistPasswordKey);
    await prefs.remove(_persistConfirmPasswordKey);
  }

  Future<void> _register() async {
    // Validate password match first
    if (_passwordController.text != _confirmPasswordController.text) {
      ToastService.showError('Passwords do not match', context: context);
      return;
    }

    // Validate required fields
    if (_fullNameController.text.trim().isEmpty) {
      ToastService.showError('Please enter your full name', context: context);
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      ToastService.showError('Please enter your email', context: context);
      return;
    }

    if (_passwordController.text.isEmpty) {
      ToastService.showError('Please enter a password', context: context);
      return;
    }

    // Set loading state
    setState(() {
      _isRegistering = true;
    });

    try {
      final auth = context.read<AuthProvider>();
      final client = HttpClientService.instance;
      auth.enableRemote(RemoteAuthService(client));

      // Call register and wait for result
      final success = await auth.register(
        _fullNameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success) {
        // Registration successful - clear form and redirect to login
        await _clearDraft();
        if (mounted) {
          _fullNameController.clear();
          _emailController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();

          // Navigate to login screen after successful registration
          context.go('/login');
        }
      }
      // If registration fails, stay on the page (error toast is shown by auth provider)
    } finally {
      // Always clear loading state
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  void _goToLogin() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return FScaffold(
      // embed the app bar content into Forui header
      header: FHeader(
        style: (style) => style.copyWith(
          titleTextStyle: style.titleTextStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        // put the back button inline with the title so it appears on the left
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
            Text('Register', style: TextStyle(color: theme.colors.foreground)),
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
                const SizedBox(height: 20),
                Text(
                  "Let's Get Started",
                  style: theme.typography.xl2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colors.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'create an acccount to get all features',
                  style: theme.typography.lg.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _fullNameController,
                  hintText: 'enter your full name',
                  label: const Text('Full name'),
                  prefixIcon: const Icon(FIcons.user),
                ),
                const SizedBox(height: 4),
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
                  prefixIcon: const Icon(FIcons.lock),
                  obscureText: _obscurePassword,
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
                const SizedBox(height: 4),
                AppTextField(
                  controller: _confirmPasswordController,
                  hintText: 'confirm password',
                  label: const Text('Confirm password'),
                  prefixIcon: const Icon(FIcons.lock),
                  obscureText: _obscureConfirmPassword,
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Sign Up',
                    onPressed: _isRegistering ? null : _register,
                    isLoading: _isRegistering,
                    expand: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have account? ',
                      style: theme.typography.sm.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colors.foreground,
                      ),
                    ),
                    AppButton(
                      label: 'Sign In',
                      onPressed: _goToLogin,
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
