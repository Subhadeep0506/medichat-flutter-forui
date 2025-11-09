enum ChatRole { user, ai }

class ChatMessage {
  final String id;
  final String sessionId;
  final ChatRole role;
  final String content;
  final DateTime timestamp;
  final bool pending; // For streaming / in-progress AI responses
  final int? safetyScore; // AI safety score (10-100) if available
  final String? safetyJustification; // Explanation of score
  final String? safetyLevel; // Low / Medium / High etc.

  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.pending = false,
    this.safetyScore,
    this.safetyJustification,
    this.safetyLevel,
  });

  ChatMessage copyWith({
    String? content,
    bool? pending,
    int? safetyScore,
    String? safetyJustification,
    String? safetyLevel,
  }) => ChatMessage(
    id: id,
    sessionId: sessionId,
    role: role,
    content: content ?? this.content,
    timestamp: timestamp,
    pending: pending ?? this.pending,
    safetyScore: safetyScore ?? this.safetyScore,
    safetyJustification: safetyJustification ?? this.safetyJustification,
    safetyLevel: safetyLevel ?? this.safetyLevel,
  );

  factory ChatMessage.fromHistoryJson(Map<String, dynamic> json) {
    // Backend contract: top-level 'role' and 'content'. Content may be:
    //  String OR List[ {type,text,content} ] OR Map with 'text'/'content'.
    final rawRole = (json['role']?.toString() ?? '').toLowerCase();
    final dynamic rawContent = json['content'];

    String pull(dynamic c) {
      if (c == null) return '';
      if (c is String) return c.trim();
      if (c is List) {
        return c
            .map((e) {
              if (e is Map) {
                // Handle OpenAI-style message format with type field
                if (e['type'] == 'text') {
                  return e['text']?.toString() ?? '';
                }
                // Handle standard content fields
                return e['text']?.toString() ?? e['content']?.toString() ?? '';
              }
              return e?.toString() ?? '';
            })
            .where((s) => s.trim().isNotEmpty)
            .join('\n\n')
            .trim();
      }
      if (c is Map) {
        // Handle OpenAI-style content with type
        if (c['type'] == 'text') {
          return (c['text'] as String?)?.trim() ?? '';
        }
        if (c['text'] is String) return (c['text'] as String).trim();
        if (c['content'] is String) return (c['content'] as String).trim();
        if (c['content'] is List) return pull(c['content']);
      }
      return '';
    }

    final text = pull(rawContent);

    // Enhanced role detection - try multiple fields and formats
    ChatRole role = ChatRole.ai; // default
    if (rawRole == 'user' || rawRole == 'human') {
      role = ChatRole.user;
    } else if (rawRole == 'assistant' || rawRole == 'ai' || rawRole == 'bot') {
      role = ChatRole.ai;
    } else if (json.containsKey('role') == false) {
      // No role field - try to infer from content or other fields
      // If content looks like a user query (short, question-like), assume user
      if (text.isNotEmpty && text.length < 200 && text.contains('?')) {
        role = ChatRole.user;
      }
    }

    return ChatMessage(
      id:
          json['message_id']?.toString() ??
          json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      sessionId: json['session_id']?.toString() ?? '',
      role: role,
      content: text,
      timestamp: DateTime.now(),
      safetyScore: _extractSafetyScore(json['safety']),
      safetyJustification: _extractSafetyJustification(json['safety']),
      safetyLevel: _extractSafetyLevel(json['safety']),
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    sessionId: json['sessionId'] as String,
    role: (json['role'] == 'user') ? ChatRole.user : ChatRole.ai,
    content: json['content'] as String? ?? '',
    timestamp:
        DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    pending: json['pending'] as bool? ?? false,
    safetyScore: json['safetyScore'] as int?,
    safetyJustification: json['safetyJustification'] as String?,
    safetyLevel: json['safetyLevel'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'role': role == ChatRole.user ? 'user' : 'ai',
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'pending': pending,
    if (safetyScore != null) 'safetyScore': safetyScore,
    if (safetyJustification != null) 'safetyJustification': safetyJustification,
    if (safetyLevel != null) 'safetyLevel': safetyLevel,
  };
}

int? _extractSafetyScore(dynamic safety) {
  if (safety is Map && safety['score'] is int) return safety['score'] as int;
  if (safety is Map && safety['score'] is String) {
    final v = int.tryParse(safety['score']);
    return v;
  }
  return null;
}

String? _extractSafetyJustification(dynamic safety) {
  if (safety is Map && safety['justification'] is String) {
    return safety['justification'] as String;
  }
  return null;
}

String? _extractSafetyLevel(dynamic safety) {
  if (safety is Map && safety['safety_level'] is String) {
    return safety['safety_level'] as String;
  }
  if (safety is Map && safety['level'] is String) {
    return safety['level'] as String; // fallback alternate key
  }
  return null;
}
