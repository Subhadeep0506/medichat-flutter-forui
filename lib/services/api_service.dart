import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../models/patient.dart';
import '../models/case.dart';
import '../models/session.dart';
import '../models/message.dart';

// A simple in-memory mock API layer. Replace with real HTTP calls later.
class InMemoryBackend {
  static final InMemoryBackend _singleton = InMemoryBackend._internal();
  factory InMemoryBackend() => _singleton;
  InMemoryBackend._internal() {
    _initializeSampleData();
  }

  AppUser? currentUser;
  final Map<String, Patient> patients = {}; // patientId -> Patient
  final Map<String, MedicalCase> cases = {}; // caseId -> Case
  final Map<String, ChatSession> sessions = {}; // sessionId -> Session
  final Map<String, List<ChatMessage>> messages = {}; // sessionId -> msgs

  void _initializeSampleData() {
    // Add sample patients for testing
    final now = DateTime.now();
    final patient1 = Patient(
      id: const Uuid().v4(),
      name: 'John Doe',
      age: 35,
      gender: 'Male',
      medicalHistory: 'Hypertension, diabetes type 2',
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now.subtract(const Duration(days: 5)),
    );

    final patient2 = Patient(
      id: const Uuid().v4(),
      name: 'Jane Smith',
      age: 28,
      gender: 'Female',
      medicalHistory: 'Anxiety, asthma',
      createdAt: now.subtract(const Duration(days: 15)),
      updatedAt: now.subtract(const Duration(days: 2)),
    );

    final patient3 = Patient(
      id: const Uuid().v4(),
      name: 'Robert Johnson',
      age: 42,
      gender: 'Male',
      medicalHistory: 'Depression, chronic back pain',
      createdAt: now.subtract(const Duration(days: 7)),
      updatedAt: now.subtract(const Duration(days: 1)),
    );

    patients[patient1.id] = patient1;
    patients[patient2.id] = patient2;
    patients[patient3.id] = patient3;
  }
}

class AuthApiService {
  final _backend = InMemoryBackend();

  Future<AppUser> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _backend.currentUser = AppUser(
      id: const Uuid().v4(),
      name: email.split('@').first,
      email: email,
      accessToken: 'mock-token',
      refreshToken: "mock-refresh-token",
      createdAt: DateTime.now(),
    );
    return _backend.currentUser!;
  }

  Future<AppUser> register(String name, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _backend.currentUser = AppUser(
      id: const Uuid().v4(),
      name: name,
      email: email,
      accessToken: 'mock-token',
      refreshToken: "mock-refresh-token",
      createdAt: DateTime.now(),
    );
    return _backend.currentUser!;
  }

  Future<void> registerOnly(String name, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // Registration successful but don't set current user
    // User will need to login manually after registration
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _backend.currentUser = null;
  }
}

class PatientApiService {
  final _backend = InMemoryBackend();

  Future<List<Patient>> listPatients() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _backend.patients.values.toList()..sort(
      (a, b) => a.createdAt?.compareTo(b.createdAt ?? DateTime.now()) ?? 0,
    );
  }

  Future<Patient> createPatient(String name, int age, {String? notes}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    final patient = Patient(
      id: const Uuid().v4(),
      name: name,
      age: age,
      medicalHistory: notes,
      createdAt: now,
      updatedAt: now,
    );
    _backend.patients[patient.id] = patient;
    return patient;
  }

  Future<Patient> updatePatient(
    String id, {
    String? name,
    int? age,
    String? medicalHistory,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final existing = _backend.patients[id];
    if (existing == null) throw Exception('Patient not found');
    final updated = existing.copyWith(
      name: name,
      age: age,
      medicalHistory: medicalHistory,
      updatedAt: DateTime.now(),
    );
    _backend.patients[id] = updated;
    return updated;
  }

  Future<void> deletePatient(String id) async {
    await Future.delayed(const Duration(milliseconds: 250));
    // Also cascade delete cases/sessions/messages
    _backend.patients.remove(id);
    final caseIds = _backend.cases.values
        .where((c) => c.patientId == id)
        .map((c) => c.id)
        .toList();
    for (final caseId in caseIds) {
      _backend.cases.remove(caseId);
      final sessionIds = _backend.sessions.values
          .where((s) => s.caseId == caseId)
          .map((s) => s.id)
          .toList();
      for (final sid in sessionIds) {
        _backend.sessions.remove(sid);
        _backend.messages.remove(sid);
      }
    }
  }
}

class CaseApiService {
  final _backend = InMemoryBackend();

  Future<List<MedicalCase>> listCases(String patientId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _backend.cases.values.where((c) => c.patientId == patientId).toList()
      ..sort(
        (a, b) => a.createdAt?.compareTo(b.createdAt ?? DateTime.now()) ?? 0,
      );
  }

  Future<MedicalCase> createCase(
    String patientId,
    String title,
    String description,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    final mc = MedicalCase(
      id: const Uuid().v4(),
      patientId: patientId,
      title: title,
      description: description,
      createdAt: now,
      updatedAt: now,
    );
    _backend.cases[mc.id] = mc;
    return mc;
  }

  Future<MedicalCase> updateCase(
    String id, {
    String? title,
    String? description,
    List<String>? tags,
    String? priority,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final existing = _backend.cases[id];
    if (existing == null) throw Exception('Case not found');
    final updated = existing.copyWith(
      title: title,
      description: description,
      tags: tags,
      priority: priority,
      updatedAt: DateTime.now(),
    );
    _backend.cases[id] = updated;
    return updated;
  }

  Future<void> deleteCase(String id) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _backend.cases.remove(id);
    final sessionIds = _backend.sessions.values
        .where((s) => s.caseId == id)
        .map((s) => s.id)
        .toList();
    for (final sid in sessionIds) {
      _backend.sessions.remove(sid);
      _backend.messages.remove(sid);
    }
  }
}

class SessionApiService {
  final _backend = InMemoryBackend();

  Future<List<ChatSession>> listSessions(String caseId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _backend.sessions.values.where((s) => s.caseId == caseId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<ChatSession> createSession(String caseId, {String? title}) async {
    await Future.delayed(const Duration(milliseconds: 280));
    final session = ChatSession(
      id: const Uuid().v4(),
      caseId: caseId,
      title: title ?? 'Session ${DateTime.now().toIso8601String()}',
      createdAt: DateTime.now(),
    );
    _backend.sessions[session.id] = session;
    return session;
  }

  Future<void> deleteSession(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _backend.sessions.remove(id);
    _backend.messages.remove(id);
  }
}

class ChatApiService {
  final _backend = InMemoryBackend();

  Future<List<ChatMessage>> listMessages(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_backend.messages[sessionId] ?? []);
  }

  Future<ChatMessage> addUserMessage(String sessionId, String content) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final msg = ChatMessage(
      id: const Uuid().v4(),
      sessionId: sessionId,
      role: ChatRole.user,
      content: content,
      timestamp: DateTime.now(),
    );
    final list = _backend.messages.putIfAbsent(sessionId, () => []);
    list.add(msg);
    return msg;
  }

  Future<ChatMessage> addAIMessage(String sessionId, String content) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final msg = ChatMessage(
      id: const Uuid().v4(),
      sessionId: sessionId,
      role: ChatRole.ai,
      content: content,
      timestamp: DateTime.now(),
    );
    final list = _backend.messages.putIfAbsent(sessionId, () => []);
    list.add(msg);
    return msg;
  }
}
