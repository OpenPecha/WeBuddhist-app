import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Skeleton loading widget for the day carousel in plan preview/details screens.
///
/// Displays shimmer-animated placeholder content that mimics the
/// [DayCarousel] layout while data is being fetched.
class DayCarouselSkeleton extends StatelessWidget {
  const DayCarouselSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Container(
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 7,
          itemBuilder: (context, index) => _buildDayItemSkeleton(context),
        ),
      ),
    );
  }

  Widget _buildDayItemSkeleton(BuildContext context) {
    return Container(
      width: 70,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Bone(
            width: 28,
            height: 28,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 8),
          Bone(
            width: 40,
            height: 12,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loading widget for the day content/activities section.
///
/// Displays shimmer-animated placeholder content that mimics the
/// activity list layout while data is being fetched.
class DayContentSkeleton extends StatelessWidget {
  /// Number of activity items to display.
  final int itemCount;

  const DayContentSkeleton({
    super.key,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          itemCount,
          (index) => _buildActivityItemSkeleton(context),
        ),
      ),
    );
  }

  Widget _buildActivityItemSkeleton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Checkbox placeholder
          Bone.circle(size: 24),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone(
                  width: 180,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 6),
                Bone(
                  width: 120,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          // Action icon placeholder
          Bone.circle(size: 20),
        ],
      ),
    );
  }
}

/// Combined skeleton for the entire plan preview screen body.
///
/// Includes cover image placeholder, day carousel skeleton,
/// and activity list skeleton.
class PlanPreviewBodySkeleton extends StatelessWidget {
  const PlanPreviewBodySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            // Cover image skeleton
            _buildCoverImageSkeleton(context),
            // Day carousel skeleton
            const DayCarouselSkeleton(),
            const SizedBox(height: 16),
            // Day content section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day title skeleton
                  Bone(
                    width: 120,
                    height: 20,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 12),
                  // Activity list skeleton
                  const DayContentSkeleton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImageSkeleton(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: const Bone(
        width: double.infinity,
        height: 200,
        borderRadius: BorderRadius.zero,
      ),
    );
  }
}
