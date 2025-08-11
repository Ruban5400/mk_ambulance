import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/patient_form_data.dart';

class PatientDetailsForm extends StatelessWidget {
  const PatientDetailsForm({super.key});

  // A helper function to check if a map value is not null and not empty.
  bool _hasValue(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) {
      return false;
    }
    if (value is String) {
      return value.trim().isNotEmpty;
    }
    if (value is List) {
      return value.isNotEmpty;
    }
    if (value is Map) {
      return value.isNotEmpty;
    }
    return true;
  }

  // A helper function to display a single information row.
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

  // A helper widget to display a section header.
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
      ],
    );
  }

  // A helper widget to display signature images from a base64 string.
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

  // A helper widget to build the Primary Survey section.
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

  // A helper widget to build the Observations Table.
  Widget _buildObservationsTable(Map<String, List<String>> observations) {
    int maxColumns = 0;

    observations.values.forEach((row) {
      int lastNonNullIndex = -1;
      for (int i = 0; i < row.length; i++) {
        if (row[i] != null && row[i].toString().trim().isNotEmpty) {
          lastNonNullIndex = i;
        }
      }
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
    final parts = time.split('(');
    if (parts.length > 1) {
      return parts[1].replaceAll(')', '');
    }
    return time;
  }

  Widget _buildText(String text) {
    return Text(text, style: GoogleFonts.poppins(fontSize: 14));
  }

  @override
  Widget build(BuildContext context) {
    // Use a Consumer to listen for changes to the entire form data, including signatures
    return Consumer<PatientFormProvider>(
      builder: (context, provider, child) {
        final details = provider.patientDetails;
        final observations = provider.observations;
        final frontImage = provider.frontSignatureImage;
        final backImage = provider.backSignatureImage;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isLargeScreen = constraints.maxWidth > 600;

              return Column(
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
                    child: isLargeScreen
                        ? Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_hasValue(details, 'Name'))
                                _buildInfoRow('Name:', details['Name'].toString()),
                              if (_hasValue(details, 'NRIC Number'))
                                _buildInfoRow('NRIC Number:', details['NRIC Number'].toString()),
                              if (_hasValue(details, 'patient_dob'))
                                _buildInfoRow('Date of Birth:', details['patient_dob'].toString()),
                              if (_hasValue(details, 'Age'))
                                _buildInfoRow('Age:', details['Age'].toString()),
                              if (_hasValue(details, 'patient_gender'))
                                _buildInfoRow('Gender:', details['patient_gender'].toString()),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_hasValue(details, 'patient_entry_date'))
                                _buildInfoRow('Date:', _getSafeDatePart(details['patient_entry_date']?.toString())),
                              if (_hasValue(details, 'patient_entry_time'))
                                _buildInfoRow('Time:', details['patient_entry_time'].toString()),
                              if (_hasValue(details, 'referral_type'))
                                _buildInfoRow('Referral Type:', details['referral_type'].toString()),
                              if (_hasValue(details, 'Location'))
                                _buildInfoRow('Location:', details['Location'].toString()),
                            ],
                          ),
                        ),
                      ],
                    )
                        : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_hasValue(details, 'Name'))
                          _buildInfoRow('Name:', details['Name'].toString()),
                        if (_hasValue(details, 'NRIC Number'))
                          _buildInfoRow('NRIC Number:', details['NRIC Number'].toString()),
                        if (_hasValue(details, 'patient_dob'))
                          _buildInfoRow('Date of Birth:', details['patient_dob'].toString()),
                        if (_hasValue(details, 'Age'))
                          _buildInfoRow('Age:', details['Age'].toString()),
                        if (_hasValue(details, 'patient_gender'))
                          _buildInfoRow('Gender:', details['patient_gender'].toString()),
                        if (_hasValue(details, 'patient_entry_date'))
                          _buildInfoRow('Date:', _getSafeDatePart(details['patient_entry_date']?.toString())),
                        if (_hasValue(details, 'patient_entry_time'))
                          _buildInfoRow('Time:', details['patient_entry_time'].toString()),
                        if (_hasValue(details, 'referral_type'))
                          _buildInfoRow('Referral Type:', details['referral_type'].toString()),
                        if (_hasValue(details, 'Location'))
                          _buildInfoRow('Location:', details['Location'].toString()),
                      ],
                    ),
                  ),
                  if (_hasValue(details, 'chief_complain')) ...[
                    const SizedBox(height: 20),
                    _buildSectionHeader(context, 'Chief Complaint'),
                    _buildText(details['chief_complain'].toString()),
                  ],
                  if (_hasValue(details, 'primary_survey') || _hasValue(details, 'Allergies') || _hasValue(details, 'Medication')) ...[
                    const SizedBox(height: 20),
                    isLargeScreen
                        ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_hasValue(details, 'primary_survey'))
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(context, 'Primary Survey'),
                                if (details['primary_survey'] is Map<String, List<String>>)
                                  ..._buildPrimarySurvey(details['primary_survey'] as Map<String, List<String>>),
                              ],
                            ),
                          ),
                        if (_hasValue(details, 'Allergies') || _hasValue(details, 'Medication'))
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(context, 'Allergies & Medication'),
                                if (_hasValue(details, 'Allergies'))
                                  _buildInfoRow('Allergies:', details['Allergies'].toString()),
                                if (_hasValue(details, 'Medication'))
                                  _buildInfoRow('Medication:', details['Medication'].toString()),
                              ],
                            ),
                          ),
                      ],
                    )
                        : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_hasValue(details, 'primary_survey'))
                          ...[
                            _buildSectionHeader(context, 'Primary Survey'),
                            if (details['primary_survey'] is Map<String, List<String>>)
                              ..._buildPrimarySurvey(details['primary_survey'] as Map<String, List<String>>),
                            const SizedBox(height: 20),
                          ],
                        if (_hasValue(details, 'Allergies') || _hasValue(details, 'Medication'))
                          ...[
                            _buildSectionHeader(context, 'Allergies & Medication'),
                            if (_hasValue(details, 'Allergies'))
                              _buildInfoRow('Allergies:', details['Allergies'].toString()),
                            if (_hasValue(details, 'Medication'))
                              _buildInfoRow('Medication:', details['Medication'].toString()),
                          ],
                      ],
                    ),
                  ],
                  if (_hasValue(details, 'previous_history') || _hasValue(details, 'Other History')) ...[
                    const SizedBox(height: 20),
                    _buildSectionHeader(context, 'Previous History'),
                    if (details['previous_history'] is List && (details['previous_history'] as List).isNotEmpty)
                      _buildText((details['previous_history'] as List).join(', ')),
                    if (_hasValue(details, 'Other History'))
                      _buildInfoRow('Other History:', details['Other History'].toString()),
                  ],
                  if (_hasValue(details, 'Nurse\'s Notes')) ...[
                    const SizedBox(height: 20),
                    _buildSectionHeader(context, 'Nurse\'s Notes'),
                    _buildText(details['Nurse\'s Notes'].toString()),
                  ],
                  if (frontImage != null || backImage != null) ...[
                    const SizedBox(height: 20),
                    _buildSectionHeader(context, 'Sign of Symptoms'),
                    isLargeScreen
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(child: _buildImageDisplay(frontImage, 'Front View')),
                        const SizedBox(width: 20),
                        Expanded(child: _buildImageDisplay(backImage, 'Back View')),
                      ],
                    )
                        : Column(
                      children: [
                        _buildImageDisplay(frontImage, 'Front View'),
                        const SizedBox(height: 20),
                        _buildImageDisplay(backImage, 'Back View'),
                      ],
                    ),
                  ],
                  if (observations.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSectionHeader(context, 'Observation Notes'),
                    _buildObservationsTable(observations),
                  ],
                  if (_hasValue(details, 'TREATMENT/ACTION')) ...[
                    const SizedBox(height: 20),
                    _buildSectionHeader(context, 'Treatment/Action'),
                    if (details['TREATMENT/ACTION'] is List)
                      _buildText((details['TREATMENT/ACTION'] as List).join(', ')),
                  ],
                  if (_hasValue(details, 'HANDLING & IMMOBILISATION ON DEPARTURE')) ...[
                    const SizedBox(height: 20),
                    _buildSectionHeader(context, 'Handling & Immobilisation on Departure'),
                    if (details['HANDLING & IMMOBILISATION ON DEPARTURE'] is List)
                      _buildText((details['HANDLING & IMMOBILISATION ON DEPARTURE'] as List).join(', ')),
                  ],
                  if (_hasValue(details, 'General Condition')) ...[
                    const SizedBox(height: 20),
                    _buildSectionHeader(context, 'General Condition'),
                    _buildText(details['General Condition'].toString()),
                  ],
                  if (_hasValue(details, 'BP (mmHg)') || _hasValue(details, 'RR (min)') || _hasValue(details, 'SPO2 (%)') || _hasValue(details, 'Pain Score (/10)') || _hasValue(details, 'Temperature (°C)') || _hasValue(details, 'Glucose (mmol/L)')) ...[
                    const SizedBox(height: 20),
                    _buildSectionHeader(context, 'On Arrival Vital Signs Record'),
                    if (_hasValue(details, 'BP (mmHg)')) _buildInfoRow('BP (mmHg):', details['BP (mmHg)'].toString()),
                    if (_hasValue(details, 'RR (min)')) _buildInfoRow('RR (min):', details['RR (min)'].toString()),
                    if (_hasValue(details, 'SPO2 (%)')) _buildInfoRow('SPO2 (%):', details['SPO2 (%)'].toString()),
                    if (_hasValue(details, 'Pain Score (/10)')) _buildInfoRow('Pain Score (/10):', details['Pain Score (/10)'].toString()),
                    if (_hasValue(details, 'Temperature (°C)')) _buildInfoRow('Temperature (°C):', details['Temperature (°C)'].toString()),
                    if (_hasValue(details, 'Glucose (mmol/L)')) _buildInfoRow('Glucose (mmol/L):', details['Glucose (mmol/L)'].toString()),
                  ],
                  if (_hasValue(details, 'Condition Status') || (details['Condition Status'] == 'Death' && _hasValue(details, 'DeathTime')) || (details['Condition Status'] == 'Others' && _hasValue(details, 'Other Condition Text'))) ...[
                    const SizedBox(height: 20),
                    _buildSectionHeader(context, 'Condition Status'),
                    if (_hasValue(details, 'Condition Status')) _buildInfoRow('Condition:', details['Condition Status'].toString()),
                    if (details['Condition Status'] == "Death" && _hasValue(details, 'DeathTime')) _buildInfoRow('Death Time:', details['DeathTime'].toString()),
                    if (details['Condition Status'] == "Others" && _hasValue(details, 'Other Condition Text')) _buildInfoRow('Other details:', details['Other Condition Text'].toString()),
                  ],
                  if (_hasValue(details, 'Other Patient Progress/ Remarks')) ...[
                    const SizedBox(height: 20),
                    _buildSectionHeader(context, 'Other Patient Progress / Remarks'),
                    _buildText(details['Other Patient Progress/ Remarks'].toString()),
                  ],
                  const SizedBox(height: 20),
                  _buildSectionHeader(context, 'Sign-Off Details'),
                  if (_hasValue(details, 'documents_provided'))
                    _buildInfoRow('Documents Provided:', (details['documents_provided'] as List).join(', ')),
                  isLargeScreen
                      ? Row(
                    children: [
                      Expanded(child: _buildSignOffColumn(details, isPatient: true)),
                      Expanded(child: _buildSignOffColumn(details, isPatient: false)),
                    ],
                  )
                      : Column(
                    children: [
                      _buildSignOffColumn(details, isPatient: true),
                      const SizedBox(height: 20),
                      _buildSignOffColumn(details, isPatient: false),
                    ],
                  ),
                  const SizedBox(height: 20),
                  isLargeScreen
                      ? Row(
                    children: [
                      Expanded(child: _buildEndorsedColumn(details)),
                      Expanded(child: _buildReceivedColumn(details)),
                    ],
                  )
                      : Column(
                    children: [
                      _buildEndorsedColumn(details),
                      const SizedBox(height: 20),
                      _buildReceivedColumn(details),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildImageDisplay(Uint8List? image, String title) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (image != null)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.memory(
              image,
              fit: BoxFit.contain,
              height: 200,
            ),
          )
        else
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: Text('No signature drawn.')),
          ),
      ],
    );
  }

  Widget _buildSignOffColumn(Map<String, dynamic> details, {required bool isPatient}) {
    String nameKey = isPatient ? 'patient_name' : 'staff_name';
    String icKey = isPatient ? 'patient_ic_no' : 'staff_ic_no';
    String sigKey = isPatient ? 'patient_signature' : 'staff_signature';
    String nameLabel = isPatient ? 'Patient Name:' : 'Staff Name:';
    String icLabel = isPatient ? 'Patient IC No:' : 'Staff IC No:';

    return Column(
      children: [
        if (_hasValue(details, nameKey)) _buildInfoRow(nameLabel, details[nameKey].toString()),
        if (_hasValue(details, icKey)) _buildInfoRow(icLabel, details[icKey].toString()),
        if (_hasValue(details, sigKey)) _buildSignatureDisplay(details[sigKey]),
      ],
    );
  }

  Widget _buildEndorsedColumn(Map<String, dynamic> details) {
    return Column(
      children: [
        if (_hasValue(details, 'endorsed_by_name')) _buildInfoRow('Endorsed By:', details['endorsed_by_name'].toString()),
        if (_hasValue(details, 'endorsedDate')) _buildInfoRow('Endorsed Date:', _getSafeDatePart(details['endorsedDate']?.toString())),
        if (_hasValue(details, 'endorsedTime')) _buildInfoRow('Endorsed Time:', _getSafeTimePart(details['endorsedTime']?.toString())),
        if (_hasValue(details, 'endorsed_by_signature')) _buildSignatureDisplay(details['endorsed_by_signature']),
      ],
    );
  }

  Widget _buildReceivedColumn(Map<String, dynamic> details) {
    return Column(
      children: [
        if (_hasValue(details, 'received_by_name')) _buildInfoRow('Received By:', details['received_by_name'].toString()),
        if (_hasValue(details, 'receivedDate')) _buildInfoRow('Received Date:', _getSafeDatePart(details['receivedDate']?.toString())),
        if (_hasValue(details, 'receivedTime')) _buildInfoRow('Received Time:', _getSafeTimePart(details['receivedTime']?.toString())),
        if (_hasValue(details, 'received_by_signature')) _buildSignatureDisplay(details['received_by_signature']),
      ],
    );
  }
}

// code without ui responsiveness
// import 'dart:convert';
// import 'dart:typed_data';
//
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import '../../providers/patient_form_data.dart';
//
// class PatientDetailsForm extends StatelessWidget {
//   const PatientDetailsForm({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     // Use a Consumer to listen for changes to the entire form data, including signatures
//     return Consumer<PatientFormProvider>(
//       builder: (context, provider, child) {
//         final details = provider.patientDetails;
//         final observations = provider.observations;
//         // Accessing the signature images using the custom getters on the provider.
//         final frontImage = provider.frontSignatureImage;
//         final backImage = provider.backSignatureImage;
//
//         // Helper function to safely get the first part of a date string.
//         String _getSafeDatePart(String? date) {
//           if (date == null || !date.contains(' ')) {
//             return date ?? '';
//           }
//           return date.split(' ')[0];
//         }
//
//         // Helper function to safely get the time from a string.
//         String _getSafeTimePart(String? time) {
//           if (time == null || !time.contains('(') || !time.contains(')')) {
//             return time ?? '';
//           }
//           // Assuming the format is "Time (value)"
//           final parts = time.split('(');
//           if (parts.length > 1) {
//             return parts[1].replaceAll(')', '');
//           }
//           return time;
//         }
//
//         return Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Patient Information',
//                 style: Theme.of(context).textTheme.headlineMedium,
//               ),
//               const SizedBox(height: 10),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 15,
//                   vertical: 20,
//                 ),
//                 decoration: BoxDecoration(
//                   borderRadius: const BorderRadius.all(Radius.circular(10)),
//                   border: Border.all(color: Colors.grey, width: 1.0),
//                 ),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           if (_hasValue(details, 'Name'))
//                             _buildInfoRow('Name:', details['Name'].toString()),
//                           if (_hasValue(details, 'NRIC Number'))
//                             _buildInfoRow(
//                               'NRIC Number:',
//                               details['NRIC Number'].toString(),
//                             ),
//                           if (_hasValue(details, 'patient_dob'))
//                             _buildInfoRow(
//                               'Date of Birth:',
//                               details['patient_dob'].toString(),
//                             ),
//                           if (_hasValue(details, 'Age'))
//                             _buildInfoRow('Age:', details['Age'].toString()),
//                           if (_hasValue(details, 'patient_gender'))
//                             _buildInfoRow(
//                               'Gender:',
//                               details['patient_gender'].toString(),
//                             ),
//                         ],
//                       ),
//                     ),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           if (_hasValue(details, 'patient_entry_date'))
//                             _buildInfoRow(
//                               'Date:',
//                               _getSafeDatePart(
//                                 details['patient_entry_date']?.toString(),
//                               ),
//                             ),
//                           if (_hasValue(details, 'patient_entry_time'))
//                             _buildInfoRow(
//                               'Time:',
//                               details['patient_entry_time'].toString(),
//                             ),
//                           if (_hasValue(details, 'referral_type'))
//                             _buildInfoRow(
//                               'Referral Type:',
//                               details['referral_type'].toString(),
//                             ),
//                           if (_hasValue(details, 'Location'))
//                             _buildInfoRow(
//                               'Location:',
//                               details['Location'].toString(),
//                             ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               if (_hasValue(details, 'chief_complain')) ...[
//                 const SizedBox(height: 20),
//                 _buildSectionHeader(context, 'Chief Complaint'),
//                 _buildText(details['chief_complain'].toString()),
//               ],
//               if (_hasValue(details, 'primary_survey') || _hasValue(details, 'Allergies') || _hasValue(details, 'Medication')) ...[
//                 const SizedBox(height: 20),
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     if (_hasValue(details, 'primary_survey'))
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             _buildSectionHeader(context, 'Primary Survey'),
//                             if (details['primary_survey'] is Map<String, List<String>>)
//                               ..._buildPrimarySurvey(
//                                 details['primary_survey']
//                                 as Map<String, List<String>>,
//                               ),
//                           ],
//                         ),
//                       ),
//                     if (_hasValue(details, 'Allergies') || _hasValue(details, 'Medication'))
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             _buildSectionHeader(context, 'Allergies & Medication'),
//                             if (_hasValue(details, 'Allergies'))
//                               _buildInfoRow(
//                                 'Allergies:',
//                                 details['Allergies'].toString(),
//                               ),
//                             if (_hasValue(details, 'Medication'))
//                               _buildInfoRow(
//                                 'Medication:',
//                                 details['Medication'].toString(),
//                               ),
//                           ],
//                         ),
//                       ),
//                   ],
//                 ),
//               ],
//               if (_hasValue(details, 'previous_history') || _hasValue(details, 'Other History')) ...[
//                 const SizedBox(height: 20),
//                 _buildSectionHeader(context, 'Previous History'),
//                 if (details['previous_history'] is List && (details['previous_history'] as List).isNotEmpty)
//                   _buildText((details['previous_history'] as List).join(', ')),
//                 if (_hasValue(details, 'Other History'))
//                   _buildInfoRow(
//                     'Other History:',
//                     details['Other History'].toString(),
//                   ),
//               ],
//               if (_hasValue(details, 'Nurse\'s Notes')) ...[
//                 const SizedBox(height: 20),
//                 _buildSectionHeader(context, 'Nurse\'s Notes'),
//                 _buildText(details['Nurse\'s Notes'].toString()),
//               ],
//               // New section to display the signature images
//               if (frontImage != null || backImage != null) ...[
//                 const SizedBox(height: 20),
//                 _buildSectionHeader(context, 'Sign of Symptoms'),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     Expanded(
//                       child: Column(
//                         children: [
//                           const Text(
//                             "Front View",
//                             style: TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           const SizedBox(height: 8),
//                           if (frontImage != null)
//                             Image.memory(
//                               frontImage,
//                               fit: BoxFit.contain,
//                               height: 400,
//                             )
//                           else
//                             const Text("No front signature drawn."),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(width: 20),
//                     Expanded(
//                       child: Column(
//                         children: [
//                           const Text(
//                             "Back View",
//                             style: TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           const SizedBox(height: 8),
//                           if (backImage != null)
//                             Image.memory(
//                               backImage,
//                               fit: BoxFit.contain,
//                               height: 400,
//                             )
//                           else
//                             const Text("No back signature drawn."),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//               if (observations.isNotEmpty) ...[
//                 const SizedBox(height: 20),
//                 _buildSectionHeader(context, 'Observation Notes'),
//                 _buildObservationsTable(observations),
//               ],
//               if (details['TREATMENT/ACTION'] is List && (details['TREATMENT/ACTION'] as List).isNotEmpty) ...[
//                 const SizedBox(height: 20),
//                 _buildSectionHeader(context, 'Treatment/Action'),
//                 _buildText((details['TREATMENT/ACTION'] as List).join(', ')),
//               ],
//               if (details['HANDLING & IMMOBILISATION ON DEPARTURE'] is List && (details['HANDLING & IMMOBILISATION ON DEPARTURE'] as List).isNotEmpty) ...[
//                 const SizedBox(height: 20),
//                 _buildSectionHeader(
//                   context,
//                   'Handling & Immobilisation on Departure',
//                 ),
//                 _buildText(
//                   (details['HANDLING & IMMOBILISATION ON DEPARTURE'] as List)
//                       .join(', '),
//                 ),
//               ],
//               if (_hasValue(details, 'General Condition')) ...[
//                 const SizedBox(height: 20),
//                 _buildSectionHeader(context, 'General Condition'),
//                 _buildText(details['General Condition'].toString()),
//               ],
//               if (_hasValue(details, 'BP (mmHg)') ||
//                   _hasValue(details, 'RR (min)') ||
//                   _hasValue(details, 'SPO2 (%)') ||
//                   _hasValue(details, 'Pain Score (/10)') ||
//                   _hasValue(details, 'Temperature (°C)') ||
//                   _hasValue(details, 'Glucose (mmol/L)')) ...[
//                 const SizedBox(height: 20),
//                 _buildSectionHeader(context, 'On Arrival Vital Signs Record'),
//                 if (_hasValue(details, 'BP (mmHg)'))
//                   _buildInfoRow('BP (mmHg):', details['BP (mmHg)'].toString()),
//                 if (_hasValue(details, 'RR (min)'))
//                   _buildInfoRow('RR (min):', details['RR (min)'].toString()),
//                 if (_hasValue(details, 'SPO2 (%)'))
//                   _buildInfoRow('SPO2 (%):', details['SPO2 (%)'].toString()),
//                 if (_hasValue(details, 'Pain Score (/10)'))
//                   _buildInfoRow(
//                     'Pain Score (/10):',
//                     details['Pain Score (/10)'].toString(),
//                   ),
//                 if (_hasValue(details, 'Temperature (°C)'))
//                   _buildInfoRow(
//                     'Temperature (°C):',
//                     details['Temperature (°C)'].toString(),
//                   ),
//                 if (_hasValue(details, 'Glucose (mmol/L)'))
//                   _buildInfoRow(
//                     'Glucose (mmol/L):',
//                     details['Glucose (mmol/L)'].toString(),
//                   ),
//               ],
//               if (_hasValue(details, 'Condition Status') ||
//                   (details['Condition Status'] == 'Death' && _hasValue(details, 'DeathTime')) ||
//                   (details['Condition Status'] == 'Others' && _hasValue(details, 'Other Condition Text'))) ...[
//                 const SizedBox(height: 20),
//                 _buildSectionHeader(context, 'Condition Status'),
//                 if (_hasValue(details, 'Condition Status'))
//                   _buildInfoRow(
//                     'Condition:',
//                     details['Condition Status'].toString(),
//                   ),
//                 if (details['Condition Status'] == "Death" && _hasValue(details, 'DeathTime'))
//                   _buildInfoRow('Death Time:', details['DeathTime'].toString()),
//                 if (details['Condition Status'] == "Others" && _hasValue(details, 'Other Condition Text'))
//                   _buildInfoRow(
//                     'Other details:',
//                     details['Other Condition Text'].toString(),
//                   ),
//               ],
//               if (_hasValue(details, 'Other Patient Progress/ Remarks')) ...[
//                 const SizedBox(height: 20),
//                 _buildSectionHeader(context, 'Other Patient Progress / Remarks'),
//                 _buildText(details['Other Patient Progress/ Remarks'].toString()),
//               ],
//               const SizedBox(height: 20),
//               _buildSectionHeader(context, 'Staff & Documentation'),
//               if (_hasValue(details, 'documents_provided'))
//                 _buildInfoRow(
//                   'Documents Provided:',
//                   (details['documents_provided'] as List).join(', '),
//                 ),
//               Row(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       children: [
//                         if (_hasValue(details, 'patient_name'))
//                           _buildInfoRow(
//                             'Patient Name:',
//                             details['patient_name'].toString(),
//                           ),
//                         if (_hasValue(details, 'patient_ic_no'))
//                           _buildInfoRow(
//                             'Patient IC No:',
//                             details['patient_ic_no'].toString(),
//                           ),
//                         if (_hasValue(details, 'patient_signature'))
//                           _buildSignatureDisplay(details['patient_signature']),
//                       ],
//                     ),
//                   ),
//                   Expanded(
//                     child: Column(
//                       children: [
//                         if (_hasValue(details, 'staff_name'))
//                           _buildInfoRow(
//                             'Staff Name:',
//                             details['staff_name'].toString(),
//                           ),
//                         if (_hasValue(details, 'staff_ic_no'))
//                           _buildInfoRow(
//                             'Staff IC No:',
//                             details['staff_ic_no'].toString(),
//                           ),
//                         if (_hasValue(details, 'staff_signature'))
//                           _buildSignatureDisplay(details['staff_signature']),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               Row(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       children: [
//                         if (_hasValue(details, 'endorsed_by_name'))
//                           _buildInfoRow(
//                             'Endorsed By:',
//                             details['endorsed_by_name'].toString(),
//                           ),
//                         if (_hasValue(details, 'endorsedDate'))
//                           _buildInfoRow(
//                             'Endorsed Date:',
//                             _getSafeDatePart(details['endorsedDate']?.toString()),
//                           ),
//                         if (_hasValue(details, 'endorsedTime'))
//                           _buildInfoRow(
//                             'Endorsed Date:',
//                             _getSafeDatePart(details['endorsedTime']?.toString()),
//                           ),
//                         if (_hasValue(details, 'endorsed_by_signature'))
//                           _buildSignatureDisplay(
//                             details['endorsed_by_signature'],
//                           ),
//                       ],
//                     ),
//                   ),
//                   Expanded(
//                     child: Column(
//                       children: [
//                         if (_hasValue(details, 'received_by_name'))
//                           _buildInfoRow(
//                             'Received By:',
//                             details['received_by_name'].toString(),
//                           ),
//                         if (_hasValue(details, 'receivedDate'))
//                           _buildInfoRow(
//                             'Received Date:',
//                             _getSafeDatePart(details['receivedDate']?.toString()),
//                           ),
//                         if (_hasValue(details, 'receivedTime'))
//                           _buildInfoRow(
//                             'Received Time:',
//                             _getSafeTimePart(details['receivedTime']?.toString()),
//                           ),
//                         if (_hasValue(details, 'received_by_signature'))
//                           _buildSignatureDisplay(
//                             details['received_by_signature'],
//                           ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   // A helper function to check if a map value is not null and not empty.
//   bool _hasValue(Map<String, dynamic> map, String key) {
//     final value = map[key];
//     if (value == null) {
//       return false;
//     }
//     if (value is String) {
//       return value.trim().isNotEmpty;
//     }
//     if (value is List) {
//       return value.isNotEmpty;
//     }
//     if (value is Map) {
//       return value.isNotEmpty;
//     }
//     return true;
//   }
//
//   Widget _buildSignatureDisplay(String? base64String) {
//     if (base64String == null || base64String.isEmpty) {
//       return Container(
//         height: 100,
//         width: 300,
//         decoration: BoxDecoration(
//           border: Border.all(color: Colors.grey.shade400),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: const Center(child: Text('No Signature Provided')),
//       );
//     }
//     try {
//       final Uint8List bytes = base64Decode(base64String);
//       return Container(
//         decoration: BoxDecoration(
//           border: Border.all(color: Colors.grey.shade400),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Image.memory(
//           bytes,
//           height: 100,
//           width: 300,
//           fit: BoxFit.contain,
//         ),
//       );
//     } catch (e) {
//       return const Text('Error loading signature');
//     }
//   }
//
//   Widget _buildSectionHeader(BuildContext context, String title) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(title, style: Theme.of(context).textTheme.headlineSmall),
//         const SizedBox(height: 8),
//       ],
//     );
//   }
//
//   List<Widget> _buildPrimarySurvey(dynamic surveyData) {
//     if (surveyData is! Map<String, dynamic>) {
//       return [const Text('No primary survey data available.')];
//     }
//     return surveyData.entries.map((entry) {
//       String value = '';
//       if (entry.value is List) {
//         value = (entry.value as List).join(', ');
//       } else if (entry.value is Set) {
//         value = (entry.value as Set).join(', ');
//       } else {
//         value = entry.value.toString();
//       }
//       return _buildInfoRow('${entry.key}:', value);
//     }).toList();
//   }
//
//   Widget _buildText(String text) {
//     return Text(text, style: GoogleFonts.poppins(fontSize: 14));
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
//           Expanded(child: Text(value)),
//         ],
//       ),
//     );
//   }
//
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
// }