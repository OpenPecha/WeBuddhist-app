import 'package:flutter/material.dart';

/// Reusable title widget for onboarding questionnaire screens
class OnboardingQuestionTitle extends StatelessWidget {
  const OnboardingQuestionTitle({super.key, required this.title, this.style});

  final String title;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style:
          style ??
          const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
    );
  }
}
