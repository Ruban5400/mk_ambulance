import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mk_ambulance/screens/patientDetailsPage.dart';

import '../constants/step_tiles.dart';
import '../widgets/buttons.dart';
import '../widgets/stepper_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentStep = 0;

  void _goNext() {
    if (_currentStep < stepTitles.length - 1) {
      setState(() {
        _currentStep++;
      });
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
      // return assessmentPage();
      case 2:
      // return treatmentPage();
      case 3:
      // return signOffPage();
      case 4:
      // return summaryPage();
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
              const Icon(Icons.local_hospital_rounded, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                'Ambulance Patient Record',
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

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              color: Colors.white,
            ),
            child: Column(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: CustomStepper(
                    stepTitles: stepTitles,
                    currentStep: _currentStep,
                  ),
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
}
