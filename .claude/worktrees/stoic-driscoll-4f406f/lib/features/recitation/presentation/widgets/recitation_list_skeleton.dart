import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Skeleton loading widget for recitation list screens.
///
/// Displays shimmer-animated placeholder cards that mimic the
/// [RecitationCard] layout while data is being fetched.
class RecitationListSkeleton extends StatelessWidget {
  /// Whether to show a drag handle placeholder on each card.
  /// Used in [MyRecitationsTab] where cards are reorderable.
  final bool showDragHandle;

  /// Number of skeleton cards to display.
  final int itemCount;

  const RecitationListSkeleton({
    super.key,
    this.showDragHandle = false,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: itemCount,
        itemBuilder: (context, index) => _buildSkeletonCard(context),
      ),
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: const Color(0xFFE4E4E4), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            if (showDragHandle) ...[
              const Bone(
                width: 26,
                height: 26,
                borderRadius: BorderRadius.zero,
              ),
              const SizedBox(width: 8),
            ],
            const SizedBox(width: 12),
            const Bone.circle(size: 60),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Bone(
                    width: 180,
                    height: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
