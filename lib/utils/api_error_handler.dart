import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/remote_api_service.dart';
import '../services/toast_service.dart';
import '../services/global_token_expiration_service.dart';
import 'app_logger.dart';

/// Global error handler for API calls that automatically handles token expiration
class ApiErrorHandler {
  /// Wraps an API call and handles TokenExpiredException globally
  /// Automatically attempts to refresh the token and retry the operation
  static Future<T> handleApiCall<T>(
    BuildContext context,
    Future<T> Function() apiCall,
  ) async {
    try {
      return await apiCall();
    } catch (e) {
      if (e is TokenExpiredException) {
        // Get auth provider from context to avoid navigation issues
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        // Automatically handle token expiration
        final refreshSuccess =
            await GlobalTokenExpirationService.handleTokenExpiration(
              authProvider: authProvider,
              context: context,
            );

        if (refreshSuccess) {
          // Token refresh successful, retry the original operation
          AppLogger.debug(
            'Token refreshed successfully, retrying operation...',
          );
          try {
            return await apiCall();
          } catch (retryError) {
            // If the retry fails, re-throw the original error
            AppLogger.debug('Retry after token refresh failed: $retryError');
            rethrow;
          }
        } else {
          // Token refresh failed, operation cannot continue
          AppLogger.debug('Token refresh failed, operation aborted');
          rethrow;
        }
      }

      // For other exceptions, just re-throw
      rethrow;
    }
  }

  /// Wraps an API call that may throw TokenExpiredException and shows a user-friendly error
  static Future<T?> safeApiCall<T>(
    BuildContext context,
    Future<T> Function() apiCall, {
    String? errorMessage,
    bool showErrorToast = true,
  }) async {
    try {
      return await handleApiCall(context, apiCall);
    } catch (e) {
      if (e is TokenExpiredException) {
        // Token expiration is already handled in handleApiCall
        return null;
      }

      // Handle other errors
      if (showErrorToast) {
        ToastService.showError(
          errorMessage ?? 'An error occurred: ${e.toString()}',
          context: context,
        );
      }

      return null;
    }
  }
}
