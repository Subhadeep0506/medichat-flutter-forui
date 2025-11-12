import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../config/app_config.dart';
import '../utils/platform_helper.dart';
import '../utils/app_logger.dart';

/// Enhanced HTTP client with mobile-optimized configurations
class HttpClientService {
  static http.Client? _instance;

  static http.Client get instance {
    _instance ??= _createClient();
    return _instance!;
  }

  static http.Client _createClient() {
    if (AppConfig.isWeb) {
      // For web, use the default browser client
      if (AppConfig.enableDebugLogging) {
        AppLogger.debug('HttpClientService: Creating web client');
      }
      return http.Client();
    }

    // For mobile/desktop, use IOClient with custom configuration
    try {
      final httpClient = HttpClient();

      // Configure timeouts for mobile networks
      httpClient.connectionTimeout = AppConfig.networkTimeout;
      httpClient.idleTimeout = AppConfig.networkTimeout;

      // For mobile apps, handle SSL certificate issues with self-signed certificates
      // Only enable this in development!
      if (AppConfig.enableDebugLogging) {
        httpClient.badCertificateCallback = (cert, host, port) {
          // Log the certificate issue
          AppLogger.warning('SSL Certificate warning for $host:$port');
          // In production, you should validate the certificate properly
          return false; // Change to true only for development with self-signed certs
        };
      }

      // Configure user agent for mobile
      httpClient.userAgent = _getUserAgent();

      if (AppConfig.enableDebugLogging) {
        AppLogger.debug(
          'HttpClientService: Creating IOClient for mobile/desktop',
        );
      }

      return IOClient(httpClient);
    } catch (e) {
      // Fallback to basic client if IOClient creation fails
      if (AppConfig.enableDebugLogging) {
        AppLogger.error(
          'HttpClientService: Falling back to basic client due to: $e',
        );
      }
      return http.Client();
    }
  }

  static String _getUserAgent() {
    return 'MedichatApp/1.0 (${PlatformHelper.platformName})';
  }

  static void dispose() {
    _instance?.close();
    _instance = null;
  }

  /// Enhanced HTTP request with retry logic and better error handling
  static Future<http.Response> makeRequest(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    int maxRetries = 3,
  }) async {
    Exception? lastException;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        http.Response response;

        switch (method.toUpperCase()) {
          case 'GET':
            response = await instance
                .get(uri, headers: headers)
                .timeout(AppConfig.networkTimeout);
            break;
          case 'POST':
            response = await instance
                .post(uri, headers: headers, body: body)
                .timeout(AppConfig.networkTimeout);
            break;
          case 'PUT':
            response = await instance
                .put(uri, headers: headers, body: body)
                .timeout(AppConfig.networkTimeout);
            break;
          case 'DELETE':
            response = await instance
                .delete(uri, headers: headers)
                .timeout(AppConfig.networkTimeout);
            break;
          default:
            throw ArgumentError('Unsupported HTTP method: $method');
        }

        // Log response in debug mode
        if (AppConfig.enableDebugLogging) {
          AppLogger.debug(
            'HTTP $method ${uri.toString()} -> ${response.statusCode}',
          );
          if (response.statusCode >= 400) {
            AppLogger.debug('Response body: ${response.body}');
          }
        }

        return response;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        if (AppConfig.enableDebugLogging) {
          AppLogger.debug('HTTP request failed (attempt ${attempt + 1}): $e');
        }

        // Don't retry on certain errors
        if (e is http.ClientException ||
            e.toString().contains('Connection refused') ||
            e.toString().contains('No route to host')) {
          if (attempt < maxRetries) {
            await Future.delayed(Duration(milliseconds: 1000 * (attempt + 1)));
            continue;
          }
        }

        // For other errors, don't retry
        if (attempt == maxRetries) {
          rethrow;
        }
      }
    }

    throw lastException ??
        Exception('Request failed after $maxRetries attempts');
  }
}
