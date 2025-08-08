import 'package:flutter/material.dart';

class PatientFormProvider with ChangeNotifier {
  final Map<String, dynamic> _patientDetails = {};

  Map<String, dynamic> get patientDetails => _patientDetails;

  void updateField(String key, dynamic value) {
    _patientDetails[key] = value;
    notifyListeners();
  }

  dynamic getField(String key) => _patientDetails[key];

  void clearForm() {
    _patientDetails.clear();
    notifyListeners();
  }
}
