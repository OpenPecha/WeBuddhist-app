import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Skeleton loading widget for commentary panel content.
///
/// Displays shimmer-animated placeholder items that mimic the
/// commentary expansion panels while data is being fetched.
class CommentarySkeleton extends StatelessWidget {
  /// Number of skeleton commentary items to display.
  final int itemCount;

  const CommentarySkeleton({
    super.key,
    this.itemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: itemCount,
        itemBuilder: (context, index) => _buildSkeletonItem(context),
      ),
    );
  }

  Widget _buildSkeletonItem(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.grey[300]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Bone(
              width: 200,
              height: 18,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Bone(
              width: 120,
              height: 14,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
        children: [
          Bone(
            width: double.infinity,
            height: 14,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Bone(
            width: double.infinity,
            height: 14,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Bone(
            width: MediaQuery.of(context).size.width * 0.6,
            height: 14,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
