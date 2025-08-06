import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomStepper extends StatelessWidget {
  final List<String> stepTitles;
  final int currentStep;

  const CustomStepper({
    super.key,
    required this.stepTitles,
    required this.currentStep,
  });

  Widget _buildStep(int index, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundColor: isActive ? Colors.red[100] : Colors.transparent,
          child: CircleAvatar(
            radius: 14,
            backgroundColor: isActive ? Colors.red : Colors.grey[400],
            child: Text('${index + 1}', style: TextStyle(color: Colors.white)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          stepTitles[index],
          style: GoogleFonts.poppins(
            color: isActive ? Colors.red : Colors.black54,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(stepTitles.length, (index) {
        final isActive = index == currentStep;
        return Expanded(
          child: Column(
            children: [
              _buildStep(index, isActive),
              if (index != stepTitles.length)
                Divider(
                  color: index < currentStep ? Colors.red : Colors.grey[300],
                  thickness: 2,
                ),
            ],
          ),
        );
      }),
    );
  }
}
