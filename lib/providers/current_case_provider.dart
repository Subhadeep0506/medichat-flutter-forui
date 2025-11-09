import 'package:flutter/foundation.dart';
import '../models/case.dart';

class CurrentCaseProvider with ChangeNotifier {
  MedicalCase? _currentCase;

  MedicalCase? get currentCase => _currentCase;

  void setCurrentCase(MedicalCase medicalCase) {
    _currentCase = medicalCase;
    notifyListeners();
  }

  void clearCurrentCase() {
    _currentCase = null;
    notifyListeners();
  }

  String? get currentCaseId => _currentCase?.id;
  String? get currentCaseTitle => _currentCase?.title;
}
