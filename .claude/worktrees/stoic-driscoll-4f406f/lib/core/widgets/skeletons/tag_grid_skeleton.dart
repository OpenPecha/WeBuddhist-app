import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Skeleton loading widget for the tag grid on HomeScreen.
///
/// Displays shimmer-animated placeholder cards that mimic the
/// [TagCard] layout while data is being fetched.
/// Dynamically calculates the number of items based on screen size.
class TagGridSkeleton extends StatelessWidget {
  const TagGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemCount = _calculateItemCount(constraints);
        return Skeletonizer(
          enabled: true,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.4,
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) => _buildSkeletonCard(context),
          ),
        );
      },
    );
  }

  int _calculateItemCount(BoxConstraints constraints) {
    // Calculate based on available height
    // Each card has aspectRatio 1.4, with spacing of 8
    // Estimate card height based on width (2 columns with 8 spacing and 32 total horizontal padding)
    final availableWidth = constraints.maxWidth - 32 - 8; // padding + spacing
    final cardWidth = availableWidth / 2;
    final cardHeight = cardWidth / 1.4;
    final rowHeight = cardHeight + 8; // card height + spacing
    final visibleRows = (constraints.maxHeight / rowHeight).ceil();
    // Show enough items to fill visible area, minimum 4, maximum 10
    return (visibleRows * 2).clamp(4, 10);
  }

  Widget _buildSkeletonCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainer,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background placeholder
          const Bone(
            width: double.infinity,
            height: double.infinity,
            borderRadius: BorderRadius.zero,
          ),
          // Text placeholder at bottom
          Positioned(
            left: 8,
            right: 8,
            bottom: 12,
            child: Center(
              child: Bone(
                width: 80,
                height: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
