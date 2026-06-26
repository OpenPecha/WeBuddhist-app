import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MyPracticesStatsCardSkeleton extends StatelessWidget {
  const MyPracticesStatsCardSkeleton({super.key});

  static const _borderRadius = 20.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Skeletonizer(
        enabled: true,
        child: Material(
          color: AppColors.blue,
          borderRadius: BorderRadius.circular(_borderRadius),
          clipBehavior: Clip.antiAlias,
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Bone(width: 140, height: 22)),
                    Bone.circle(size: 32),
                  ],
                ),
                SizedBox(height: 4),
                Bone(width: 160, height: 18),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _StatSkeleton(icon: AppAssets.homeList)),
                    Expanded(
                      child: _StatSkeleton(icon: AppAssets.bookOpenText),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatSkeleton extends StatelessWidget {
  const _StatSkeleton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Skeleton.ignore(
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.6),
            size: 22,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Bone(width: 72, height: 22)),
      ],
    );
  }
}
