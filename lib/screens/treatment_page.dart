import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/patient_form_data.dart';

class TreatmentPage extends StatefulWidget {
  const TreatmentPage({super.key});

  @override
  State<TreatmentPage> createState() => _TreatmentPageState();
}

class _TreatmentPageState extends State<TreatmentPage> {

  final Map<String, bool> treatmentOptions = {
    'NO TREATMENT / ADVICE ONLY GIVEN': false,
    'REST-ICE-COMPRESS-ELEVATE': false,
    'SPLIT': false,
    'AIRWAY SUCTION': false,
    'NEUROLOGICAL TEST': false,
    'OTHER TREATMENT': false,
    'WOUND CLEANSED': false,
    'FRACTURE SUPPORT': false,
    'C-SPINE CONTROL (IMMOBILISATION)': false,
    'AIRWAY INSERTED (TYPE/SIZE)': false,
    'HEAD INJURY ADVICE GIVEN': false,
  };

  final Map<String, bool> handlingOptions = {
    'WALKED UNAIDED': false,
    'CHAIR': false,
    'LONGBOARD': false,
    'OTHER': false,
    'SCOOP': false,
    'WALKED AIDED': false,
    'STRETCHER': false,
  };

  String? conditionStatus = 'Unchanged';
  final TextEditingController generalConditionController = TextEditingController();
  final TextEditingController bpController = TextEditingController();
  final TextEditingController rrController = TextEditingController();
  final TextEditingController spo2Controller = TextEditingController();
  final TextEditingController temperatureController = TextEditingController();
  final TextEditingController glucoseController = TextEditingController();
  final TextEditingController painScoreController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool deathChecked = false;
  bool othersChecked = false;

  Widget _buildCheckboxList(String title, Map<String, bool> options) {
    final entries = options.entries.toList();
    final half = (entries.length / 2).ceil();
    final leftColumn = entries.sublist(0, half);
    final rightColumn = entries.sublist(half);

    Widget buildColumn(List<MapEntry<String, bool>> items) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((entry) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: entry.value,
                onChanged: (value) {
                  setState(() {
                    options[entry.key] = value!;

                    // Only collect keys where the value is true
                    final selectedOptions = options.entries
                        .where((e) => e.value == true)
                        .map((e) => e.key)
                        .toList();

                    // Update only if true
                    Provider.of<PatientFormProvider>(context, listen: false)
                        .updateField(title, selectedOptions);
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                activeColor: Colors.red.shade800,
              ),
              Flexible(
                child: Text(entry.key, style: GoogleFonts.roboto(fontSize: 14)),
              ),
            ],
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
          Text(title,
              style: GoogleFonts.roboto(
                  fontSize: 18, fontWeight: FontWeight.bold)),
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

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.roboto(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: (value){
            Provider.of<PatientFormProvider>(context, listen: false)
                .updateField(label, value.trim());
          },
          maxLines: maxLines,
          keyboardType: [
            'General Condition',
            'Other Patient Progress/ Remarks',
          ].contains(label.toUpperCase().trim())
              ? TextInputType.text
              : TextInputType.number,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("ACKNOWLEDGEMENT ON PATIENT ARRIVAL AT TRANSFERRED FACILITY",
              style: GoogleFonts.roboto(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildTextField("General Condition", generalConditionController, maxLines: 3),
          Row(
            children: [
              Expanded(child: _buildTextField("BP (mmHg)", bpController)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Condition Status",
                        style: GoogleFonts.roboto(fontWeight: FontWeight.w500)),
                    Row(
                      children: ['Improved', 'Deteriorated', 'Unchanged'].map((status) {
                        return Row(
                          children: [
                            Radio<String>(
                              value: status,
                              groupValue: conditionStatus,
                              onChanged: (val) {
                                setState(() => conditionStatus = val);
                                Provider.of<PatientFormProvider>(context, listen: false)
                                    .updateField("Condition Status", val);
                              },
                              activeColor: Colors.red.shade800,
                            ),
                            Text(status),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildTextField("RR (min)", rrController)),
              const SizedBox(width: 20),
              Expanded(child: _buildTextField("Temperature (°C)", temperatureController)),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildTextField("SPO2 (%)", spo2Controller)),
              const SizedBox(width: 20),
              Expanded(child: _buildTextField("Glucose (mmol/L)", glucoseController)),
            ],
          ),
          Row(
            children: [
              Checkbox(
                value: deathChecked,
                onChanged: (val) {
                  setState(() => deathChecked = val!);
                  Provider.of<PatientFormProvider>(context, listen: false)
                      .updateField("Death", val);
                },
                activeColor: Colors.red.shade800,
              ),
              const Text("Death"),
              const SizedBox(width: 20),
              Checkbox(
                value: othersChecked,
                onChanged: (val) {
                  setState(() => othersChecked = val!);
                  Provider.of<PatientFormProvider>(context, listen: false)
                      .updateField("Others", val);
                },
                activeColor: Colors.red.shade800,
              ),
              const Text("Others"),
            ],
          ),
          _buildTextField("Pain Score (/10)", painScoreController),
          _buildTextField("Other Patient Progress/ Remarks", remarksController, maxLines: 3),
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
            const SizedBox(height: 20),
            _buildCheckboxList("TREATMENT/ACTION", treatmentOptions),
            const SizedBox(height: 20),
            _buildCheckboxList(
                "HANDLING & IMMOBILISATION ON DEPARTURE", handlingOptions),
            const SizedBox(height: 20),
            _buildAcknowledgementForm(),
            const SizedBox(height: 40),
          ],
        ),
    );
  }
}

