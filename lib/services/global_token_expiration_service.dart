import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// Global service for handling token expiration across the entire app
/// This service automatically refreshes tokens when they expire without showing popups
class GlobalTokenExpirationService {
  static GlobalKey<NavigatorState>? _navigatorKey;
  static bool _isRefreshing = false;
  static final List<Function()> _pendingOperations = [];

  /// Sets the navigator key from the router - should only be called once
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Gets the navigator key - returns null if not set
  static GlobalKey<NavigatorState>? get navigatorKey => _navigatorKey;

  /// Automatically handles token expiration by refreshing the token
  /// Returns true if token refresh was successful, false if user needs to login again
  /// This method works independently of navigation context to avoid state issues
  static Future<bool> handleTokenExpiration({
    AuthProvider? authProvider,
    BuildContext? context,
  }) async {
    // Prevent multiple refresh attempts from running simultaneously
    if (_isRefreshing) {
      // Wait for ongoing refresh to complete
      while (_isRefreshing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      // Return whether we have a valid user after the refresh
      if (authProvider != null) {
        return authProvider.isAuthenticated;
      }
      // Try provided context first, then navigator key context
      BuildContext? availableContext = context ?? _navigatorKey?.currentContext;
      if (availableContext != null) {
        try {
          final provider = Provider.of<AuthProvider>(
            availableContext,
            listen: false,
          );
          return provider.isAuthenticated;
        } catch (e) {
          debugPrint('Error getting auth provider during refresh check: $e');
        }
      }
      return false;
    }

    _isRefreshing = true;

    try {
      // Use provided authProvider or get from context
      AuthProvider? provider = authProvider;
      if (provider == null) {
        // Try provided context first, then navigator key context
        BuildContext? availableContext =
            context ?? _navigatorKey?.currentContext;
        if (availableContext != null && availableContext.mounted) {
          provider = Provider.of<AuthProvider>(availableContext, listen: false);
        }
      }

      if (provider == null) {
        debugPrint('No auth provider available for token refresh');
        return false;
      }

      // Attempt to refresh the token automatically
      debugPrint('Token expired, attempting automatic refresh...');
      final refreshSuccess = await provider.relogin();

      if (refreshSuccess) {
        debugPrint('Token refresh successful, resuming operations');
        // Execute any pending operations
        _executePendingOperations();
        return true;
      } else {
        // Refresh failed, logout and redirect to login
        debugPrint('Token refresh failed, clearing session');
        await provider.handleTokenExpiration();
        _redirectToLogin();
        return false;
      }
    } catch (e) {
      // Handle any errors gracefully - don't crash the app
      debugPrint('Error during automatic token refresh: $e');

      // Fallback: logout and navigate to login
      if (authProvider != null) {
        await authProvider.handleTokenExpiration();
      } else {
        // Try provided context first, then navigator key context
        BuildContext? availableContext =
            context ?? _navigatorKey?.currentContext;
        if (availableContext != null && availableContext.mounted) {
          final provider = Provider.of<AuthProvider>(
            availableContext,
            listen: false,
          );
          await provider.handleTokenExpiration();
        }
      }
      _redirectToLogin();
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Safely redirects to login without navigation context issues
  static void _redirectToLogin() {
    // Use a delayed approach to avoid navigation state issues
    Future.microtask(() {
      final context = _navigatorKey?.currentContext;
      if (context != null && context.mounted) {
        try {
          context.go('/login');
        } catch (e) {
          debugPrint('Navigation error during login redirect: $e');
          // If go fails, try push replacement
          try {
            context.pushReplacement('/login');
          } catch (e2) {
            debugPrint('Push replacement also failed: $e2');
            // As last resort, just clear the navigation stack
            debugPrint(
              'All navigation methods failed, unable to redirect to login',
            );
          }
        }
      } else {
        debugPrint('No navigation context available for login redirect');
      }
    });
  }

  /// Adds an operation to be executed after successful token refresh
  static void addPendingOperation(Function() operation) {
    _pendingOperations.add(operation);
  }

  /// Executes all pending operations and clears the list
  static void _executePendingOperations() {
    for (final operation in _pendingOperations) {
      try {
        operation();
      } catch (e) {
        debugPrint('Error executing pending operation: $e');
      }
    }
    _pendingOperations.clear();
  }

  /// Clears all pending operations (useful when redirect to login)
  static void clearPendingOperations() {
    _pendingOperations.clear();
  }

  /// Wraps an API call with automatic token refresh handling
  /// This is a convenience method that can be used directly for API calls
  /// that might throw TokenExpiredException
  static Future<T> wrapApiCall<T>(
    Future<T> Function() apiCall, {
    AuthProvider? authProvider,
    BuildContext? context,
  }) async {
    try {
      return await apiCall();
    } catch (e) {
      if (e.toString().contains('TokenExpiredException') ||
          e.toString().contains('401') ||
          e.toString().contains('Invalid token') ||
          e.toString().contains('expired token')) {
        final refreshSuccess = await handleTokenExpiration(
          authProvider: authProvider,
          context: context,
        );

        if (refreshSuccess) {
          // Token refresh successful, retry the original operation
          debugPrint('Token refreshed successfully, retrying API call...');
          return await apiCall();
        } else {
          // Token refresh failed, re-throw the original error
          debugPrint('Token refresh failed, API call cannot continue');
          rethrow;
        }
      }

      // For other exceptions, just re-throw
      rethrow;
    }
  }

  /// Checks if token refresh is currently in progress
  static bool get isRefreshing => _isRefreshing;

  /// Resets the refresh state (useful for testing or manual state management)
  static void resetRefreshState() {
    _isRefreshing = false;
    clearPendingOperations();
  }
}
