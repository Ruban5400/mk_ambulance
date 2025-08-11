import 'dart:typed_data';
import 'package:flutter/material.dart';

class PatientFormProvider with ChangeNotifier {
  final Map<String, dynamic> _patientDetails = {};
  final Map<String, List<String>> _observations = {};

  // Getters for the patient details and observations maps
  Map<String, dynamic> get patientDetails => _patientDetails;
  Map<String, List<String>> get observations => _observations;

  // New getters to specifically access the signature image data
  Uint8List? get frontSignatureImage => _patientDetails['front_side'] as Uint8List?;
  Uint8List? get backSignatureImage => _patientDetails['back_side'] as Uint8List?;

  // Method to update any field in the patient details map
  void updateField(String key, dynamic value) {
    _patientDetails[key] = value;
    notifyListeners();
  }

  // Method to update observation fields
  void updateObservationField({
    required String fieldName,
    required int index,
    required String value,
  })
  {
    // Initialize the list for the field name if it doesn't exist.
    // The list is now created as a growable, empty list.
    if (!_observations.containsKey(fieldName)) {
      _observations[fieldName] = [];
    }

    // A reference to the growable list for easier modification
    final observationList = _observations[fieldName]!;

    // Ensure the list is large enough for the new index
    // We add empty strings until the list is the correct size.
    while (observationList.length <= index) {
      observationList.add('');
    }

    // Update the value at the specific index
    observationList[index] = value;
    notifyListeners();
  }
}


// old code
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
//
// class PatientFormProvider with ChangeNotifier {
//   final Map<String, dynamic> _patientDetails = {};
//   final Map<String, List<String>> _observations = {};
//
//   // Getters for the patient details and observations maps
//   Map<String, dynamic> get patientDetails => _patientDetails;
//   Map<String, List<String>> get observations => _observations;
//
//   // New getters to specifically access the signature image data
//   Uint8List? get frontSignatureImage => _patientDetails['front_side'] as Uint8List?;
//   Uint8List? get backSignatureImage => _patientDetails['back_side'] as Uint8List?;
//
//   // Method to update any field in the patient details map
//   void updateField(String key, dynamic value) {
//     _patientDetails[key] = value;
//     notifyListeners();
//   }
//
//   // Method to update observation fields
//   void updateObservationField({
//     required String fieldName,
//     required int index,
//     required String value,
//   })
//   {
//     // Initialize the list for the field name if it doesn't exist
//     if (!_observations.containsKey(fieldName)) {
//       // Adjust size as needed, creating a list of empty strings
//       _observations[fieldName] = List<String>.filled(index + 1, '');
//     }
//
//     // Ensure the list is large enough for the new index
//     if (index >= _observations[fieldName]!.length) {
//       // If adding a new column, expand the list
//       _observations[fieldName]!.length = index + 1;
//     }
//
//     // Update the value at the specific index
//     _observations[fieldName]![index] = value;
//     notifyListeners();
//   }
// }

// old code without image
// import 'package:flutter/material.dart';
//
// class PatientFormProvider with ChangeNotifier {
//   final Map<String, dynamic> _patientDetails = {};
//   final Map<String, List<String>> _observations = {};
//
//   // You need a way to access observations
//   Map<String, dynamic> get patientDetails => _patientDetails;
//   Map<String, List<String>> get observations => _observations;
//
//   // Existing methods...
//   void updateField(String key, dynamic value) {
//     _patientDetails[key] = value;
//     notifyListeners();
//   }
//
//   // --- New method to update observation fields ---
//   void updateObservationField({
//     required String fieldName,
//     required int index,
//     required String value,
//   }) {
//     // Initialize the list for the field name if it doesn't exist
//     if (!_observations.containsKey(fieldName)) {
//       _observations[fieldName] = List<String>.filled(5, ''); // Adjust size as needed
//     }
//
//     // Ensure the list is large enough for the new index
//     if (index >= _observations[fieldName]!.length) {
//       // If adding a new column, expand the list
//       _observations[fieldName]!.length = index + 1;
//     }
//
//     // Update the value at the specific index
//     _observations[fieldName]![index] = value;
//
//     // Optional: Store the observation map inside the patient details
//     _patientDetails['observations'] = _observations;
//
//     notifyListeners();
//   }
// }
