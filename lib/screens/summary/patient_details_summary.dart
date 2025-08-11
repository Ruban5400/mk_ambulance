import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/patient_form_data.dart';

class PatientDetailsForm extends StatelessWidget {
  const PatientDetailsForm({super.key});

  @override
  Widget build(BuildContext context) {
    // Use a Consumer to listen for changes to the entire form data, including signatures
    final data = Provider.of<PatientFormProvider>(
      context,
      listen: false,
    ).patientDetails;

    data.forEach((key, value) {
      print('$key : $value');
    });

    return Consumer<PatientFormProvider>(
      builder: (context, provider, child) {
        final details = provider.patientDetails;
        final observations = provider.observations;
        // Accessing the signature images using the custom getters on the provider.
        final frontImage = provider.frontSignatureImage;
        final backImage = provider.backSignatureImage;

        // Helper function to safely get the first part of a date string.
        String _getSafeDatePart(String? date) {
          if (date == null || !date.contains(' ')) {
            return date ?? '';
          }
          return date.split(' ')[0];
        }

        // Helper function to safely get the time from a string.
        String _getSafeTimePart(String? time) {
          if (time == null || !time.contains('(') || !time.contains(')')) {
            return time ?? '';
          }
          // Assuming the format is "Time (value)"
          final parts = time.split('(');
          if (parts.length > 1) {
            return parts[1].replaceAll(')', '');
          }
          return time;
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Patient Information',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  border: Border.all(color: Colors.grey, width: 1.0),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Name:', details['Name'].toString()),
                          _buildInfoRow(
                            'NRIC Number:',
                            details['NRIC Number'].toString(),
                          ),
                          _buildInfoRow(
                            'Date of Birth:',
                            details['patient_dob'].toString(),
                          ),
                          _buildInfoRow('Age:', details['Age'].toString()),
                          _buildInfoRow(
                            'Gender:',
                            details['patient_gender'].toString(),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            'Date:',
                            _getSafeDatePart(
                              details['patient_entry_date']?.toString(),
                            ),
                          ),
                          _buildInfoRow(
                            'Time:',
                            details['patient_entry_time'].toString(),
                          ),
                          _buildInfoRow(
                            'Referral Type:',
                            details['referral_type'].toString(),
                          ),
                          _buildInfoRow(
                            'Location:',
                            details['Location'].toString(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionHeader(context, 'Chief Complaint'),
              _buildText(details['chief_complain'].toString()),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(context, 'Primary Survey'),
                        if (details['primary_survey']
                            is Map<String, List<String>>)
                          ..._buildPrimarySurvey(
                            details['primary_survey']
                                as Map<String, List<String>>,
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(context, 'Allergies & Medication'),
                        _buildInfoRow(
                          'Allergies:',
                          details['Allergies'].toString(),
                        ),
                        _buildInfoRow(
                          'Medication:',
                          details['Medication'].toString(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionHeader(context, 'Previous History'),
              if (details['previous_history'] is List)
                _buildText((details['previous_history'] as List).join(', ')),
              _buildInfoRow(
                'Other History:',
                details['Other History'].toString(),
              ),
              const SizedBox(height: 20),
              _buildSectionHeader(context, 'Nurse\'s Notes'),
              _buildText(details['Nurse\'s Notes'].toString()),
              // New section to display the signature images
              const SizedBox(height: 20),
              _buildSectionHeader(context, 'Sign of Symptoms'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          "Front View",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (frontImage != null)
                          Image.memory(
                            frontImage,
                            fit: BoxFit.contain,
                            height: 400,
                          )
                        else
                          const Text("No front signature drawn."),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          "Back View",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (backImage != null)
                          Image.memory(
                            backImage,
                            fit: BoxFit.contain,
                            height: 400,
                          )
                        else
                          const Text("No back signature drawn."),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionHeader(context, 'Observation Notes'),
              _buildObservationsTable(observations),
              const SizedBox(height: 20),
              _buildSectionHeader(context, 'Treatment/Action'),
              if (details['TREATMENT/ACTION'] is List)
                _buildText((details['TREATMENT/ACTION'] as List).join(', ')),
              const SizedBox(height: 20),
              _buildSectionHeader(
                context,
                'Handling & Immobilisation on Departure',
              ),
              if (details['HANDLING & IMMOBILISATION ON DEPARTURE'] is List)
                _buildText(
                  (details['HANDLING & IMMOBILISATION ON DEPARTURE'] as List)
                      .join(', '),
                ),
              const SizedBox(height: 20),
              _buildSectionHeader(context, 'General Condition'),
              _buildText(details['General Condition'].toString()),
              const SizedBox(height: 20),
              _buildSectionHeader(context, 'On Arrival Vital Signs Record'),
              _buildInfoRow('BP (mmHg):', details['BP (mmHg)'].toString()),
              _buildInfoRow('RR (min):', details['RR (min)'].toString()),
              _buildInfoRow('SPO2 (%):', details['SPO2 (%)'].toString()),
              _buildInfoRow(
                'Pain Score (/10):',
                details['Pain Score (/10)'].toString(),
              ),
              _buildInfoRow(
                'Temperature (°C):',
                details['Temperature (°C)'].toString(),
              ),
              _buildInfoRow(
                'Glucose (mmol/L):',
                details['Glucose (mmol/L)'].toString(),
              ),
              const SizedBox(height: 20),
              _buildSectionHeader(context, 'Condition Status'),
              _buildInfoRow(
                'Condition:',
                details['Condition Status'].toString(),
              ),
              if (details['Condition Status'] == "Death")
                _buildInfoRow('Death Time:', details['DeathTime'].toString()),
              if (details['Condition Status'] == "Others")
                _buildInfoRow(
                  'Other details:',
                  details['Other Condition Text'].toString(),
                ),
              _buildSectionHeader(context, 'Other Patient Progress / Remarks'),
              _buildText(details['Other Patient Progress/ Remarks'].toString()),

              if (details['documents_provided'] is List)
                _buildInfoRow(
                  'Documents Provided:',
                  (details['documents_provided'] as List).join(', '),
                ),
              const SizedBox(height: 20),
              _buildSectionHeader(context, 'Staff & Documentation'),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildInfoRow(
                          'Patient Name:',
                          details['patient_name'].toString(),
                        ),
                        _buildInfoRow(
                          'Patient IC No:',
                          details['patient_ic_no'].toString(),
                        ),
                        _buildSignatureDisplay(details['patient_signature']),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _buildInfoRow(
                          'Staff Name:',
                          details['staff_name'].toString(),
                        ),
                        _buildInfoRow(
                          'Staff IC No:',
                          details['staff_ic_no'].toString(),
                        ),
                        _buildSignatureDisplay(details['staff_signature']),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildInfoRow(
                          'Endorsed By:',
                          details['endorsed_by_name'].toString(),
                        ),
                        _buildInfoRow(
                          'Endorsed Date:',
                          _getSafeDatePart(details['endorsedDate']?.toString()),
                        ),
                        _buildInfoRow(
                          'Endorsed Date:',
                          _getSafeDatePart(details['endorsedTime']?.toString()),
                        ),
                        _buildSignatureDisplay(
                          details['endorsed_by_signature'],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _buildInfoRow(
                          'Received By:',
                          details['received_by_name'].toString(),
                        ),
                        _buildInfoRow(
                          'Received Date:',
                          _getSafeDatePart(details['receivedDate']?.toString()),
                        ),
                        _buildInfoRow(
                          'Received Time:',
                          _getSafeTimePart(details['receivedTime']?.toString()),
                        ),
                        _buildSignatureDisplay(
                          details['received_by_signature'],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSignatureDisplay(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return Container(
        height: 100,
        width: 300,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: Text('No Signature Provided')),
      );
    }
    try {
      final Uint8List bytes = base64Decode(base64String);
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Image.memory(
          bytes,
          height: 100,
          width: 300,
          fit: BoxFit.contain,
        ),
      );
    } catch (e) {
      return const Text('Error loading signature');
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
      ],
    );
  }

  List<Widget> _buildPrimarySurvey(dynamic surveyData) {
    if (surveyData is! Map<String, dynamic>) {
      return [const Text('No primary survey data available.')];
    }
    return surveyData.entries.map((entry) {
      String value = '';
      if (entry.value is List) {
        value = (entry.value as List).join(', ');
      } else if (entry.value is Set) {
        value = (entry.value as Set).join(', ');
      } else {
        value = entry.value.toString();
      }
      return _buildInfoRow('${entry.key}:', value);
    }).toList();
  }

  // List<Widget> _b

  Widget _buildText(String text) {
    return Text(text, style: GoogleFonts.poppins(fontSize: 14));
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildObservationsTable(Map<String, List<String>> observations) {
    int maxColumns = 0;

    observations.values.forEach((row) {
      int lastNonNullIndex = -1;

      // Find the last non-null/non-empty index in the row
      for (int i = 0; i < row.length; i++) {
        if (row[i] != null && row[i].toString().trim().isNotEmpty) {
          lastNonNullIndex = i;
        }
      }

      // Column count = index + 1 (since index starts at 0)
      int count = lastNonNullIndex >= 0 ? lastNonNullIndex + 1 : 0;

      if (count > maxColumns) {
        maxColumns = count;
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(flex: 2, child: Text('')),
            for (int i = 0; i < maxColumns; i++)
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    // Logic to label the columns based on their index and the total number of columns.
                    maxColumns <= 1
                        ? 'Arrival'
                        : i == 0
                        ? 'Arrival'
                        : i == maxColumns - 1
                        ? 'Handover'
                        : 'Intermediate',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
        const Divider(),
        ...observations.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                for (int i = 0; i < maxColumns; i++)
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Text(
                        // Display the value at the correct index, which handles empty strings correctly.
                        i < entry.value.length ? entry.value[i] : '',
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}

// old code without images
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
//
// import '../../providers/patient_form_data.dart';
//
// class PatientDetailsForm extends StatelessWidget {
//   const PatientDetailsForm({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     // final details = Provider.of<PatientFormProvider>(context, listen: false).formData;
//     final data = Provider.of<PatientFormProvider>(context, listen: false).patientDetails;
//
//     data.forEach((key, value) {
//       print('$key : $value');
//     });
//
//
//     // new value
//     final details = {
//       "patient_entry_date": "2025-08-11 14:16:34.563",
//       "patient_entry_time": "2:16 PM",
//       "referral_type": "SELF REFERRAL",
//       "Location": "abc",
//       "Name": "def",
//       "NRIC Number": "ijk",
//       "patient_dob": "01-01-2000",
//       "Age": "24",
//       "patient_gender": "Female",
//       "chief_complain": "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.",
//       "primary_survey": {
//         "Airway": ["CLEAR", "OBSTRUCTED", "AGONAL", "ABSENT"],
//         "Breathing": ["ABSENT", "SHALLOW"],
//         "Circulation": ["NORMAL", "PALE", "FLUSHED"],
//       },
//       "Allergies": "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.",
//       "Medication": "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.",
//       "previous_history": ["HIGH BLOOD PRESSURE", "RESPIRATORY", "DIABETES", "CARDIAC", "SEIZURES", "ASTHMA", "STROKE", "OTHER"],
//       "Other History": "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.",
//       "Nurse's Notes": "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.",
//       "observations": {
//         "RESPIRATORY RATE": ["1", "2", "", "", ""],
//         "PULSE RATE": ["3", "", "", "", ""],
//         "SPO2": ["", "4", "", "", ""],
//         "BLOOD PRESSURE": ["", "5", "", "7", ""],
//         "BLOOD GLUCOSE": ["66", "77", "", "", ""],
//         "TEMPERATURE": ["88", "", "", "", ""],
//         "GCS": ["9", "", "", "", ""],
//         "PUPIL SIZE (mm)": ["", "10", "", "", ""],
//         "PUPIL REACTION": ["11", "12", "", "", ""],
//       },
//       "TREATMENT/ACTION": ["NO TREATMENT / ADVICE ONLY GIVEN", "REST-ICE-COMPRESS-ELEVATE", "C-SPINE CONTROL (IMMOBILISATION)", "AIRWAY INSERTED (TYPE/SIZE)", "HEAD INJURY ADVICE GIVEN", "alpha"],
//       "HANDLING & IMMOBILISATION ON DEPARTURE": ["LONGBOARD", "SCOOP", "WALKED AIDED", "STRETCHER", "bravo"],
//       "General Condition": "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.",
//       "BP (mmHg)": "12",
//       "RR (min)": "23",
//       "SPO2 (%)": "56",
//       "Pain Score (/10)": "10",
//       "Temperature (°C)": "200",
//       "Glucose (mmol/L)": "12",
//       "Condition Status": "Death",
//       "DeathTime": "2:19 PM",
//       "Other Patient Progress/ Remarks": "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.",
//       "patient_name": "patient name",
//       "patient_ic_no": "12345",
//       "staff_name": "staff name",
//       "staff_ic_no": "6788910",
//       "documents_provided": ["REFERRAL LETTER", "INVESTIGATION RESULT", "IMAGING FILM/REPORT", "AOR"],
//       "endorsed_by_name": "endorsed by name",
//       "endorsedDate": "2025-08-11 00:00:00.000",
//       "received_by_name": "received by name",
//       "receivedDate": "2025-08-06 00:00:00.000",
//       "receivedTime": "TimeOfDay(12:19)",
//     };
//
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Patient Information',
//             style: Theme.of(context).textTheme.headlineMedium,
//           ),
//           const SizedBox(height: 10),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
//             decoration: BoxDecoration(
//               borderRadius: const BorderRadius.all(Radius.circular(10)),
//               border: Border.all(color: Colors.grey, width: 1.0),
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _buildInfoRow('Name:', details['Name'].toString()),
//                       _buildInfoRow('NRIC Number:', details['NRIC Number'].toString()),
//                       _buildInfoRow('Date of Birth:', details['patient_dob'].toString()),
//                       _buildInfoRow('Age:', details['Age'].toString()),
//                       _buildInfoRow('Gender:', details['patient_gender'].toString()),
//                     ],
//                   ),
//                 ),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _buildInfoRow('Date:', details['patient_entry_date'].toString().split(' ')[0]),
//                       _buildInfoRow('Time:', details['patient_entry_time'].toString()),
//                       _buildInfoRow('Referral Type:', details['referral_type'].toString()),
//                       _buildInfoRow('Location:', details['Location'].toString()),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 20),
//           _buildSectionHeader(context, 'Chief Complaint'),
//           _buildText(details['chief_complain'].toString()),
//           const SizedBox(height: 20),
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Expanded(
//                 flex: 1,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildSectionHeader(context, 'Primary Survey'),
//                     ..._buildPrimarySurvey(details['primary_survey'] as Map<String, List<String>>),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 flex: 3,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildSectionHeader(context, 'Allergies & Medication'),
//                     _buildInfoRow('Allergies:', details['Allergies'].toString()),
//                     _buildInfoRow('Medication:', details['Medication'].toString()),
//                   ],
//                 ),
//               )
//             ],
//           ),
//           const SizedBox(height: 20),
//           _buildSectionHeader(context, 'Previous History'),
//           _buildText((details['previous_history'] as List).join(', ')),
//           _buildInfoRow('Other History:', details['Other History'].toString()),
//           const SizedBox(height: 20),
//           _buildSectionHeader(context, 'Observation Notes'),
//           _buildObservationsTable(details['observations'] as Map<String, List<String>>),
//           const SizedBox(height: 20),
//           _buildSectionHeader(context, 'Nurse\'s Notes'),
//           _buildText(details['Nurse\'s Notes'].toString()),
//           const SizedBox(height: 20),
//           _buildSectionHeader(context, 'Treatment/Action'),
//           _buildText((details['TREATMENT/ACTION'] as List).join(', ')),
//           const SizedBox(height: 20),
//           const SizedBox(height: 20),
//           _buildSectionHeader(context, 'Handling & Immobilisation on Departure'),
//           _buildText((details['HANDLING & IMMOBILISATION ON DEPARTURE'] as List).join(', ')),
//           const SizedBox(height: 20),
//           _buildSectionHeader(context, 'General Condition'),
//           _buildText(details['General Condition'].toString()),
//           const SizedBox(height: 20),
//           _buildSectionHeader(context, 'On Arrival Vital Signs Record'),
//           _buildInfoRow('BP (mmHg):', details['BP (mmHg)'].toString()),
//           _buildInfoRow('RR (min):', details['RR (min)'].toString()),
//           _buildInfoRow('SPO2 (%):', details['SPO2 (%)'].toString()),
//           _buildInfoRow('Pain Score (/10):', details['Pain Score (/10)'].toString()),
//           _buildInfoRow('Temperature (°C):', details['Temperature (°C)'].toString()),
//           _buildInfoRow('Glucose (mmol/L):', details['Glucose (mmol/L)'].toString()),
//           const SizedBox(height: 20),
//           _buildSectionHeader(context, 'Condition Status'),
//           _buildInfoRow('Condition:', details['Condition Status'].toString()),
//           if (details['Condition Status'] == "Death")
//             _buildInfoRow('Death Time:', details['DeathTime'].toString()),
//           _buildSectionHeader(context, 'Other Patient Progress / Remarks'),
//           _buildText(details['Other Patient Progress/ Remarks'].toString()),
//           const SizedBox(height: 20),
//           _buildSectionHeader(context, 'Staff & Documentation'),
//           _buildInfoRow('Patient Name:', details['patient_name'].toString()),
//           _buildInfoRow('Patient IC No:', details['patient_ic_no'].toString()),
//           _buildInfoRow('Staff Name:', details['staff_name'].toString()),
//           _buildInfoRow('Staff IC No:', details['staff_ic_no'].toString()),
//           _buildInfoRow('Documents Provided:', (details['documents_provided'] as List).join(', ')),
//           _buildInfoRow('Endorsed By:', details['endorsed_by_name'].toString()),
//           _buildInfoRow('Endorsed Date:', details['endorsedDate'].toString().split(' ')[0]),
//           _buildInfoRow('Received By:', details['received_by_name'].toString()),
//           _buildInfoRow('Received Date:', details['receivedDate'].toString().split(' ')[0]),
//           _buildInfoRow('Received Time:', details['receivedTime'].toString().split('(')[1].replaceAll(')', '')),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSectionHeader(BuildContext context, String title) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: Theme.of(context).textTheme.headlineSmall,
//         ),
//         const SizedBox(height: 8),
//       ],
//     );
//   }
//
//   List<Widget> _buildPrimarySurvey(Map<String, List<String>> surveyData) {
//     return surveyData.entries.map((entry) {
//       return _buildInfoRow(
//         '${entry.key}:',
//         entry.value.join(', '),
//       );
//     }).toList();
//   }
//
//   Widget _buildText(String text) {
//     return Text(
//       text,
//       style: GoogleFonts.poppins(fontSize: 14),
//     );
//   }
//
//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 150,
//             child: Text(
//               label,
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ),
//           Expanded(
//             child: Text(value),
//           ),
//         ],
//       ),
//     );
//   }
//   Widget _buildObservationsTable(Map<String, List<String>> observations) {
//     int maxColumns = 0;
//
//     observations.values.forEach((row) {
//       int lastNonNullIndex = -1;
//
//       // Find the last non-null/non-empty index in the row
//       for (int i = 0; i < row.length; i++) {
//         if (row[i] != null && row[i].toString().trim().isNotEmpty) {
//           lastNonNullIndex = i;
//         }
//       }
//
//       // Column count = index + 1 (since index starts at 0)
//       int count = lastNonNullIndex >= 0 ? lastNonNullIndex + 1 : 0;
//
//       if (count > maxColumns) {
//         maxColumns = count;
//       }
//     });
//
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             const Expanded(flex: 2, child: Text('')),
//             for (int i = 0; i < maxColumns; i++)
//               Expanded(
//                 flex: 1,
//                 child: Center(
//                   child: Text(
//                     // Logic to label the columns based on their index and the total number of columns.
//                     maxColumns <= 1
//                         ? 'Arrival'
//                         : i == 0
//                         ? 'Arrival'
//                         : i == maxColumns - 1
//                         ? 'Handover'
//                         : 'Intermediate',
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//         const Divider(),
//         ...observations.entries.map((entry) {
//           return Padding(
//             padding: const EdgeInsets.symmetric(vertical: 4.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   flex: 2,
//                   child: Text(
//                     entry.key,
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//                 for (int i = 0; i < maxColumns; i++)
//                   Expanded(
//                     flex: 1,
//                     child: Center(
//                       child: Text(
//                         // Display the value at the correct index, which handles empty strings correctly.
//                         i < entry.value.length ? entry.value[i] : '',
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           );
//         }).toList(),
//       ],
//     );
//   }
//
// }
