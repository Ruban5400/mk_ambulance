import 'package:flutter/material.dart';

void main() {
  runApp(const MKAmbulanceApp());
}

class MKAmbulanceApp extends StatelessWidget {
  const MKAmbulanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PatientDetailsPage(),
    );
  }
}

class PatientDetailsPage extends StatefulWidget {
  const PatientDetailsPage({super.key});

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  String referralType = 'SELF REFERRAL';

  final locationController = TextEditingController();
  final nameController = TextEditingController();
  final nricController = TextEditingController();
  final dobController = TextEditingController();
  final ageController = TextEditingController();

  final referralOptions = [
    'SELF REFERRAL',
    'HOSPITAL REFERRAL',
    'CALL TO SCENE',
    'Connectica ZEN CLIENT',
  ];

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text("MK AMBULANCE - PATIENT DETAIL"),
        backgroundColor: Colors.red.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date & Time
                isWide
                    ? Row(
                  children: [
                    Expanded(child: _buildDatePicker()),
                    const SizedBox(width: 20),
                    Expanded(child: _buildTimePicker()),
                  ],
                )
                    : Column(
                  children: [
                    _buildDatePicker(),
                    const SizedBox(height: 10),
                    _buildTimePicker(),
                  ],
                ),
                const SizedBox(height: 20),

                // Referral Type
                const Text("Referral Type", style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 20,
                  children: referralOptions.map((type) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Radio<String>(
                          value: type,
                          groupValue: referralType,
                          onChanged: (val) => setState(() => referralType = val!),
                        ),
                        Text(type),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Location
                _buildTextField("Location", locationController, "Location of incident"),
                const SizedBox(height: 20),

                // Name & NRIC
                isWide
                    ? Row(
                  children: [
                    Expanded(child: _buildTextField("Name", nameController, "Patient's full name")),
                    const SizedBox(width: 20),
                    Expanded(child: _buildTextField("NRIC Number", nricController, "Patient's NRIC number")),
                  ],
                )
                    : Column(
                  children: [
                    _buildTextField("Name", nameController, "Patient's full name"),
                    const SizedBox(height: 10),
                    _buildTextField("NRIC Number", nricController, "Patient's NRIC number"),
                  ],
                ),
                const SizedBox(height: 20),

                // DOB & Age
                isWide
                    ? Row(
                  children: [
                    Expanded(child: _buildTextField("Date of Birth", dobController, "dd-mm-yyyy")),
                    const SizedBox(width: 20),
                    Expanded(child: _buildTextField("Age", ageController, "Patient's age")),
                  ],
                )
                    : Column(
                  children: [
                    _buildTextField("Date of Birth", dobController, "dd-mm-yyyy"),
                    const SizedBox(height: 10),
                    _buildTextField("Age", ageController, "Patient's age"),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return TextFormField(
      readOnly: true,
      onTap: pickDate,
      decoration: InputDecoration(
        labelText: 'Date',
        suffixIcon: const Icon(Icons.calendar_today),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade100,
        hintText: 'Select date',
      ),
      controller: TextEditingController(text: "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}"),
    );
  }

  Widget _buildTimePicker() {
    return TextFormField(
      readOnly: true,
      onTap: pickTime,
      decoration: InputDecoration(
        labelText: 'Time',
        suffixIcon: const Icon(Icons.access_time),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade100,
        hintText: 'Select time',
      ),
      controller: TextEditingController(text: selectedTime.format(context)),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
