import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

class MyPracticesStatsCardSkeleton extends StatelessWidget {
  const MyPracticesStatsCardSkeleton({super.key});

  static const _borderRadius = 20.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.blue.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
      ),
    );
  }
}
