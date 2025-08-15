import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/patient_form_data.dart';
import '../widgets/signature.dart';

class SignOffPage extends StatefulWidget {
  const SignOffPage({super.key});

  @override
  State<SignOffPage> createState() => _SignOffPageState();
}

class _SignOffPageState extends State<SignOffPage> {
  final TextEditingController patientNameController = TextEditingController();
  final TextEditingController patientIcController = TextEditingController();
  final TextEditingController staffNameController = TextEditingController();
  final TextEditingController staffIcController = TextEditingController();
  final TextEditingController endorsedNameController = TextEditingController();
  final TextEditingController receivedNameController = TextEditingController();

  DateTime endorsedDate = DateTime.now();
  TimeOfDay endorsedTime = TimeOfDay.now();
  DateTime receivedDate = DateTime.now();
  TimeOfDay receivedTime = TimeOfDay.now();

  Map<String, bool> options = {
    'REFERRAL LETTER': false,
    'INVESTIGATION RESULT': false,
    'IMAGING FILM/REPORT': false,
    'AOR': false,
  };

  final dateFormat = DateFormat('dd-MM-yyyy');

  @override
  void initState() {
    super.initState();
    // Load existing data from the provider when the page is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataFromProvider();
    });
  }

  void _loadDataFromProvider() {
    final provider = Provider.of<PatientFormProvider>(context, listen: false);
    final patientDetails = provider.patientDetails;

    // Load text field data
    patientNameController.text = patientDetails['patient_name'] ?? '';
    patientIcController.text = patientDetails['patient_ic_no'] ?? '';
    staffNameController.text = patientDetails['staff_name'] ?? '';
    staffIcController.text = patientDetails['staff_ic_no'] ?? '';
    endorsedNameController.text = patientDetails['endorsed_by_name'] ?? '';
    receivedNameController.text = patientDetails['received_by_name'] ?? '';

    // Load date and time data
    String? endorsedDateString = patientDetails['endorsedDate'];
    if (endorsedDateString != null) {
      try {
        endorsedDate = dateFormat.parse(endorsedDateString);
      } catch (e) {
        // Fallback to current date if parsing fails
      }
    }

    String? endorsedTimeString = patientDetails['endorsedTime'];
    if (endorsedTimeString != null) {
      try {
        final parsedTime = DateFormat.jm().parse(endorsedTimeString);
        endorsedTime = TimeOfDay.fromDateTime(parsedTime);
      } catch (e) {
        // Fallback to current time if parsing fails
      }
    }

    String? receivedDateString = patientDetails['receivedDate'];
    if (receivedDateString != null) {
      try {
        receivedDate = dateFormat.parse(receivedDateString);
      } catch (e) {
        // Fallback to current date if parsing fails
      }
    }

    String? receivedTimeString = patientDetails['receivedTime'];
    if (receivedTimeString != null) {
      try {
        final parsedTime = DateFormat.jm().parse(receivedTimeString);
        receivedTime = TimeOfDay.fromDateTime(parsedTime);
      } catch (e) {
        // Fallback to current time if parsing fails
      }
    }

    // Load checkbox data
    final savedDocuments = patientDetails['documents_provided'] as List<dynamic>?;
    if (savedDocuments != null) {
      setState(() {
        options.forEach((key, value) {
          options[key] = savedDocuments.contains(key);
        });
      });
    }

    setState(() {}); // Trigger a rebuild to update the UI with loaded data
  }

  Future<void> _pickDate(String label) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: label == 'endorsedDate' ? endorsedDate : receivedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        if (label == 'endorsedDate') {
          endorsedDate = picked;
          Provider.of<PatientFormProvider>(context, listen: false)
              .updateField('endorsedDate', DateFormat('dd-MM-yyyy').format(picked));
        } else {
          receivedDate = picked;
          Provider.of<PatientFormProvider>(context, listen: false)
              .updateField('receivedDate', DateFormat('dd-MM-yyyy').format(picked));
        }
      });
    }
  }

  Future<void> _pickTime(String label) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: label == 'endorsedTime' ? endorsedTime : receivedTime,
    );

    if (picked != null) {
      setState(() {
        if (label == 'endorsedTime') {
          endorsedTime = picked;
          Provider.of<PatientFormProvider>(context, listen: false)
              .updateField('endorsedTime', picked.format(context));
        } else {
          receivedTime = picked;
          Provider.of<PatientFormProvider>(context, listen: false)
              .updateField('receivedTime', picked.format(context));
        }
      });
    }
  }

  Widget _buildCheckboxTile(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Use MainAxisSize.min to prevent the row from taking full width
        children: [
          Checkbox(
            value: options[label],
            onChanged: (bool? value) {
              setState(() {
                options[label] = value ?? false;
                final selectedDocuments = options.entries
                    .where((e) => e.value)
                    .map((e) => e.key)
                    .toList();
                Provider.of<PatientFormProvider>(context, listen: false)
                    .updateField('documents_provided', selectedDocuments);
              });
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: BorderSide(color: Colors.red.shade800),
            activeColor: Colors.red.shade800,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 8),
          Flexible( // Wrap Text in Flexible to prevent overflow
            child: Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PatientFormProvider>(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1000),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              border: Border.all(color: Colors.grey, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DECLINED TREATMENT/TRANSPORT',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "PATIENT: I hereby acknowledge the treatment(s) provided, and I understand the nature, purpose, risks, and alternatives explained to me.",
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade800,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Signature Area
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Patient Signature",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          width: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: SignatureField(
                            fieldName: "Patient Signature",
                            formValues: provider.patientDetails, // Pass the entire map
                            onChanged: (signature) {
                              Provider.of<PatientFormProvider>(context, listen: false)
                                  .updateField('patient_signature', signature);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Name",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: patientNameController,
                        onChanged: (value) {
                          Provider.of<PatientFormProvider>(context, listen: false)
                              .updateField('patient_name', value);
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade200,
                          border: OutlineInputBorder(borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "I/C Number",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: patientIcController,
                        onChanged: (value) {
                          Provider.of<PatientFormProvider>(context, listen: false)
                              .updateField('patient_ic_no', value);
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade200,
                          border: OutlineInputBorder(borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "STAFF: I confirmed that I have explained the situation to the patient in terms that in my judgement, they understand.",
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade800,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Staff Signature",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          width: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: SignatureField(
                            fieldName: "Staff Signature",
                            formValues: provider.patientDetails,
                            onChanged: (signature) {
                              Provider.of<PatientFormProvider>(context, listen: false)
                                  .updateField('staff_signature', signature);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Name",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: staffNameController,
                        onChanged: (value) {
                          Provider.of<PatientFormProvider>(context, listen: false)
                              .updateField('staff_name', value);
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade200,
                          border: OutlineInputBorder(borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "I/C Number",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: staffIcController,
                        onChanged: (value) {
                          Provider.of<PatientFormProvider>(context, listen: false)
                              .updateField('staff_ic_no', value);
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade200,
                          border: OutlineInputBorder(borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Documents Provided",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Wrap( // Use Wrap to handle responsiveness
                    spacing: 16.0, // horizontal spacing
                    runSpacing: 8.0, // vertical spacing
                    children: options.keys.map((label) {
                      return _buildCheckboxTile(label);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              border: Border.all(color: Colors.grey, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ENDORSED BY',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Name",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: endorsedNameController,
                  onChanged: (value) {
                    Provider.of<PatientFormProvider>(context, listen: false)
                        .updateField('endorsed_by_name', value);
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Digital Signature",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: SignatureField(
                      fieldName: "ENDORSED BY",
                      formValues: provider.patientDetails,
                      onChanged: (signature) {
                        Provider.of<PatientFormProvider>(context, listen: false)
                            .updateField('endorsed_by_signature', signature);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Date', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              _pickDate('endorsedDate');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Text(dateFormat.format(endorsedDate)),
                                  const Spacer(),
                                  const Icon(Icons.calendar_today, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Time', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              _pickTime('endorsedTime');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Text(endorsedTime.format(context)),
                                  const Spacer(),
                                  const Icon(Icons.access_time, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              border: Border.all(color: Colors.grey, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RECEIVED BY',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Name",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: receivedNameController,
                  onChanged: (value) {
                    Provider.of<PatientFormProvider>(context, listen: false)
                        .updateField('received_by_name', value);
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Digital Signature",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: SignatureField(
                      fieldName: "RECEIVED BY",
                      formValues: provider.patientDetails,
                      onChanged: (signature) {
                        Provider.of<PatientFormProvider>(context, listen: false)
                            .updateField('received_by_signature', signature);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Date', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              _pickDate('receivedDate');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Text(dateFormat.format(receivedDate)),
                                  const Spacer(),
                                  const Icon(Icons.calendar_today, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Time', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              _pickTime('receivedTime');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Text(receivedTime.format(context)),
                                  const Spacer(),
                                  const Icon(Icons.access_time, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}



// code without UI responsiveness
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
//
// import '../providers/patient_form_data.dart';
// import '../widgets/signature.dart';
//
// class SignOffPage extends StatefulWidget {
//   const SignOffPage({super.key});
//
//   @override
//   State<SignOffPage> createState() => _SignOffPageState();
// }
//
// class _SignOffPageState extends State<SignOffPage> {
//   final TextEditingController patientNameController = TextEditingController();
//   final TextEditingController patientIcController = TextEditingController();
//   final TextEditingController staffNameController = TextEditingController();
//   final TextEditingController staffIcController = TextEditingController();
//   final TextEditingController endorsedNameController = TextEditingController();
//   final TextEditingController receivedNameController = TextEditingController();
//
//   DateTime endorsedDate = DateTime.now();
//   TimeOfDay endorsedTime = TimeOfDay.now();
//   DateTime receivedDate = DateTime.now();
//   TimeOfDay receivedTime = TimeOfDay.now();
//
//   Map<String, bool> options = {
//     'REFERRAL LETTER': false,
//     'INVESTIGATION RESULT': false,
//     'IMAGING FILM/REPORT': false,
//     'AOR': false,
//   };
//
//   final dateFormat = DateFormat('dd-MM-yyyy');
//
//   @override
//   void initState() {
//     super.initState();
//     // Load existing data from the provider when the page is initialized
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _loadDataFromProvider();
//     });
//   }
//
//   void _loadDataFromProvider() {
//     final provider = Provider.of<PatientFormProvider>(context, listen: false);
//     final patientDetails = provider.patientDetails;
//
//     // Load text field data
//     patientNameController.text = patientDetails['patient_name'] ?? '';
//     patientIcController.text = patientDetails['patient_ic_no'] ?? '';
//     staffNameController.text = patientDetails['staff_name'] ?? '';
//     staffIcController.text = patientDetails['staff_ic_no'] ?? '';
//     endorsedNameController.text = patientDetails['endorsed_by_name'] ?? '';
//     receivedNameController.text = patientDetails['received_by_name'] ?? '';
//
//     // Load date and time data
//     String? endorsedDateString = patientDetails['endorsedDate'];
//     if (endorsedDateString != null) {
//       try {
//         endorsedDate = dateFormat.parse(endorsedDateString);
//       } catch (e) {
//         // Fallback to current date if parsing fails
//       }
//     }
//
//     String? endorsedTimeString = patientDetails['endorsedTime'];
//     if (endorsedTimeString != null) {
//       try {
//         final parsedTime = DateFormat.jm().parse(endorsedTimeString);
//         endorsedTime = TimeOfDay.fromDateTime(parsedTime);
//       } catch (e) {
//         // Fallback to current time if parsing fails
//       }
//     }
//
//     String? receivedDateString = patientDetails['receivedDate'];
//     if (receivedDateString != null) {
//       try {
//         receivedDate = dateFormat.parse(receivedDateString);
//       } catch (e) {
//         // Fallback to current date if parsing fails
//       }
//     }
//
//     String? receivedTimeString = patientDetails['receivedTime'];
//     if (receivedTimeString != null) {
//       try {
//         final parsedTime = DateFormat.jm().parse(receivedTimeString);
//         receivedTime = TimeOfDay.fromDateTime(parsedTime);
//       } catch (e) {
//         // Fallback to current time if parsing fails
//       }
//     }
//
//     // Load checkbox data
//     final savedDocuments = patientDetails['documents_provided'] as List<dynamic>?;
//     if (savedDocuments != null) {
//       setState(() {
//         options.forEach((key, value) {
//           options[key] = savedDocuments.contains(key);
//         });
//       });
//     }
//
//     setState(() {}); // Trigger a rebuild to update the UI with loaded data
//   }
//
//   Future<void> _pickDate(String label) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: label == 'endorsedDate' ? endorsedDate : receivedDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//     );
//
//     if (picked != null) {
//       setState(() {
//         if (label == 'endorsedDate') {
//           endorsedDate = picked;
//           Provider.of<PatientFormProvider>(context, listen: false)
//               .updateField('endorsedDate', DateFormat('dd-MM-yyyy').format(picked));
//         } else {
//           receivedDate = picked;
//           Provider.of<PatientFormProvider>(context, listen: false)
//               .updateField('receivedDate', DateFormat('dd-MM-yyyy').format(picked));
//         }
//       });
//     }
//   }
//
//   Future<void> _pickTime(String label) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: label == 'endorsedTime' ? endorsedTime : receivedTime,
//     );
//
//     if (picked != null) {
//       setState(() {
//         if (label == 'endorsedTime') {
//           endorsedTime = picked;
//           Provider.of<PatientFormProvider>(context, listen: false)
//               .updateField('endorsedTime', picked.format(context));
//         } else {
//           receivedTime = picked;
//           Provider.of<PatientFormProvider>(context, listen: false)
//               .updateField('receivedTime', picked.format(context));
//         }
//       });
//     }
//   }
//
//   Widget _buildCheckboxTile(String label) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         children: [
//           Checkbox(
//             value: options[label],
//             onChanged: (bool? value) {
//               setState(() {
//                 options[label] = value ?? false;
//                 final selectedDocuments = options.entries
//                     .where((e) => e.value)
//                     .map((e) => e.key)
//                     .toList();
//                 Provider.of<PatientFormProvider>(context, listen: false)
//                     .updateField('documents_provided', selectedDocuments);
//               });
//             },
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(4),
//             ),
//             side: BorderSide(color: Colors.red.shade800),
//             activeColor: Colors.red.shade800,
//             visualDensity: VisualDensity.compact,
//           ),
//           const SizedBox(width: 8),
//           Text(
//             label,
//             style: GoogleFonts.roboto(
//               fontSize: 15,
//               fontWeight: FontWeight.w500,
//               letterSpacing: 0.5,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     List<String> keys = options.keys.toList();
//     int mid = (keys.length / 2).ceil();
//     final provider = Provider.of<PatientFormProvider>(context);
//
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
//                   'DECLINED TREATMENT/TRANSPORT',
//                   style: GoogleFonts.poppins(
//                     fontSize: 20,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade100,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Text(
//                     "PATIENT: I hereby acknowledge the treatment(s) provided, and I understand the nature, purpose, risks, and alternatives explained to me.",
//                     style: GoogleFonts.poppins(
//                       color: Colors.grey.shade800,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 // Signature Area
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     border: Border.all(color: Colors.grey.shade300),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Patient Signature",
//                         style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
//                       ),
//                       const SizedBox(height: 12),
//                       Center(
//                         child: Container(
//                           width: 300,
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: SignatureField(
//                             fieldName: "Patient Signature",
//                             formValues: provider.patientDetails, // Pass the entire map
//                             onChanged: (signature) {
//                               Provider.of<PatientFormProvider>(context, listen: false)
//                                   .updateField('patient_signature', signature);
//                             },
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       Text(
//                         "Name",
//                         style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
//                       ),
//                       const SizedBox(height: 6),
//                       TextField(
//                         controller: patientNameController,
//                         onChanged: (value) {
//                           Provider.of<PatientFormProvider>(context, listen: false)
//                               .updateField('patient_name', value);
//                         },
//                         decoration: InputDecoration(
//                           filled: true,
//                           fillColor: Colors.grey.shade200,
//                           border: OutlineInputBorder(borderSide: BorderSide.none),
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       Text(
//                         "I/C Number",
//                         style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
//                       ),
//                       const SizedBox(height: 6),
//                       TextField(
//                         controller: patientIcController,
//                         onChanged: (value) {
//                           Provider.of<PatientFormProvider>(context, listen: false)
//                               .updateField('patient_ic_no', value);
//                         },
//                         decoration: InputDecoration(
//                           filled: true,
//                           fillColor: Colors.grey.shade200,
//                           border: OutlineInputBorder(borderSide: BorderSide.none),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade100,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Text(
//                     "STAFF: I confirmed that I have explained the situation to the patient in terms that in my judgement, they understand.",
//                     style: GoogleFonts.poppins(
//                       color: Colors.grey.shade800,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     border: Border.all(color: Colors.grey.shade300),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Staff Signature",
//                         style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
//                       ),
//                       const SizedBox(height: 12),
//                       Center(
//                         child: Container(
//                           width: 300,
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: SignatureField(
//                             fieldName: "Staff Signature",
//                             formValues: provider.patientDetails,
//                             onChanged: (signature) {
//                               Provider.of<PatientFormProvider>(context, listen: false)
//                                   .updateField('staff_signature', signature);
//                             },
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       Text(
//                         "Name",
//                         style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
//                       ),
//                       const SizedBox(height: 6),
//                       TextField(
//                         controller: staffNameController,
//                         onChanged: (value) {
//                           Provider.of<PatientFormProvider>(context, listen: false)
//                               .updateField('staff_name', value);
//                         },
//                         decoration: InputDecoration(
//                           filled: true,
//                           fillColor: Colors.grey.shade200,
//                           border: OutlineInputBorder(borderSide: BorderSide.none),
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       Text(
//                         "I/C Number",
//                         style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
//                       ),
//                       const SizedBox(height: 6),
//                       TextField(
//                         controller: staffIcController,
//                         onChanged: (value) {
//                           Provider.of<PatientFormProvider>(context, listen: false)
//                               .updateField('staff_ic_no', value);
//                         },
//                         decoration: InputDecoration(
//                           filled: true,
//                           fillColor: Colors.grey.shade200,
//                           border: OutlineInputBorder(borderSide: BorderSide.none),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   "Documents Provided",
//                   style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Expanded(
//                         child: Column(
//                           children: keys.sublist(0, mid).map((label) {
//                             return _buildCheckboxTile(label);
//                           }).toList(),
//                         ),
//                       ),
//                       const SizedBox(width: 30),
//                       Expanded(
//                         child: Column(
//                           children: keys.sublist(mid).map((label) {
//                             return _buildCheckboxTile(label);
//                           }).toList(),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 20),
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
//                   'ENDORSED BY',
//                   style: GoogleFonts.poppins(
//                     fontSize: 20,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   "Name",
//                   style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
//                 ),
//                 const SizedBox(height: 6),
//                 TextField(
//                   controller: endorsedNameController,
//                   onChanged: (value) {
//                     Provider.of<PatientFormProvider>(context, listen: false)
//                         .updateField('endorsed_by_name', value);
//                   },
//                   decoration: InputDecoration(
//                     filled: true,
//                     fillColor: Colors.grey.shade200,
//                     border: OutlineInputBorder(borderSide: BorderSide.none),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   "Digital Signature",
//                   style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
//                 ),
//                 const SizedBox(height: 12),
//                 Center(
//                   child: Container(
//                     width: 300,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: SignatureField(
//                       fieldName: "ENDORSED BY",
//                       formValues: provider.patientDetails,
//                       onChanged: (signature) {
//                         Provider.of<PatientFormProvider>(context, listen: false)
//                             .updateField('endorsed_by_signature', signature);
//                       },
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 Row(
//                   children: [
//                     // Date
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text('Date', style: TextStyle(fontWeight: FontWeight.w500)),
//                           const SizedBox(height: 8),
//                           GestureDetector(
//                             onTap: () {
//                               _pickDate('endorsedDate');
//                             },
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
//                               decoration: BoxDecoration(
//                                 color: Colors.grey.shade200,
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Row(
//                                 children: [
//                                   Text(dateFormat.format(endorsedDate)),
//                                   const Spacer(),
//                                   const Icon(Icons.calendar_today, size: 18),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(width: 20),
//                     // Time
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text('Time', style: TextStyle(fontWeight: FontWeight.w500)),
//                           const SizedBox(height: 8),
//                           GestureDetector(
//                             onTap: () {
//                               _pickTime('endorsedTime');
//                             },
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
//                               decoration: BoxDecoration(
//                                 color: Colors.grey.shade200,
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Row(
//                                 children: [
//                                   Text(endorsedTime.format(context)),
//                                   const Spacer(),
//                                   const Icon(Icons.access_time, size: 18),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 )
//               ],
//             ),
//           ),
//           const SizedBox(height: 20),
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
//                   'RECEIVED BY',
//                   style: GoogleFonts.poppins(
//                     fontSize: 20,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   "Name",
//                   style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
//                 ),
//                 const SizedBox(height: 6),
//                 TextField(
//                   controller: receivedNameController,
//                   onChanged: (value) {
//                     Provider.of<PatientFormProvider>(context, listen: false)
//                         .updateField('received_by_name', value);
//                   },
//                   decoration: InputDecoration(
//                     filled: true,
//                     fillColor: Colors.grey.shade200,
//                     border: OutlineInputBorder(borderSide: BorderSide.none),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   "Digital Signature",
//                   style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
//                 ),
//                 const SizedBox(height: 12),
//                 Center(
//                   child: Container(
//                     width: 300,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: SignatureField(
//                       fieldName: "RECEIVED BY",
//                       formValues: provider.patientDetails,
//                       onChanged: (signature) {
//                         Provider.of<PatientFormProvider>(context, listen: false)
//                             .updateField('received_by_signature', signature);
//                       },
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 Row(
//                   children: [
//                     // Date
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text('Date', style: TextStyle(fontWeight: FontWeight.w500)),
//                           const SizedBox(height: 8),
//                           GestureDetector(
//                             onTap: () {
//                               _pickDate('receivedDate');
//                             },
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
//                               decoration: BoxDecoration(
//                                 color: Colors.grey.shade200,
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Row(
//                                 children: [
//                                   Text(dateFormat.format(receivedDate)),
//                                   const Spacer(),
//                                   const Icon(Icons.calendar_today, size: 18),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(width: 20),
//                     // Time
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text('Time', style: TextStyle(fontWeight: FontWeight.w500)),
//                           const SizedBox(height: 8),
//                           GestureDetector(
//                             onTap: () {
//                               _pickTime('receivedTime');
//                             },
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
//                               decoration: BoxDecoration(
//                                 color: Colors.grey.shade200,
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Row(
//                                 children: [
//                                   Text(receivedTime.format(context)),
//                                   const Spacer(),
//                                   const Icon(Icons.access_time, size: 18),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 )
//               ],
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }