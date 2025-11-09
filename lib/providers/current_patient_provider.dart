import 'package:flutter/foundation.dart';
import '../models/patient.dart';

class CurrentPatientProvider with ChangeNotifier {
  Patient? _currentPatient;

  Patient? get currentPatient => _currentPatient;

  void setCurrentPatient(Patient patient) {
    _currentPatient = patient;
    notifyListeners();
  }

  void clearCurrentPatient() {
    _currentPatient = null;
    notifyListeners();
  }

  String? get currentPatientId => _currentPatient?.id;
}
