import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class FeaturedPlanSectionSkeleton extends StatelessWidget {
  const FeaturedPlanSectionSkeleton({super.key});

  static const _horizontalPadding = 16.0;
  static const _imageBorderRadius = 16.0;

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
            Material(
              borderRadius: BorderRadius.circular(_imageBorderRadius),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Bone(
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: BorderRadius.circular(0),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Bone.text(words: 3, fontSize: 16),
                        const SizedBox(height: 4),
                        Bone.text(words: 3, fontSize: 13),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < 2; i++) ...[
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(_imageBorderRadius),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                            const SizedBox(height: 4),
                            Bone.text(words: 3, fontSize: 13),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (i == 0) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
