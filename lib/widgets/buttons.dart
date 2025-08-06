import 'package:flutter/material.dart';

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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: currentStep > 0 ? onBack : null,
            child: const Text("Back"),
          ),
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
              currentStep < totalSteps - 1 ? Colors.green : null,
            ),
            onPressed: currentStep < totalSteps - 1 ? onNext : null,
            child: const Text(
              "Next",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
