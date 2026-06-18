import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Skeleton loading widget for the AI search results tabs.
///
/// Displays shimmer-animated placeholder cards that mimic the
/// search result layout (title cards + content cards) while results are loading.
class SearchResultSkeleton extends StatelessWidget {
  /// Number of skeleton result groups to display.
  final int itemCount;

  const SearchResultSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Section header skeleton
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 16, top: 8),
            child: Bone(
              width: 100,
              height: 22,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // Result cards
          for (int i = 0; i < itemCount; i++) ...[
            _buildTitleCard(context, i),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 24),
          // Second section
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 16, top: 8),
            child: Bone(
              width: 120,
              height: 22,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          for (int i = 0; i < 2; i++) ...[
            _buildContentCard(context, i),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  /// Mimics the title result card layout
  Widget _buildTitleCard(BuildContext context, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Bone.text(words: index.isEven ? 4 : 6),
            ),
            const SizedBox(width: 12),
            const Bone.square(size: 20),
          ],
        ),
      ),
    );
  }

  /// Mimics the content search result card layout
  Widget _buildContentCard(BuildContext context, int index) {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Bone.text(words: 3),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Content lines
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone.text(words: 10),
                const SizedBox(height: 6),
                Bone.text(words: 7),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
