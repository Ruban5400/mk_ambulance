import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AssessmentPage extends StatefulWidget {
  const AssessmentPage({super.key});

  @override
  State<AssessmentPage> createState() => _AssessmentPageState();
}

class _AssessmentPageState extends State<AssessmentPage> {
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
    'PUPIL REACTION'
  ];

  @override
  void initState() {
    super.initState();
    for (var field in fieldNames) {
      fieldControllers[field] = List.generate(columns.length, (_) => TextEditingController(
        text: field == 'DATE/TIME' ? formatter.format(DateTime.now()) : '',
      ));
    }
  }

  void addIntermediateColumn() {
    setState(() {
      columns.insert(columns.length - 1, 'Intermediate');
      for (var field in fieldNames) {
        fieldControllers[field]!.insert(columns.length - 2, TextEditingController());
      }
    });
  }

  @override
  void dispose() {
    for (var controllerList in fieldControllers.values) {
      for (var controller in controllerList) {
        controller.dispose();
      }
    }
    super.dispose();
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
                  keyboardType: [
                    'RESPIRATORY RATE',
                    'PULSE RATE',
                    'SPO2',
                    'BLOOD PRESSURE',
                    'BLOOD GLUCOSE',
                    'TEMPERATURE',
                    'PAIN SCORE',
                    'GCS',
                    'PUPIL SIZE (mm)'
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
                            final selected = DateTime(date.year, date.month, date.day, time.hour, time.minute);
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
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
                      const Expanded(flex: 2, child: SizedBox()), // Empty space for labels
                      ...columns.asMap().entries.map(
                            (entry) {
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
                        },
                      )

                    ],
                  ),
                  const Divider(thickness: 1),
                  // Rows
                  for (var field in fieldNames) buildFieldRow(field, fieldControllers[field]!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
