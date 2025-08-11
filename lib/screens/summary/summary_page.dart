import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'patient_details_summary.dart';

class SummaryPage extends StatelessWidget {
  const SummaryPage({super.key});

  Future<void> _printDocument(BuildContext context) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context pwContext) {
          // This is where you would build the PDF content.
          // For simplicity, we'll just add some text.
          return pw.Center(
            child: pw.Column(
              children: [
                pw.Text('Patient Details Report'),
                pw.Text('Patient Details Report'),
                pw.Text('Patient Details Report'),
              ],
            ),
          );
        },
      ),
    );

    // This is the core function that shows the print dialog on the web.
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          const PatientDetailsForm(),
          SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.print),
            onPressed: () => _printDocument(context),
            label: Text('Print Page'),
          ),
        ],
      ),
    );
  }
}

// old code
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../providers/patient_form_data.dart';
//
// class SummaryPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final data = {
//       "patient_entry_date": "2025-08-09 16:14:16.490",
//       "patient_entry_time": "4:14 PM",
//       "referral_type": "SELF REFERRAL",
//       "Location": "alpha",
//       "Name": "bravo",
//       "NRIC Number": "charlie",
//       "patient_dob": "01-01-2000",
//       "Age": "12",
//       "patient_gender": "Female",
//       "chief_complain": "chief complaint",
//       "primary_survey": {
//         "Airway": ["CLEAR", "AGONAL"],
//         "Breathing": ["ABSENT", "SHALLOW"],
//         "Circulation": ["PALE", "NORMAL", "FLUSHED", "CYNOSED"],
//       },
//       "Allergies": "allergies",
//       "Medication": "medication",
//       "previous_history": ["HIGH BLOOD PRESSURE", "RESPIRATORY", "OTHER"],
//       "Other History": "previour history",
//       "Nurse's Notes": "nurse's notes",
//       "observations": {
//         "RESPIRATORY RATE": ["1", "2", "3"],
//         "PULSE RATE": ["4", "5"],
//         "SPO2": ["6"],
//       },
//       "TREATMENT/ACTION": [
//         "NO TREATMENT / ADVICE ONLY GIVEN",
//         "REST-ICE-COMPRESS-ELEVATE",
//         "SPLIT",
//       ],
//       "Condition Status": "Improved",
//       "Death": true,
//       "DeathTime": "4:20 PM",
//     };
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         children: data.entries.map((entry) {
//           return _buildDetailItem(entry.key, entry.value);
//         }).toList(),
//       ),
//     );
//   }
//
//   Widget _buildDetailItem(String title, dynamic value) {
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 6),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               title.replaceAll("_", " "),
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 14,
//                 color: Colors.teal,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(_formatValue(value), style: const TextStyle(fontSize: 15)),
//           ],
//         ),
//       ),
//     );
//   }
//
//   String _formatValue(dynamic value) {
//     if (value == null) return '';
//     if (value is Map) {
//       return value.entries
//           .map((e) => "${e.key}: ${_formatValue(e.value)}")
//           .join("\n");
//     }
//     if (value is List) {
//       return value
//           .where((v) => v != null && v.toString().trim().isNotEmpty)
//           .join(", ");
//     }
//     return value.toString();
//   }
// }
