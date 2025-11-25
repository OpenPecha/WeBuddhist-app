import 'package:flutter/material.dart';

/// Reusable back button for onboarding questionnaire screens
class OnboardingBackButton extends StatelessWidget {
  const OnboardingBackButton({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onBack,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: const Icon(Icons.arrow_back_ios, size: 20),
      ),
    );
  }
}
