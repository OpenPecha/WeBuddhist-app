import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Skeleton loading widget for text search results in ReaderSearchDelegate.
///
/// Displays shimmer-animated placeholder items that mimic the
/// search result list layout while search results are being fetched.
class TextSearchSkeleton extends StatelessWidget {
  /// Number of skeleton items to display.
  final int itemCount;

  const TextSearchSkeleton({
    super.key,
    this.itemCount = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ListView.separated(
          itemCount: itemCount,
          separatorBuilder: (context, index) => const Divider(
            height: 1,
            color: Colors.grey,
            indent: 20,
            endIndent: 20,
          ),
          itemBuilder: (context, index) => _buildSkeletonItem(context),
        ),
      ),
    );
  }

  Widget _buildSkeletonItem(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Bone(
            width: double.infinity,
            height: 16,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Bone(
            width: MediaQuery.of(context).size.width * 0.7,
            height: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Bone(
          width: 100,
          height: 12,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
