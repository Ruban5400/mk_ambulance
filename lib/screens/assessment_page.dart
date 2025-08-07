import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';

class AssessmentPage extends StatefulWidget {
  const AssessmentPage({super.key});

  @override
  State<AssessmentPage> createState() => _AssessmentPageState();
}

class _AssessmentPageState extends State<AssessmentPage> {
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

  Future<void> _saveSignatureImage() async {
    final controller = showFront ? frontController : backController;
    final Uint8List? data = await controller.toPngBytes();

    if (data != null) {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/${showFront ? 'front' : 'back'}_marked.png',
      );
      await file.writeAsBytes(data);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved to: ${file.path}')));
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
          ...controllers.map(
            (controller) => Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextFormField(
                  controller: controller,
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
            ),
          ),
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
                      Stack(
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
