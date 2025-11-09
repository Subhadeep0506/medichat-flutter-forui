import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/session.dart';
import '../services/api_service.dart';
import '../services/remote_api_service.dart';

class SessionProvider with ChangeNotifier {
  final SessionApiService _api; // mock
  RemoteSessionService? _remote;
  bool useRemote = false;
  SessionProvider(this._api);

  void enableRemote(RemoteSessionService remote) {
    useRemote = true;
    _remote = remote;
  }

  final Map<String, List<ChatSession>> _sessionsByCase =
      {}; // caseId -> sessions
  final Map<String, bool> _loadingByCase = {}; // caseId -> loading
  final Map<String, bool> _creatingByCase =
      {}; // caseId -> creating new session
  String? _error;
  // Maintain mapping of caseId -> patientId (needed for remote listing)
  final Map<String, String> _casePatientMap = {};

  List<ChatSession> sessionsFor(String caseId) =>
      List.unmodifiable(_sessionsByCase[caseId] ?? []);
  bool isLoading(String caseId) => _loadingByCase[caseId] == true;
  bool isCreating(String caseId) => _creatingByCase[caseId] == true;
  String? get error => _error;

  Future<void> refresh(String caseId, {String? patientId}) async {
    if (patientId != null) {
      _casePatientMap[caseId] = patientId;
    }
    _loadingByCase[caseId] = true;
    notifyListeners();
    try {
      // Attempt load from local cache first
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'sessions_$caseId';
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        try {
          final List data = jsonDecode(cached) as List;
          final list = data
              .map((e) => ChatSession.fromJson(e as Map<String, dynamic>))
              .toList();
          if (list.isNotEmpty) {
            _sessionsByCase[caseId] = list;
            // Soft notify to show something while remote fetch proceeds
            notifyListeners();
          }
        } catch (_) {}
      }
      if (useRemote && _remote != null) {
        final sessions = await _remote!.listForCase(
          caseId: caseId,
          patientId: patientId ?? _currentPatientIdForCase(caseId),
        );
        _sessionsByCase[caseId] = sessions;
      } else {
        final list = await _api.listSessions(caseId);
        _sessionsByCase[caseId] = list;
      }
      _persist(caseId); // fire & forget
      _error = null;
    } catch (e) {
      // Re-throw token expiration exceptions so they can be handled by UI
      if (e is TokenExpiredException) {
        _loadingByCase[caseId] = false;
        notifyListeners();
        rethrow;
      }
      _error = e.toString();
    } finally {
      _loadingByCase[caseId] = false;
      notifyListeners();
    }
  }

  Future<ChatSession?> create(
    String caseId, {
    String? title,
    required String patientId,
  }) async {
    _casePatientMap[caseId] = patientId; // ensure mapping
    _creatingByCase[caseId] = true;
    notifyListeners();
    try {
      final session = (useRemote && _remote != null)
          ? ChatSession(
              id: const Uuid().v4(), // ensure globally unique id
              caseId: caseId,
              title: title ?? 'New Session',
              createdAt: DateTime.now(),
            )
          : await _api.createSession(caseId, title: title);
      if (useRemote && _remote != null) {
        await _remote!.create(
          sessionId: session.id,
          caseId: caseId,
          patientId: patientId,
          title: session.title,
        );
      }
      _sessionsByCase[caseId] = [...(_sessionsByCase[caseId] ?? []), session];
      _persist(caseId);
      notifyListeners();
      return session;
    } catch (e) {
      // Re-throw token expiration exceptions so they can be handled by UI
      if (e is TokenExpiredException) {
        _creatingByCase[caseId] = false;
        notifyListeners();
        rethrow;
      }
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      _creatingByCase[caseId] = false;
      notifyListeners();
    }
  }

  Future<bool> remove(String sessionId, String caseId) async {
    try {
      if (useRemote && _remote != null) {
        await _remote!.delete(sessionId);
      } else {
        await _api.deleteSession(sessionId);
      }
      _sessionsByCase[caseId] = (_sessionsByCase[caseId] ?? [])
          .where((s) => s.id != sessionId)
          .toList();
      _persist(caseId);
      notifyListeners();
      return true;
    } catch (e) {
      // Re-throw token expiration exceptions so they can be handled by UI
      if (e is TokenExpiredException) {
        rethrow;
      }
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> rename(String sessionId, String caseId, String newTitle) async {
    try {
      if (useRemote && _remote != null) {
        await _remote!.rename(sessionId, newTitle);
      } else {
        // For mock backend just update in-place
        final list = _sessionsByCase[caseId] ?? [];
        final idx = list.indexWhere((s) => s.id == sessionId);
        if (idx != -1) {
          list[idx] = ChatSession(
            id: list[idx].id,
            caseId: list[idx].caseId,
            title: newTitle,
            createdAt: list[idx].createdAt,
          );
          _sessionsByCase[caseId] = List.of(list);
        }
      }
      // Update local cache for remote path as well
      final list = _sessionsByCase[caseId] ?? [];
      final idx = list.indexWhere((s) => s.id == sessionId);
      if (idx != -1) {
        list[idx] = ChatSession(
          id: list[idx].id,
          caseId: list[idx].caseId,
          title: newTitle,
          createdAt: list[idx].createdAt,
        );
        _sessionsByCase[caseId] = List.of(list);
      }
      _persist(caseId);
      notifyListeners();
      return true;
    } catch (e) {
      // Re-throw token expiration exceptions so they can be handled by UI
      if (e is TokenExpiredException) {
        rethrow;
      }
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Placeholder: establish patientId mapping for a case if needed (UI should call create with patientId)
  String _currentPatientIdForCase(String caseId) {
    // Without global case->patient mapping store, rely on scanning existing sessions (not ideal for remote). For now return empty.
    final sessions = _sessionsByCase[caseId];
    if (sessions != null && sessions.isNotEmpty) {
      // Not stored; would require augmenting ChatSession to include patientId; skipping to keep patch minimal.
    }
    return _casePatientMap[caseId] ?? '';
  }

  /// Ensure latest session for a case exists (create if empty) and return it.
  /// Always updates local cache and returns the session object.
  Future<ChatSession> openOrCreateLatest({
    required String caseId,
    required String patientId,
    String? defaultTitle,
  }) async {
    _casePatientMap[caseId] = patientId;
    List<ChatSession> sessions;
    if (useRemote && _remote != null) {
      // Always fetch fresh remote list to decide latest
      sessions = await _remote!.listForCase(
        caseId: caseId,
        patientId: patientId,
      );
    } else {
      sessions = await _api.listSessions(caseId);
    }
    if (sessions.isEmpty) {
      // Create new session
      final String newId = const Uuid().v4();
      final ChatSession newSession = (useRemote && _remote != null)
          ? ChatSession(
              id: newId,
              caseId: caseId,
              title: defaultTitle ?? 'New Session',
              createdAt: DateTime.now(),
            )
          : await _api.createSession(caseId, title: defaultTitle);
      if (useRemote && _remote != null) {
        await _remote!.create(
          sessionId: newSession.id,
          caseId: caseId,
          patientId: patientId,
          title: newSession.title,
        );
      }
      _sessionsByCase[caseId] = [newSession];
      _persist(caseId);
      notifyListeners();
      return newSession;
    } else {
      // Determine latest by createdAt
      sessions.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final latest = sessions.last;
      _sessionsByCase[caseId] = sessions; // cache sorted list
      _persist(caseId);
      notifyListeners();
      return latest;
    }
  }

  Future<void> _persist(String caseId) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'sessions_$caseId';
    final list = _sessionsByCase[caseId] ?? [];
    final jsonList = list.map((s) => s.toJson()).toList();
    await prefs.setString(cacheKey, jsonEncode(jsonList));
  }
}
