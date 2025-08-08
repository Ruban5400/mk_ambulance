import 'dart:io';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import '../providers/patient_form_data.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'dart:io' if (dart.library.js_interop) 'dart:js_interop';
import 'package:painter/painter.dart'; // Assuming you're using this for the controller
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui; // For ui.Image

// Conditional import for the web APIs
import 'package:web/web.dart' as web;

class AssessmentPage extends StatefulWidget {
  const AssessmentPage({super.key});

  @override
  State<AssessmentPage> createState() => _AssessmentPageState();
}

class _AssessmentPageState extends State<AssessmentPage> {
  final GlobalKey _signatureBoundaryKey = GlobalKey();
  final SignatureController frontController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.red,
    exportBackgroundColor: Colors.transparent,
  );

  final SignatureController backController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.blue,
    exportBackgroundColor: Colors.transparent,
  );

  bool showFront = true;

  void toggleView() {
    setState(() => showFront = !showFront);
  }

  // saves file in web but without background
  //   Future<void> _saveSignatureImage() async {
  //     final controller = showFront ? frontController : backController;
  //     final Uint8List? data = await controller.toPngBytes();
  //     final fieldName = showFront ? 'front_side' : 'back_side';
  //
  //     if (data != null) {
  //       if (kIsWeb) {
  //         // --- Web-specific logic using package:web ---
  //
  //         // Create a Blob from the image bytes
  //         final blob = web.Blob([data] as JSArray<web.BlobPart>);
  //         // final blob = web.Blob([data.toJS] as JSArray<JSAny?>); // Use toJS() for interop
  //
  //         // Create a URL for the Blob
  //         final url = web.URL.createObjectURL(blob);
  //
  //         // Create a temporary anchor element to trigger the download
  //         final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  //         anchor.href = url;
  //         anchor.style.display = 'none';
  //         anchor.download = '${fieldName}_marked.png';
  //
  //         // Add the element to the DOM, click it, and then remove it
  //         web.document.body!.appendChild(anchor);
  //         anchor.click();
  //         anchor.remove();
  //
  //         // Revoke the URL to free up memory
  //         web.URL.revokeObjectURL(url);
  //
  //         // Pass the URL to your provider
  //         // You may need to change your provider's field type to String
  //         // to store this URL instead of a local File object.
  //         Provider.of<PatientFormProvider>(context, listen: false).updateField(fieldName, url);
  // print('5400 ---- $url');
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Image download initiated.')),
  //         );
  //       } else {
  //         // --- Mobile-specific logic (Android/iOS) ---
  //         final dir = await getApplicationDocumentsDirectory();
  //         final file = File('${dir.path}/${fieldName}_marked.png');
  //         await file.writeAsBytes(data);
  //
  //         Provider.of<PatientFormProvider>(context, listen: false).updateField(fieldName, file);
  //
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text('Saved to: ${file.path}')),
  //         );
  //       }
  //     }
  //   }

  Future<void> _saveSignatureImage() async {
    RenderRepaintBoundary boundary =
        _signatureBoundaryKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage();
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List? data = byteData?.buffer.asUint8List();

    final fieldName = showFront ? 'front_side' : 'back_side';

    if (data != null) {
      if (kIsWeb) {
        // Your existing web-specific logic remains the same, but using the new 'data'
        // final blob = web.Blob([data].toJS as web.JSArray<web.BlobPart>);
        final blob = web.Blob([data] as JSArray<web.BlobPart>);
        final url = web.URL.createObjectURL(blob);
        final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
        anchor.href = url;
        anchor.style.display = 'none';
        anchor.download = '${fieldName}_marked.png';
        web.document.body!.appendChild(anchor);
        anchor.click();
        anchor.remove();
        web.URL.revokeObjectURL(url);
        Provider.of<PatientFormProvider>(
          context,
          listen: false,
        ).updateField(fieldName, url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image download initiated.')),
        );
      } else {
        // Your existing mobile-specific logic remains the same
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/${fieldName}_marked.png');
        await file.writeAsBytes(data);
        Provider.of<PatientFormProvider>(
          context,
          listen: false,
        ).updateField(fieldName, file);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Saved to: ${file.path}')));
      }
    }
  }

  @override
  void dispose() {
    frontController.dispose();
    backController.dispose();
    super.dispose();
  }

  final DateFormat formatter = DateFormat('dd-MM-yyyy HH:mm');

  // Header columns
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
    for (var field in fieldNames) {
      fieldControllers[field] = List.generate(
        columns.length,
        (_) => TextEditingController(
          text: field == 'DATE/TIME' ? formatter.format(DateTime.now()) : '',
        ),
      );
    }
  }

  void addIntermediateColumn() {
    setState(() {
      columns.insert(columns.length - 1, 'Intermediate');
      for (var field in fieldNames) {
        fieldControllers[field]!.insert(
          columns.length - 2,
          TextEditingController(),
        );
      }
    });
  }

  // Widget buildFieldRow(String label, List<TextEditingController> controllers) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 8.0),
  //     child: Row(
  //       children: [
  //         // Field name
  //         Expanded(
  //           flex: 2,
  //           child: Text(
  //             label,
  //             style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
  //           ),
  //         ),
  //         const SizedBox(width: 8),
  //         // Dynamic columns
  //
  //         ...controllers.asMap().entries.map((entry) {
  //           int colIndex = entry.key;
  //           TextEditingController controller = entry.value;
  //             return Expanded(
  //               flex: 3,
  //               child: Padding(
  //                 padding: const EdgeInsets.symmetric(horizontal: 4),
  //                 child: TextFormField(
  //                   controller: fieldControllers[fieldNames]![colIndex],
  //                   onChanged: (value) {
  //                     Provider.of<PatientFormProvider>(context, listen: false)
  //                         .updateObservationField(
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
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget buildFieldRow(String label, List<TextEditingController> controllers) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Field name
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          // Dynamic columns
          ...controllers.asMap().entries.map((entry) {
            int colIndex = entry.key;
            TextEditingController controller = entry.value;
            return Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextFormField(
                  controller: controller, // <-- Corrected line
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
                  keyboardType:
                      [
                        'RESPIRATORY RATE',
                        'PULSE RATE',
                        'SPO2',
                        'BLOOD PRESSURE',
                        'BLOOD GLUCOSE',
                        'TEMPERATURE',
                        'PAIN SCORE',
                        'GCS',
                        'PUPIL SIZE (mm)',
                      ].contains(label.toUpperCase().trim())
                      ? TextInputType.number
                      : TextInputType.text,
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1000),
      child: Column(
        children: [
          Container(
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
                  'SIGN OF SYMPTOMS',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            showFront ? 'Front View' : 'Back View',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: toggleView,
                            icon: const Icon(Icons.flip),
                            label: Text(showFront ? "Show Back" : "Show Front"),
                          ),
                        ],
                      ),
                      RepaintBoundary(
                        key: _signatureBoundaryKey,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              showFront
                                  ? 'assets/images/front.png'
                                  : 'assets/images/back.png',
                              width: double.infinity,
                              height: 500,
                              fit: BoxFit.contain,
                            ),
                            Positioned.fill(
                              child: Signature(
                                controller: showFront
                                    ? frontController
                                    : backController,
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              (showFront ? frontController : backController)
                                  .clear();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Clear Drawing'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: _saveSignatureImage,
                            icon: const Icon(Icons.save),
                            label: const Text('Save Image'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              border: Border.all(color: Colors.grey, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'OBSERVATION',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                ),
                const SizedBox(height: 20),
                // Table header
                Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: SizedBox(),
                    ), // Empty space for labels
                    ...columns.asMap().entries.map((entry) {
                      int index = entry.key;
                      String col = entry.value;

                      return Expanded(
                        flex: 3,
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
                            if (col == 'Intermediate')
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
                      );
                    }),
                  ],
                ),
                const Divider(thickness: 1),
                // Rows
                for (var field in fieldNames)
                  buildFieldRow(field, fieldControllers[field]!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
