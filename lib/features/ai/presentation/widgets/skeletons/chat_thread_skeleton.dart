import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Skeleton loading widget for the chat history thread list.
///
/// Displays shimmer-animated placeholder items that mimic the
/// [ThreadListItem] layout while thread data is being fetched.
class ChatThreadSkeleton extends StatelessWidget {
  /// Number of skeleton thread items to display.
  final int itemCount;

  const ChatThreadSkeleton({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: itemCount,
        itemBuilder: (context, index) => _buildSkeletonItem(index),
      ),
    );
  }

  Widget _buildSkeletonItem(int index) {
    // Vary the text width to look more natural
    final wordCount = index.isEven ? 5 : 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(child: Bone.text(words: wordCount)),
        ],
      ),
    );
  }
}
