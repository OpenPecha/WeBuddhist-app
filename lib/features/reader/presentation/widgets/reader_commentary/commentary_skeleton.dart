import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_panels/reader_panel_constants.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Skeleton loading widget for commentary panel content.
///
/// Displays shimmer-animated placeholder items that mimic the
/// commentary expansion panels while data is being fetched.
class CommentarySkeleton extends StatelessWidget {
  /// Number of skeleton commentary items to display.
  final int itemCount;

  const CommentarySkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          for (var index = 0; index < itemCount; index++) ...[
            _buildSectionHeader(context, index),
            _buildSkeletonItem(context, index),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, int index) {
    return Padding(
      padding: const EdgeInsets.only(top: ReaderPanelConstants.sectionSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ReaderPanelConstants.horizontalPadding,
              0,
              ReaderPanelConstants.horizontalPadding,
              ReaderPanelConstants.contentSpacing,
            ),
            child: Bone(
              width: index.isEven ? 112 : 88,
              height: 18,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Container(
            height: 1,
            color: ReaderPanelConstants.dividerColor(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonItem(BuildContext context, int index) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ReaderPanelConstants.horizontalPadding,
        ReaderPanelConstants.contentSpacing,
        ReaderPanelConstants.horizontalPadding,
        ReaderPanelConstants.itemSpacing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Bone(
            width: double.infinity,
            height: index.isEven ? 24 : 20,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Bone(
            width: MediaQuery.sizeOf(context).width * 0.72,
            height: index.isEven ? 24 : 20,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: ReaderPanelConstants.contentSpacing),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const Skeleton.ignore(child: Icon(Icons.expand_more, size: 18)),
                const SizedBox(width: 4),
                Expanded(
                  child: Bone(
                    width: 180,
                    height: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
