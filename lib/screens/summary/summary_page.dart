import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/patient_form_data.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Your PatientDetailsForm widget is still used to display the content on the screen.
import 'patient_details_summary.dart';

class SummaryPage extends StatelessWidget {
  const SummaryPage({super.key});

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

  // Helper function to safely get the first part of a date string for the PDF.
  String _getSafeDatePart(String? date) {
    if (date == null || !date.contains(' ')) {
      return date ?? '';
    }
    return date.split(' ')[0];
  }

  // Helper function to safely get the time from a string for the PDF.
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

  pw.Widget _buildPdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4.0),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfSectionHeader(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
      ],
    );
  }

  pw.Widget _buildPdfSignatureDisplay(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return pw.Container(
        height: 100,
        width: 300,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Center(child: pw.Text('No Signature Provided')),
      );
    }
    try {
      final Uint8List bytes = base64Decode(base64String);
      return pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Image(
          pw.MemoryImage(bytes),
          height: 100,
          width: 300,
          fit: pw.BoxFit.contain,
        ),
      );
    } catch (e) {
      return pw.Text('Error loading signature');
    }
  }

  pw.Widget _buildPdfObservationsTable(
      Map<String, List<String>> observations) {
    int maxColumns = 0;

    observations.values.forEach((row) {
      int lastNonNullIndex = -1;
      for (int i = 0; i < row.length; i++) {
        if (row[i].toString().trim().isNotEmpty) {
          lastNonNullIndex = i;
        }
      }
      int count = lastNonNullIndex >= 0 ? lastNonNullIndex + 1 : 0;
      if (count > maxColumns) {
        maxColumns = count;
      }
    });

    List<pw.Widget> observationRows = [];

    // Header row
    List<pw.Widget> headerCells = [
      pw.Expanded(flex: 2, child: pw.Text('')),
    ];
    for (int i = 0; i < maxColumns; i++) {
      headerCells.add(pw.Expanded(
        flex: 1,
        child: pw.Center(
          child: pw.Text(
            maxColumns <= 1
                ? 'Arrival'
                : i == 0
                ? 'Arrival'
                : i == maxColumns - 1
                ? 'Handover'
                : 'Intermediate',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
      ));
    }
    observationRows.add(pw.Row(children: headerCells));
    observationRows.add(pw.Divider());

    // Data rows
    observations.entries.forEach((entry) {
      List<pw.Widget> rowCells = [
        pw.Expanded(
          flex: 2,
          child: pw.Text(entry.key,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
      ];
      for (int i = 0; i < maxColumns; i++) {
        rowCells.add(pw.Expanded(
          flex: 1,
          child: pw.Center(
            child: pw.Text(
              i < entry.value.length ? entry.value[i] : '',
            ),
          ),
        ));
      }
      observationRows.add(pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4.0),
        child: pw.Row(children: rowCells),
      ));
    });

    return pw.Column(children: observationRows);
  }

  pw.Widget _buildPdfPrimarySurvey(dynamic surveyData) {
    if (surveyData is! Map<String, dynamic>) {
      return pw.Text('No primary survey data available.');
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: surveyData.entries.map((entry) {
        String value = '';
        if (entry.value is List) {
          value = (entry.value as List).join(', ');
        } else if (entry.value is Set) {
          value = (entry.value as Set).join(', ');
        } else {
          value = entry.value.toString();
        }
        return _buildPdfInfoRow('${entry.key}:', value);
      }).toList(),
    );
  }

  Future<void> _generatePdf(BuildContext context) async {
    final doc = pw.Document();
    final provider = Provider.of<PatientFormProvider>(context, listen: false);
    final details = provider.patientDetails;
    final observations = provider.observations;
    final frontImage = provider.frontSignatureImage;
    final backImage = provider.backSignatureImage;

    doc.addPage(
      pw.MultiPage( // Changed from pw.Page to pw.MultiPage
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context pwContext) {
          return [
            pw.Text(
              'MK Ambulance Patient Record',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
            pw.Text(
              'Patient Information',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 15, vertical: 20),
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.all(const pw.Radius.circular(10)),
                border: pw.Border.all(color: PdfColors.grey, width: 1.0),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (_hasValue(details, 'Name'))
                          _buildPdfInfoRow('Name:', details['Name'].toString()),
                        if (_hasValue(details, 'NRIC Number'))
                          _buildPdfInfoRow(
                            'NRIC Number:',
                            details['NRIC Number'].toString(),
                          ),
                        if (_hasValue(details, 'patient_dob'))
                          _buildPdfInfoRow(
                            'Date of Birth:',
                            details['patient_dob'].toString(),
                          ),
                        if (_hasValue(details, 'Age'))
                          _buildPdfInfoRow('Age:', details['Age'].toString()),
                        if (_hasValue(details, 'patient_gender'))
                          _buildPdfInfoRow(
                            'Gender:',
                            details['patient_gender'].toString(),
                          ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (_hasValue(details, 'patient_entry_date'))
                          _buildPdfInfoRow(
                            'Date:',
                            _getSafeDatePart(
                              details['patient_entry_date']?.toString(),
                            ),
                          ),
                        if (_hasValue(details, 'patient_entry_time'))
                          _buildPdfInfoRow(
                            'Time:',
                            details['patient_entry_time'].toString(),
                          ),
                        if (_hasValue(details, 'referral_type'))
                          _buildPdfInfoRow(
                            'Referral Type:',
                            details['referral_type'].toString(),
                          ),
                        if (details['referral_type'] == 'HOSPITAL REFERRAL' && _hasValue(details, 'Referral Hospital'))
                          _buildPdfInfoRow(
                            'Referral Hospital:',
                            details['Referral Hospital'].toString(),
                          ),
                        if (_hasValue(details, 'Location'))
                          _buildPdfInfoRow(
                            'Location:',
                            details['Location'].toString(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_hasValue(details, 'chief_complain')) ...[
              pw.SizedBox(height: 20),
              _buildPdfSectionHeader('Chief Complaint'),
              pw.Text(details['chief_complain'].toString()),
            ],
            if (_hasValue(details, 'primary_survey') || _hasValue(details, 'Allergies') || _hasValue(details, 'Medication')) ...[
              pw.SizedBox(height: 20),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (_hasValue(details, 'primary_survey'))
                    pw.Expanded(
                      flex: 1,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildPdfSectionHeader('Primary Survey'),
                          if (details['primary_survey'] is Map<String, List<String>>)
                            _buildPdfPrimarySurvey(
                              details['primary_survey']
                              as Map<String, List<String>>,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            if (_hasValue(details, 'primary_survey') || _hasValue(details, 'Allergies') || _hasValue(details, 'Medication')) ...[
              pw.SizedBox(height: 20),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (_hasValue(details, 'Allergies') || _hasValue(details, 'Medication'))
                    pw.Expanded(
                      flex: 3,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildPdfSectionHeader('Allergies & Medication'),
                          if (_hasValue(details, 'Allergies'))
                            _buildPdfInfoRow(
                              'Allergies:',
                              details['Allergies'].toString(),
                            ),
                          if (_hasValue(details, 'Medication'))
                            _buildPdfInfoRow(
                              'Medication:',
                              details['Medication'].toString(),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            if (_hasValue(details, 'previous_history') || _hasValue(details, 'Other History')) ...[
              pw.SizedBox(height: 20),
              _buildPdfSectionHeader('Previous History'),
              if (details['previous_history'] is List && (details['previous_history'] as List).isNotEmpty)
                pw.Text((details['previous_history'] as List).join(', ')),
              if (_hasValue(details, 'Other History'))
                _buildPdfInfoRow(
                  'Other History:',
                  details['Other History'].toString(),
                ),
            ],
            if (_hasValue(details, 'Nurse\'s Notes')) ...[
              pw.SizedBox(height: 20),
              _buildPdfSectionHeader('Nurse\'s Notes'),
              pw.Text(details['Nurse\'s Notes'].toString()),
            ],
            if (frontImage != null || backImage != null) ...[
              pw.SizedBox(height: 20),
              _buildPdfSectionHeader('Sign of Symptoms'),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          "Front View",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 8),
                        if (frontImage != null)
                          pw.Image(
                            pw.MemoryImage(frontImage),
                            fit: pw.BoxFit.contain,
                            height: 400,
                          )
                        else
                          pw.Text("No front signature drawn."),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          "Back View",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 8),
                        if (backImage != null)
                          pw.Image(
                            pw.MemoryImage(backImage),
                            fit: pw.BoxFit.contain,
                            height: 400,
                          )
                        else
                          pw.Text("No back signature drawn."),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (observations.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              _buildPdfSectionHeader('Observation Notes'),
              _buildPdfObservationsTable(observations),
            ],
            if (details['TREATMENT/ACTION'] is List && (details['TREATMENT/ACTION'] as List).isNotEmpty) ...[
              pw.SizedBox(height: 20),
              _buildPdfSectionHeader('Treatment/Action'),
              pw.Text((details['TREATMENT/ACTION'] as List).join(', ')),
            ],
            if (details['HANDLING & IMMOBILISATION ON DEPARTURE'] is List && (details['HANDLING & IMMOBILISATION ON DEPARTURE'] as List).isNotEmpty) ...[
              pw.SizedBox(height: 20),
              _buildPdfSectionHeader(
                'Handling & Immobilisation on Departure',
              ),
              pw.Text(
                (details['HANDLING & IMMOBILISATION ON DEPARTURE'] as List)
                    .join(', '),
              ),
            ],
            if (_hasValue(details, 'General Condition')) ...[
              pw.SizedBox(height: 20),
              _buildPdfSectionHeader('General Condition'),
              pw.Text(details['General Condition'].toString()),
            ],
            if (_hasValue(details, 'BP (mmHg)') ||
                _hasValue(details, 'RR (min)') ||
                _hasValue(details, 'SPO2 (%)') ||
                _hasValue(details, 'Pain Score (/10)') ||
                _hasValue(details, 'Temperature (°C)') ||
                _hasValue(details, 'Glucose (mmol/L)')) ...[
              pw.SizedBox(height: 20),
              _buildPdfSectionHeader('On Arrival Vital Signs Record'),
              if (_hasValue(details, 'BP (mmHg)'))
                _buildPdfInfoRow('BP (mmHg):', details['BP (mmHg)'].toString()),
              if (_hasValue(details, 'RR (min)'))
                _buildPdfInfoRow('RR (min):', details['RR (min)'].toString()),
              if (_hasValue(details, 'SPO2 (%)'))
                _buildPdfInfoRow('SPO2 (%):', details['SPO2 (%)'].toString()),
              if (_hasValue(details, 'Pain Score (/10)'))
                _buildPdfInfoRow(
                  'Pain Score (/10):',
                  details['Pain Score (/10)'].toString(),
                ),
              if (_hasValue(details, 'Temperature (°C)'))
                _buildPdfInfoRow(
                  'Temperature (°C):',
                  details['Temperature (°C)'].toString(),
                ),
              if (_hasValue(details, 'Glucose (mmol/L)'))
                _buildPdfInfoRow(
                  'Glucose (mmol/L):',
                  details['Glucose (mmol/L)'].toString(),
                ),
            ],
            if (_hasValue(details, 'Condition Status') ||
                (details['Condition Status'] == 'Death' && _hasValue(details, 'DeathTime')) ||
                (details['Condition Status'] == 'Others' && _hasValue(details, 'Specify others'))) ...[
              pw.SizedBox(height: 20),
              _buildPdfSectionHeader('Condition Status'),
              if (_hasValue(details, 'Condition Status'))
                _buildPdfInfoRow(
                  'Condition:',
                  details['Condition Status'].toString(),
                ),
              if (details['Condition Status'] == "Death" && _hasValue(details, 'DeathTime'))
                _buildPdfInfoRow('Death Time:', details['DeathTime'].toString()),
              if (details['Condition Status'] == "Others" && _hasValue(details, 'Specify others'))
                _buildPdfInfoRow(
                  'Other details:',
                  details['Specify others'].toString(),
                ),
            ],
            if (_hasValue(details, 'Other Patient Progress/ Remarks')) ...[
              pw.SizedBox(height: 20),
              _buildPdfSectionHeader('Other Patient Progress / Remarks'),
              pw.Text(details['Other Patient Progress/ Remarks'].toString()),
            ],
            pw.SizedBox(height: 20),
            _buildPdfSectionHeader('Sign-Off Details'),
            if (_hasValue(details, 'documents_provided'))
              _buildPdfInfoRow(
                'Documents Provided:',
                (details['documents_provided'] as List).join(', '),
              ),
            if (_hasValue(details, 'referral_letter_documents_text'))
              _buildPdfInfoRow('Referral Letter:', (details['referral_letter_documents_text'])),
            if (_hasValue(details, 'other_docs'))
              _buildPdfInfoRow('Other Documents Provided:', (details['other_docs'])),
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      if (_hasValue(details, 'patient_name'))
                        _buildPdfInfoRow(
                          'Patient Name:',
                          details['patient_name'].toString(),
                        ),
                      if (_hasValue(details, 'patient_ic_no'))
                        _buildPdfInfoRow(
                          'Patient IC No:',
                          details['patient_ic_no'].toString(),
                        ),
                      if (_hasValue(details, 'patient_signature'))
                        _buildPdfSignatureDisplay(details['patient_signature']),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      if (_hasValue(details, 'staff_name'))
                        _buildPdfInfoRow(
                          'Staff Name:',
                          details['staff_name'].toString(),
                        ),
                      if (_hasValue(details, 'staff_ic_no'))
                        _buildPdfInfoRow(
                          'Staff IC No:',
                          details['staff_ic_no'].toString(),
                        ),
                      if (_hasValue(details, 'staff_signature'))
                        _buildPdfSignatureDisplay(details['staff_signature']),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      if (_hasValue(details, 'endorsed_by_name'))
                        _buildPdfInfoRow(
                          'Endorsed By:',
                          details['endorsed_by_name'].toString(),
                        ),
                      if (_hasValue(details, 'endorsedDate'))
                        _buildPdfInfoRow(
                          'Endorsed Date:',
                          _getSafeDatePart(details['endorsedDate']?.toString()),
                        ),
                      if (_hasValue(details, 'endorsedTime'))
                        _buildPdfInfoRow(
                          'Endorsed Time:',
                          _getSafeTimePart(details['endorsedTime']?.toString()),
                        ),
                      if (_hasValue(details, 'endorsed_by_signature'))
                        _buildPdfSignatureDisplay(
                          details['endorsed_by_signature'],
                        ),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      if (_hasValue(details, 'received_by_name'))
                        _buildPdfInfoRow(
                          'Received By:',
                          details['received_by_name'].toString(),
                        ),
                      if (_hasValue(details, 'receivedDate'))
                        _buildPdfInfoRow(
                          'Received Date:',
                          _getSafeDatePart(details['receivedDate']?.toString()),
                        ),
                      if (_hasValue(details, 'receivedTime'))
                        _buildPdfInfoRow(
                          'Received Time:',
                          _getSafeTimePart(details['receivedTime']?.toString()),
                        ),
                      if (_hasValue(details, 'received_by_signature'))
                        _buildPdfSignatureDisplay(
                          details['received_by_signature'],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ]; // The build function of pw.MultiPage returns a list of widgets.
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  // pdf contains only 1 page
  // Future<void> _generatePdf(BuildContext context) async {
  //   final doc = pw.Document();
  //   final provider = Provider.of<PatientFormProvider>(context, listen: false);
  //   final details = provider.patientDetails;
  //   final observations = provider.observations;
  //   final frontImage = provider.frontSignatureImage;
  //   final backImage = provider.backSignatureImage;
  //
  //   doc.addPage(
  //     pw.Page(
  //       pageFormat: PdfPageFormat.a4,
  //       build: (pw.Context pwContext) {
  //         return pw.Column(
  //           crossAxisAlignment: pw.CrossAxisAlignment.start,
  //           children: [
  //             pw.Text(
  //               'MK Ambulance Patient Record',
  //               style: pw.TextStyle(
  //                 fontSize: 24,
  //                 fontWeight: pw.FontWeight.bold,
  //               ),
  //               textAlign: pw.TextAlign.center,
  //             ),
  //             pw.Text(
  //               'Patient Information',
  //               style: pw.TextStyle(
  //                 fontSize: 20,
  //                 fontWeight: pw.FontWeight.bold,
  //               ),
  //             ),
  //             pw.SizedBox(height: 10),
  //             pw.Container(
  //               padding: const pw.EdgeInsets.symmetric(
  //                   horizontal: 15, vertical: 20),
  //               decoration: pw.BoxDecoration(
  //                 borderRadius: pw.BorderRadius.all(const pw.Radius.circular(10)),
  //                 border: pw.Border.all(color: PdfColors.grey, width: 1.0),
  //               ),
  //               child: pw.Row(
  //                 children: [
  //                   pw.Expanded(
  //                     child: pw.Column(
  //                       crossAxisAlignment: pw.CrossAxisAlignment.start,
  //                       children: [
  //                         if (_hasValue(details, 'Name'))
  //                           _buildPdfInfoRow('Name:', details['Name'].toString()),
  //                         if (_hasValue(details, 'NRIC Number'))
  //                           _buildPdfInfoRow(
  //                             'NRIC Number:',
  //                             details['NRIC Number'].toString(),
  //                           ),
  //                         if (_hasValue(details, 'patient_dob'))
  //                           _buildPdfInfoRow(
  //                             'Date of Birth:',
  //                             details['patient_dob'].toString(),
  //                           ),
  //                         if (_hasValue(details, 'Age'))
  //                           _buildPdfInfoRow('Age:', details['Age'].toString()),
  //                         if (_hasValue(details, 'patient_gender'))
  //                           _buildPdfInfoRow(
  //                             'Gender:',
  //                             details['patient_gender'].toString(),
  //                           ),
  //                       ],
  //                     ),
  //                   ),
  //                   pw.Expanded(
  //                     child: pw.Column(
  //                       crossAxisAlignment: pw.CrossAxisAlignment.start,
  //                       children: [
  //                         if (_hasValue(details, 'patient_entry_date'))
  //                           _buildPdfInfoRow(
  //                             'Date:',
  //                             _getSafeDatePart(
  //                               details['patient_entry_date']?.toString(),
  //                             ),
  //                           ),
  //                         if (_hasValue(details, 'patient_entry_time'))
  //                           _buildPdfInfoRow(
  //                             'Time:',
  //                             details['patient_entry_time'].toString(),
  //                           ),
  //                         if (_hasValue(details, 'referral_type'))
  //                           _buildPdfInfoRow(
  //                             'Referral Type:',
  //                             details['referral_type'].toString(),
  //                           ),
  //                         if (_hasValue(details, 'Location'))
  //                           _buildPdfInfoRow(
  //                             'Location:',
  //                             details['Location'].toString(),
  //                           ),
  //                       ],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             if (_hasValue(details, 'chief_complain')) ...[
  //               pw.SizedBox(height: 20),
  //               _buildPdfSectionHeader('Chief Complaint'),
  //               pw.Text(details['chief_complain'].toString()),
  //             ],
  //             if (_hasValue(details, 'primary_survey') || _hasValue(details, 'Allergies') || _hasValue(details, 'Medication')) ...[
  //               pw.SizedBox(height: 20),
  //               pw.Row(
  //                 crossAxisAlignment: pw.CrossAxisAlignment.start,
  //                 children: [
  //                   if (_hasValue(details, 'primary_survey'))
  //                     pw.Expanded(
  //                       flex: 1,
  //                       child: pw.Column(
  //                         crossAxisAlignment: pw.CrossAxisAlignment.start,
  //                         children: [
  //                           _buildPdfSectionHeader('Primary Survey'),
  //                           if (details['primary_survey'] is Map<String, List<String>>)
  //                             _buildPdfPrimarySurvey(
  //                               details['primary_survey']
  //                               as Map<String, List<String>>,
  //                             ),
  //                         ],
  //                       ),
  //                     ),
  //                 ],
  //               ),
  //             ],
  //             if (_hasValue(details, 'primary_survey') || _hasValue(details, 'Allergies') || _hasValue(details, 'Medication')) ...[
  //               pw.SizedBox(height: 20),
  //               pw.Row(
  //                 crossAxisAlignment: pw.CrossAxisAlignment.start,
  //                 children: [
  //                   if (_hasValue(details, 'Allergies') || _hasValue(details, 'Medication'))
  //                     pw.Expanded(
  //                       flex: 3,
  //                       child: pw.Column(
  //                         crossAxisAlignment: pw.CrossAxisAlignment.start,
  //                         children: [
  //                           _buildPdfSectionHeader('Allergies & Medication'),
  //                           if (_hasValue(details, 'Allergies'))
  //                             _buildPdfInfoRow(
  //                               'Allergies:',
  //                               details['Allergies'].toString(),
  //                             ),
  //                           if (_hasValue(details, 'Medication'))
  //                             _buildPdfInfoRow(
  //                               'Medication:',
  //                               details['Medication'].toString(),
  //                             ),
  //                         ],
  //                       ),
  //                     ),
  //                 ],
  //               ),
  //             ],
  //             if (_hasValue(details, 'previous_history') || _hasValue(details, 'Other History')) ...[
  //               pw.SizedBox(height: 20),
  //               _buildPdfSectionHeader('Previous History'),
  //               if (details['previous_history'] is List && (details['previous_history'] as List).isNotEmpty)
  //                 pw.Text((details['previous_history'] as List).join(', ')),
  //               if (_hasValue(details, 'Other History'))
  //                 _buildPdfInfoRow(
  //                   'Other History:',
  //                   details['Other History'].toString(),
  //                 ),
  //             ],
  //             if (_hasValue(details, 'Nurse\'s Notes')) ...[
  //               pw.SizedBox(height: 20),
  //               _buildPdfSectionHeader('Nurse\'s Notes'),
  //               pw.Text(details['Nurse\'s Notes'].toString()),
  //             ],
  //             if (frontImage != null || backImage != null) ...[
  //               pw.SizedBox(height: 20),
  //               _buildPdfSectionHeader('Sign of Symptoms'),
  //               pw.Row(
  //                 mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
  //                 children: [
  //                   pw.Expanded(
  //                     child: pw.Column(
  //                       children: [
  //                         pw.Text(
  //                           "Front View",
  //                           style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
  //                         ),
  //                         pw.SizedBox(height: 8),
  //                         if (frontImage != null)
  //                           pw.Image(
  //                             pw.MemoryImage(frontImage),
  //                             fit: pw.BoxFit.contain,
  //                             height: 400,
  //                           )
  //                         else
  //                           pw.Text("No front signature drawn."),
  //                       ],
  //                     ),
  //                   ),
  //                   pw.SizedBox(width: 20),
  //                   pw.Expanded(
  //                     child: pw.Column(
  //                       children: [
  //                         pw.Text(
  //                           "Back View",
  //                           style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
  //                         ),
  //                         pw.SizedBox(height: 8),
  //                         if (backImage != null)
  //                           pw.Image(
  //                             pw.MemoryImage(backImage),
  //                             fit: pw.BoxFit.contain,
  //                             height: 400,
  //                           )
  //                         else
  //                           pw.Text("No back signature drawn."),
  //                       ],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //             if (observations.isNotEmpty) ...[
  //               pw.SizedBox(height: 20),
  //               _buildPdfSectionHeader('Observation Notes'),
  //               _buildPdfObservationsTable(observations),
  //             ],
  //             if (details['TREATMENT/ACTION'] is List && (details['TREATMENT/ACTION'] as List).isNotEmpty) ...[
  //               pw.SizedBox(height: 20),
  //               _buildPdfSectionHeader('Treatment/Action'),
  //               pw.Text((details['TREATMENT/ACTION'] as List).join(', ')),
  //             ],
  //             if (details['HANDLING & IMMOBILISATION ON DEPARTURE'] is List && (details['HANDLING & IMMOBILISATION ON DEPARTURE'] as List).isNotEmpty) ...[
  //               pw.SizedBox(height: 20),
  //               _buildPdfSectionHeader(
  //                 'Handling & Immobilisation on Departure',
  //               ),
  //               pw.Text(
  //                 (details['HANDLING & IMMOBILISATION ON DEPARTURE'] as List)
  //                     .join(', '),
  //               ),
  //             ],
  //             if (_hasValue(details, 'General Condition')) ...[
  //               pw.SizedBox(height: 20),
  //               _buildPdfSectionHeader('General Condition'),
  //               pw.Text(details['General Condition'].toString()),
  //             ],
  //             if (_hasValue(details, 'BP (mmHg)') ||
  //                 _hasValue(details, 'RR (min)') ||
  //                 _hasValue(details, 'SPO2 (%)') ||
  //                 _hasValue(details, 'Pain Score (/10)') ||
  //                 _hasValue(details, 'Temperature (°C)') ||
  //                 _hasValue(details, 'Glucose (mmol/L)')) ...[
  //               pw.SizedBox(height: 20),
  //               _buildPdfSectionHeader('On Arrival Vital Signs Record'),
  //               if (_hasValue(details, 'BP (mmHg)'))
  //                 _buildPdfInfoRow('BP (mmHg):', details['BP (mmHg)'].toString()),
  //               if (_hasValue(details, 'RR (min)'))
  //                 _buildPdfInfoRow('RR (min):', details['RR (min)'].toString()),
  //               if (_hasValue(details, 'SPO2 (%)'))
  //                 _buildPdfInfoRow('SPO2 (%):', details['SPO2 (%)'].toString()),
  //               if (_hasValue(details, 'Pain Score (/10)'))
  //                 _buildPdfInfoRow(
  //                   'Pain Score (/10):',
  //                   details['Pain Score (/10)'].toString(),
  //                 ),
  //               if (_hasValue(details, 'Temperature (°C)'))
  //                 _buildPdfInfoRow(
  //                   'Temperature (°C):',
  //                   details['Temperature (°C)'].toString(),
  //                 ),
  //               if (_hasValue(details, 'Glucose (mmol/L)'))
  //                 _buildPdfInfoRow(
  //                   'Glucose (mmol/L):',
  //                   details['Glucose (mmol/L)'].toString(),
  //                 ),
  //             ],
  //             if (_hasValue(details, 'Condition Status') ||
  //                 (details['Condition Status'] == 'Death' && _hasValue(details, 'DeathTime')) ||
  //                 (details['Condition Status'] == 'Others' && _hasValue(details, 'Specify others'))) ...[
  //               pw.SizedBox(height: 20),
  //               _buildPdfSectionHeader('Condition Status'),
  //               if (_hasValue(details, 'Condition Status'))
  //                 _buildPdfInfoRow(
  //                   'Condition:',
  //                   details['Condition Status'].toString(),
  //                 ),
  //               if (details['Condition Status'] == "Death" && _hasValue(details, 'DeathTime'))
  //                 _buildPdfInfoRow('Death Time:', details['DeathTime'].toString()),
  //               if (details['Condition Status'] == "Others" && _hasValue(details, 'Specify others'))
  //                 _buildPdfInfoRow(
  //                   'Other details:',
  //                   details['Specify others'].toString(),
  //                 ),
  //             ],
  //             if (_hasValue(details, 'Other Patient Progress/ Remarks')) ...[
  //               pw.SizedBox(height: 20),
  //               _buildPdfSectionHeader('Other Patient Progress / Remarks'),
  //               pw.Text(details['Other Patient Progress/ Remarks'].toString()),
  //             ],
  //             pw.SizedBox(height: 20),
  //             _buildPdfSectionHeader('Sign-Off Details'),
  //             if (_hasValue(details, 'documents_provided'))
  //               _buildPdfInfoRow(
  //                 'Documents Provided:',
  //                 (details['documents_provided'] as List).join(', '),
  //               ),
  //             pw.Row(
  //               children: [
  //                 pw.Expanded(
  //                   child: pw.Column(
  //                     children: [
  //                       if (_hasValue(details, 'patient_name'))
  //                         _buildPdfInfoRow(
  //                           'Patient Name:',
  //                           details['patient_name'].toString(),
  //                         ),
  //                       if (_hasValue(details, 'patient_ic_no'))
  //                         _buildPdfInfoRow(
  //                           'Patient IC No:',
  //                           details['patient_ic_no'].toString(),
  //                         ),
  //                       if (_hasValue(details, 'patient_signature'))
  //                         _buildPdfSignatureDisplay(details['patient_signature']),
  //                     ],
  //                   ),
  //                 ),
  //                 pw.Expanded(
  //                   child: pw.Column(
  //                     children: [
  //                       if (_hasValue(details, 'staff_name'))
  //                         _buildPdfInfoRow(
  //                           'Staff Name:',
  //                           details['staff_name'].toString(),
  //                         ),
  //                       if (_hasValue(details, 'staff_ic_no'))
  //                         _buildPdfInfoRow(
  //                           'Staff IC No:',
  //                           details['staff_ic_no'].toString(),
  //                         ),
  //                       if (_hasValue(details, 'staff_signature'))
  //                         _buildPdfSignatureDisplay(details['staff_signature']),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             pw.SizedBox(height: 20),
  //             pw.Row(
  //               children: [
  //                 pw.Expanded(
  //                   child: pw.Column(
  //                     children: [
  //                       if (_hasValue(details, 'endorsed_by_name'))
  //                         _buildPdfInfoRow(
  //                           'Endorsed By:',
  //                           details['endorsed_by_name'].toString(),
  //                         ),
  //                       if (_hasValue(details, 'endorsedDate'))
  //                         _buildPdfInfoRow(
  //                           'Endorsed Date:',
  //                           _getSafeDatePart(details['endorsedDate']?.toString()),
  //                         ),
  //                       if (_hasValue(details, 'endorsedTime'))
  //                         _buildPdfInfoRow(
  //                           'Endorsed Time:',
  //                           _getSafeTimePart(details['endorsedTime']?.toString()),
  //                         ),
  //                       if (_hasValue(details, 'endorsed_by_signature'))
  //                         _buildPdfSignatureDisplay(
  //                           details['endorsed_by_signature'],
  //                         ),
  //                     ],
  //                   ),
  //                 ),
  //                 pw.Expanded(
  //                   child: pw.Column(
  //                     children: [
  //                       if (_hasValue(details, 'received_by_name'))
  //                         _buildPdfInfoRow(
  //                           'Received By:',
  //                           details['received_by_name'].toString(),
  //                         ),
  //                       if (_hasValue(details, 'receivedDate'))
  //                         _buildPdfInfoRow(
  //                           'Received Date:',
  //                           _getSafeDatePart(details['receivedDate']?.toString()),
  //                         ),
  //                       if (_hasValue(details, 'receivedTime'))
  //                         _buildPdfInfoRow(
  //                           'Received Time:',
  //                           _getSafeTimePart(details['receivedTime']?.toString()),
  //                         ),
  //                       if (_hasValue(details, 'received_by_signature'))
  //                         _buildPdfSignatureDisplay(
  //                           details['received_by_signature'],
  //                         ),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         );
  //       },
  //     ),
  //   );
  //
  //   await Printing.layoutPdf(
  //     onLayout: (PdfPageFormat format) async => doc.save(),
  //   );
  // }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const PatientDetailsForm(),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.print),
            onPressed: () => _generatePdf(context),
            label: const Text('Print Page'),
          ),
        ],
      ),
    );
  }
}
