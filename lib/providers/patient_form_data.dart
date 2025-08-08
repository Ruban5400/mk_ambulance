// Inside your PatientFormProvider class
import 'package:flutter/material.dart';

class PatientFormProvider with ChangeNotifier {
  final Map<String, dynamic> _patientDetails = {};
  final Map<String, List<String>> _observations = {};

  // You need a way to access observations
  Map<String, dynamic> get patientDetails => _patientDetails;
  Map<String, List<String>> get observations => _observations;

  // Existing methods...
  void updateField(String key, dynamic value) {
    _patientDetails[key] = value;
    notifyListeners();
  }

  // --- New method to update observation fields ---
  void updateObservationField({
    required String fieldName,
    required int index,
    required String value,
  }) {
    // Initialize the list for the field name if it doesn't exist
    if (!_observations.containsKey(fieldName)) {
      _observations[fieldName] = List<String>.filled(5, ''); // Adjust size as needed
    }

    // Ensure the list is large enough for the new index
    if (index >= _observations[fieldName]!.length) {
      // If adding a new column, expand the list
      _observations[fieldName]!.length = index + 1;
    }

    // Update the value at the specific index
    _observations[fieldName]![index] = value;

    // Optional: Store the observation map inside the patient details
    _patientDetails['observations'] = _observations;

    notifyListeners();
  }
}

// old code without observations
// import 'package:flutter/material.dart';
//
// class PatientFormProvider with ChangeNotifier {
//   final Map<String, dynamic> _patientDetails = {};
//
//   Map<String, dynamic> get patientDetails => _patientDetails;
//
//   void updateField(String key, dynamic value) {
//     _patientDetails[key] = value;
//     notifyListeners();
//   }
//
//   dynamic getField(String key) => _patientDetails[key];
//
//   void clearForm() {
//     _patientDetails.clear();
//     notifyListeners();
//   }
// }
