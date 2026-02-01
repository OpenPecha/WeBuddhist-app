import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Skeleton loading widget for the recitation detail screen.
///
/// Displays shimmer-animated placeholder content that mimics the
/// [RecitationContent] layout while recitation data is being fetched.
class RecitationDetailSkeleton extends StatelessWidget {
  const RecitationDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title placeholder
            Bone(
              width: 250,
              height: 26,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 26),

            // Fake segments mimicking RecitationSegment layout
            for (int i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(height: 26),
              _buildSkeletonSegment(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonSegment(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary text line (full width)
        Bone(
          width: double.infinity,
          height: 20,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        // Secondary text line (80% width)
        Bone(
          width: MediaQuery.of(context).size.width * 0.75,
          height: 20,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        // Tertiary text line (60% width)
        Bone(
          width: MediaQuery.of(context).size.width * 0.55,
          height: 20,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
