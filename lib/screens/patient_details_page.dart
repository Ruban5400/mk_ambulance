import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  String selectedGender = "Male";
  final complaintController = TextEditingController();
  Map<String, Set<String>> primarySurveySelections = {
    "Airway": {},
    "Breathing": {},
    "Circulation": {},
  };

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
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
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
      });
    }
  }

  Widget _buildCheckBoxColumn(String title, List<String> options) {
    return Expanded(
      child: Column(
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
                  visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        primarySurveySelections[title]!.add(option);
                      } else {
                        primarySurveySelections[title]!.remove(option);
                      }
                    });
                  },
                ),
                SizedBox(width: 10),
                Flexible(child: Text(option, style: TextStyle(fontSize: 13))),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAllergiesMedicationSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "ALLERGIES & MEDICATION",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          _buildTextField(
            "Allergies",
            TextEditingController(),
            "List known allergies",
            maxLines: 3,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            "Medication",
            TextEditingController(),
            "List current medications",
            maxLines: 3,
          ),
        ],
      ),
    );
  }

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
  Set<String> selectedHistory = {};

  Widget _buildPreviousHistorySection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "PREVIOUS HISTORY",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
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
                          }
                        });
                      },
                    ),
                    Text(option, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 15),
          _buildTextField(
            "Nurse's Notes",
            TextEditingController(),
            "Additional notes from the nurse...",
            maxLines: 3,
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
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              border: Border.all(color: Colors.grey, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MK AMBULANCE - PATIENT DETAIL',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildDatePicker()),
                    const SizedBox(width: 20),
                    Expanded(child: _buildTimePicker()),
                  ],
                ),
                const SizedBox(height: 20),

                Text('Referral Type'),
                SizedBox(height: 5),
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
                          onChanged: (val) =>
                              setState(() => referralType = val!),
                        ),
                        Text(type),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Location
                _buildTextField(
                  "Location",
                  locationController,
                  "Location of incident",
                ),
                const SizedBox(height: 20),

                // Name & NRIC
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        "Name",
                        nameController,
                        "Patient's full name",
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildTextField(
                        "NRIC Number",
                        nricController,
                        "Patient's NRIC number",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // DOB & Age
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date of Birth'),
                          SizedBox(height: 5),
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
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildTextField(
                        "Age",
                        ageController,
                        "Patient's age",
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Gender
                Text("Gender"),
                SizedBox(height: 5),
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
                              setState(() => selectedGender = val!),
                        ),
                        Text(gender),
                      ],
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Chief Complaint
                Text("Chief Complain (Patient Complaint)"),
                SizedBox(height: 5),
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
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              border: Border.all(color: Colors.grey, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Primary Survey
                Text(
                  "PRIMARY SURVEY",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCheckBoxColumn("Airway", [
                      "CLEAR",
                      "OBSTRUCTED",
                      "AGONAL",
                      "ABSENT",
                    ]),
                    SizedBox(width: 40),
                    _buildCheckBoxColumn("Breathing", [
                      "NORMAL",
                      "SHALLOW",
                      "ABSENT",
                    ]),
                    SizedBox(width: 40),
                    _buildCheckBoxColumn("Circulation", [
                      "NORMAL",
                      "PALE",
                      "FLUSHED",
                      "CYNOSED",
                    ]),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _buildAllergiesMedicationSection(),
          const SizedBox(height: 30),
          _buildPreviousHistorySection(),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date'),
        SizedBox(height: 5),
        TextFormField(
          readOnly: true,
          onTap: pickDate,
          decoration: InputDecoration(
            // labelText: 'Date',
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
        Text('Time'),
        SizedBox(height: 5),
        TextFormField(
          readOnly: true,
          onTap: pickTime,
          decoration: InputDecoration(
            // labelText: 'Time',
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
        ),
      ],
    );
  }
}
