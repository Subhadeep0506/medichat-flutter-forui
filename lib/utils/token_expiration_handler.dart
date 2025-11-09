import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/remote_api_service.dart';
import '../utils/api_error_handler.dart';

/// A mixin that provides token expiration handling for screens and widgets
/// This should be used in screens that make API calls that might result in token expiration
mixin TokenExpirationHandler<T extends StatefulWidget> on State<T> {
  /// Wraps an async operation with token expiration handling
  /// Automatically attempts to refresh tokens and retry the operation
  Future<R?> handleTokenExpiration<R>(
    Future<R> Function() operation, {
    String? errorMessage,
  }) async {
    try {
      return await operation();
    } catch (e) {
      if (e is TokenExpiredException) {
        // Use the API error handler to automatically refresh tokens
        try {
          return await ApiErrorHandler.handleApiCall(context, operation);
        } catch (_) {
          // Token refresh failed or operation still failed after retry
          return null;
        }
      }
      rethrow;
    }
  }

  /// Safely executes an API call with token expiration handling
  /// Returns null if the operation fails or if token is expired
  Future<R?> safeApiCall<R>(
    Future<R> Function() apiCall, {
    String? errorMessage,
    bool showErrorToast = true,
  }) {
    return ApiErrorHandler.safeApiCall(
      context,
      apiCall,
      errorMessage: errorMessage,
      showErrorToast: showErrorToast,
    );
  }

  /// Gets the current auth provider
  AuthProvider get authProvider => context.read<AuthProvider>();

  /// Checks if user is authenticated
  bool get isAuthenticated => authProvider.isAuthenticated;

  /// Gets current user's access token
  String? get accessToken => authProvider.user?.accessToken;
}
