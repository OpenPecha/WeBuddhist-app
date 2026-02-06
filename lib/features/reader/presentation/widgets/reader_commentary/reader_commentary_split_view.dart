import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/data/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_commentary/reader_commentary_panel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Split view wrapper that handles the main content and commentary panel
class ReaderCommentarySplitView extends ConsumerWidget {
  final Widget mainContent;
  final ReaderParams params;

  const ReaderCommentarySplitView({
    super.key,
    required this.mainContent,
    required this.params,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(readerNotifierProvider(params));
    final notifier = ref.read(readerNotifierProvider(params).notifier);

    final isCommentaryOpen = state.isCommentaryOpen;
    final splitRatio = state.splitRatio;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final dividerHeight = isCommentaryOpen
            ? ReaderConstants.commentaryDividerHeight
            : 0.0;
        final commentaryHeight = isCommentaryOpen
            ? availableHeight * (1 - splitRatio) - dividerHeight
            : 0.0;
        final mainHeight = availableHeight - commentaryHeight - dividerHeight;

        return Column(
          children: [
            // Main content (top)
            SizedBox(
              height: mainHeight,
              child: mainContent,
            ),
            // Resizable divider (only when commentary is open)
            if (isCommentaryOpen)
              GestureDetector(
                onVerticalDragUpdate: (details) {
                  final newRatio = (mainHeight + details.delta.dy) / availableHeight;
                  notifier.updateSplitRatio(newRatio);
                },
                child: Container(
                  height: dividerHeight,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.greyMedium
                      : Colors.grey[300],
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            // Commentary panel (bottom, only when open)
            if (isCommentaryOpen && state.commentarySegmentId != null)
              SizedBox(
                height: commentaryHeight,
                child: ReaderCommentaryPanel(
                  segmentId: state.commentarySegmentId!,
                  params: params,
                ),
              ),
          ],
        );
      },
    );
  }
}
