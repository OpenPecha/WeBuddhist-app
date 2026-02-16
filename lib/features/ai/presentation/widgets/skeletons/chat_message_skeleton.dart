import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Skeleton loading widget for the AI chat message list.
///
/// Displays shimmer-animated placeholder message bubbles that mimic
/// the [MessageBubble] layout while a conversation is being loaded.
class ChatMessageSkeleton extends StatelessWidget {
  /// Number of skeleton message pairs (user + assistant) to display.
  final int pairCount;

  const ChatMessageSkeleton({super.key, this.pairCount = 3});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 16, bottom: 16),
        children: [
          for (int i = 0; i < pairCount; i++) ...[
            // User message (right-aligned, shorter)
            _buildUserBubble(context, i),
            const SizedBox(height: 16),
            // Assistant message (left-aligned, longer)
            _buildAssistantBubble(context, i),
            if (i < pairCount - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildUserBubble(BuildContext context, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Spacer to push bubble to the right
          const Spacer(flex: 2),
          Flexible(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Bone.text(words: index.isEven ? 6 : 4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantBubble(BuildContext context, int index) {
    // Vary the number of lines per assistant message
    final lineCount = index == 0 ? 4 : (index == 1 ? 3 : 2);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int j = 0; j < lineCount; j++) ...[
                  Bone.text(
                    words: j == lineCount - 1 ? 4 : 8,
                  ),
                  if (j < lineCount - 1) const SizedBox(height: 6),
                ],
                const SizedBox(height: 12),
                // Sources button placeholder
                Bone(
                  width: 100,
                  height: 28,
                  borderRadius: BorderRadius.circular(30),
                ),
              ],
            ),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }
}
