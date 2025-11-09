import 'package:MediChat/services/toast_service.dart';
import 'package:flutter/foundation.dart';
import '../models/patient.dart';
import '../services/api_service.dart';
import '../services/remote_api_service.dart';
import '../config/app_config.dart';

class PatientProvider with ChangeNotifier {
  final PatientApiService _api; // mock
  RemotePatientService? _remote;
  bool useRemote = false;
  PatientProvider(this._api);

  void enableRemote(RemotePatientService remote) {
    useRemote = true;
    _remote = remote;
  }

  List<Patient> _patients = [];
  bool _loading = false;
  String? _error;

  List<Patient> get patients => List.unmodifiable(_patients);
  bool get isLoading => _loading;
  String? get error => _error;

  Patient? getPatientById(String patientId) {
    try {
      return _patients.firstWhere((p) => p.id == patientId);
    } catch (e) {
      return null;
    }
  }

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    try {
      if (useRemote && _remote != null) {
        if (AppConfig.enableDebugLogging) {
          print('PatientProvider: Using remote API to fetch patients');
        }
        _patients = await _remote!.list();
      } else {
        if (AppConfig.enableDebugLogging) {
          print('PatientProvider: Using local mock API to fetch patients');
        }
        _patients = await _api.listPatients();
      }
      if (AppConfig.enableDebugLogging) {
        print(
          'PatientProvider: Successfully fetched ${_patients.length} patients',
        );
        // Only show toast after initial load to avoid scaffold messenger issues
        if (_patients.isNotEmpty) {
          ToastService.showInfo('Fetched ${_patients.length} patients');
        }
      }
      _error = null;
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('PatientProvider: Error fetching patients: $e');
      }
      // Only show error toast if this isn't during initial app startup
      if (_patients.isNotEmpty || _error != null) {
        ToastService.showError('Failed to fetch patients: ${e.toString()}');
      }
      // Re-throw token expiration exceptions so they can be handled by UI
      if (e is TokenExpiredException) {
        _loading = false;
        notifyListeners();
        rethrow;
      }
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Patient?> create(
    String patientId,
    String name,
    int age,
    String gender,
    String height,
    String weight,
    String dob,
    String medicalHistory,
  ) async {
    try {
      final p = (useRemote && _remote != null)
          ? await _remote!.create(
              patientId: patientId,
              name: name,
              age: age,
              gender: gender,
              dob: dob,
              height: height,
              weight: weight,
              medicalHistory: medicalHistory,
            )
          : await _api.createPatient(name, age, notes: medicalHistory);
      _patients = [..._patients, p];
      notifyListeners();
      ToastService.showSuccess('Created patient: ${p.name}');
      return p;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      ToastService.showError('Failed to create patient: ${e.toString()}');
      rethrow; // Let the caller handle the error display
    }
  }

  Future<bool> update(
    String id, {
    String? name,
    int? age,
    String? notes,
    String? gender,
    String? dob,
    String? height,
    String? weight,
    String? medicalHistory,
    List<String>? tags,
  }) async {
    try {
      final updated = (useRemote && _remote != null)
          ? await _remote!.update(
              id,
              name: name,
              age: age,
              gender: gender,
              dob: dob,
              height: height,
              weight: weight,
              medicalHistory: medicalHistory,
              tags: tags,
            )
          : await _api.updatePatient(
              id,
              name: name,
              age: age,
              medicalHistory: medicalHistory,
            );
      _patients = _patients.map((p) => p.id == id ? updated : p).toList();
      notifyListeners();
      ToastService.showSuccess('Updated patient: ${updated.name}');
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      ToastService.showError('Failed to update patient: ${e.toString()}');
      rethrow; // Let the caller handle the error display
    }
  }

  Future<bool> remove(String id) async {
    try {
      if (useRemote && _remote != null) {
        await _remote!.delete(id);
      } else {
        await _api.deletePatient(id);
      }
      _patients = _patients.where((p) => p.id != id).toList();
      notifyListeners();
      ToastService.showSuccess('Deleted patient');
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      ToastService.showError('Failed to delete patient: ${e.toString()}');
      return false;
    }
  }
}
