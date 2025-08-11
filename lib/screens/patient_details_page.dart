import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/patient_form_data.dart';

// Define a breakpoint for mobile vs. web/tablet layout
const double kMobileBreakpoint = 600.0;

class PatientDetails extends StatefulWidget {
  const PatientDetails({super.key});

  @override
  State<PatientDetails> createState() => _PatientDetailsState();
}

class _PatientDetailsState extends State<PatientDetails> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  String referralType = '';
  DateTime? dob;
  final locationController = TextEditingController();
  final nameController = TextEditingController();
  final nricController = TextEditingController();
  final dobController = TextEditingController();
  final ageController = TextEditingController();
  String selectedGender = "";
  final complaintController = TextEditingController();
  final allergiesController = TextEditingController();
  final medicationController = TextEditingController();
  final nursesNotesController = TextEditingController();
  final otherHistoryController = TextEditingController();

  Map<String, List<String>> primarySurveySelections = {
    "Airway": [],
    "Breathing": [],
    "Circulation": [],
  };

  final referralOptions = [
    'SELF REFERRAL',
    'HOSPITAL REFERRAL',
    'CALL TO SCENE',
    'Connectica ZEN CLIENT',
  ];

  final List<String> previousHistoryOptions = [
    "HIGH BLOOD PRESSURE",
    "RESPIRATORY",
    "DIABETES",
    "CARDIAC",
    "SEIZURES",
    "ASTHMA",
    "STROKE",
    "OTHER",
  ];
  List<String> selectedHistory = [];

  @override
  void initState() {
    super.initState();
    // This is the key fix. We use WidgetsBinding.instance.addPostFrameCallback
    // to safely access the provider and update the UI state after the widget
    // has been built for the first time.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PatientFormProvider>(context, listen: false);
      final details = provider.patientDetails;
      String formattedDate = DateFormat('dd-MM-yyyy').format(selectedDate);
      provider.updateField('patient_entry_date', formattedDate);
      String timeString = selectedTime.format(context);
      provider.updateField('patient_entry_time', timeString);

      // Populate TextFields
      nameController.text = details['Name'] ?? '';
      nricController.text = details['NRIC Number'] ?? '';
      dobController.text = details['patient_dob'] ?? '';
      ageController.text = details['Age'] ?? '';
      locationController.text = details['Location'] ?? '';
      complaintController.text = details['chief_complain'] ?? '';
      allergiesController.text = details['Allergies'] ?? '';
      medicationController.text = details['Medication'] ?? '';
      nursesNotesController.text = details['Nurse\'s Notes'] ?? '';
      otherHistoryController.text = details['Other History'] ?? '';


      // Populate Radio buttons
      if (details['referral_type'] != null) {
        setState(() {
          referralType = details['referral_type']!;
        });
      }
      if (details['patient_gender'] != null) {
        setState(() {
          selectedGender = details['patient_gender']!;
        });
      }

      // Populate Checkbox Groups
      if (details['primary_survey'] is Map<String, List<String>>) {
        setState(() {
          primarySurveySelections = details['primary_survey'] as Map<String, List<String>>;
        });
      }
      if (details['previous_history'] is List<String>) {
        setState(() {
          selectedHistory = details['previous_history'] as List<String>;
        });
      }

      // Populate Date and Time pickers
      // We need to parse the string back to a DateTime object
      if (details['patient_entry_date'] is String) {
        try {
          setState(() {
            selectedDate = DateFormat('dd-MM-yyyy').parse(details['patient_entry_date']);
          });
        } catch (e) {
          // Fallback to current date if parsing fails
          print('Error parsing date: $e');
        }
      }

      // We need to parse the time string back to a TimeOfDay object
      if (details['patient_entry_time'] is String) {
        try {
          setState(() {
            selectedTime = TimeOfDay.fromDateTime(DateFormat.jm().parse(details['patient_entry_time']));
          });
        } catch (e) {
          // Fallback to current time if parsing fails
          print('Error parsing time: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // The LayoutBuilder is the key to responsive design. It allows us
    // to build different layouts based on the available constraints.
    return LayoutBuilder(
      builder: (context, constraints) {
        // If the screen width is less than the mobile breakpoint, show a mobile-friendly layout.
        if (constraints.maxWidth < kMobileBreakpoint) {
          return _buildMobileLayout();
        } else {
          // Otherwise, show a layout optimized for wider screens (tablet/web).
          return _buildWebLayout();
        }
      },
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Using a padding that is suitable for mobile screens.
        _buildDetailsContainer(
          padding: 16.0,
          children: [
            _buildHeader("MK AMBULANCE - PATIENT DETAIL"),
            const SizedBox(height: 16),
            // On mobile, the date and time pickers are stacked vertically.
            _buildDatePicker(),
            const SizedBox(height: 16),
            _buildTimePicker(),
            const SizedBox(height: 16),
            _buildReferralTypeSection(),
            const SizedBox(height: 16),
            _buildTextField("Location", locationController, "Location of incident"),
            const SizedBox(height: 16),
            // Name and NRIC are now in a column.
            _buildTextField("Name", nameController, "Patient's full name"),
            const SizedBox(height: 16),
            _buildTextField("NRIC Number", nricController, "Patient's NRIC number"),
            const SizedBox(height: 16),
            // DOB and Age are now in a column.
            _buildDatePickerField(),
            const SizedBox(height: 16),
            _buildTextField("Age", ageController, "Patient's age"),
            const SizedBox(height: 16),
            _buildGenderSection(),
            const SizedBox(height: 16),
            _buildChiefComplaintSection(),
          ],
        ),
        const SizedBox(height: 24),
        _buildDetailsContainer(
          padding: 16.0,
          children: [
            _buildHeader("PRIMARY SURVEY", size: 18),
            const SizedBox(height: 8),
            // Checkbox columns are now stacked vertically on mobile.
            _buildCheckBoxColumn("Airway", ["CLEAR", "OBSTRUCTED", "AGONAL", "ABSENT"]),
            const SizedBox(height: 20),
            _buildCheckBoxColumn("Breathing", ["NORMAL", "SHALLOW", "ABSENT"]),
            const SizedBox(height: 20),
            _buildCheckBoxColumn("Circulation", ["NORMAL", "PALE", "FLUSHED", "CYNOSED"]),
          ],
        ),
        const SizedBox(height: 24),
        _buildAllergiesMedicationSection(),
        const SizedBox(height: 24),
        _buildPreviousHistorySection(),
      ],
    );
  }

  Widget _buildWebLayout() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1000),
      child: Column(
        children: [
          _buildDetailsContainer(
            padding: 20.0,
            children: [
              _buildHeader("MK AMBULANCE - PATIENT DETAIL"),
              const SizedBox(height: 20),
              // On web, date and time pickers are side by side.
              Row(
                children: [
                  Expanded(child: _buildDatePicker()),
                  const SizedBox(width: 20),
                  Expanded(child: _buildTimePicker()),
                ],
              ),
              const SizedBox(height: 20),
              _buildReferralTypeSection(),
              const SizedBox(height: 20),
              _buildTextField("Location", locationController, "Location of incident"),
              const SizedBox(height: 20),
              // Name and NRIC are side by side.
              Row(
                children: [
                  Expanded(child: _buildTextField("Name", nameController, "Patient's full name")),
                  const SizedBox(width: 20),
                  Expanded(child: _buildTextField("NRIC Number", nricController, "Patient's NRIC number")),
                ],
              ),
              const SizedBox(height: 20),
              // DOB and Age are side by side.
              Row(
                children: [
                  Expanded(child: _buildDatePickerField()),
                  const SizedBox(width: 20),
                  Expanded(child: _buildTextField("Age", ageController, "Patient's age")),
                ],
              ),
              const SizedBox(height: 20),
              _buildGenderSection(),
              const SizedBox(height: 20),
              _buildChiefComplaintSection(),
            ],
          ),
          const SizedBox(height: 30),
          _buildDetailsContainer(
            padding: 20.0,
            children: [
              _buildHeader("PRIMARY SURVEY", size: 18),
              const SizedBox(height: 10),
              // Checkbox columns are side by side.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildCheckBoxColumn("Airway", ["CLEAR", "OBSTRUCTED", "AGONAL", "ABSENT"])),
                  const SizedBox(width: 40),
                  Expanded(child: _buildCheckBoxColumn("Breathing", ["NORMAL", "SHALLOW", "ABSENT"])),
                  const SizedBox(width: 40),
                  Expanded(child: _buildCheckBoxColumn("Circulation", ["NORMAL", "PALE", "FLUSHED", "CYNOSED"])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          _buildAllergiesMedicationSection(),
          const SizedBox(height: 30),
          _buildPreviousHistorySection(),
        ],
      ),
    );
  }

  // --- Reusable Widget Builders ---

  Widget _buildDetailsContainer({required double padding, required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: Colors.grey, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildHeader(String title, {double size = 20}) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: size,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildReferralTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Referral Type'),
        const SizedBox(height: 5),
        Wrap(
          spacing: 20,
          children: referralOptions.map((type) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<String>(
                  activeColor: Colors.red,
                  value: type,
                  groupValue: referralType,
                  onChanged: (val) => setState(() {
                    referralType = val!;
                    Provider.of<PatientFormProvider>(
                      context,
                      listen: false,
                    ).updateField('referral_type', referralType);
                  }),
                ),
                Text(type),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGenderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Gender"),
        const SizedBox(height: 5),
        Wrap(
          spacing: 20,
          children: ["Male", "Female", "Other"].map((gender) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<String>(
                  value: gender,
                  activeColor: Colors.red,
                  groupValue: selectedGender,
                  onChanged: (val) =>
                      setState(() {
                        selectedGender = val!;
                        Provider.of<PatientFormProvider>(context, listen: false)
                            .updateField('patient_gender', selectedGender);
                      }),
                ),
                Text(gender),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildChiefComplaintSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Chief Complain (Patient Complaint)"),
        const SizedBox(height: 5),
        TextFormField(
          maxLines: 4,
          controller: complaintController,
          decoration: InputDecoration(
            hintText: "Describe the chief complaint",
            filled: true,
            fillColor: Colors.grey.shade100,
            border: const OutlineInputBorder(
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) {
            Provider.of<PatientFormProvider>(context, listen: false)
                .updateField('chief_complain', value);
          },
        ),
      ],
    );
  }

  Widget _buildAllergiesMedicationSection() {
    return _buildDetailsContainer(
      padding: 15.0,
      children: [
        _buildHeader("ALLERGIES & MEDICATION", size: 18),
        const SizedBox(height: 15),
        _buildTextField(
          "Allergies",
          allergiesController,
          "List known allergies",
          maxLines: 3,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          "Medication",
          medicationController,
          "List current medications",
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildPreviousHistorySection() {
    return _buildDetailsContainer(
      padding: 15.0,
      children: [
        _buildHeader("PREVIOUS HISTORY", size: 18),
        const SizedBox(height: 15),
        Wrap(
          spacing: 20,
          runSpacing: -8,
          children: previousHistoryOptions.map((option) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: selectedHistory.contains(option),
                    activeColor: Colors.red,
                    visualDensity: const VisualDensity(
                      horizontal: -4,
                      vertical: -4,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          selectedHistory.add(option);
                        } else {
                          selectedHistory.remove(option);
                          if (option == "OTHER") {
                            otherHistoryController.clear();
                          }
                        }
                        Provider.of<PatientFormProvider>(context, listen: false)
                            .updateField('previous_history', selectedHistory);
                      });
                    },
                  ),
                  Text(option, style: const TextStyle(fontSize: 13)),
                ],
              ),
            );
          }).toList(),
        ),
        // Show "Other History" field only if "OTHER" is checked
        if (selectedHistory.contains("OTHER")) ...[
          const SizedBox(height: 10),
          _buildTextField(
            "Other History",
            otherHistoryController,
            "Please specify",
          ),
        ],
        const SizedBox(height: 15),
        _buildTextField(
          "Nurse's Notes",
          nursesNotesController,
          "Additional notes from the nurse...",
          maxLines: 3,
        ),
      ],
    );
  }

  // NOTE: This is the refactored function. It no longer returns an Expanded widget.
  // The parent Row will be responsible for wrapping it in an Expanded if needed.
  Widget _buildCheckBoxColumn(String title, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        ...options.map((option) {
          final selected = primarySurveySelections[title]!.contains(option);
          return Row(
            children: [
              Checkbox(
                value: selected,
                activeColor: Colors.red,
                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      primarySurveySelections[title]!.add(option);
                    } else {
                      primarySurveySelections[title]!.remove(option);
                    }
                    Provider.of<PatientFormProvider>(context, listen: false)
                        .updateField('primary_survey', primarySurveySelections);
                  });
                },
              ),
              const SizedBox(width: 10),
              Flexible(child: Text(option, style: const TextStyle(fontSize: 13))),
            ],
          );
        }),
      ],
    );
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        Provider.of<PatientFormProvider>(
          context,
          listen: false,
        ).updateField('patient_entry_date', DateFormat('dd-MM-yyyy').format(selectedDate));
      });
    }
  }

  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
        Provider.of<PatientFormProvider>(
          context,
          listen: false,
        ).updateField('patient_entry_time', selectedTime.format(context));
      });
    }
  }

  Future<void> pickDOB() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dob ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dob = picked;
        dobController.text =
        "${dob!.day.toString().padLeft(2, '0')}-${dob!.month.toString().padLeft(2, '0')}-${dob!.year}";
        Provider.of<PatientFormProvider>(
          context,
          listen: false,
        ).updateField('patient_dob', dobController.text);
      });
    }
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Date'),
        const SizedBox(height: 5),
        TextFormField(
          readOnly: true,
          onTap: pickDate,
          decoration: InputDecoration(
            suffixIcon: const Icon(Icons.calendar_today, size: 18),
            border: const OutlineInputBorder(borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.grey.shade100,
            hintText: 'Select date',
          ),
          controller: TextEditingController(
            text:
            "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}",
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Time'),
        const SizedBox(height: 5),
        TextFormField(
          readOnly: true,
          onTap: pickTime,
          decoration: InputDecoration(
            suffixIcon: const Icon(Icons.access_time, size: 18),
            border: const OutlineInputBorder(borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.grey.shade100,
            hintText: 'Select time',
          ),
          controller: TextEditingController(text: selectedTime.format(context)),
        ),
      ],
    );
  }

  Widget _buildDatePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Date of Birth'),
        const SizedBox(height: 5),
        TextFormField(
          controller: dobController,
          readOnly: true,
          onTap: pickDOB,
          decoration: InputDecoration(
            suffixIcon: const Icon(
              Icons.calendar_today,
              size: 18,
            ),
            border: const OutlineInputBorder(
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            hintText: 'dd-mm-yyyy',
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller,
      String hint, {
        int maxLines = 1,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: const OutlineInputBorder(borderSide: BorderSide.none),
          ),
          onChanged: (value) {
            Provider.of<PatientFormProvider>(
              context,
              listen: false,
            ).updateField(label, value);
          },
        ),
      ],
    );
  }
}

// SnackBar(content: Text('$fieldName image saved to form.'),backgroundColor: Colors.green,),

// UI without responsiveness
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
//
// import '../providers/patient_form_data.dart';
//
// class PatientDetails extends StatefulWidget {
//   const PatientDetails({super.key});
//
//   @override
//   State<PatientDetails> createState() => _PatientDetailsState();
// }
//
// class _PatientDetailsState extends State<PatientDetails> {
//   DateTime selectedDate = DateTime.now();
//   TimeOfDay selectedTime = TimeOfDay.now();
//   String referralType = '';
//   DateTime? dob;
//   final locationController = TextEditingController();
//   final nameController = TextEditingController();
//   final nricController = TextEditingController();
//   final dobController = TextEditingController();
//   final ageController = TextEditingController();
//   String selectedGender = "";
//   final complaintController = TextEditingController();
//   final allergiesController = TextEditingController();
//   final medicationController = TextEditingController();
//   final nursesNotesController = TextEditingController();
//   final otherHistoryController = TextEditingController();
//
//
//   Map<String, List<String>> primarySurveySelections = {
//     "Airway": [],
//     "Breathing": [],
//     "Circulation": [],
//   };
//
//   final referralOptions = [
//     'SELF REFERRAL',
//     'HOSPITAL REFERRAL',
//     'CALL TO SCENE',
//     'Connectica ZEN CLIENT',
//   ];
//
//
//   Future<void> pickDate() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(1900),
//       lastDate: DateTime.now(),
//     );
//     if (picked != null) {
//       setState(() {
//         selectedDate = picked;
//         Provider.of<PatientFormProvider>(
//           context,
//           listen: false,
//         ).updateField('patient_entry_date', DateFormat('dd-MM-yyyy').format(selectedDate));
//       });
//     }
//   }
//
//   Future<void> pickTime() async {
//     final picked = await showTimePicker(
//       context: context,
//       initialTime: selectedTime,
//     );
//     if (picked != null) {
//       setState(() {
//         selectedTime = picked;
//         Provider.of<PatientFormProvider>(
//           context,
//           listen: false,
//         ).updateField('patient_entry_time', selectedTime.format(context));
//       });
//     }
//   }
//
//   Future<void> pickDOB() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: dob ?? DateTime(2000),
//       firstDate: DateTime(1900),
//       lastDate: DateTime.now(),
//     );
//     if (picked != null) {
//       setState(() {
//         dob = picked;
//         dobController.text =
//         "${dob!.day.toString().padLeft(2, '0')}-${dob!.month.toString().padLeft(2, '0')}-${dob!.year}";
//         Provider.of<PatientFormProvider>(
//           context,
//           listen: false,
//         ).updateField('patient_dob', dobController.text);
//       });
//     }
//   }
//
//   Widget _buildCheckBoxColumn(String title, List<String> options) {
//     return Expanded(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: GoogleFonts.poppins(
//               fontWeight: FontWeight.w500,
//               fontSize: 14,
//             ),
//           ),
//           ...options.map((option) {
//             final selected = primarySurveySelections[title]!.contains(option);
//             return Row(
//               children: [
//                 Checkbox(
//                   value: selected,
//                   activeColor: Colors.red,
//                   visualDensity: VisualDensity(horizontal: -4, vertical: -4),
//                   materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                   onChanged: (bool? value) {
//                     setState(() {
//                       if (value == true) {
//                         primarySurveySelections[title]!.add(option);
//                       } else {
//                         primarySurveySelections[title]!.remove(option);
//                       }
//                       Provider.of<PatientFormProvider>(context, listen: false)
//                           .updateField('primary_survey', primarySurveySelections);
//                     });
//                   },
//                 ),
//                 SizedBox(width: 10),
//                 Flexible(child: Text(option, style: TextStyle(fontSize: 13))),
//               ],
//             );
//           }),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildAllergiesMedicationSection() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: Colors.grey, width: 1),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "ALLERGIES & MEDICATION",
//             style: GoogleFonts.poppins(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 15),
//           _buildTextField(
//             "Allergies",
//             allergiesController,
//             "List known allergies",
//             maxLines: 3,
//           ),
//           const SizedBox(height: 15),
//           _buildTextField(
//             "Medication",
//             medicationController,
//             "List current medications",
//             maxLines: 3,
//           ),
//         ],
//       ),
//     );
//   }
//
//   final List<String> previousHistoryOptions = [
//     "HIGH BLOOD PRESSURE",
//     "RESPIRATORY",
//     "DIABETES",
//     "CARDIAC",
//     "SEIZURES",
//     "ASTHMA",
//     "STROKE",
//     "OTHER",
//   ];
//   List<String> selectedHistory = [];
//
//   Widget _buildPreviousHistorySection() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: Colors.grey, width: 1),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "PREVIOUS HISTORY",
//             style: GoogleFonts.poppins(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 15),
//           Wrap(
//             spacing: 20,
//             runSpacing: -8,
//             children: previousHistoryOptions.map((option) {
//               return Padding(
//                 padding: const EdgeInsets.only(bottom: 8.0),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Checkbox(
//                       value: selectedHistory.contains(option),
//                       activeColor: Colors.red,
//                       visualDensity: const VisualDensity(
//                         horizontal: -4,
//                         vertical: -4,
//                       ),
//                       materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                       onChanged: (val) {
//                         setState(() {
//                           if (val == true) {
//                             selectedHistory.add(option);
//                           } else {
//                             selectedHistory.remove(option);
//                             if (option == "OTHER") {
//                               otherHistoryController.clear();
//                             }
//                           }
//                           Provider.of<PatientFormProvider>(context, listen: false)
//                               .updateField('previous_history', selectedHistory);
//                         });
//                       },
//                     ),
//                     Text(option, style: const TextStyle(fontSize: 13)),
//                   ],
//                 ),
//               );
//             }).toList(),
//           ),
//           // Show "Other History" field only if "OTHER" is checked
//           if (selectedHistory.contains("OTHER")) ...[
//             const SizedBox(height: 10),
//             _buildTextField(
//               "Other History",
//               otherHistoryController,
//               "Please specify",
//             ),
//           ],
//           const SizedBox(height: 15),
//           _buildTextField(
//             "Nurse's Notes",
//             nursesNotesController,
//             "Additional notes from the nurse...",
//             maxLines: 3,
//           ),
//         ],
//       ),
//     );
//   }
//
//
//   @override
//   void initState() {
//     super.initState();
//     // This is the key fix. We use WidgetsBinding.instance.addPostFrameCallback
//     // to safely access the provider and update the UI state after the widget
//     // has been built for the first time.
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final provider = Provider.of<PatientFormProvider>(context, listen: false);
//       final details = provider.patientDetails;
//       String formattedDate = DateFormat('dd-MM-yyyy').format(selectedDate);
//       provider.updateField('patient_entry_date', formattedDate);
//       String timeString = selectedTime.format(context);
//       provider.updateField('patient_entry_time', timeString);
//
//       // Populate TextFields
//       nameController.text = details['Name'] ?? '';
//       nricController.text = details['NRIC Number'] ?? '';
//       dobController.text = details['patient_dob'] ?? '';
//       ageController.text = details['Age'] ?? '';
//       locationController.text = details['Location'] ?? '';
//       complaintController.text = details['chief_complain'] ?? '';
//       allergiesController.text = details['Allergies'] ?? '';
//       medicationController.text = details['Medication'] ?? '';
//       nursesNotesController.text = details['Nurse\'s Notes'] ?? '';
//       otherHistoryController.text = details['Other History'] ?? '';
//
//
//       // Populate Radio buttons
//       if (details['referral_type'] != null) {
//         setState(() {
//           referralType = details['referral_type']!;
//         });
//       }
//       if (details['patient_gender'] != null) {
//         setState(() {
//           selectedGender = details['patient_gender']!;
//         });
//       }
//
//       // Populate Checkbox Groups
//       if (details['primary_survey'] is Map<String, List<String>>) {
//         setState(() {
//           primarySurveySelections = details['primary_survey'] as Map<String, List<String>>;
//         });
//       }
//       if (details['previous_history'] is List<String>) {
//         setState(() {
//           selectedHistory = details['previous_history'] as List<String>;
//         });
//       }
//
//       // Populate Date and Time pickers
//       // We need to parse the string back to a DateTime object
//       if (details['patient_entry_date'] is String) {
//         try {
//           setState(() {
//             selectedDate = DateFormat('dd-MM-yyyy').parse(details['patient_entry_date']);
//           });
//         } catch (e) {
//           // Fallback to current date if parsing fails
//           print('Error parsing date: $e');
//         }
//       }
//
//       // We need to parse the time string back to a TimeOfDay object
//       if (details['patient_entry_time'] is String) {
//         try {
//           setState(() {
//             selectedTime = TimeOfDay.fromDateTime(DateFormat.jm().parse(details['patient_entry_time']));
//           });
//         } catch (e) {
//           // Fallback to current time if parsing fails
//           print('Error parsing time: $e');
//         }
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return ConstrainedBox(
//       constraints: const BoxConstraints(maxWidth: 1000),
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
//             decoration: BoxDecoration(
//               borderRadius: const BorderRadius.all(Radius.circular(10)),
//               border: Border.all(color: Colors.grey, width: 1.0),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'MK AMBULANCE - PATIENT DETAIL',
//                   style: GoogleFonts.poppins(
//                     fontSize: 20,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Row(
//                   children: [
//                     Expanded(child: _buildDatePicker()),
//                     const SizedBox(width: 20),
//                     Expanded(child: _buildTimePicker()),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//
//                 Text('Referral Type'),
//                 SizedBox(height: 5),
//                 Wrap(
//                   spacing: 20,
//                   children: referralOptions.map((type) {
//                     return Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Radio<String>(
//                           activeColor: Colors.red,
//                           value: type,
//                           groupValue: referralType,
//                           onChanged: (val) => setState(() {
//                             referralType = val!;
//                             Provider.of<PatientFormProvider>(
//                               context,
//                               listen: false,
//                             ).updateField('referral_type', referralType);
//                           }),
//                         ),
//                         Text(type),
//                       ],
//                     );
//                   }).toList(),
//                 ),
//                 const SizedBox(height: 20),
//
//                 // Location
//                 _buildTextField(
//                   "Location",
//                   locationController,
//                   "Location of incident",
//                 ),
//                 const SizedBox(height: 20),
//
//                 // Name & NRIC
//                 Row(
//                   children: [
//                     Expanded(
//                       child: _buildTextField(
//                         "Name",
//                         nameController,
//                         "Patient's full name",
//                       ),
//                     ),
//                     const SizedBox(width: 20),
//                     Expanded(
//                       child: _buildTextField(
//                         "NRIC Number",
//                         nricController,
//                         "Patient's NRIC number",
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//
//                 // DOB & Age
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text('Date of Birth'),
//                           SizedBox(height: 5),
//                           TextFormField(
//                             controller: dobController,
//                             readOnly: true,
//                             onTap: pickDOB,
//                             decoration: InputDecoration(
//                               suffixIcon: const Icon(
//                                 Icons.calendar_today,
//                                 size: 18,
//                               ),
//                               border: const OutlineInputBorder(
//                                 borderSide: BorderSide.none,
//                               ),
//                               filled: true,
//                               fillColor: Colors.grey.shade100,
//                               hintText: 'dd-mm-yyyy',
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(width: 20),
//                     Expanded(
//                       child: _buildTextField(
//                         "Age",
//                         ageController,
//                         "Patient's age",
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 const SizedBox(height: 20),
//
//                 // Gender
//                 Text("Gender"),
//                 SizedBox(height: 5),
//                 Wrap(
//                   spacing: 20,
//                   children: ["Male", "Female", "Other"].map((gender) {
//                     return Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Radio<String>(
//                           value: gender,
//                           activeColor: Colors.red,
//                           groupValue: selectedGender,
//                           onChanged: (val) =>
//                               setState(() {
//                                 selectedGender = val!;
//                                 Provider.of<PatientFormProvider>(context, listen: false)
//                                     .updateField('patient_gender', selectedGender);
//                               } ),
//                         ),
//                         Text(gender),
//                       ],
//                     );
//                   }).toList(),
//                 ),
//
//                 const SizedBox(height: 20),
//
//                 // Chief Complaint
//                 Text("Chief Complain (Patient Complaint)"),
//                 SizedBox(height: 5),
//                 TextFormField(
//                   maxLines: 4,
//                   controller: complaintController,
//                   decoration: InputDecoration(
//                     hintText: "Describe the chief complaint",
//                     filled: true,
//                     fillColor: Colors.grey.shade100,
//                     border: const OutlineInputBorder(
//                       borderSide: BorderSide.none,
//                     ),
//                   ),
//                   onChanged: (val){
//                     Provider.of<PatientFormProvider>(context, listen: false)
//                         .updateField('chief_complain', val);
//                   },
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 30),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
//             decoration: BoxDecoration(
//               borderRadius: const BorderRadius.all(Radius.circular(10)),
//               border: Border.all(color: Colors.grey, width: 1.0),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Primary Survey
//                 Text(
//                   "PRIMARY SURVEY",
//                   style: GoogleFonts.poppins(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildCheckBoxColumn("Airway", [
//                       "CLEAR",
//                       "OBSTRUCTED",
//                       "AGONAL",
//                       "ABSENT",
//                     ]),
//                     SizedBox(width: 40),
//                     _buildCheckBoxColumn("Breathing", [
//                       "NORMAL",
//                       "SHALLOW",
//                       "ABSENT",
//                     ]),
//                     SizedBox(width: 40),
//                     _buildCheckBoxColumn("Circulation", [
//                       "NORMAL",
//                       "PALE",
//                       "FLUSHED",
//                       "CYNOSED",
//                     ]),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 30),
//           _buildAllergiesMedicationSection(),
//           const SizedBox(height: 30),
//           _buildPreviousHistorySection(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDatePicker() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text('Date'),
//         SizedBox(height: 5),
//         TextFormField(
//           readOnly: true,
//           onTap: pickDate,
//           decoration: InputDecoration(
//             // labelText: 'Date',
//             suffixIcon: const Icon(Icons.calendar_today, size: 18),
//             border: const OutlineInputBorder(borderSide: BorderSide.none),
//             filled: true,
//             fillColor: Colors.grey.shade100,
//             hintText: 'Select date',
//           ),
//           controller: TextEditingController(
//             text:
//             "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}",
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildTimePicker() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text('Time'),
//         SizedBox(height: 5),
//         TextFormField(
//           readOnly: true,
//           onTap: pickTime,
//           decoration: InputDecoration(
//             // labelText: 'Time',
//             suffixIcon: const Icon(Icons.access_time, size: 18),
//             border: const OutlineInputBorder(borderSide: BorderSide.none),
//             filled: true,
//             fillColor: Colors.grey.shade100,
//             hintText: 'Select time',
//           ),
//           controller: TextEditingController(text: selectedTime.format(context)),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildTextField(
//       String label,
//       TextEditingController controller,
//       String hint, {
//         int maxLines = 1,
//       }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label),
//         const SizedBox(height: 5),
//         TextFormField(
//           controller: controller,
//           maxLines: maxLines,
//           decoration: InputDecoration(
//             hintText: hint,
//             filled: true,
//             fillColor: Colors.grey.shade100,
//             border: const OutlineInputBorder(borderSide: BorderSide.none),
//           ),
//           onChanged: (value) {
//             Provider.of<PatientFormProvider>(
//               context,
//               listen: false,
//             ).updateField(label, value);
//           },
//         ),
//       ],
//     );
//   }
// }
