import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/patient.dart';
import '../models/case.dart';
import '../models/session.dart';
import '../models/message.dart';
import '../config/app_config.dart';
// message.dart defines private helpers we can't import; replicate minimal parsing here.

/// Helper function to extract error message from API response
String _extractErrorMessage(http.Response r) {
  try {
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    if (data.containsKey('detail')) {
      final detail = data['detail'];
      if (detail is String) {
        return detail;
      } else if (detail is Map && detail.containsKey('message')) {
        return detail['message'].toString();
      }
    }
    // Fallback to other common error fields
    if (data.containsKey('message')) {
      return data['message'].toString();
    }
    if (data.containsKey('error')) {
      return data['error'].toString();
    }
  } catch (e) {
    // If JSON parsing fails, return the raw body
  }
  // Fallback to raw response body if no structured error found
  return r.body;
}

/// Remote API client mapped to FastAPI backend.
/// Base URL should be configured (e.g., via const or runtime config).
class RemoteApiConfig {
  static String get baseUrl => AppConfig.backendBaseUrl;
}

/// Callback used to attempt a silent token refresh.
/// Should return true if refresh succeeded and tokens are updated, false otherwise.
typedef TokenRefreshCallback = Future<bool> Function();

class RemoteAuthService {
  final http.Client _client;
  RemoteAuthService(this._client);

  Future<AppUser> login(String email, String password) async {
    final r = await _client.post(
      Uri.parse('${RemoteApiConfig.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    _check(r);
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    // Need user profile? Backend returns only tokens; we could decode or add /users/me endpoint later.
    return AppUser(
      id: email, // placeholder until profile endpoint
      name: email.split('@').first,
      email: email,
      accessToken: data['access_token'],
      refreshToken: data['refresh_token'],
    );
  }

  Future<AppUser> register({
    required String userId,
    required String name,
    required String email,
    required String password,
    String? phone,
    String role = 'user',
  }) async {
    final r = await _client.post(
      Uri.parse('${RemoteApiConfig.baseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
      }),
    );
    _check(r);
    // After register, do login to receive tokens.
    return login(email, password);
  }

  Future<void> registerOnly({
    required String userId,
    required String name,
    required String email,
    required String password,
    String? phone,
    String role = 'user',
  }) async {
    final r = await _client.post(
      Uri.parse('${RemoteApiConfig.baseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
      }),
    );
    _check(r);
    // Registration successful but don't auto-login
    // User will need to login manually after registration
  }

  Future<void> logout(String accessToken) async {
    final r = await _client.post(
      Uri.parse('${RemoteApiConfig.baseUrl}/auth/logout'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    _check(r, allow204: true);
  }

  Future<AppUser> relogin(String refreshToken) async {
    final r = await _client.post(
      Uri.parse('${RemoteApiConfig.baseUrl}/auth/relogin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
    );
    _check(r);
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    // The backend returns new access token and keeps the same refresh token
    return AppUser(
      id: 'relogin_user', // placeholder - would need user profile endpoint for real data
      name: 'User', // placeholder
      email: '', // placeholder
      accessToken: data['access_token'],
      refreshToken: data['refresh_token'],
    );
  }

  void _check(http.Response r, {bool allow204 = false}) {
    if ((r.statusCode < 200 || r.statusCode >= 300) &&
        !(allow204 && r.statusCode == 204)) {
      final errorMessage = _extractErrorMessage(r);
      throw Exception('HTTP ${r.statusCode}: $errorMessage');
    }
  }
}

class RemotePatientService {
  final http.Client _client;
  final String Function() _tokenProvider;
  final TokenRefreshCallback? _refreshCallback;
  RemotePatientService(
    this._client,
    this._tokenProvider, [
    this._refreshCallback,
  ]);

  Map<String, String> _headers() => {
    'Authorization': 'Bearer ${_tokenProvider()}',
  };

  Future<List<Patient>> list() async {
    final r = await _sendWithRetry(
      () => _client.get(
        Uri.parse('${RemoteApiConfig.baseUrl}/patient/'),
        headers: _headers(),
      ),
    );
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final list = (data['patients'] as List?) ?? [];
    return list
        .map((e) => Patient.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Patient> create({
    required String patientId,
    required String name,
    required int age,
    required String gender,
    required String dob,
    required String height,
    required String weight,
    required String medicalHistory,
  }) async {
    final queryParams = {
      'patient_id': patientId,
      'name': name,
      'age': age.toString(),
      'gender': gender,
      'dob': dob,
      'height': height,
      'weight': weight,
      'medical_history': medicalHistory,
    };

    final uri = Uri.parse(
      '${RemoteApiConfig.baseUrl}/patient/',
    ).replace(queryParameters: queryParams);

    final r = await _sendWithRetry(
      () => _client.post(uri, headers: _headers()),
    );
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    return Patient.fromJson(data['patient']);
  }

  Future<Patient> update(
    String patientId, {
    String? name,
    int? age,
    String? gender,
    String? dob,
    String? height,
    String? weight,
    String? medicalHistory,
    List<String>? tags,
  }) async {
    final qp = <String, String>{};
    if (name != null) qp['name'] = name;
    if (age != null) qp['age'] = age.toString();
    if (gender != null) qp['gender'] = gender;
    if (dob != null) qp['dob'] = dob;
    if (height != null) qp['height'] = height;
    if (weight != null) qp['weight'] = weight;
    if (medicalHistory != null) qp['medical_history'] = medicalHistory;

    // Handle tags as multiple query parameters
    if (tags != null) {
      for (String tag in tags) {
        qp['tags'] = tag;
      }
    }

    final uri = Uri.parse(
      '${RemoteApiConfig.baseUrl}/patient/$patientId',
    ).replace(queryParameters: qp.isEmpty ? null : qp);
    final r = await _sendWithRetry(() => _client.put(uri, headers: _headers()));
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    return Patient.fromJson(data['patient']);
  }

  Future<void> delete(String patientId) async {
    await _sendWithRetry(
      () => _client.delete(
        Uri.parse('${RemoteApiConfig.baseUrl}/patient/$patientId'),
        headers: _headers(),
      ),
    );
  }

  Future<http.Response> _sendWithRetry(
    Future<http.Response> Function() send,
  ) async {
    http.Response r = await send();
    // Check if token expired - retry with refresh if callback available
    if (_isExpired(r) && _refreshCallback != null) {
      final ok = await _refreshCallback();
      if (ok) {
        r = await send();
      }
    }
    // Now check the final response
    _check(r);
    return r;
  }

  bool _isExpired(http.Response r) =>
      r.statusCode == 401 || r.statusCode == 403;
  void _check(http.Response r) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      final errorMessage = _extractErrorMessage(r);
      throw Exception('HTTP ${r.statusCode}: $errorMessage');
    }
  }
}

class RemoteCaseService {
  final http.Client _client;
  final String Function() _tokenProvider;
  final TokenRefreshCallback? _refreshCallback;
  RemoteCaseService(this._client, this._tokenProvider, [this._refreshCallback]);

  Map<String, String> _headers() => {
    'Authorization': 'Bearer ${_tokenProvider()}',
  };

  Future<List<MedicalCase>> list() async {
    final r = await _sendWithRetry(
      () => _client.get(
        Uri.parse('${RemoteApiConfig.baseUrl}/cases/'),
        headers: _headers(),
      ),
    );
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final list = (data['cases'] as List?) ?? [];
    return list.map((e) => MedicalCase.fromJson(e)).toList();
  }

  Future<MedicalCase> create({
    required String caseId,
    required String patientId,
    required String name,
    required String description,
    required List<String> tags,
    required String priority,
  }) async {
    final qp = <String, String>{
      'case_id': caseId,
      'patient_id': patientId,
      'case_name': name,
      'description': description,
      'priority': priority,
    };

    // Create URI with base query parameters
    Uri uri = Uri.parse(
      '${RemoteApiConfig.baseUrl}/cases/',
    ).replace(queryParameters: qp);

    // Add tags as multiple query parameters if present
    if (tags.isNotEmpty) {
      final existingQuery = uri.query;
      final tagsQuery = tags
          .map((tag) => 'tags=${Uri.encodeComponent(tag)}')
          .join('&');
      final fullQuery = existingQuery.isEmpty
          ? tagsQuery
          : '$existingQuery&$tagsQuery';
      uri = Uri.parse('${uri.scheme}://${uri.authority}${uri.path}?$fullQuery');
    }

    final r = await _sendWithRetry(
      () => _client.post(uri, headers: _headers()),
    );
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    return MedicalCase.fromJson(data['case']);
  }

  Future<MedicalCase> update(
    String caseId, {
    String? name,
    String? description,
    List<String>? tags,
    String? priority,
  }) async {
    final qp = <String, String>{};
    if (name != null) qp['case_name'] = name;
    if (description != null) qp['description'] = description;
    if (priority != null) qp['priority'] = priority;

    // Create URI with base query parameters
    Uri uri = Uri.parse(
      '${RemoteApiConfig.baseUrl}/cases/$caseId',
    ).replace(queryParameters: qp.isEmpty ? null : qp);

    // Add tags as multiple query parameters if present
    if (tags != null && tags.isNotEmpty) {
      final existingQuery = uri.query;
      final tagsQuery = tags
          .map((tag) => 'tags=${Uri.encodeComponent(tag)}')
          .join('&');
      final fullQuery = existingQuery.isEmpty
          ? tagsQuery
          : '$existingQuery&$tagsQuery';
      uri = Uri.parse('${uri.scheme}://${uri.authority}${uri.path}?$fullQuery');
    }

    final r = await _sendWithRetry(() => _client.put(uri, headers: _headers()));
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    return MedicalCase.fromJson(data['case']);
  }

  Future<void> delete(String caseId) async {
    await _sendWithRetry(
      () => _client.delete(
        Uri.parse('${RemoteApiConfig.baseUrl}/cases/$caseId'),
        headers: _headers(),
      ),
    );
  }

  Future<http.Response> _sendWithRetry(
    Future<http.Response> Function() send,
  ) async {
    http.Response r = await send();
    // Check if token expired - retry with refresh if callback available
    if (_isExpired(r) && _refreshCallback != null) {
      final ok = await _refreshCallback();
      if (ok) {
        r = await send();
      }
    }
    // Now check the final response
    _check(r);
    return r;
  }

  bool _isExpired(http.Response r) =>
      r.statusCode == 401 || r.statusCode == 403;
  void _check(http.Response r) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      final errorMessage = _extractErrorMessage(r);
      throw Exception('HTTP ${r.statusCode}: $errorMessage');
    }
  }
}

class RemoteSessionService {
  final http.Client _client;
  final String Function() _tokenProvider;
  final TokenRefreshCallback? _refreshCallback;
  RemoteSessionService(
    this._client,
    this._tokenProvider, [
    this._refreshCallback,
  ]);
  Map<String, String> _headers() => {
    'Authorization': 'Bearer ${_tokenProvider()}',
  };

  Future<List<ChatSession>> listForCase({
    required String caseId,
    required String patientId,
  }) async {
    final uri = Uri.parse(
      '${RemoteApiConfig.baseUrl}/history/sessions',
    ).replace(queryParameters: {'case_id': caseId, 'patient_id': patientId});
    final r = await _sendWithRetry(() => _client.get(uri, headers: _headers()));
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final sessions = (data['sessions'] as List?) ?? [];
    return sessions.map((e) {
      final m = e as Map<String, dynamic>;
      return ChatSession(
        id: m['session_id'] ?? '',
        caseId: m['case_id'] ?? '',
        title: m['title'] ?? '',
        createdAt:
            DateTime.tryParse(
              m['time_created'] ?? DateTime.now().toIso8601String(),
            ) ??
            DateTime.now(),
      );
    }).toList();
  }

  Future<String> create({
    required String sessionId,
    required String caseId,
    required String patientId,
    required String title,
  }) async {
    final uri = Uri.parse('${RemoteApiConfig.baseUrl}/history/sessions')
        .replace(
          queryParameters: {
            'session_id': sessionId,
            'case_id': caseId,
            'patient_id': patientId,
            'title': title,
          },
        );
    await _sendWithRetry(() => _client.post(uri, headers: _headers()));
    return sessionId;
  }

  Future<void> rename(String sessionId, String title) async {
    final uri = Uri.parse(
      '${RemoteApiConfig.baseUrl}/history/sessions/$sessionId',
    ).replace(queryParameters: {'title': title});
    await _sendWithRetry(() => _client.put(uri, headers: _headers()));
  }

  Future<void> delete(String sessionId) async {
    final uri = Uri.parse(
      '${RemoteApiConfig.baseUrl}/history/session/$sessionId',
    );
    await _sendWithRetry(() => _client.delete(uri, headers: _headers()));
  }

  Future<http.Response> _sendWithRetry(
    Future<http.Response> Function() send,
  ) async {
    http.Response r = await send();
    // Check if token expired - retry with refresh if callback available
    if (_isExpired(r) && _refreshCallback != null) {
      final ok = await _refreshCallback();
      if (ok) {
        r = await send();
      }
    }
    // Now check the final response
    _check(r);
    return r;
  }

  bool _isExpired(http.Response r) =>
      r.statusCode == 401 || r.statusCode == 403;
  void _check(http.Response r) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      final errorMessage = _extractErrorMessage(r);
      throw Exception('HTTP ${r.statusCode}: $errorMessage');
    }
  }
}

class RemoteChatResponse {
  final String response;
  final int? safetyScore;
  final String? safetyJustification;
  final String? safetyLevel;
  const RemoteChatResponse({
    required this.response,
    this.safetyScore,
    this.safetyJustification,
    this.safetyLevel,
  });
}

class RemoteChatService {
  final http.Client _client;
  final String Function() _tokenProvider;
  final TokenRefreshCallback? _refreshCallback;
  RemoteChatService(this._client, this._tokenProvider, [this._refreshCallback]);
  Map<String, String> _headers() => {
    'Authorization': 'Bearer ${_tokenProvider()}',
  };
  Future<List<ChatMessage>> history(String sessionId) async {
    final uri = Uri.parse(
      '${RemoteApiConfig.baseUrl}/history/messages/$sessionId',
    );
    final r = await _sendWithRetry(() => _client.get(uri, headers: _headers()));
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final conv = (data['conversations'] as List?) ?? [];

    // Flatten messages from the backend format
    final List<ChatMessage> messages = [];

    for (int convIndex = 0; convIndex < conv.length; convIndex++) {
      final conversation = conv[convIndex] as Map<String, dynamic>;
      final sessionIdFromConv =
          conversation['session_id']?.toString() ?? sessionId;
      final dynamic content = conversation['content'];
      final safety = conversation['safety'];
      // Flattened format already: {session_id, message_id, role, content, safety}
      if (content is String) {
        final role =
            conversation['role']?.toString().toLowerCase() ?? 'assistant';
        final chatRole = (role == 'user' || role == 'human')
            ? ChatRole.user
            : ChatRole.ai;
        messages.add(
          ChatMessage(
            id:
                conversation['message_id']?.toString() ??
                'msg_${DateTime.now().microsecondsSinceEpoch}',
            sessionId: sessionIdFromConv,
            role: chatRole,
            content: content.trim(),
            timestamp: DateTime.now(),
            safetyScore: _parseSafetyScore(safety),
            safetyJustification: _parseSafetyJustification(safety),
            safetyLevel: _parseSafetyLevel(safety),
          ),
        );
        continue;
      }
      // Legacy nested list handling
      final contentArray = content as List?;
      if (contentArray != null) {
        for (int msgIndex = 0; msgIndex < contentArray.length; msgIndex++) {
          final msgData = contentArray[msgIndex] as Map<String, dynamic>;
          final role = msgData['role']?.toString().toLowerCase() ?? 'assistant';
          final dynamic rawContent = msgData['content'];
          String finalContent = '';
          if (rawContent is String) {
            finalContent = rawContent;
          } else if (rawContent is List) {
            final textParts = <String>[];
            for (final item in rawContent) {
              if (item is Map<String, dynamic>) {
                if (item['type'] == 'text') {
                  textParts.add(item['text']?.toString() ?? '');
                } else {
                  textParts.add(
                    item['text']?.toString() ??
                        item['content']?.toString() ??
                        '',
                  );
                }
              } else {
                textParts.add(item?.toString() ?? '');
              }
            }
            finalContent = textParts
                .where((s) => s.trim().isNotEmpty)
                .join('\n\n');
          } else {
            finalContent = rawContent?.toString() ?? '';
          }
          final chatRole = (role == 'user' || role == 'human')
              ? ChatRole.user
              : ChatRole.ai;
          messages.add(
            ChatMessage(
              id: 'msg_${convIndex}_${msgIndex}_${DateTime.now().millisecondsSinceEpoch}',
              sessionId: sessionIdFromConv,
              role: chatRole,
              content: finalContent.trim(),
              timestamp: DateTime.now(),
              safetyScore: _parseSafetyScore(safety),
              safetyJustification: _parseSafetyJustification(safety),
              safetyLevel: _parseSafetyLevel(safety),
            ),
          );
        }
      }
    }

    return messages;
  }

  Future<RemoteChatResponse> send({
    required String sessionId,
    required String caseId,
    required String patientId,
    required String prompt,
    Map<String, String>? chatSettings,
  }) async {
    final queryParams = {
      'session_id': sessionId,
      'case_id': caseId,
      'patient_id': patientId,
      'prompt': prompt,
    };

    // Add chat settings if provided
    if (chatSettings != null) {
      queryParams.addAll(chatSettings);
    }

    final uri = Uri.parse(
      '${RemoteApiConfig.baseUrl}/chat/',
    ).replace(queryParameters: queryParams);
    final r = await _sendWithRetry(
      () => _client.post(uri, headers: _headers()),
    );
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final responseText = data['response']?.toString() ?? '';
    final safety = data['safety_score'];
    return RemoteChatResponse(
      response: responseText,
      safetyScore: _parseSafetyScore(safety),
      safetyJustification: _parseSafetyJustification(safety),
      safetyLevel: _parseSafetyLevel(safety),
    );
  }

  Future<http.Response> _sendWithRetry(
    Future<http.Response> Function() send,
  ) async {
    http.Response r = await send();
    // Check if token expired - retry with refresh if callback available
    if (_isExpired(r) && _refreshCallback != null) {
      final ok = await _refreshCallback();
      if (ok) {
        r = await send();
      }
    }
    // Now check the final response
    _check(r);
    return r;
  }

  bool _isExpired(http.Response r) =>
      r.statusCode == 401 || r.statusCode == 403;
  void _check(http.Response r) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      final errorMessage = _extractErrorMessage(r);
      throw Exception('HTTP ${r.statusCode}: $errorMessage');
    }
  }
}

int? _parseSafetyScore(dynamic safety) {
  if (safety is Map && safety['score'] is int) return safety['score'] as int;
  if (safety is Map && safety['score'] is String) {
    return int.tryParse(safety['score']);
  }
  return null;
}

String? _parseSafetyJustification(dynamic safety) {
  if (safety is Map && safety['justification'] is String) {
    return safety['justification'] as String;
  }
  return null;
}

String? _parseSafetyLevel(dynamic safety) {
  if (safety is Map && safety['safety_level'] is String) {
    return safety['safety_level'] as String;
  }
  if (safety is Map && safety['level'] is String) {
    return safety['level'] as String;
  }
  return null;
}

class RemoteUserService {
  final http.Client _client;
  final String Function() _tokenProvider;
  final TokenRefreshCallback? _refreshCallback;

  RemoteUserService(this._client, this._tokenProvider, [this._refreshCallback]);

  Map<String, String> _headers() => {
    'Authorization': 'Bearer ${_tokenProvider()}',
  };

  /// Fetch current user profile from /users/me endpoint
  Future<AppUser> getCurrentUser() async {
    final r = await _sendWithRetry(
      () => _client.get(
        Uri.parse('${RemoteApiConfig.baseUrl}/users/me'),
        headers: _headers(),
      ),
    );
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final userJson = data['user'] as Map<String, dynamic>;

    // Return user with current tokens preserved
    return AppUser.fromJson(
      userJson,
      accessToken: _tokenProvider(),
      refreshToken: null, // We don't have refresh token in this context
    );
  }

  /// Update current user profile
  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? role,
  }) async {
    final Map<String, String> queryParams = {};
    if (name != null) queryParams['name'] = name;
    if (email != null) queryParams['email'] = email;
    if (phone != null) queryParams['phone'] = phone;
    if (role != null) queryParams['role'] = role;

    final uri = Uri.parse(
      '${RemoteApiConfig.baseUrl}/users/',
    ).replace(queryParameters: queryParams);

    await _sendWithRetry(() => _client.put(uri, headers: _headers()));
  }

  Future<http.Response> _sendWithRetry(
    Future<http.Response> Function() send,
  ) async {
    http.Response r = await send();
    // Check if token expired - retry with refresh if callback available
    if (_isExpired(r) && _refreshCallback != null) {
      final ok = await _refreshCallback();
      if (ok) {
        r = await send();
      }
    }
    // Now check the final response
    _check(r);
    return r;
  }

  bool _isExpired(http.Response r) =>
      r.statusCode == 401 || r.statusCode == 403;
  void _check(http.Response r) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      final errorMessage = _extractErrorMessage(r);
      throw Exception('HTTP ${r.statusCode}: $errorMessage');
    }
  }
}

/// Exception thrown when token is expired or invalid
class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException(this.message);

  @override
  String toString() => 'TokenExpiredException: $message';
}
