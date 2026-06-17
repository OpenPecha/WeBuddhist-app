import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Skeleton placeholder for [MyGroupsSection] while my groups are loading.
class MyGroupsSectionSkeleton extends StatelessWidget {
  const MyGroupsSectionSkeleton({super.key});

  static const double _tileSize = 72;
  static const int _placeholderCount = 4;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Bone(
                  width: 100,
                  height: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
                const Spacer(),
                Bone(
                  width: 56,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 108,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _placeholderCount,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 80,
                  child: Column(
                    children: [
                      Bone(
                        width: _tileSize,
                        height: _tileSize,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      const SizedBox(height: 8),
                      Bone(
                        width: 64,
                        height: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
