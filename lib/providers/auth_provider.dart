import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'package:uuid/uuid.dart';
import '../services/api_service.dart';
import '../services/remote_api_service.dart';
import '../services/toast_service.dart';

/// Helper function to extract user-friendly error message from exception
String _extractErrorMessage(dynamic error) {
  final errorString = error.toString();

  // Check if it's an HTTP error with JSON response
  final httpMatch = RegExp(r'HTTP \d+: (.+)').firstMatch(errorString);
  if (httpMatch != null) {
    final responseBody = httpMatch.group(1) ?? '';

    // Try to parse JSON and extract detail/message
    try {
      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      if (data.containsKey('detail')) {
        final detail = data['detail'];
        if (detail is String) {
          return detail;
        } else if (detail is Map && detail.containsKey('message')) {
          return detail['message'].toString();
        }
      }
      if (data.containsKey('message')) {
        return data['message'].toString();
      }
    } catch (e) {
      // If JSON parsing fails, return the original response body
      return responseBody;
    }
  }

  // For non-HTTP errors or if no structured error found, return the original error
  return errorString.replaceFirst('Exception: ', '');
}

class AuthProvider with ChangeNotifier {
  final AuthApiService _api; // local mock
  RemoteAuthService? _remote; // optional remote backend
  bool useRemote = false;
  AuthProvider(this._api);

  AppUser? _user;
  bool _loading = false;
  String? _error;
  bool _initialized = false;

  AppUser? get user => _user;
  bool get isLoading => _loading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;
  bool get initialized => _initialized;

  void enableRemote(RemoteAuthService remote) {
    useRemote = true;
    _remote = remote;
  }

  Future<AppUser?> login(String email, String password) async {
    _error = null;
    try {
      AppUser user;
      if (useRemote && _remote != null) {
        user = await _remote!.login(email, password);
      } else {
        user = await _api.login(email, password);
      }
      // Don't set _user yet - let the calling screen handle success
      return user;
    } catch (e) {
      final errorMessage = _extractErrorMessage(e);
      _error = errorMessage;
      ToastService.showError('Login failed: $errorMessage');
      return null;
    }
  }

  /// Sets the authenticated user after successful login verification
  Future<void> setAuthenticatedUser(AppUser user) async {
    _user = user;
    _error = null;
    await _persistUser();
    notifyListeners();
  }

  Future<bool> register(String name, String email, String password) async {
    _error = null;
    try {
      if (useRemote && _remote != null) {
        // Create a separate registration call that doesn't auto-login
        await _remote!.registerOnly(
          userId: Uuid().v4(),
          name: name,
          email: email,
          password: password,
        );
        // Don't set _user - user needs to login manually after registration
      } else {
        await _api.registerOnly(name, email, password);
      }
      ToastService.showSuccess(
        'Account created successfully! Please log in with your credentials.',
      );
      return true;
    } catch (e) {
      final errorMessage = _extractErrorMessage(e);
      _error = errorMessage;
      ToastService.showError('Registration failed: $errorMessage');
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      if (useRemote && _remote != null && _user?.accessToken != null) {
        await _remote!.logout(_user!.accessToken!);
      } else {
        await _api.logout();
      }
      _user = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_user');
      ToastService.showInfo('You have been logged out successfully.');
    } catch (e) {
      final errorMessage = _extractErrorMessage(e);
      ToastService.showError('Error during logout: $errorMessage');
    } finally {
      _setLoading(false);
    }
  }

  /// Silently refreshes the access token using the refresh token
  /// Returns true if refresh was successful, false otherwise
  /// This method is designed to work silently without showing toast notifications
  Future<bool> relogin({bool showToasts = false}) async {
    if (_user?.refreshToken == null) {
      _error = 'No refresh token available';
      if (showToasts) {
        ToastService.showError('Cannot relogin: No refresh token available');
      }
      return false;
    }

    _setLoading(true);
    _error = null;

    try {
      if (useRemote && _remote != null) {
        final reloggedUser = await _remote!.relogin(_user!.refreshToken!);
        // Update the existing user with new tokens while preserving user data
        _user = AppUser(
          id: _user!.id,
          name: _user!.name,
          email: _user!.email,
          accessToken: reloggedUser.accessToken,
          refreshToken: reloggedUser.refreshToken,
          phone: _user!.phone,
          role: _user!.role,
          createdAt: _user!.createdAt,
        );
        await _persistUser();
        if (showToasts) {
          ToastService.showSuccess('Session refreshed successfully');
        }
        return true;
      } else {
        // For local API, just generate new mock token
        _user = _user!.copyWith(accessToken: 'mock-refreshed-token');
        await _persistUser();
        if (showToasts) {
          ToastService.showSuccess('Session refreshed successfully');
        }
        return true;
      }
    } catch (e) {
      final errorMessage = _extractErrorMessage(e);
      _error = errorMessage;
      if (showToasts) {
        ToastService.showError('Failed to refresh session: $errorMessage');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPersistedUser() async {
    if (_initialized) return; // avoid re-entry
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('auth_user');
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _user = AppUser(
          id: map['user_id'] ?? map['id'] ?? '',
          name: map['name'],
          email: map['email'] ?? '',
          accessToken: map['accessToken'],
          refreshToken: map['refreshToken'],
          phone: map['phone'],
          role: map['role'],
        );
      }
    } catch (e) {
      // swallow errors in restore path
      if (kDebugMode) {
        print('Failed to restore user: $e');
      }
    }
    notifyListeners();
  }

  Future<void> _persistUser() async {
    if (_user == null) return;
    final prefs = await SharedPreferences.getInstance();
    final map = _user!.toJson();
    map['accessToken'] = _user!.accessToken;
    map['refreshToken'] = _user!.refreshToken;
    await prefs.setString('auth_user', jsonEncode(map));
  }

  /// Handle token expiration by logging out user and clearing stored data
  Future<void> handleTokenExpiration({bool showToast = false}) async {
    try {
      _user = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_user');
      if (showToast) {
        ToastService.showError(
          'Your session has expired. Please log in again.',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing expired session: $e');
      }
    }
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
