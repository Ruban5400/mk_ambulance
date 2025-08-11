import 'package:flutter/material.dart';

import '../screens/home.dart';

class StepNavigationButtons extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const StepNavigationButtons({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: currentStep == 0 || currentStep == 4 ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
        children: [
          if (currentStep > 0  && currentStep < 4)
          ElevatedButton(
            onPressed: currentStep > 0 ? onBack : null,
            child: const Text("Back"),
          ),
          if (currentStep < 5)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              backgroundColor:
              Colors.green,
            ),
            onPressed: () {
              if (currentStep < totalSteps - 1) {
                onNext();
              } else {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                      (route) => false,
                );
              }
            },

            child: Text(
              currentStep == 3 ? 'Submit form' : currentStep == 4 ? 'Home' : 'Next',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
