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
  final bool? liked; // null = no reaction, true = liked, false = disliked
  final bool
  hasFeedback; // Whether feedback has been submitted for this message
  final String? feedback; // User feedback text
  final int? feedbackStars; // User rating 1-5 stars

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
    this.liked,
    this.hasFeedback = false,
    this.feedback,
    this.feedbackStars,
  });

  ChatMessage copyWith({
    String? content,
    bool? pending,
    int? safetyScore,
    String? safetyJustification,
    String? safetyLevel,
    bool? liked,
    bool? hasFeedback,
    String? feedback,
    int? feedbackStars,
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
    liked: liked ?? this.liked,
    hasFeedback: hasFeedback ?? this.hasFeedback,
    feedback: feedback ?? this.feedback,
    feedbackStars: feedbackStars ?? this.feedbackStars,
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
      timestamp: _parseTimestamp(json['timestamp']),
      safetyScore: _extractSafetyScore(json['safety']),
      safetyJustification: _extractSafetyJustification(json['safety']),
      safetyLevel: _extractSafetyLevel(json['safety']),
      liked: _convertLikeStatus(json['like']),
      hasFeedback: _hasValidFeedback(json['feedback'], json['stars']),
      feedback: json['feedback'] as String?,
      feedbackStars: _convertStars(json['stars']),
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
    liked: json['liked'] as bool?,
    hasFeedback: json['hasFeedback'] as bool? ?? false,
    feedback: json['feedback'] as String?,
    feedbackStars: json['feedbackStars'] as int?,
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
    if (liked != null) 'liked': liked,
    'hasFeedback': hasFeedback,
    if (feedback != null) 'feedback': feedback,
    if (feedbackStars != null) 'feedbackStars': feedbackStars,
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

DateTime _parseTimestamp(dynamic t) {
  if (t == null) return DateTime.now();
  if (t is String) {
    final parsed = DateTime.tryParse(t);
    if (parsed != null) return parsed;
    // Try common formats like 'yyyy-MM-dd HH:mm:ss.SSS'
    try {
      return DateTime.parse(t.replaceFirst(' ', 'T'));
    } catch (e) {
      return DateTime.now();
    }
  }
  if (t is int) {
    // assume epoch millis
    return DateTime.fromMillisecondsSinceEpoch(t);
  }
  return DateTime.now();
}

/// Convert backend 'like' field to boolean representation
/// Backend: "like" -> true, "dislike" -> false, null -> null
bool? _convertLikeStatus(dynamic likeValue) {
  if (likeValue == null) return null;
  final likeStr = likeValue.toString().toLowerCase();
  if (likeStr == 'like') return true;
  if (likeStr == 'dislike') return false;
  return null;
}

/// Check if message has valid feedback (non-empty feedback or rating > 0)
bool _hasValidFeedback(dynamic feedback, dynamic stars) {
  final feedbackText = feedback?.toString().trim();
  final starRating = _convertStars(stars);
  return (feedbackText != null && feedbackText.isNotEmpty) ||
      (starRating != null && starRating > 0);
}

/// Convert backend 'stars' field to nullable int
/// Backend: 0 or null -> null, positive number -> the number
int? _convertStars(dynamic stars) {
  if (stars == null) return null;
  if (stars is int) {
    return stars > 0 ? stars : null;
  }
  if (stars is String) {
    final parsed = int.tryParse(stars);
    return (parsed != null && parsed > 0) ? parsed : null;
  }
  return null;
}
