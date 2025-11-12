import 'package:flutter/foundation.dart';
import '../models/case.dart';
import '../services/api_service.dart';
import '../services/remote_api_service.dart';
import '../services/toast_service.dart';

class CaseProvider with ChangeNotifier {
  final CaseApiService _api; // mock
  RemoteCaseService? _remote;
  bool useRemote = false;
  CaseProvider(this._api);

  void enableRemote(RemoteCaseService remote) {
    useRemote = true;
    _remote = remote;
  }

  // patientId -> list of cases
  final Map<String, List<MedicalCase>> _casesByPatient = {};
  final Map<String, bool> _loadingByPatient = {}; // loading state per patient
  String? _error;

  List<MedicalCase> casesFor(String patientId) =>
      List.unmodifiable(_casesByPatient[patientId] ?? []);
  bool isLoading(String patientId) => _loadingByPatient[patientId] == true;
  String? get error => _error;

  MedicalCase? getCaseById(String caseId, String patientId) {
    final cases = _casesByPatient[patientId] ?? [];
    try {
      return cases.firstWhere((c) => c.id == caseId);
    } catch (e) {
      return null;
    }
  }

  Future<void> refresh(String patientId) async {
    _loadingByPatient[patientId] = true;
    notifyListeners();
    try {
      // remote list returns all cases; filter by patient if remote
      if (useRemote && _remote != null) {
        final List<MedicalCase> all = await _remote!.list();
        final List<MedicalCase> filtered = all
            .where((MedicalCase c) => c.patientId == patientId)
            .toList();
        _casesByPatient[patientId] = filtered;
      } else {
        final List<MedicalCase> list = await _api.listCases(patientId);
        _casesByPatient[patientId] = list;
      }
      _error = null;
    } catch (e) {
      // Re-throw token expiration exceptions so they can be handled by UI
      if (e is TokenExpiredException) {
        _loadingByPatient[patientId] = false;
        notifyListeners();
        rethrow;
      }
      _error = e.toString();
    } finally {
      _loadingByPatient[patientId] = false;
      notifyListeners();
    }
  }

  Future<MedicalCase?> create(
    String caseId,
    String patientId,
    String title,
    String description,
    List<String> tags,
    String priority,
  ) async {
    try {
      final MedicalCase mc = (useRemote && _remote != null)
          ? await _remote!.create(
              caseId: caseId,
              patientId: patientId,
              name: title,
              description: description,
              tags: tags,
              priority: priority,
            )
          : await _api.createCase(patientId, title, description);
      final List<MedicalCase> list = [
        ...(_casesByPatient[patientId] ?? <MedicalCase>[]),
        mc,
      ];
      _casesByPatient[patientId] = list; // now correctly typed
      notifyListeners();
      ToastService.showSuccess('Case "$title" created successfully!');
      return mc;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      ToastService.showError('Failed to create case: ${e.toString()}');
      return null;
    }
  }

  Future<bool> update(
    String id,
    String patientId, {
    String? title,
    String? description,
    List<String>? tags,
    String? priority,
  }) async {
    try {
      final MedicalCase updated = (useRemote && _remote != null)
          ? await _remote!.update(
              id,
              name: title,
              description: description,
              tags: tags,
              priority: priority,
            )
          : await _api.updateCase(
              id,
              title: title,
              description: description,
              tags: tags,
              priority: priority,
            );
      final List<MedicalCase> list =
          (_casesByPatient[patientId] ?? <MedicalCase>[])
              .map((MedicalCase c) => c.id == id ? updated : c)
              .toList();
      _casesByPatient[patientId] = list;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> remove(String id, String patientId) async {
    try {
      if (useRemote && _remote != null) {
        await _remote!.delete(id);
      } else {
        await _api.deleteCase(id);
      }
      final List<MedicalCase> list =
          (_casesByPatient[patientId] ?? <MedicalCase>[])
              .where((MedicalCase c) => c.id != id)
              .toList();
      _casesByPatient[patientId] = list;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
