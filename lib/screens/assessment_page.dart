import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import '../providers/patient_form_data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

// Define a breakpoint for mobile vs. web/tablet layout
const double kMobileBreakpoint = 600.0;
// Define a constant for the width of each column in the observation table.
const double kObservationColumnWidth = 150.0;

class AssessmentPage extends StatefulWidget {
  const AssessmentPage({super.key});

  @override
  State<AssessmentPage> createState() => _AssessmentPageState();
}

class _AssessmentPageState extends State<AssessmentPage> {
  final GlobalKey _signatureBoundaryKeyFront = GlobalKey();
  final GlobalKey _signatureBoundaryKeyBack = GlobalKey();
  final GlobalKey<FormState> _observationsFormKey = GlobalKey<FormState>();

  late SignatureController frontController;
  late SignatureController backController;

  bool isFront = true;
  bool _isLoading = true;

  Future<void> _saveSignatureToProvider({required bool isFront}) async {
    RenderRepaintBoundary? boundary = isFront
        ? _signatureBoundaryKeyFront.currentContext!.findRenderObject() as RenderRepaintBoundary
        : _signatureBoundaryKeyBack.currentContext!.findRenderObject() as RenderRepaintBoundary;

    if (boundary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Signature boundary not found.'), backgroundColor: Colors.red),
      );
      return;
    }

    ui.Image image = await boundary.toImage();
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List? data = byteData?.buffer.asUint8List();

    final fieldName = isFront ? 'front_side' : 'back_side';

    if (data != null) {
      Provider.of<PatientFormProvider>(
        context,
        listen: false,
      ).updateField(fieldName, data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$fieldName image saved to form.'),backgroundColor: Colors.green,),
      );
    }
  }

  @override
  void dispose() {
    frontController.dispose();
    backController.dispose();
    super.dispose();
  }

  final DateFormat formatter = DateFormat('dd-MM-yyyy HH:mm');

  List<String> columns = ['Arrival', 'Handover'];
  Map<String, List<TextEditingController>> fieldControllers = {};

  final List<String> fieldNames = [
    'DATE/TIME',
    'RESPIRATORY RATE',
    'PULSE RATE',
    'SPO2',
    'BLOOD PRESSURE',
    'BLOOD GLUCOSE',
    'TEMPERATURE',
    'PAIN SCORE',
    'GCS',
    'PUPIL SIZE (mm)',
    'PUPIL REACTION',
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final provider = Provider.of<PatientFormProvider>(context, listen: false);
    final existingObservations = provider.observations;

    // Initialize controllers with either existing points or an empty list
    frontController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.red,
      exportBackgroundColor: Colors.transparent,
    );
    backController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.blue,
      exportBackgroundColor: Colors.transparent,
    );

    int maxColumns = 0;
    if (existingObservations.isNotEmpty) {
      final validLists = existingObservations.values.whereType<List>();
      if (validLists.isNotEmpty) {
        maxColumns = validLists
            .map((list) => list.length)
            .reduce((a, b) => a > b ? a : b);
      }
    }

    if (maxColumns > 0) {
      if (maxColumns > 2) {
        columns = [
          'Arrival',
          ...List.generate(maxColumns - 2, (index) => ' '),
          'Handover',
        ];
      } else {
        columns = ['Arrival', 'Handover'];
      }

      for (var field in fieldNames) {
        final savedValues = existingObservations[field] ?? [];
        fieldControllers[field] = List.generate(maxColumns, (colIndex) {
          final controller = TextEditingController();
          if (colIndex < savedValues.length) {
            controller.text = savedValues[colIndex];
          }
          return controller;
        });
      }
    } else {
      for (var field in fieldNames) {
        fieldControllers[field] = List.generate(
          columns.length,
              (_) => TextEditingController(
            text: field == 'DATE/TIME' ? formatter.format(DateTime.now()) : '',
          ),
        );
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  void addIntermediateColumn() {
    setState(() {
      columns.insert(columns.length - 1, ' ');
      for (var field in fieldNames) {
        fieldControllers[field]!.insert(
          columns.length - 2,
          TextEditingController(),
        );
      }
    });
  }

  // A helper function to build the row for a single field in the observation table.
  Widget buildFieldRow(String label, List<TextEditingController> controllers) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: kObservationColumnWidth,
            child: Text(
              label,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          ...controllers.asMap().entries.map((entry) {
            int colIndex = entry.key;
            TextEditingController controller = entry.value;

            // Determine validation and keyboard type based on the field label
            TextInputType keyboardType = TextInputType.text;
            List<TextInputFormatter> formatters = [];
            String? Function(String?)? validator;

            if (label == 'BLOOD PRESSURE') {
              keyboardType = TextInputType.number;
              formatters = [
                // Allows only digits and a single slash
                FilteringTextInputFormatter.allow(RegExp(r'^[0-9/]+$')),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  // Enforce only one slash
                  if (newValue.text.contains('/') && newValue.text.indexOf('/') != newValue.text.lastIndexOf('/')) {
                    return oldValue;
                  }
                  return newValue;
                }),
              ];
              validator = (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter BP in "__/__" format';
                }
                if (!RegExp(r'^\d+\/\d+$').hasMatch(value)) {
                  return 'Invalid format. Use numbers and a single slash.';
                }
                return null;
              };
            } else if ([
              'RESPIRATORY RATE',
              'PULSE RATE',
              'SPO2',
              'BLOOD GLUCOSE',
              'TEMPERATURE',
              'PAIN SCORE',
              'GCS',
              'PUPIL SIZE (mm)',
            ].contains(label.toUpperCase().trim())) {
              keyboardType = TextInputType.number;
              formatters = [
                FilteringTextInputFormatter.digitsOnly,
              ];
              validator = (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter a valid number';
                }
                return null;
              };
            }

            return SizedBox(
              width: kObservationColumnWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextFormField(
                  controller: controller,
                  onChanged: (value) {
                    Provider.of<PatientFormProvider>(
                      context,
                      listen: false,
                    ).updateObservationField(
                      fieldName: label,
                      index: colIndex,
                      value: value.trim(),
                    );
                  },
                  readOnly: label == 'DATE/TIME',
                  keyboardType: keyboardType,
                  inputFormatters: formatters,
                  validator: validator,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[200],
                    suffixText: label == 'SPO2'
                        ? '%'
                        : label == 'TEMPERATURE'
                        ? '°C'
                        : label == 'PAIN SCORE'
                        ? '/10'
                        : null,
                    suffixIcon: label == 'DATE/TIME'
                        ? IconButton(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      onPressed: () async {
                        final now = DateTime.now();
                        final date = await showDatePicker(
                          context: context,
                          initialDate: now,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(now),
                          );
                          if (time != null) {
                            final selected = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                            controller.text = formatter.format(selected);
                            Provider.of<PatientFormProvider>(
                              context,
                              listen: false,
                            ).updateObservationField(
                              fieldName: label,
                              index: colIndex,
                              value: controller.text,
                            );
                          }
                        }
                      },
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 10,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < kMobileBreakpoint) {
          return _buildMobileLayout();
        } else {
          return _buildWebLayout();
        }
      },
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildSymptomsContainer(
          children: [
            _buildHeader('SIGN OF SYMPTOMS', 20),
            const SizedBox(height: 16),
            _buildFrontView(),
            const SizedBox(height: 16),
            _buildBackView(),
          ],
        ),
        const SizedBox(height: 20),
        _buildObservationsContainer(
          children: [
            _buildObservationsHeader(),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildObservationsTable(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWebLayout() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1000),
      child: Column(
        children: [
          _buildSymptomsContainer(
            children: [
              _buildHeader('SIGN OF SYMPTOMS', 20),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildFrontView()),
                  const SizedBox(width: 10),
                  Expanded(child: _buildBackView()),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildObservationsContainer(
            children: [
              _buildObservationsHeader(),
              const SizedBox(height: 20),
              // The table on web/desktop now also has a horizontal scroll view.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildObservationsTable(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Reusable Sub-Widgets for both layouts ---

  Widget _buildHeader(String title, double size) {
    return Text(
      title,
      style: GoogleFonts.poppins(fontSize: size, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildSymptomsContainer({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
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

  Widget _buildFrontView() {
    final provider = Provider.of<PatientFormProvider>(context, listen: false);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            'Front View',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          if (provider.patientDetails['front_side'] != null) ...[
            Image.memory(
              provider.patientDetails['front_side'],
              fit: BoxFit.contain,
              height: 400,
            ),
          ] else ...[
            RepaintBoundary(
              key: _signatureBoundaryKeyFront,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/images/front.png',
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                  Positioned.fill(
                    child: Signature(
                      controller: frontController,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    provider.patientDetails['front_side'] = null;
                  });
                  frontController.clear();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Clear'),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _saveSignatureToProvider(isFront: true),
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackView() {
    final provider = Provider.of<PatientFormProvider>(context, listen: false);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            'Back View',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          if (provider.patientDetails['back_side'] != null) ...[
            Image.memory(
              provider.patientDetails['back_side'],
              fit: BoxFit.contain,
              height: 400,
            ),
          ] else ...[
            RepaintBoundary(
              key: _signatureBoundaryKeyBack,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/images/back.png',
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                  Positioned.fill(
                    child: Signature(
                      controller: backController,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    provider.patientDetails['back_side'] = null;
                  });
                  backController.clear();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Clear'),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _saveSignatureToProvider(isFront: false),
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildObservationsContainer({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
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

  Widget _buildObservationsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildHeader('OBSERVATION', 20),
        if (columns.length < 5)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: addIntermediateColumn,
            icon: const Icon(Icons.add),
            label: const Text('Add Intermediate'),
          ),
      ],
    );
  }

  Widget _buildObservationsTable() {
    // Calculate the total width of the table.
    final tableWidth = kObservationColumnWidth * (columns.length + 1) + (columns.length * 4); // plus padding
    return SizedBox(
      width: tableWidth,
      child: Form(
        key: _observationsFormKey,
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: kObservationColumnWidth),
                ...columns.asMap().entries.map((entry) {
                  int index = entry.key;
                  String col = entry.value;

                  return SizedBox(
                    width: kObservationColumnWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            col.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (col == ' ')
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              tooltip: 'Remove',
                              onPressed: () {
                                setState(() {
                                  columns.removeAt(index);
                                  for (var field in fieldNames) {
                                    fieldControllers[field]!.removeAt(index);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
            const Divider(thickness: 1),
            for (var field in fieldNames)
              buildFieldRow(field, fieldControllers[field]!),
          ],
        ),
      ),
    );
  }
}


// needs validation
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:signature/signature.dart';
// import '../providers/patient_form_data.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/rendering.dart';
// import 'dart:ui' as ui;
//
// // Define a breakpoint for mobile vs. web/tablet layout
// const double kMobileBreakpoint = 600.0;
// // Define a constant for the width of each column in the observation table.
// const double kObservationColumnWidth = 150.0;
//
// class AssessmentPage extends StatefulWidget {
//   const AssessmentPage({super.key});
//
//   @override
//   State<AssessmentPage> createState() => _AssessmentPageState();
// }
//
// class _AssessmentPageState extends State<AssessmentPage> {
//   final GlobalKey _signatureBoundaryKeyFront = GlobalKey();
//   final GlobalKey _signatureBoundaryKeyBack = GlobalKey();
//   late SignatureController frontController;
//   late SignatureController backController;
//
//   bool isFront = true;
//   bool _isLoading = true;
//
//   Future<void> _saveSignatureToProvider({required bool isFront}) async {
//     RenderRepaintBoundary boundary = isFront
//         ? _signatureBoundaryKeyFront.currentContext!.findRenderObject()
//     as RenderRepaintBoundary
//         : _signatureBoundaryKeyBack.currentContext!.findRenderObject()
//     as RenderRepaintBoundary;
//     ui.Image image = await boundary.toImage();
//     ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
//     final Uint8List? data = byteData?.buffer.asUint8List();
//
//     final fieldName = isFront ? 'front_side' : 'back_side';
//
//     if (data != null) {
//       Provider.of<PatientFormProvider>(
//         context,
//         listen: false,
//       ).updateField(fieldName, data);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('$fieldName image saved to form.'),backgroundColor: Colors.green,),
//       );
//     }
//   }
//
//   @override
//   void dispose() {
//     frontController.dispose();
//     backController.dispose();
//     super.dispose();
//   }
//
//   final DateFormat formatter = DateFormat('dd-MM-yyyy HH:mm');
//
//   List<String> columns = ['Arrival', 'Handover'];
//   Map<String, List<TextEditingController>> fieldControllers = {};
//
//   final List<String> fieldNames = [
//     'DATE/TIME',
//     'RESPIRATORY RATE',
//     'PULSE RATE',
//     'SPO2',
//     'BLOOD PRESSURE',
//     'BLOOD GLUCOSE',
//     'TEMPERATURE',
//     'PAIN SCORE',
//     'GCS',
//     'PUPIL SIZE (mm)',
//     'PUPIL REACTION',
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeData();
//   }
//
//   Future<void> _initializeData() async {
//     final provider = Provider.of<PatientFormProvider>(context, listen: false);
//     final existingObservations = provider.observations;
//
//     // Initialize controllers with either existing points or an empty list
//     frontController = SignatureController(
//       penStrokeWidth: 3,
//       penColor: Colors.red,
//       exportBackgroundColor: Colors.transparent,
//     );
//     backController = SignatureController(
//       penStrokeWidth: 3,
//       penColor: Colors.blue,
//       exportBackgroundColor: Colors.transparent,
//     );
//
//     int maxColumns = 0;
//     if (existingObservations.isNotEmpty) {
//       final validLists = existingObservations.values.whereType<List>();
//       if (validLists.isNotEmpty) {
//         maxColumns = validLists
//             .map((list) => list.length)
//             .reduce((a, b) => a > b ? a : b);
//       }
//     }
//
//     if (maxColumns > 0) {
//       if (maxColumns > 2) {
//         columns = [
//           'Arrival',
//           ...List.generate(maxColumns - 2, (index) => ' '),
//           'Handover',
//         ];
//       } else {
//         columns = ['Arrival', 'Handover'];
//       }
//
//       for (var field in fieldNames) {
//         final savedValues = existingObservations[field] ?? [];
//         fieldControllers[field] = List.generate(maxColumns, (colIndex) {
//           final controller = TextEditingController();
//           if (colIndex < savedValues.length) {
//             controller.text = savedValues[colIndex];
//           }
//           return controller;
//         });
//       }
//     } else {
//       for (var field in fieldNames) {
//         fieldControllers[field] = List.generate(
//           columns.length,
//               (_) => TextEditingController(
//             text: field == 'DATE/TIME' ? formatter.format(DateTime.now()) : '',
//           ),
//         );
//       }
//     }
//     setState(() {
//       _isLoading = false;
//     });
//   }
//
//   void addIntermediateColumn() {
//     setState(() {
//       columns.insert(columns.length - 1, ' ');
//       for (var field in fieldNames) {
//         fieldControllers[field]!.insert(
//           columns.length - 2,
//           TextEditingController(),
//         );
//       }
//     });
//   }
//
//   // A helper function to build the row for a single field in the observation table.
//   Widget buildFieldRow(String label, List<TextEditingController> controllers) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         children: [
//           SizedBox(
//             width: kObservationColumnWidth,
//             child: Text(
//               label,
//               style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
//             ),
//           ),
//           const SizedBox(width: 8),
//           ...controllers.asMap().entries.map((entry) {
//             int colIndex = entry.key;
//             TextEditingController controller = entry.value;
//             return SizedBox(
//               width: kObservationColumnWidth,
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 4),
//                 child: TextFormField(
//                   controller: controller,
//                   onChanged: (value) {
//                     Provider.of<PatientFormProvider>(
//                       context,
//                       listen: false,
//                     ).updateObservationField(
//                       fieldName: label,
//                       index: colIndex,
//                       value: value.trim(),
//                     );
//                   },
//                   readOnly: label == 'DATE/TIME',
//                   keyboardType:
//                   [
//                     'RESPIRATORY RATE',
//                     'PULSE RATE',
//                     'SPO2',
//                     'BLOOD PRESSURE',
//                     'BLOOD GLUCOSE',
//                     'TEMPERATURE',
//                     'PAIN SCORE',
//                     'GCS',
//                     'PUPIL SIZE (mm)',
//                   ].contains(label.toUpperCase().trim())
//                       ? TextInputType.number
//                       : TextInputType.text,
//                   decoration: InputDecoration(
//                     filled: true,
//                     fillColor: Colors.grey[200],
//                     suffixText: label == 'SPO2'
//                         ? '%'
//                         : label == 'TEMPERATURE'
//                         ? '°C'
//                         : label == 'PAIN SCORE'
//                         ? '/10'
//                         : null,
//                     suffixIcon: label == 'DATE/TIME'
//                         ? IconButton(
//                       icon: const Icon(Icons.calendar_today, size: 16),
//                       onPressed: () async {
//                         final now = DateTime.now();
//                         final date = await showDatePicker(
//                           context: context,
//                           initialDate: now,
//                           firstDate: DateTime(2000),
//                           lastDate: DateTime(2100),
//                         );
//                         if (date != null) {
//                           final time = await showTimePicker(
//                             context: context,
//                             initialTime: TimeOfDay.fromDateTime(now),
//                           );
//                           if (time != null) {
//                             final selected = DateTime(
//                               date.year,
//                               date.month,
//                               date.day,
//                               time.hour,
//                               time.minute,
//                             );
//                             controller.text = formatter.format(selected);
//                             Provider.of<PatientFormProvider>(
//                               context,
//                               listen: false,
//                             ).updateObservationField(
//                               fieldName: label,
//                               index: colIndex,
//                               value: controller.text,
//                             );
//                           }
//                         }
//                       },
//                     )
//                         : null,
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(6.0),
//                       borderSide: BorderSide.none,
//                     ),
//                     contentPadding: const EdgeInsets.symmetric(
//                       vertical: 12,
//                       horizontal: 10,
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           }),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }
//
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         if (constraints.maxWidth < kMobileBreakpoint) {
//           return _buildMobileLayout();
//         } else {
//           return _buildWebLayout();
//         }
//       },
//     );
//   }
//
//   Widget _buildMobileLayout() {
//     return Column(
//       children: [
//         _buildSymptomsContainer(
//           children: [
//             _buildHeader('SIGN OF SYMPTOMS', 20),
//             const SizedBox(height: 16),
//             _buildFrontView(),
//             const SizedBox(height: 16),
//             _buildBackView(),
//           ],
//         ),
//         const SizedBox(height: 20),
//         _buildObservationsContainer(
//           children: [
//             _buildObservationsHeader(),
//             const SizedBox(height: 16),
//             SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: _buildObservationsTable(),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Widget _buildWebLayout() {
//     return ConstrainedBox(
//       constraints: const BoxConstraints(maxWidth: 1000),
//       child: Column(
//         children: [
//           _buildSymptomsContainer(
//             children: [
//               _buildHeader('SIGN OF SYMPTOMS', 20),
//               const SizedBox(height: 20),
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Expanded(child: _buildFrontView()),
//                   const SizedBox(width: 10),
//                   Expanded(child: _buildBackView()),
//                 ],
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           _buildObservationsContainer(
//             children: [
//               _buildObservationsHeader(),
//               const SizedBox(height: 20),
//               // The table on web/desktop now also has a horizontal scroll view.
//               SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: _buildObservationsTable(),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   // --- Reusable Sub-Widgets for both layouts ---
//
//   Widget _buildHeader(String title, double size) {
//     return Text(
//       title,
//       style: GoogleFonts.poppins(fontSize: size, fontWeight: FontWeight.w600),
//     );
//   }
//
//   Widget _buildSymptomsContainer({required List<Widget> children}) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
//       decoration: BoxDecoration(
//         borderRadius: const BorderRadius.all(Radius.circular(10)),
//         border: Border.all(color: Colors.grey, width: 1.0),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: children,
//       ),
//     );
//   }
//
//   Widget _buildFrontView() {
//     final provider = Provider.of<PatientFormProvider>(context, listen: false);
//     return Container(
//       padding: const EdgeInsets.all(15),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade400),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Column(
//         children: [
//           Text(
//             'Front View',
//             style: GoogleFonts.poppins(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const SizedBox(height: 10),
//           if (provider.patientDetails['front_side'] != null) ...[
//             Image.memory(
//               provider.patientDetails['front_side'],
//               fit: BoxFit.contain,
//               height: 400,
//             ),
//           ] else ...[
//             RepaintBoundary(
//               key: _signatureBoundaryKeyFront,
//               child: Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   Image.asset(
//                     'assets/images/front.png',
//                     width: double.infinity,
//                     height: 300,
//                     fit: BoxFit.contain,
//                   ),
//                   Positioned.fill(
//                     child: Signature(
//                       controller: frontController,
//                       backgroundColor: Colors.transparent,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//           const SizedBox(height: 10),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               ElevatedButton.icon(
//                 onPressed: () {
//                   setState(() {
//                     provider.patientDetails['front_side'] = null;
//                   });
//                   frontController.clear();
//                 },
//                 icon: const Icon(Icons.refresh),
//                 label: const Text('Clear'),
//               ),
//               const SizedBox(width: 10),
//               ElevatedButton.icon(
//                 onPressed: () => _saveSignatureToProvider(isFront: true),
//                 icon: const Icon(Icons.save),
//                 label: const Text('Save'),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildBackView() {
//     final provider = Provider.of<PatientFormProvider>(context, listen: false);
//     return Container(
//       padding: const EdgeInsets.all(15),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade400),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Column(
//         children: [
//           Text(
//             'Back View',
//             style: GoogleFonts.poppins(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const SizedBox(height: 10),
//           if (provider.patientDetails['back_side'] != null) ...[
//             Image.memory(
//               provider.patientDetails['back_side'],
//               fit: BoxFit.contain,
//               height: 400,
//             ),
//           ] else ...[
//             RepaintBoundary(
//               key: _signatureBoundaryKeyBack,
//               child: Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   Image.asset(
//                     'assets/images/back.png',
//                     width: double.infinity,
//                     height: 300,
//                     fit: BoxFit.contain,
//                   ),
//                   Positioned.fill(
//                     child: Signature(
//                       controller: backController,
//                       backgroundColor: Colors.transparent,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//           const SizedBox(height: 10),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               ElevatedButton.icon(
//                 onPressed: () {
//                   setState(() {
//                     provider.patientDetails['back_side'] = null;
//                   });
//                   backController.clear();
//                 },
//                 icon: const Icon(Icons.refresh),
//                 label: const Text('Clear'),
//               ),
//               const SizedBox(width: 10),
//               ElevatedButton.icon(
//                 onPressed: () => _saveSignatureToProvider(isFront: false),
//                 icon: const Icon(Icons.save),
//                 label: const Text('Save'),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildObservationsContainer({required List<Widget> children}) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
//       decoration: BoxDecoration(
//         borderRadius: const BorderRadius.all(Radius.circular(10)),
//         border: Border.all(color: Colors.grey, width: 1.0),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: children,
//       ),
//     );
//   }
//
//   Widget _buildObservationsHeader() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         _buildHeader('OBSERVATION', 20),
//         if (columns.length < 5)
//           ElevatedButton.icon(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red.shade700,
//               foregroundColor: Colors.white,
//             ),
//             onPressed: addIntermediateColumn,
//             icon: const Icon(Icons.add),
//             label: const Text('Add Intermediate'),
//           ),
//       ],
//     );
//   }
//
//   Widget _buildObservationsTable() {
//     // Calculate the total width of the table.
//     final tableWidth = kObservationColumnWidth * (columns.length + 1) + (columns.length * 4); // plus padding
//     return SizedBox(
//       width: tableWidth,
//       child: Column(
//         children: [
//           Row(
//             children: [
//               const SizedBox(width: kObservationColumnWidth),
//               ...columns.asMap().entries.map((entry) {
//                 int index = entry.key;
//                 String col = entry.value;
//
//                 return SizedBox(
//                   width: kObservationColumnWidth,
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 4),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           col.toUpperCase(),
//                           style: GoogleFonts.poppins(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 14,
//                           ),
//                         ),
//                         if (col == ' ')
//                           IconButton(
//                             icon: const Icon(Icons.close, size: 18),
//                             tooltip: 'Remove',
//                             onPressed: () {
//                               setState(() {
//                                 columns.removeAt(index);
//                                 for (var field in fieldNames) {
//                                   fieldControllers[field]!.removeAt(index);
//                                 }
//                               });
//                             },
//                           ),
//                       ],
//                     ),
//                   ),
//                 );
//               }),
//             ],
//           ),
//           const Divider(thickness: 1),
//           for (var field in fieldNames)
//             buildFieldRow(field, fieldControllers[field]!),
//         ],
//       ),
//     );
//   }
// }




//  UI without responsiveness
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:signature/signature.dart';
// import '../providers/patient_form_data.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/rendering.dart';
// import 'dart:ui' as ui;
//
// class AssessmentPage extends StatefulWidget {
//   const AssessmentPage({super.key});
//
//   @override
//   State<AssessmentPage> createState() => _AssessmentPageState();
// }
//
// class _AssessmentPageState extends State<AssessmentPage> {
//   final GlobalKey _signatureBoundaryKeyFront = GlobalKey();
//   final GlobalKey _signatureBoundaryKeyBack = GlobalKey();
//   // Changed to 'late' to allow deferred initialization with provider data
//   late SignatureController frontController;
//   late SignatureController backController;
//
//   bool isFront = true;
//   bool _isLoading = true;
//
//   Future<void> _saveSignatureToProvider({required bool isFront}) async {
//     RenderRepaintBoundary boundary = isFront
//         ? _signatureBoundaryKeyFront.currentContext!.findRenderObject()
//               as RenderRepaintBoundary
//         : _signatureBoundaryKeyBack.currentContext!.findRenderObject()
//               as RenderRepaintBoundary;
//     ui.Image image = await boundary.toImage();
//     ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
//     final Uint8List? data = byteData?.buffer.asUint8List();
//
//     final fieldName = isFront ? 'front_side' : 'back_side';
//
//     if (data != null) {
//       Provider.of<PatientFormProvider>(
//         context,
//         listen: false,
//       ).updateField(fieldName, data);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('$fieldName image saved to form.')),
//       );
//     }
//   }
//
//   @override
//   void dispose() {
//     frontController.dispose();
//     backController.dispose();
//     super.dispose();
//   }
//
//   final DateFormat formatter = DateFormat('dd-MM-yyyy HH:mm');
//
//   List<String> columns = ['Arrival', 'Handover'];
//   Map<String, List<TextEditingController>> fieldControllers = {};
//
//   final List<String> fieldNames = [
//     'DATE/TIME',
//     'RESPIRATORY RATE',
//     'PULSE RATE',
//     'SPO2',
//     'BLOOD PRESSURE',
//     'BLOOD GLUCOSE',
//     'TEMPERATURE',
//     'PAIN SCORE',
//     'GCS',
//     'PUPIL SIZE (mm)',
//     'PUPIL REACTION',
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeData();
//   }
//
//   Future<void> _initializeData() async {
//     final provider = Provider.of<PatientFormProvider>(context, listen: false);
//     final existingObservations = provider.observations;
//
//     // Initialize controllers with either existing points or an empty list
//     frontController = SignatureController(
//       penStrokeWidth: 3,
//       penColor: Colors.red,
//       exportBackgroundColor: Colors.transparent,
//       // points: existingFrontPoints ?? [],
//     );
//     backController = SignatureController(
//       penStrokeWidth: 3,
//       penColor: Colors.blue,
//       exportBackgroundColor: Colors.transparent,
//       // points: existingBackPoints ?? [],
//     );
//
//     int maxColumns = 0;
//     if (existingObservations.isNotEmpty) {
//       final validLists = existingObservations.values.whereType<List>();
//       if (validLists.isNotEmpty) {
//         maxColumns = validLists
//             .map((list) => list.length)
//             .reduce((a, b) => a > b ? a : b);
//       }
//     }
//
//     if (maxColumns > 0) {
//       if (maxColumns > 2) {
//         columns = [
//           'Arrival',
//           ...List.generate(maxColumns - 2, (index) => 'Intermediate'),
//           'Handover',
//         ];
//       } else {
//         columns = ['Arrival', 'Handover'];
//       }
//
//       for (var field in fieldNames) {
//         final savedValues = existingObservations[field] ?? [];
//         fieldControllers[field] = List.generate(maxColumns, (colIndex) {
//           final controller = TextEditingController();
//           if (colIndex < savedValues.length) {
//             controller.text = savedValues[colIndex];
//           }
//           return controller;
//         });
//       }
//     } else {
//       for (var field in fieldNames) {
//         fieldControllers[field] = List.generate(
//           columns.length,
//           (_) => TextEditingController(
//             text: field == 'DATE/TIME' ? formatter.format(DateTime.now()) : '',
//           ),
//         );
//       }
//     }
//     setState(() {
//       _isLoading = false;
//     });
//   }
//
//   void addIntermediateColumn() {
//     setState(() {
//       columns.insert(columns.length - 1, 'Intermediate');
//       for (var field in fieldNames) {
//         fieldControllers[field]!.insert(
//           columns.length - 2,
//           TextEditingController(),
//         );
//       }
//     });
//   }
//
//   Widget buildFieldRow(String label, List<TextEditingController> controllers) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         children: [
//           Expanded(
//             flex: 2,
//             child: Text(
//               label,
//               style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
//             ),
//           ),
//           const SizedBox(width: 8),
//           ...controllers.asMap().entries.map((entry) {
//             int colIndex = entry.key;
//             TextEditingController controller = entry.value;
//             return Expanded(
//               flex: 3,
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 4),
//                 child: TextFormField(
//                   controller: controller,
//                   onChanged: (value) {
//                     Provider.of<PatientFormProvider>(
//                       context,
//                       listen: false,
//                     ).updateObservationField(
//                       fieldName: label,
//                       index: colIndex,
//                       value: value.trim(),
//                     );
//                   },
//                   readOnly: label == 'DATE/TIME',
//                   keyboardType:
//                       [
//                         'RESPIRATORY RATE',
//                         'PULSE RATE',
//                         'SPO2',
//                         'BLOOD PRESSURE',
//                         'BLOOD GLUCOSE',
//                         'TEMPERATURE',
//                         'PAIN SCORE',
//                         'GCS',
//                         'PUPIL SIZE (mm)',
//                       ].contains(label.toUpperCase().trim())
//                       ? TextInputType.number
//                       : TextInputType.text,
//                   decoration: InputDecoration(
//                     filled: true,
//                     fillColor: Colors.grey[200],
//                     suffixText: label == 'SPO2'
//                         ? '%'
//                         : label == 'TEMPERATURE'
//                         ? '°C'
//                         : label == 'PAIN SCORE'
//                         ? '/10'
//                         : null,
//                     suffixIcon: label == 'DATE/TIME'
//                         ? IconButton(
//                             icon: const Icon(Icons.calendar_today, size: 16),
//                             onPressed: () async {
//                               final now = DateTime.now();
//                               final date = await showDatePicker(
//                                 context: context,
//                                 initialDate: now,
//                                 firstDate: DateTime(2000),
//                                 lastDate: DateTime(2100),
//                               );
//                               if (date != null) {
//                                 final time = await showTimePicker(
//                                   context: context,
//                                   initialTime: TimeOfDay.fromDateTime(now),
//                                 );
//                                 if (time != null) {
//                                   final selected = DateTime(
//                                     date.year,
//                                     date.month,
//                                     date.day,
//                                     time.hour,
//                                     time.minute,
//                                   );
//                                   controller.text = formatter.format(selected);
//                                   Provider.of<PatientFormProvider>(
//                                     context,
//                                     listen: false,
//                                   ).updateObservationField(
//                                     fieldName: label,
//                                     index: colIndex,
//                                     value: controller.text,
//                                   );
//                                 }
//                               }
//                             },
//                           )
//                         : null,
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(6.0),
//                       borderSide: BorderSide.none,
//                     ),
//                     contentPadding: const EdgeInsets.symmetric(
//                       vertical: 12,
//                       horizontal: 10,
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           }),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<PatientFormProvider>(context, listen: false);
//     if (_isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }
//
//     return ConstrainedBox(
//       constraints: const BoxConstraints(maxWidth: 1000),
//       child: Column(
//         children: [
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
//             decoration: BoxDecoration(
//               borderRadius: const BorderRadius.all(Radius.circular(10)),
//               border: Border.all(color: Colors.grey, width: 1.0),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'SIGN OF SYMPTOMS',
//                   style: GoogleFonts.poppins(
//                     fontSize: 20,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // FRONT VIEW
//                     Expanded(
//                       child: Container(
//                         padding: const EdgeInsets.all(15),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey.shade400),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Column(
//                           children: [
//                             Text(
//                               'Front View',
//                               style: GoogleFonts.poppins(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                             const SizedBox(height: 10),
//                             if (provider.patientDetails['front_side'] !=
//                                 null) ...[
//                               Image.memory(
//                                 provider.patientDetails['front_side'],
//                                 fit: BoxFit.contain,
//                                 height: 400,
//                               ),
//                             ] else ...[
//                               RepaintBoundary(
//                                 key: _signatureBoundaryKeyFront,
//                                 child: Stack(
//                                   alignment: Alignment.center,
//                                   children: [
//                                     Image.asset(
//                                       'assets/images/front.png',
//                                       width: double.infinity,
//                                       height: 300,
//                                       fit: BoxFit.contain,
//                                     ),
//                                     Positioned.fill(
//                                       child: Signature(
//                                         controller: frontController,
//                                         backgroundColor: Colors.transparent,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                             const SizedBox(height: 10),
//                             Row(
//                               children: [
//                                 ElevatedButton.icon(
//                                   onPressed: () {
//                                     setState(() {
//                                       provider.patientDetails['front_side'] =
//                                       null;
//                                     });
//
//                                     frontController.clear();
//                                   },
//                                   icon: const Icon(Icons.refresh),
//                                   label: const Text('Clear'),
//                                 ),
//                                 const SizedBox(width: 10),
//                                 ElevatedButton.icon(
//                                   onPressed: () =>
//                                       _saveSignatureToProvider(isFront: true),
//                                   icon: const Icon(Icons.save),
//                                   label: const Text('Save'),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//
//                     // BACK VIEW
//                     Expanded(
//                       child: Container(
//                         padding: const EdgeInsets.all(15),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey.shade400),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Column(
//                           children: [
//                             Text(
//                               'Back View',
//                               style: GoogleFonts.poppins(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                             const SizedBox(height: 10),
//                             if (provider.patientDetails['back_side'] !=
//                                 null) ...[
//                               Image.memory(
//                                 provider.patientDetails['back_side'],
//                                 fit: BoxFit.contain,
//                                 height: 400,
//                               ),
//                             ] else ...[
//                               RepaintBoundary(
//                                 key: _signatureBoundaryKeyBack,
//                                 child: Stack(
//                                   alignment: Alignment.center,
//                                   children: [
//                                     Image.asset(
//                                       'assets/images/back.png',
//                                       width: double.infinity,
//                                       height: 300,
//                                       fit: BoxFit.contain,
//                                     ),
//                                     Positioned.fill(
//                                       child: Signature(
//                                         controller: backController,
//                                         backgroundColor: Colors.transparent,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                             const SizedBox(height: 10),
//                             Row(
//                               children: [
//                                 ElevatedButton.icon(
//                                   onPressed: () {
//                                     setState(() {
//                                       provider.patientDetails['back_side'] =
//                                       null;
//                                     });
//
//                                     backController.clear();
//                                   },
//                                   icon: const Icon(Icons.refresh),
//                                   label: const Text('Clear'),
//                                 ),
//                                 const SizedBox(width: 10),
//                                 ElevatedButton.icon(
//                                   onPressed: () =>
//                                       _saveSignatureToProvider(isFront: false),
//                                   icon: const Icon(Icons.save),
//                                   label: const Text('Save'),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//
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
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'OBSERVATION',
//                       style: GoogleFonts.poppins(
//                         fontSize: 20,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     if (columns.length < 5)
//                       ElevatedButton.icon(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.red.shade700,
//                           foregroundColor: Colors.white,
//                         ),
//                         onPressed: addIntermediateColumn,
//                         icon: const Icon(Icons.add),
//                         label: const Text('Add Intermediate'),
//                       ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//                 Row(
//                   children: [
//                     const Expanded(flex: 2, child: SizedBox()),
//                     ...columns.asMap().entries.map((entry) {
//                       int index = entry.key;
//                       String col = entry.value;
//
//                       return Expanded(
//                         flex: 3,
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               col.toUpperCase(),
//                               style: GoogleFonts.poppins(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 14,
//                               ),
//                             ),
//                             if (col == 'Intermediate')
//                               IconButton(
//                                 icon: const Icon(Icons.close, size: 18),
//                                 tooltip: 'Remove',
//                                 onPressed: () {
//                                   setState(() {
//                                     columns.removeAt(index);
//                                     for (var field in fieldNames) {
//                                       fieldControllers[field]!.removeAt(index);
//                                     }
//                                   });
//                                 },
//                               ),
//                           ],
//                         ),
//                       );
//                     }),
//                   ],
//                 ),
//                 const Divider(thickness: 1),
//                 for (var field in fieldNames)
//                   buildFieldRow(field, fieldControllers[field]!),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
