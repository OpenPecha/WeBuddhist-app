import 'package:flutter/material.dart';
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

    final isCommentaryOpen = state.isCommentaryOpen;
    final splitRatio = state.splitRatio;
    final textLanguage = state.textDetail?.language ?? 'en';

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final commentaryHeight =
            isCommentaryOpen ? availableHeight * (1 - splitRatio) : 0.0;
        final mainHeight = availableHeight - commentaryHeight;

        return Column(
          children: [
            // Main content (top)
            SizedBox(height: mainHeight, child: mainContent),
            // Commentary panel (bottom, only when open)
            if (isCommentaryOpen && state.commentarySegmentId != null)
              SizedBox(
                height: commentaryHeight,
                child: ReaderCommentaryPanel(
                  segmentId: state.commentarySegmentId!,
                  textLanguage: textLanguage,
                  params: params,
                  availableHeight: availableHeight,
                ),
              ),
          ],
        );
      },
    );
  }
}
