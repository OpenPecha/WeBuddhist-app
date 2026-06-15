import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class FeaturedPlanSectionSkeleton extends StatelessWidget {
  const FeaturedPlanSectionSkeleton({super.key});

  static const _horizontalPadding = 16.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _horizontalPadding,
        0,
        _horizontalPadding,
        16,
      ),
      child: Skeletonizer(
        enabled: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Bone.text(words: 2, fontSize: 18),
            const SizedBox(height: 12),
            Bone(
              width: double.infinity,
              height: 180,
              borderRadius: BorderRadius.circular(16),
            ),
            const SizedBox(height: 12),
            Bone.text(words: 3, fontSize: 16),
            const SizedBox(height: 8),
            Bone.text(words: 6, fontSize: 13),
            const SizedBox(height: 16),
            for (var i = 0; i < 2; i++) ...[
              Row(
                children: [
                  Bone(
                    width: 72,
                    height: 72,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Bone.text(words: 3, fontSize: 16),
                        const SizedBox(height: 8),
                        Bone.text(words: 4, fontSize: 13),
                      ],
                    ),
                  ),
                ],
              ),
              if (i == 0) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
