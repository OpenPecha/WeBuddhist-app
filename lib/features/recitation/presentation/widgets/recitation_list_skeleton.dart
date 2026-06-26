import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:skeletonizer/skeletonizer.dart';

enum RecitationListSkeletonVariant { card, chantTile }

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

  final RecitationListSkeletonVariant variant;

  const RecitationListSkeleton({
    super.key,
    this.showDragHandle = false,
    this.itemCount = 6,
    this.variant = RecitationListSkeletonVariant.card,
  });

  @override
  Widget build(BuildContext context) {
    final isChantTile = variant == RecitationListSkeletonVariant.chantTile;

    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding:
            isChantTile
                ? const EdgeInsets.only(top: 8, bottom: 16)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: itemCount,
        itemBuilder:
            (context, index) =>
                isChantTile
                    ? _buildChantTileSkeleton(context)
                    : _buildSkeletonCard(context),
      ),
    );
  }

  Widget _buildChantTileSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 96,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : AppColors.grey800,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Bone(
                      width: 180,
                      height: 18,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Bone(
                      width: double.infinity,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 6),
                    Bone(
                      width: 150,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Center(child: Bone.circle(size: 40)),
            ],
          ),
        ),
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
            ],
            const SizedBox(width: 12),
            const SizedBox(
              width: 70,
              height: 70,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(left: 0, top: 10, child: Bone.circle(size: 60)),
                  Positioned(left: 7, top: 18, child: Bone.circle(size: 46)),
                  Positioned(left: 12, top: 26, child: Bone.circle(size: 36)),
                  Positioned(left: 17, top: 30, child: Bone.circle(size: 26)),
                ],
              ),
            ),
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
