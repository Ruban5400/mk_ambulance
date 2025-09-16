import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/patient_form_data.dart';

class TreatmentPage extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const TreatmentPage({super.key, required this.formKey});

  @override
  State<TreatmentPage> createState() => _TreatmentPageState();
}

class _TreatmentPageState extends State<TreatmentPage> {
  // Maps to hold the state of the checkboxes
  late Map<String, bool> treatmentOptions;
  late Map<String, bool> handlingOptions;

  String? conditionStatus;
  final TextEditingController generalConditionController = TextEditingController();
  final TextEditingController bpController = TextEditingController();
  final TextEditingController rrController = TextEditingController();
  final TextEditingController spo2Controller = TextEditingController();
  final TextEditingController temperatureController = TextEditingController();
  final TextEditingController glucoseController = TextEditingController();
  final TextEditingController painScoreController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController otherTreatmentController = TextEditingController();
  final TextEditingController otherHandlingController = TextEditingController();
  final TextEditingController otherConditionController = TextEditingController();

  bool deathChecked = false;
  bool othersChecked = false;

  @override
  void initState() {
    super.initState();
    // Initialize with default values
    treatmentOptions = {
      'NO TREATMENT / ADVICE ONLY GIVEN': false,
      'REST-ICE-COMPRESS-ELEVATE': false,
      'SPLIT': false,
      'AIRWAY SUCTION': false,
      'NEUROLOGICAL TEST': false,
      'OTHERS': false,
      'WOUND CLEANSED': false,
      'FRACTURE SUPPORT': false,
      'C-SPINE CONTROL (IMMOBILISATION)': false,
      'AIRWAY INSERTED (TYPE/SIZE)': false,
      'HEAD INJURY ADVICE GIVEN': false,
    };
    handlingOptions = {
      'WALKED UNAIDED': false,
      'CHAIR': false,
      'LONGBOARD': false,
      'OTHERS': false,
      'SCOOP': false,
      'WALKED AIDED': false,
      'STRETCHER': false,
    };

    // Corrected: Initialize conditionStatus with a default value.
    conditionStatus = 'Unchanged';

    // Load existing data from the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataFromProvider();
    });
  }

  @override
  void dispose() {
    generalConditionController.dispose();
    bpController.dispose();
    rrController.dispose();
    spo2Controller.dispose();
    temperatureController.dispose();
    glucoseController.dispose();
    painScoreController.dispose();
    remarksController.dispose();
    otherTreatmentController.dispose();
    otherHandlingController.dispose();
    otherConditionController.dispose();
    super.dispose();
  }

  // Method to load existing data from the provider and update the UI state
  void _loadDataFromProvider() {
    final provider = Provider.of<PatientFormProvider>(context, listen: false);
    final patientDetails = provider.patientDetails;

    // Load checkbox data
    final savedTreatment = patientDetails['TREATMENT/ACTION'] as List<dynamic>?;
    if (savedTreatment != null) {
      setState(() {
        for (var key in treatmentOptions.keys.toList()) {
          treatmentOptions[key] = savedTreatment.contains(key);
        }
        if (savedTreatment.contains('OTHERS')) {
          otherTreatmentController.text = savedTreatment.lastWhere(
                  (element) => !treatmentOptions.containsKey(element),
              orElse: () => '');
          treatmentOptions['OTHERS'] = true;
        }
      });
    }

    final savedHandling = patientDetails['HANDLING & IMMOBILISATION ON DEPARTURE'] as List<dynamic>?;
    if (savedHandling != null) {
      setState(() {
        for (var key in handlingOptions.keys.toList()) {
          handlingOptions[key] = savedHandling.contains(key);
        }
        if (savedHandling.contains('OTHERS')) {
          otherHandlingController.text = savedHandling.lastWhere(
                  (element) => !handlingOptions.containsKey(element),
              orElse: () => '');
          handlingOptions['OTHERS'] = true;
        }
      });
    }

    // Load form field data
    generalConditionController.text = patientDetails['General Condition'] ?? '';
    bpController.text = patientDetails['BP (mmHg)'] ?? '';
    rrController.text = patientDetails['RR (min)'] ?? '';
    spo2Controller.text = patientDetails['SPO2 (%)'] ?? '';
    temperatureController.text = patientDetails['Temperature (°C)'] ?? '';
    glucoseController.text = patientDetails['Glucose (mmol/L)'] ?? '';
    painScoreController.text = patientDetails['Pain Score (/10)'] ?? '';
    remarksController.text = patientDetails['Other Patient Progress/ Remarks'] ?? '';

    // Corrected: Check if the saved value exists and update the state.
    // Use the null-aware operator for safety.
    final savedConditionStatus = patientDetails['Condition Status'];
    if (savedConditionStatus != null && savedConditionStatus is String) {
      setState(() {
        conditionStatus = savedConditionStatus;
        deathChecked = conditionStatus == 'Death';
        othersChecked = conditionStatus == 'Others';
      });
    }

    if(othersChecked) {
      otherConditionController.text = patientDetails['Specify others'] ?? '';
    }
  }

  // Helper method to update the provider with a list of selected options
  void _updateCheckboxProvider(String title, Map<String, bool> options, TextEditingController othersController) {
    final selectedOptions = options.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    // Add custom text if "Others" is checked and has a value
    if (options['OTHERS'] == true && othersController.text.trim().isNotEmpty) {
      selectedOptions.add(othersController.text.trim());
    }
    Provider.of<PatientFormProvider>(context, listen: false).updateField(title, selectedOptions);
  }

  Widget _buildCheckboxList(String title, Map<String, bool> options, TextEditingController othersController) {
    final entries = options.entries.toList();
    final half = (entries.length / 2).ceil();
    final leftColumn = entries.sublist(0, half);
    final rightColumn = entries.sublist(half);

    Widget buildColumn(List<MapEntry<String, bool>> items) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((entry) {
          final isOthers = entry.key == "OTHERS";

          return InkWell( // Wrap the entire clickable area in InkWell
            onTap: () {
              setState(() {
                // Toggle the checkbox value
                options[entry.key] = !entry.value;
              });
              _updateCheckboxProvider(title, options, othersController);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: entry.value,
                      // The onTap from InkWell handles the state change,
                      // so we can set onChanged to null or keep it for the checkbox itself.
                      // If you keep it, ensure it mirrors the InkWell logic.
                      onChanged: (value) {
                        setState(() {
                          options[entry.key] = value!;
                        });
                        _updateCheckboxProvider(title, options, othersController);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      activeColor: Colors.red.shade800,
                    ),
                    Flexible(
                      child: Text(
                        entry.key,
                        style: GoogleFonts.roboto(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                if (isOthers && entry.value)
                  Padding(
                    padding: const EdgeInsets.only(left: 35.0, bottom: 8),
                    child: TextField(
                      controller: othersController,
                      decoration: const InputDecoration(
                        hintText: "Please specify",
                        filled: true,
                        fillColor: Color(0xfff5f5f5),
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                      ),
                      onChanged: (value) {
                        _updateCheckboxProvider(title, options, othersController);
                      },
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: Colors.grey, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: buildColumn(leftColumn)),
              const SizedBox(width: 32),
              Expanded(child: buildColumn(rightColumn)),
            ],
          ),
        ],
      ),
    );
  }

  // validation on clicking next button
  // Widget _buildTextField({
  //   required String label,
  //   required TextEditingController controller,
  //   int maxLines = 1,
  //   TextInputType? keyboardType,
  //   String? Function(String?)? validator,
  //   List<TextInputFormatter>? inputFormatters,
  // })
  // {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(label, style: GoogleFonts.roboto(fontWeight: FontWeight.w500)),
  //       const SizedBox(height: 6),
  //       TextFormField(
  //         controller: controller,
  //         onChanged: (value) {
  //           Provider.of<PatientFormProvider>(
  //             context,
  //             listen: false,
  //           ).updateField(label, value.trim());
  //         },
  //         maxLines: maxLines,
  //         keyboardType: keyboardType,
  //         validator: validator,
  //         inputFormatters: inputFormatters,
  //         decoration: const InputDecoration(
  //           filled: true,
  //           fillColor: Color(0xfff5f5f5),
  //           border: OutlineInputBorder(borderSide: BorderSide.none),
  //         ),
  //       ),
  //       const SizedBox(height: 12),
  //     ],
  //   );
  // }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.roboto(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          onChanged: (value) {
            // Update the provider
            Provider.of<PatientFormProvider>(
              context,
              listen: false,
            ).updateField(label, value.trim());

            // Trigger real-time validation
            if (widget.formKey.currentState?.validate() ?? false) {
            }
          },
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          inputFormatters: inputFormatters,
          decoration: const InputDecoration(
            filled: true,
            fillColor: Color(0xfff5f5f5),
            border: OutlineInputBorder(borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildAcknowledgementForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: Colors.grey, width: 1.0),
      ),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "ACKNOWLEDGEMENT ON PATIENT ARRIVAL AT TRANSFERRED FACILITY",
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: "General Condition",
              controller: generalConditionController,
              maxLines: 3,
              keyboardType: TextInputType.text,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildTextField(
                        label: "BP (mmHg)",
                        controller: bpController,
                        keyboardType: TextInputType.text,
                        inputFormatters: [
                          // Allows only digits and a single slash
                          FilteringTextInputFormatter.allow(RegExp(r'^[0-9/]+$')),
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            // Enforce only one slash
                            if (newValue.text.contains('/') && newValue.text.indexOf('/') != newValue.text.lastIndexOf('/')) {
                              return oldValue;
                            }
                            return newValue;
                          }),
                        ],
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            // 1. Check for the correct format (e.g., '120/80')
                            if (!RegExp(r'^\d+\/\d+$').hasMatch(value)) {
                              return 'Invalid format. Use numbers and a single slash.';
                            }

                            final parts = value.split('/');
                            final topNumber = int.tryParse(parts[0]);
                            final bottomNumber = int.tryParse(parts[1]);

                            // 2. Ensure both parts are valid numbers
                            if (topNumber == null || bottomNumber == null) {
                              return 'Invalid number format.';
                            }

                            // 3. Check the logical relationship (top > bottom)
                            if (topNumber <= bottomNumber) {
                              return 'Systolic number must be greater than diastolic number.';
                            }

                            // 4. Validate the specified ranges
                            if (topNumber < 90 || topNumber > 180) {
                              return 'Systolic number must be between 90 and 180.';
                            }
                            if (bottomNumber < 60 || bottomNumber > 120) {
                              return 'Diastolic number must be between 60 and 120.';
                            }
                          }

                          return null; // The input is either empty or valid
                        },
                      ),
                      _buildTextField(
                        label: "RR (min)",
                        controller: rrController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        // validator: (value) {
                        //   // If the field is empty, it's considered valid.
                        //   if (value == null || value.isEmpty) {
                        //     return null;
                        //   }
                        //   final number = int.tryParse(value);
                        //
                        //   // If parsing fails, it's not a valid number.
                        //   if (number == null) {
                        //     return 'Please enter a valid number.';
                        //   }
                        //
                        //   // Check if the number is within the required range.
                        //   if (number < 12 || number > 20) {
                        //     return 'Value must be between 12 and 20.';
                        //   }
                        //
                        //   return null;
                        // },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Condition Status",
                        style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
                      ),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: [
                          'Improved',
                          'Deteriorated',
                          'Unchanged',
                          'Death',
                          'Others',
                        ].map((status) {
                          return InkWell(
                            onTap: () {
                              setState(() {
                                conditionStatus = status;
                                deathChecked = (status == 'Death');
                                othersChecked = (status == 'Others');
                              });
                              Provider.of<PatientFormProvider>(
                                context,
                                listen: false,
                              ).updateField("Condition Status", status);
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Radio<String>(
                                  value: status,
                                  groupValue: conditionStatus,
                                  onChanged: (val) {
                                    setState(() {
                                      conditionStatus = val;
                                      deathChecked = (val == 'Death');
                                      othersChecked = (val == 'Others');
                                    });
                                    Provider.of<PatientFormProvider>(
                                      context,
                                      listen: false,
                                    ).updateField("Condition Status", val);
                                  },
                                  activeColor: Colors.red.shade800,
                                ),
                                Text(status),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      if (deathChecked) ...[
                        GestureDetector(
                          onTap: () async {
                            final TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );

                            if (pickedTime != null) {
                              Provider.of<PatientFormProvider>(
                                context,
                                listen: false,
                              ).updateField(
                                "DeathTime",
                                pickedTime.format(context),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.access_time, color: Colors.grey[700]),
                                const SizedBox(width: 8),
                                Consumer<PatientFormProvider>(
                                  builder: (context, provider, child) {
                                    final deathTime =
                                    provider.patientDetails["DeathTime"];
                                    return Text(
                                      deathTime ?? "--:--",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: deathTime != null
                                            ? Colors.black
                                            : Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (othersChecked) ...[
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                width: 200,
                                child: _buildTextField(
                                  label: "Specify others",
                                  controller: otherConditionController,
                                  keyboardType: TextInputType.text,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(child: _buildTextField(
                  label: "Temperature (°C)",
                  controller: temperatureController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                  ],
                  // validator: (value) {
                  //   // If the field is empty, it's considered valid.
                  //   if (value == null || value.isEmpty) {
                  //     return null;
                  //   }
                  //
                  //   // Attempt to parse the string to a double.
                  //   final number = double.tryParse(value);
                  //
                  //   // If parsing fails, it's not a valid number.
                  //   if (number == null) {
                  //     return 'Please enter a valid temperature.';
                  //   }
                  //
                  //   // Check if the number is within the required range (35.0 to 38.0).
                  //   if (number < 35.0 || number > 38.0) {
                  //     return 'Temperature must be between 35.0 and 38.0.';
                  //   }
                  //   // If all checks pass, the input is valid.
                  //   return null;
                  // },
                )),
                const SizedBox(width: 20),
                Expanded(child: _buildTextField(
                  label: "SPO2 (%)",
                  controller: spo2Controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    // If the field is empty, it's considered valid.
                    if (value == null || value.isEmpty) {
                      return null;
                    }
                    final number = int.tryParse(value);

                    // If parsing fails, it's not a valid number.
                    if (number == null) {
                      return 'Please enter a valid number.';
                    }

                    // Check if the number is within the required range.
                    if (number < 90) {
                      return 'Value must be greater than 90.';
                    }

                    return null;
                  },
                )),
              ],
            ),
            Row(
              children: [
                Expanded(child: _buildTextField(
                  label: "Glucose (mmol/L)",
                  controller: glucoseController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                  ],
                  validator: (value) {
                    // If the field is empty, it's considered valid.
                    if (value == null || value.isEmpty) {
                      return null;
                    }
                    final number = int.tryParse(value);

                    // If parsing fails, it's not a valid number.
                    if (number == null) {
                      return 'Please enter a valid number.';
                    }

                    // Check if the number is within the required range.
                    if (number < 70 || number > 126) {
                      return 'Value must be between 70 and 126.';
                    }

                    return null;
                  },
                )),
                const SizedBox(width: 20),
                Expanded(child: _buildTextField(
                  label: "Pain Score (/10)",
                  controller: painScoreController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    // If the field is empty, it's considered valid.
                    if (value == null || value.isEmpty) {
                      return null;
                    }
                    final number = int.tryParse(value);

                    // If parsing fails, it's not a valid number.
                    if (number == null) {
                      return 'Please enter a valid number.';
                    }

                    // Check if the number is within the required range.
                    if (number < 0 || number > 10) {
                      return 'Value must be between 0 and 10.';
                    }

                    return null;
                  },
                )),
              ],
            ),
            _buildTextField(
              label: "Other Patient Progress/ Remarks",
              controller: remarksController,
              maxLines: 3,
              keyboardType: TextInputType.text,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1000),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildCheckboxList("TREATMENT/ACTION", treatmentOptions, otherTreatmentController),
          const SizedBox(height: 20),
          _buildCheckboxList("HANDLING & IMMOBILISATION ON DEPARTURE", handlingOptions, otherHandlingController),
          const SizedBox(height: 20),
          _buildAcknowledgementForm(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}



// need validation
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
//
// import '../providers/patient_form_data.dart';
//
// class TreatmentPage extends StatefulWidget {
//   const TreatmentPage({super.key});
//
//   @override
//   State<TreatmentPage> createState() => _TreatmentPageState();
// }
//
// class _TreatmentPageState extends State<TreatmentPage> {
//   // Maps to hold the state of the checkboxes
//   late Map<String, bool> treatmentOptions;
//   late Map<String, bool> handlingOptions;
//
//   String? conditionStatus;
//   final TextEditingController generalConditionController = TextEditingController();
//   final TextEditingController bpController = TextEditingController();
//   final TextEditingController rrController = TextEditingController();
//   final TextEditingController spo2Controller = TextEditingController();
//   final TextEditingController temperatureController = TextEditingController();
//   final TextEditingController glucoseController = TextEditingController();
//   final TextEditingController painScoreController = TextEditingController();
//   final TextEditingController remarksController = TextEditingController();
//   final TextEditingController otherTreatmentController = TextEditingController();
//   final TextEditingController otherHandlingController = TextEditingController();
//   final TextEditingController otherConditionController = TextEditingController();
//
//   bool deathChecked = false;
//   bool othersChecked = false;
//
//   @override
//   void initState() {
//     super.initState();
//     // Initialize with default values
//     treatmentOptions = {
//       'NO TREATMENT / ADVICE ONLY GIVEN': false,
//       'REST-ICE-COMPRESS-ELEVATE': false,
//       'SPLIT': false,
//       'AIRWAY SUCTION': false,
//       'NEUROLOGICAL TEST': false,
//       'OTHERS': false,
//       'WOUND CLEANSED': false,
//       'FRACTURE SUPPORT': false,
//       'C-SPINE CONTROL (IMMOBILISATION)': false,
//       'AIRWAY INSERTED (TYPE/SIZE)': false,
//       'HEAD INJURY ADVICE GIVEN': false,
//     };
//     handlingOptions = {
//       'WALKED UNAIDED': false,
//       'CHAIR': false,
//       'LONGBOARD': false,
//       'OTHERS': false,
//       'SCOOP': false,
//       'WALKED AIDED': false,
//       'STRETCHER': false,
//     };
//     conditionStatus = 'Unchanged';
//
//     // Load existing data from the provider
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _loadDataFromProvider();
//     });
//   }
//
//   // Method to load existing data from the provider and update the UI state
//   void _loadDataFromProvider() {
//     final provider = Provider.of<PatientFormProvider>(context, listen: false);
//     final patientDetails = provider.patientDetails;
//
//     // Load checkbox data
//     final savedTreatment = patientDetails['TREATMENT/ACTION'] as List<dynamic>?;
//     if (savedTreatment != null) {
//       setState(() {
//         for (var key in treatmentOptions.keys.toList()) {
//           treatmentOptions[key] = savedTreatment.contains(key);
//         }
//         if (savedTreatment.contains('OTHERS')) {
//           otherTreatmentController.text = savedTreatment.lastWhere(
//                   (element) => !treatmentOptions.containsKey(element),
//               orElse: () => '');
//           treatmentOptions['OTHERS'] = true;
//         }
//       });
//     }
//
//     final savedHandling = patientDetails['HANDLING & IMMOBILISATION ON DEPARTURE'] as List<dynamic>?;
//     if (savedHandling != null) {
//       setState(() {
//         for (var key in handlingOptions.keys.toList()) {
//           handlingOptions[key] = savedHandling.contains(key);
//         }
//         if (savedHandling.contains('OTHERS')) {
//           otherHandlingController.text = savedHandling.lastWhere(
//                   (element) => !handlingOptions.containsKey(element),
//               orElse: () => '');
//           handlingOptions['OTHERS'] = true;
//         }
//       });
//     }
//
//     // Load form field data
//     generalConditionController.text = patientDetails['General Condition'] ?? '';
//     bpController.text = patientDetails['BP (mmHg)'] ?? '';
//     rrController.text = patientDetails['RR (min)'] ?? '';
//     spo2Controller.text = patientDetails['SPO2 (%)'] ?? '';
//     temperatureController.text = patientDetails['Temperature (°C)'] ?? '';
//     glucoseController.text = patientDetails['Glucose (mmol/L)'] ?? '';
//     painScoreController.text = patientDetails['Pain Score (/10)'] ?? '';
//     remarksController.text = patientDetails['Other Patient Progress/ Remarks'] ?? '';
//     conditionStatus = patientDetails['Condition Status'] ?? 'Unchanged';
//     deathChecked = conditionStatus == 'Death';
//     othersChecked = conditionStatus == 'Others';
//     if(othersChecked) {
//       otherConditionController.text = patientDetails['Specify others'] ?? '';
//     }
//   }
//
//   // Helper method to update the provider with a list of selected options
//   void _updateCheckboxProvider(String title, Map<String, bool> options, TextEditingController othersController) {
//     final selectedOptions = options.entries
//         .where((e) => e.value)
//         .map((e) => e.key)
//         .toList();
//
//     // Add custom text if "Others" is checked and has a value
//     if (options['OTHERS'] == true && othersController.text.trim().isNotEmpty) {
//       selectedOptions.add(othersController.text.trim());
//     }
//     Provider.of<PatientFormProvider>(context, listen: false).updateField(title, selectedOptions);
//   }
//
//   Widget _buildCheckboxList(String title, Map<String, bool> options, TextEditingController othersController) {
//     final entries = options.entries.toList();
//     final half = (entries.length / 2).ceil();
//     final leftColumn = entries.sublist(0, half);
//     final rightColumn = entries.sublist(half);
//
//     Widget buildColumn(List<MapEntry<String, bool>> items) {
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: items.map((entry) {
//           final isOthers = entry.key == "OTHERS";
//
//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Checkbox(
//                     value: entry.value,
//                     onChanged: (value) {
//                       setState(() {
//                         options[entry.key] = value!;
//                       });
//                       _updateCheckboxProvider(title, options, othersController);
//                     },
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     activeColor: Colors.red.shade800,
//                   ),
//                   Flexible(
//                     child: Text(
//                       entry.key,
//                       style: GoogleFonts.roboto(fontSize: 14),
//                     ),
//                   ),
//                 ],
//               ),
//               if (isOthers && entry.value)
//                 Padding(
//                   padding: const EdgeInsets.only(left: 35.0, bottom: 8),
//                   child: TextField(
//                     controller: othersController,
//                     decoration: const InputDecoration(
//                       hintText: "Please specify",
//                       border: OutlineInputBorder(),
//                       contentPadding: EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 8,
//                       ),
//                     ),
//                     onChanged: (value) {
//                       _updateCheckboxProvider(title, options, othersController);
//                     },
//                   ),
//                 ),
//             ],
//           );
//         }).toList(),
//       );
//     }
//
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
//       decoration: BoxDecoration(
//         borderRadius: const BorderRadius.all(Radius.circular(10)),
//         border: Border.all(color: Colors.grey, width: 1.0),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: GoogleFonts.roboto(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 12),
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Expanded(child: buildColumn(leftColumn)),
//               const SizedBox(width: 32),
//               Expanded(child: buildColumn(rightColumn)),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTextField(
//       String label,
//       TextEditingController controller, {
//         int maxLines = 1,
//       }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label, style: GoogleFonts.roboto(fontWeight: FontWeight.w500)),
//         const SizedBox(height: 6),
//         TextField(
//           controller: controller,
//           onChanged: (value) {
//             Provider.of<PatientFormProvider>(
//               context,
//               listen: false,
//             ).updateField(label, value.trim());
//           },
//           maxLines: maxLines,
//           keyboardType:
//           [
//             'GENERAL CONDITION',
//             'OTHER PATIENT PROGRESS/ REMARKS',
//           ].contains(label.toUpperCase().trim())
//               ? TextInputType.text
//               : TextInputType.number,
//           decoration: const InputDecoration(
//             filled: true,
//             fillColor: Color(0xfff5f5f5),
//             border: OutlineInputBorder(borderSide: BorderSide.none),
//           ),
//         ),
//         const SizedBox(height: 12),
//       ],
//     );
//   }
//
//   Widget _buildAcknowledgementForm() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         borderRadius: const BorderRadius.all(Radius.circular(10)),
//         border: Border.all(color: Colors.grey, width: 1.0),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "ACKNOWLEDGEMENT ON PATIENT ARRIVAL AT TRANSFERRED FACILITY",
//             style: GoogleFonts.roboto(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 20),
//           _buildTextField(
//             "General Condition",
//             generalConditionController,
//             maxLines: 3,
//           ),
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Expanded(
//                 child: Column(
//                   children: [
//                     _buildTextField("BP (mmHg)", bpController),
//                     _buildTextField("RR (min)", rrController),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 20),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "Condition Status",
//                       style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
//                     ),
//                     Wrap(
//                       spacing: 8.0,
//                       runSpacing: 4.0,
//                       children:
//                       [
//                         'Improved',
//                         'Deteriorated',
//                         'Unchanged',
//                         'Death',
//                         'Others',
//                       ].map((status) {
//                         return Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Radio<String>(
//                               value: status,
//                               groupValue: conditionStatus,
//                               onChanged: (val) {
//                                 setState(() {
//                                   conditionStatus = val;
//                                   deathChecked = (val == 'Death');
//                                   othersChecked = (val == 'Others');
//                                 });
//                                 Provider.of<PatientFormProvider>(
//                                   context,
//                                   listen: false,
//                                 ).updateField("Condition Status", val);
//                               },
//                               activeColor: Colors.red.shade800,
//                             ),
//                             Text(status),
//                           ],
//                         );
//                       }).toList(),
//                     ),
//                     if (deathChecked) ...[
//                       GestureDetector(
//                         onTap: () async {
//                           final TimeOfDay? pickedTime = await showTimePicker(
//                             context: context,
//                             initialTime: TimeOfDay.now(),
//                           );
//
//                           if (pickedTime != null) {
//                             Provider.of<PatientFormProvider>(
//                               context,
//                               listen: false,
//                             ).updateField(
//                               "DeathTime",
//                               pickedTime.format(context),
//                             );
//                           }
//                         },
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 12,
//                           ),
//                           margin: const EdgeInsets.only(bottom: 10),
//                           decoration: BoxDecoration(
//                             border: Border.all(color: Colors.grey),
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Icon(Icons.access_time, color: Colors.grey[700]),
//                               const SizedBox(width: 8),
//                               Consumer<PatientFormProvider>(
//                                 builder: (context, provider, child) {
//                                   final deathTime =
//                                   provider.patientDetails["DeathTime"];
//                                   return Text(
//                                     deathTime ?? "--:--",
//                                     style: TextStyle(
//                                       fontSize: 16,
//                                       color: deathTime != null
//                                           ? Colors.black
//                                           : Colors.grey,
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 10),
//                     ],
//                     if (othersChecked) ...[
//                       Row(
//                         children: [
//                           Expanded(
//                             child: SizedBox(
//                               width: 200,
//                               child: TextField(
//                                 controller: otherConditionController,
//                                 decoration: const InputDecoration(
//                                   hintText: "Specify others",
//                                   border: OutlineInputBorder(),
//                                 ),
//                                 onChanged: (value) {
//                                   Provider.of<PatientFormProvider>(
//                                     context,
//                                     listen: false,
//                                   ).updateField("Specify others", value.trim());
//                                 },
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 10),
//                     ],
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           Row(
//             children: [
//               Expanded(child: _buildTextField("Temperature (°C)", temperatureController)),
//               const SizedBox(width: 20),
//               Expanded(child: _buildTextField("SPO2 (%)", spo2Controller)),
//             ],
//           ),
//           Row(
//             children: [
//               Expanded(child: _buildTextField("Glucose (mmol/L)", glucoseController)),
//               const SizedBox(width: 20),
//               Expanded(child: _buildTextField("Pain Score (/10)", painScoreController)),
//             ],
//           ),
//           _buildTextField(
//             "Other Patient Progress/ Remarks",
//             remarksController,
//             maxLines: 3,
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return ConstrainedBox(
//       constraints: const BoxConstraints(maxWidth: 1000),
//       child: Column(
//         children: [
//           const SizedBox(height: 20),
//           _buildCheckboxList("TREATMENT/ACTION", treatmentOptions, otherTreatmentController),
//           const SizedBox(height: 20),
//           _buildCheckboxList("HANDLING & IMMOBILISATION ON DEPARTURE", handlingOptions, otherHandlingController),
//           const SizedBox(height: 20),
//           _buildAcknowledgementForm(),
//           const SizedBox(height: 40),
//         ],
//       ),
//     );
//   }
// }


// code without ui responsiveness
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
//
// import '../providers/patient_form_data.dart';
//
// class TreatmentPage extends StatefulWidget {
//   const TreatmentPage({super.key});
//
//   @override
//   State<TreatmentPage> createState() => _TreatmentPageState();
// }
//
// class _TreatmentPageState extends State<TreatmentPage> {
//   // Maps to hold the state of the checkboxes
//   late Map<String, bool> treatmentOptions;
//   late Map<String, bool> handlingOptions;
//
//   String? conditionStatus;
//   final TextEditingController generalConditionController = TextEditingController();
//   final TextEditingController bpController = TextEditingController();
//   final TextEditingController rrController = TextEditingController();
//   final TextEditingController spo2Controller = TextEditingController();
//   final TextEditingController temperatureController = TextEditingController();
//   final TextEditingController glucoseController = TextEditingController();
//   final TextEditingController painScoreController = TextEditingController();
//   final TextEditingController remarksController = TextEditingController();
//   final TextEditingController otherTreatmentController = TextEditingController();
//   final TextEditingController otherHandlingController = TextEditingController();
//   final TextEditingController otherConditionController = TextEditingController();
//
//   bool deathChecked = false;
//   bool othersChecked = false;
//
//   @override
//   void initState() {
//     super.initState();
//     // Initialize with default values
//     treatmentOptions = {
//       'NO TREATMENT / ADVICE ONLY GIVEN': false,
//       'REST-ICE-COMPRESS-ELEVATE': false,
//       'SPLIT': false,
//       'AIRWAY SUCTION': false,
//       'NEUROLOGICAL TEST': false,
//       'OTHERS': false,
//       'WOUND CLEANSED': false,
//       'FRACTURE SUPPORT': false,
//       'C-SPINE CONTROL (IMMOBILISATION)': false,
//       'AIRWAY INSERTED (TYPE/SIZE)': false,
//       'HEAD INJURY ADVICE GIVEN': false,
//     };
//     handlingOptions = {
//       'WALKED UNAIDED': false,
//       'CHAIR': false,
//       'LONGBOARD': false,
//       'OTHERS': false,
//       'SCOOP': false,
//       'WALKED AIDED': false,
//       'STRETCHER': false,
//     };
//     conditionStatus = 'Unchanged';
//
//     // Load existing data from the provider
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _loadDataFromProvider();
//     });
//   }
//
//   // Method to load existing data from the provider and update the UI state
//   void _loadDataFromProvider() {
//     final provider = Provider.of<PatientFormProvider>(context, listen: false);
//     final patientDetails = provider.patientDetails;
//
//     // Load checkbox data
//     final savedTreatment = patientDetails['TREATMENT/ACTION'] as List<dynamic>?;
//     if (savedTreatment != null) {
//       setState(() {
//         for (var key in treatmentOptions.keys.toList()) {
//           treatmentOptions[key] = savedTreatment.contains(key);
//         }
//         if (savedTreatment.contains('OTHERS')) {
//           otherTreatmentController.text = savedTreatment.lastWhere(
//                   (element) => !treatmentOptions.containsKey(element),
//               orElse: () => '');
//           treatmentOptions['OTHERS'] = true;
//         }
//       });
//     }
//
//     final savedHandling = patientDetails['HANDLING & IMMOBILISATION ON DEPARTURE'] as List<dynamic>?;
//     if (savedHandling != null) {
//       setState(() {
//         for (var key in handlingOptions.keys.toList()) {
//           handlingOptions[key] = savedHandling.contains(key);
//         }
//         if (savedHandling.contains('OTHERS')) {
//           otherHandlingController.text = savedHandling.lastWhere(
//                   (element) => !handlingOptions.containsKey(element),
//               orElse: () => '');
//           handlingOptions['OTHERS'] = true;
//         }
//       });
//     }
//
//     // Load form field data
//     generalConditionController.text = patientDetails['General Condition'] ?? '';
//     bpController.text = patientDetails['BP (mmHg)'] ?? '';
//     rrController.text = patientDetails['RR (min)'] ?? '';
//     spo2Controller.text = patientDetails['SPO2 (%)'] ?? '';
//     temperatureController.text = patientDetails['Temperature (°C)'] ?? '';
//     glucoseController.text = patientDetails['Glucose (mmol/L)'] ?? '';
//     painScoreController.text = patientDetails['Pain Score (/10)'] ?? '';
//     remarksController.text = patientDetails['Other Patient Progress/ Remarks'] ?? '';
//     conditionStatus = patientDetails['Condition Status'] ?? 'Unchanged';
//     deathChecked = conditionStatus == 'Death';
//     othersChecked = conditionStatus == 'Others';
//     if(othersChecked) {
//       otherConditionController.text = patientDetails['Specify others'] ?? '';
//     }
//   }
//
//   // Helper method to update the provider with a list of selected options
//   void _updateCheckboxProvider(String title, Map<String, bool> options, TextEditingController othersController) {
//     final selectedOptions = options.entries
//         .where((e) => e.value)
//         .map((e) => e.key)
//         .toList();
//
//     // Add custom text if "Others" is checked and has a value
//     if (options['OTHERS'] == true && othersController.text.trim().isNotEmpty) {
//       selectedOptions.add(othersController.text.trim());
//     }
//     Provider.of<PatientFormProvider>(context, listen: false).updateField(title, selectedOptions);
//   }
//
//   Widget _buildCheckboxList(String title, Map<String, bool> options, TextEditingController othersController) {
//     final entries = options.entries.toList();
//     final half = (entries.length / 2).ceil();
//     final leftColumn = entries.sublist(0, half);
//     final rightColumn = entries.sublist(half);
//
//     Widget buildColumn(List<MapEntry<String, bool>> items) {
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: items.map((entry) {
//           final isOthers = entry.key == "OTHERS";
//
//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Checkbox(
//                     value: entry.value,
//                     onChanged: (value) {
//                       setState(() {
//                         options[entry.key] = value!;
//                       });
//                       _updateCheckboxProvider(title, options, othersController);
//                     },
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     activeColor: Colors.red.shade800,
//                   ),
//                   Flexible(
//                     child: Text(
//                       entry.key,
//                       style: GoogleFonts.roboto(fontSize: 14),
//                     ),
//                   ),
//                 ],
//               ),
//               if (isOthers && entry.value)
//                 Padding(
//                   padding: const EdgeInsets.only(left: 35.0, bottom: 8),
//                   child: TextField(
//                     controller: othersController,
//                     decoration: const InputDecoration(
//                       hintText: "Please specify",
//                       border: OutlineInputBorder(),
//                       contentPadding: EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 8,
//                       ),
//                     ),
//                     onChanged: (value) {
//                       _updateCheckboxProvider(title, options, othersController);
//                     },
//                   ),
//                 ),
//             ],
//           );
//         }).toList(),
//       );
//     }
//
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
//       decoration: BoxDecoration(
//         borderRadius: const BorderRadius.all(Radius.circular(10)),
//         border: Border.all(color: Colors.grey, width: 1.0),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: GoogleFonts.roboto(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 12),
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Expanded(child: buildColumn(leftColumn)),
//               const SizedBox(width: 32),
//               Expanded(child: buildColumn(rightColumn)),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTextField(
//       String label,
//       TextEditingController controller, {
//         int maxLines = 1,
//       }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label, style: GoogleFonts.roboto(fontWeight: FontWeight.w500)),
//         const SizedBox(height: 6),
//         TextField(
//           controller: controller,
//           onChanged: (value) {
//             Provider.of<PatientFormProvider>(
//               context,
//               listen: false,
//             ).updateField(label, value.trim());
//           },
//           maxLines: maxLines,
//           keyboardType:
//           [
//             'General Condition',
//             'Other Patient Progress/ Remarks',
//           ].contains(label.toUpperCase().trim())
//               ? TextInputType.text
//               : TextInputType.number,
//           decoration: const InputDecoration(
//             filled: true,
//             fillColor: Color(0xfff5f5f5),
//             border: OutlineInputBorder(borderSide: BorderSide.none),
//           ),
//         ),
//         const SizedBox(height: 12),
//       ],
//     );
//   }
//
//   Widget _buildAcknowledgementForm() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         borderRadius: const BorderRadius.all(Radius.circular(10)),
//         border: Border.all(color: Colors.grey, width: 1.0),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "ACKNOWLEDGEMENT ON PATIENT ARRIVAL AT TRANSFERRED FACILITY",
//             style: GoogleFonts.roboto(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 20),
//           _buildTextField(
//             "General Condition",
//             generalConditionController,
//             maxLines: 3,
//           ),
//           Row(
//             children: [
//               Expanded(child: _buildTextField("BP (mmHg)", bpController)),
//               const SizedBox(width: 20),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "Condition Status",
//                       style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
//                     ),
//                     Row(
//                       children:
//                       [
//                         'Improved',
//                         'Deteriorated',
//                         'Unchanged',
//                         'Death',
//                         'Others',
//                       ].map((status) {
//                         return Row(
//                           children: [
//                             Radio<String>(
//                               value: status,
//                               groupValue: conditionStatus,
//                               onChanged: (val) {
//                                 setState(() {
//                                   conditionStatus = val;
//                                   deathChecked = (val == 'Death');
//                                   othersChecked = (val == 'Others');
//                                 });
//                                 Provider.of<PatientFormProvider>(
//                                   context,
//                                   listen: false,
//                                 ).updateField("Condition Status", val);
//                               },
//                               activeColor: Colors.red.shade800,
//                             ),
//                             Text(status),
//                           ],
//                         );
//                       }).toList(),
//                     ),
//                     if (deathChecked) ...[
//                       GestureDetector(
//                         onTap: () async {
//                           final TimeOfDay? pickedTime = await showTimePicker(
//                             context: context,
//                             initialTime: TimeOfDay.now(),
//                           );
//
//                           if (pickedTime != null) {
//                             Provider.of<PatientFormProvider>(
//                               context,
//                               listen: false,
//                             ).updateField(
//                               "DeathTime",
//                               pickedTime.format(context),
//                             );
//                           }
//                         },
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 12,
//                             // vertical: 10,
//                           ),
//                           margin: const EdgeInsets.only(bottom: 10),
//                           decoration: BoxDecoration(
//                             border: Border.all(color: Colors.grey),
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Icon(Icons.access_time, color: Colors.grey[700]),
//                               const SizedBox(width: 8),
//                               Consumer<PatientFormProvider>(
//                                 builder: (context, provider, child) {
//                                   final deathTime =
//                                   provider.patientDetails["DeathTime"];
//                                   return Text(
//                                     deathTime ?? "--:--",
//                                     style: TextStyle(
//                                       fontSize: 16,
//                                       color: deathTime != null
//                                           ? Colors.black
//                                           : Colors.grey,
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 10),
//                     ],
//                     if (othersChecked) ...[
//                       Row(
//                         children: [
//                           Expanded(
//                             child: SizedBox(
//                               width: 200,
//                               child: TextField(
//                                 controller: otherConditionController,
//                                 decoration: const InputDecoration(
//                                   hintText: "Specify others",
//                                   border: OutlineInputBorder(),
//                                 ),
//                                 onChanged: (value) {
//                                   Provider.of<PatientFormProvider>(
//                                     context,
//                                     listen: false,
//                                   ).updateField("Specify others", value.trim());
//                                 },
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 10),
//                     ],
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           Row(
//             children: [
//               Expanded(child: _buildTextField("RR (min)", rrController)),
//               const SizedBox(width: 20),
//               Expanded(
//                 child: _buildTextField(
//                   "Temperature (°C)",
//                   temperatureController,
//                 ),
//               ),
//             ],
//           ),
//           Row(
//             children: [
//               Expanded(child: _buildTextField("SPO2 (%)", spo2Controller)),
//               const SizedBox(width: 20),
//               Expanded(
//                 child: _buildTextField("Glucose (mmol/L)", glucoseController),
//               ),
//             ],
//           ),
//           _buildTextField("Pain Score (/10)", painScoreController),
//           _buildTextField(
//             "Other Patient Progress/ Remarks",
//             remarksController,
//             maxLines: 3,
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return ConstrainedBox(
//       constraints: const BoxConstraints(maxWidth: 1000),
//       child: Column(
//         children: [
//           const SizedBox(height: 20),
//           _buildCheckboxList("TREATMENT/ACTION", treatmentOptions, otherTreatmentController),
//           const SizedBox(height: 20),
//           _buildCheckboxList("HANDLING & IMMOBILISATION ON DEPARTURE", handlingOptions, otherHandlingController),
//           const SizedBox(height: 20),
//           _buildAcknowledgementForm(),
//           const SizedBox(height: 40),
//         ],
//       ),
//     );
//   }
// }
