import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// The screens and widgets you've already imported
import 'package:mk_ambulance/screens/patient_details_page.dart';
import 'package:mk_ambulance/screens/sign_off_page.dart';
import 'package:mk_ambulance/screens/summary/summary_page.dart';
import 'package:mk_ambulance/screens/treatment_page.dart';
import '../constants/step_tiles.dart';
import '../widgets/buttons.dart';
import '../widgets/stepper_widget.dart';
import 'assessment_page.dart';

// Define breakpoints for different screen sizes.
const double kMobileBreakpoint = 600.0;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentStep = 0;
  final _treatmentFormKey = GlobalKey<FormState>();

  void _goNext() {
    bool isFormValid = true;
    if (_currentStep == 2) {
      // This is the TreatmentPage step.
      isFormValid = _treatmentFormKey.currentState?.validate() ?? false;
    }
    if (isFormValid) {
      if (_currentStep < stepTitles.length - 1) {
        setState(() {
          _currentStep++;
        });
      }
    }

  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Widget _buildPageContent() {
    switch (_currentStep) {
      case 0:
        return const PatientDetails();
      case 1:
        return const AssessmentPage();
      case 2:
        return TreatmentPage(formKey: _treatmentFormKey);
      case 3:
        return SignOffPage();
      case 4:
        return SummaryPage();
      default:
        return const Center(child: Text('Unknown Step'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/logo_bg.png',height: 50,),
              const SizedBox(width: 8),
              Text(
                'Patient Record',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Check if the screen is a mobile size.
          if (constraints.maxWidth < kMobileBreakpoint) {
            // Mobile Layout: Uses less padding and a full-width container
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    // The stepper takes the full available width
                    CustomStepper(
                      stepTitles: stepTitles,
                      currentStep: _currentStep,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: _buildPageContent(),
                    ),
                    StepNavigationButtons(
                      currentStep: _currentStep,
                      totalSteps: stepTitles.length,
                      onNext: _goNext,
                      onBack: _goBack,
                    ),
                  ],
                ),
              ),
            );
          } else {
            // Tablet/Web Layout: Centers the content in a container with a max-width
            return Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                  child: Container(
                    // Constrain the maximum width for better readability on large screens
                    constraints: const BoxConstraints(maxWidth: 800),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        // The stepper is also constrained by the container's max-width
                        CustomStepper(
                          stepTitles: stepTitles,
                          currentStep: _currentStep,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: _buildPageContent(),
                        ),
                        StepNavigationButtons(
                          currentStep: _currentStep,
                          totalSteps: stepTitles.length,
                          onNext: _goNext,
                          onBack: _goBack,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}


// UI without responsiveness
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:mk_ambulance/screens/patient_details_page.dart';
// import 'package:mk_ambulance/screens/sign_off_page.dart';
// import 'package:mk_ambulance/screens/summary/summary_page.dart';
// import 'package:mk_ambulance/screens/treatment_page.dart';
// import '../constants/step_tiles.dart';
// import '../widgets/buttons.dart';
// import '../widgets/stepper_widget.dart';
// import 'assessment_page.dart';
//
// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   int _currentStep = 0;
//
//   void _goNext() {
//     if (_currentStep < stepTitles.length - 1) {
//       setState(() {
//         _currentStep++;
//       });
//     }
//   }
//
//   void _goBack() {
//     if (_currentStep > 0) {
//       setState(() {
//         _currentStep--;
//       });
//     }
//   }
//
//   Widget _buildPageContent() {
//     switch (_currentStep) {
//       case 0:
//         // return const SummaryPage();
//         return const PatientDetails();
//       case 1:
//       return const AssessmentPage();
//       case 2:
//       return TreatmentPage();
//       case 3:
//       return SignOffPage();
//       case 4:
//       return SummaryPage();
//       default:
//       return const Center(child: Text('Unknown Step'));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         backgroundColor: Colors.grey[100],
//         title: FittedBox(
//           fit: BoxFit.scaleDown,
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(Icons.local_hospital_rounded, color: Colors.red),
//               const SizedBox(width: 8),
//               Text(
//                 'Ambulance Patient Record',
//                 style: GoogleFonts.poppins(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         centerTitle: true,
//       ),
//
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 10),
//           child: Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               borderRadius: const BorderRadius.all(Radius.circular(10)),
//               color: Colors.white,
//             ),
//             child: Column(
//               children: [
//                 SizedBox(
//                   width: MediaQuery.of(context).size.width * 0.5,
//                   child: CustomStepper(
//                     stepTitles: stepTitles,
//                     currentStep: _currentStep,
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 20.0),
//                   child: _buildPageContent(),
//                 ),
//                 StepNavigationButtons(
//                   currentStep: _currentStep,
//                   totalSteps: stepTitles.length,
//                   onNext: _goNext,
//                   onBack: _goBack,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
