import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/remote_api_service.dart';
import '../services/toast_service.dart';

class UserProvider with ChangeNotifier {
  RemoteUserService? _userService;
  AppUser? _user;
  bool _loading = false;
  String? _error;

  AppUser? get user => _user;
  bool get isLoading => _loading;
  String? get error => _error;

  void enableRemote(RemoteUserService userService) {
    _userService = userService;
  }

  /// Fetch current user profile from API
  Future<void> fetchProfile() async {
    if (_userService == null) {
      _error = 'User service not initialized';
      notifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;

    try {
      _user = await _userService!.getCurrentUser();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();

      // Check if it's a token expiration error
      if (e is TokenExpiredException) {
        ToastService.showError('Session expired. Please log in again.');
        // The auth provider should handle the logout
        throw e; // Re-throw to let the caller handle logout
      } else {
        ToastService.showError('Failed to fetch profile: ${e.toString()}');
      }
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? role,
  }) async {
    if (_userService == null) {
      _error = 'User service not initialized';
      notifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;

    try {
      await _userService!.updateProfile(
        name: name,
        email: email,
        phone: phone,
        role: role,
      );

      // Refresh profile after update
      await fetchProfile();

      // Success handled by ApiErrorHandler
    } catch (e) {
      _error = e.toString();

      // Check if it's a token expiration error
      if (e is TokenExpiredException) {
        throw e; // Re-throw to let the caller handle logout
      } else {
        // Error handled by ApiErrorHandler
        throw e; // Re-throw to let the caller handle error display
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Set user data (called from AuthProvider when user logs in)
  void setUser(AppUser user) {
    _user = user;
    _error = null;
    notifyListeners();
  }

  /// Clear user data (called when user logs out)
  void clearUser() {
    _user = null;
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
