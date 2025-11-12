import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/remote_api_service.dart';
import '../utils/app_logger.dart';

class ChatProvider with ChangeNotifier {
  final ChatApiService _api; // mock
  RemoteChatService? _remote;
  bool useRemote = false;
  ChatProvider(this._api);

  void enableRemote(RemoteChatService remote) {
    useRemote = true;
    _remote = remote;
  }

  final Map<String, List<ChatMessage>> _messagesBySession =
      {}; // sessionId -> messages
  final Map<String, bool> _loadingBySession = {}; // sessionId -> loading
  final Map<String, bool> _sendingBySession = {}; // sessionId -> sending
  String? _error;

  List<ChatMessage> messagesFor(String sessionId) =>
      List.from(_messagesBySession[sessionId] ?? []);
  bool isLoading(String sessionId) => _loadingBySession[sessionId] == true;
  bool isSending(String sessionId) => _sendingBySession[sessionId] == true;
  String? get error => _error;

  Future<void> load(String sessionId) async {
    _loadingBySession[sessionId] = true;
    notifyListeners();
    try {
      // Try local cache first
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'chat_messages_$sessionId';
      final cached = prefs.getString(cacheKey);
      List<ChatMessage> msgs = [];
      if (cached != null) {
        try {
          final List data = jsonDecode(cached) as List;
          msgs = data
              .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }
      // If cache empty OR no user messages OR all user messages have empty content (old parsing bug), refetch
      final userMessages = msgs.where((m) => m.role == ChatRole.user).toList();
      final bool needsRefetch =
          msgs.isEmpty ||
          (msgs.isNotEmpty && userMessages.isEmpty) || // No user messages found
          (userMessages.isNotEmpty &&
              userMessages.any((m) => m.content.trim().isEmpty));
      if (needsRefetch) {
        msgs = (useRemote && _remote != null)
            ? await _remote!.history(sessionId)
            : await _api.listMessages(sessionId);
        // Persist fetched messages
        unawaited(_persist(sessionId));
      }
      _messagesBySession[sessionId] = msgs;
      _error = null;
    } catch (e) {
      // Re-throw token expiration exceptions so they can be handled by UI
      if (e is TokenExpiredException) {
        _loadingBySession[sessionId] = false;
        notifyListeners();
        rethrow;
      }
      _error = e.toString();
    } finally {
      _loadingBySession[sessionId] = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(
    String sessionId,
    String content, {
    String? caseId,
    String? patientId,
    Map<String, String>? chatSettings,
  }) async {
    _sendingBySession[sessionId] = true;
    notifyListeners();
    try {
      final userMsg = await _api.addUserMessage(
        sessionId,
        content,
      ); // always add locally first
      _messagesBySession[sessionId] = [
        ...(_messagesBySession[sessionId] ?? []),
        userMsg,
      ];
      notifyListeners();
      unawaited(_persist(sessionId));
      // Simulate AI response
      final placeholder = ChatMessage(
        id: 'pending-${DateTime.now().microsecondsSinceEpoch}',
        sessionId: sessionId,
        role: ChatRole.ai,
        content: '...',
        timestamp: DateTime.now(),
        pending: true,
      );
      _messagesBySession[sessionId] = [
        ..._messagesBySession[sessionId]!,
        placeholder,
      ];
      notifyListeners();
      // Replace with streaming / real call
      ChatMessage aiMsg;
      if (useRemote && _remote != null && caseId != null && patientId != null) {
        final remoteResp = await _remote!.send(
          sessionId: sessionId,
          caseId: caseId,
          patientId: patientId,
          prompt: content,
          chatSettings: chatSettings,
        );
        // Debug log safety metadata
        // ignore: avoid_print
        AppLogger.debug(
          '[ChatProvider] Received remote response safety: score=${remoteResp.safetyScore?.toString() ?? 'null'}, level=${remoteResp.safetyLevel ?? 'null'}',
        );
        aiMsg = ChatMessage(
          id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
          sessionId: sessionId,
          role: ChatRole.ai,
          content: remoteResp.response,
          timestamp: DateTime.now(),
          safetyScore: remoteResp.safetyScore,
          safetyJustification: remoteResp.safetyJustification,
          safetyLevel: remoteResp.safetyLevel,
        );
      } else {
        aiMsg = await _api.addAIMessage(sessionId, 'AI response to: $content');
      }
      _messagesBySession[sessionId] =
          _messagesBySession[sessionId]!.where((m) => !m.pending).toList()
            ..add(aiMsg);
      notifyListeners();
      unawaited(_persist(sessionId));
    } catch (e) {
      // Re-throw token expiration exceptions so they can be handled by UI
      if (e is TokenExpiredException) {
        _sendingBySession[sessionId] = false;
        notifyListeners();
        rethrow;
      }
      _error = e.toString();
    } finally {
      _sendingBySession[sessionId] = false;
      notifyListeners();
    }
  }

  /// Force refresh messages from remote, clearing cache
  Future<void> forceRefresh(String sessionId) async {
    // Clear cache first
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'chat_messages_$sessionId';
    await prefs.remove(cacheKey);

    // Clear in-memory cache
    _messagesBySession.remove(sessionId);

    // Reload from remote
    await load(sessionId);
  }

  Future<void> _persist(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'chat_messages_$sessionId';
    final list = _messagesBySession[sessionId] ?? [];
    final jsonList = list.map((m) => m.toJson()).toList();
    await prefs.setString(cacheKey, jsonEncode(jsonList));
  }

  /// Like or unlike a message
  /// [messageId] - The ID of the message
  /// [action] - 'like' to like the message, 'unlike' to remove like
  Future<void> likeMessage(String messageId, String action) async {
    if (!useRemote || _remote == null) {
      AppLogger.debug(
        'ChatProvider: Remote service not available for like action',
      );
      return;
    }

    // Determine the new liked state based on action
    bool? liked;
    switch (action) {
      case 'like':
        liked = true;
        break;
      case 'dislike':
        liked = false;
        break;
      case 'unlike':
        liked = null;
        break;
      default:
        liked = null;
    }

    // Store the original state for rollback if API call fails
    ChatMessage? originalMessage;
    for (final sessionId in _messagesBySession.keys) {
      final messages = _messagesBySession[sessionId];
      if (messages != null) {
        final index = messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          originalMessage = messages[index];
          break;
        }
      }
    }

    // Optimistic update: Update local state immediately
    _updateMessageInAllSessions(messageId, (msg) => msg.copyWith(liked: liked));
    notifyListeners();

    try {
      // Make API call
      await _remote!.likeMessage(messageId, action);

      // Persist changes after successful API call
      for (final sessionId in _messagesBySession.keys) {
        final hasMessage =
            _messagesBySession[sessionId]?.any((m) => m.id == messageId) ??
            false;
        if (hasMessage) {
          unawaited(_persist(sessionId));
          break;
        }
      }
    } catch (e) {
      AppLogger.error('ChatProvider: Failed to like message: $e');

      // Rollback: Restore original state if API call failed
      if (originalMessage != null) {
        _updateMessageInAllSessions(messageId, (msg) => originalMessage!);
        notifyListeners();
      }

      _error = 'Failed to update like status';
      notifyListeners();
      rethrow;
    }
  }

  /// Submit feedback for a message
  Future<void> submitFeedback(
    String messageId, {
    String? feedback,
    int? stars,
  }) async {
    if (!useRemote || _remote == null) {
      AppLogger.debug(
        'ChatProvider: Remote service not available for feedback action',
      );
      return;
    }

    // Store the original state for rollback if API call fails
    ChatMessage? originalMessage;
    for (final sessionId in _messagesBySession.keys) {
      final messages = _messagesBySession[sessionId];
      if (messages != null) {
        final index = messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          originalMessage = messages[index];
          break;
        }
      }
    }

    // Optimistic update: Update local state immediately
    _updateMessageInAllSessions(
      messageId,
      (msg) => msg.copyWith(
        hasFeedback: true,
        feedback: feedback,
        feedbackStars: stars,
      ),
    );
    notifyListeners();

    try {
      // Make API call
      await _remote!.editFeedback(messageId, feedback: feedback, stars: stars);

      // Persist changes after successful API call
      for (final sessionId in _messagesBySession.keys) {
        final hasMessage =
            _messagesBySession[sessionId]?.any((m) => m.id == messageId) ??
            false;
        if (hasMessage) {
          unawaited(_persist(sessionId));
          break;
        }
      }
    } catch (e) {
      AppLogger.error('ChatProvider: Failed to submit feedback: $e');

      // Rollback: Restore original state if API call failed
      if (originalMessage != null) {
        _updateMessageInAllSessions(messageId, (msg) => originalMessage!);
        notifyListeners();
      }

      _error = 'Failed to submit feedback';
      notifyListeners();
      rethrow;
    }
  }

  /// Helper method to update a message across all sessions
  void _updateMessageInAllSessions(
    String messageId,
    ChatMessage Function(ChatMessage) updater,
  ) {
    for (final sessionId in _messagesBySession.keys) {
      final messages = _messagesBySession[sessionId];
      if (messages != null) {
        final index = messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          _messagesBySession[sessionId]![index] = updater(messages[index]);
        }
      }
    }
  }
}
