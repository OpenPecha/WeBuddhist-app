import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/reader/data/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_commentary/commentary_skeleton.dart';
import 'package:flutter_pecha/features/texts/data/providers/apis/segment_provider.dart';
import 'package:flutter_pecha/features/texts/models/commentary/segment_commentary.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Constants for commentary panel styling
class _CommentaryPanelConstants {
  _CommentaryPanelConstants._();

  static const double horizontalPadding = 16.0;
  static const double cardSpacing = 16.0;
  static const double dividerHeight = 1.0;
  static const double contentSpacing = 8.0;
  static const int previewMaxLength = 150;
}

/// State provider for expanded commentary index
final _expandedCommentaryIndexProvider = StateProvider.family<int?, String>(
  (ref, segmentId) => null,
);

/// Commentary panel for the reader
class ReaderCommentaryPanel extends ConsumerWidget {
  final String segmentId;
  final String textLanguage;
  final ReaderParams params;
  final double availableHeight;

  const ReaderCommentaryPanel({
    super.key,
    required this.segmentId,
    required this.textLanguage,
    required this.params,
    required this.availableHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expandedIndex = ref.watch(
      _expandedCommentaryIndexProvider(segmentId),
    );
    final segmentCommentaries = ref.watch(
      segmentCommentaryFutureProvider(segmentId),
    );
    final notifier = ref.read(readerNotifierProvider(params).notifier);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(
        children: [
          // Header with close button and resizable divider
          _CommentaryPanelHeader(
            params: params,
            availableHeight: availableHeight,
            onClose: () {
              notifier.closeCommentary();
              ref
                  .read(_expandedCommentaryIndexProvider(segmentId).notifier)
                  .state = null;
            },
          ),
          // Content
          Expanded(
            child: segmentCommentaries.when(
              data:
                  (data) => _CommentaryPanelContent(
                    commentaries: data.commentaries,
                    expandedIndex: expandedIndex,
                    segmentId: segmentId,
                    textLanguage: textLanguage,
                    onExpansionChanged: (index) {
                      ref
                          .read(
                            _expandedCommentaryIndexProvider(
                              segmentId,
                            ).notifier,
                          )
                          .state = index;
                    },
                  ),
              error:
                  (error, _) => _ErrorState(
                    error: error,
                    onRetry: () {
                      ref.invalidate(
                        segmentCommentaryFutureProvider(segmentId),
                      );
                    },
                  ),
              loading: () => const CommentarySkeleton(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header for the commentary panel with resizable divider
class _CommentaryPanelHeader extends ConsumerWidget {
  final VoidCallback onClose;
  final ReaderParams params;
  final double availableHeight;

  const _CommentaryPanelHeader({
    required this.onClose,
    required this.params,
    required this.availableHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = context.l10n;
    final notifier = ref.read(readerNotifierProvider(params).notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Resizable divider handle
        GestureDetector(
          onVerticalDragUpdate: (details) {
            final state = ref.read(readerNotifierProvider(params));
            final currentMainHeight = availableHeight * state.splitRatio;
            final newRatio =
                (currentMainHeight + details.delta.dy) / availableHeight;
            notifier.updateSplitRatio(newRatio);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.greyDark
                      : AppColors.greyLight,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Text(
                  localizations.text_commentary,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  tooltip: localizations.text_close_commentary,
                  iconSize: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Content list for commentaries
class _CommentaryPanelContent extends StatelessWidget {
  final List<SegmentCommentary> commentaries;
  final int? expandedIndex;
  final String segmentId;
  final String textLanguage;
  final ValueChanged<int?> onExpansionChanged;

  const _CommentaryPanelContent({
    required this.commentaries,
    required this.expandedIndex,
    required this.segmentId,
    required this.textLanguage,
    required this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (commentaries.isEmpty) {
      return const _EmptyState();
    }
    final sortedCommentaries = List<SegmentCommentary>.from(commentaries)
      ..sort((a, b) {
        final aFirst = a.language == textLanguage ? 0 : 1;
        final bFirst = b.language == textLanguage ? 0 : 1;
        return aFirst.compareTo(bFirst);
      });
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: _CommentaryPanelConstants.horizontalPadding,
      ),
      itemCount: sortedCommentaries.length,
      itemBuilder: (context, index) {
        final commentary = sortedCommentaries[index];
        final isExpanded = expandedIndex == index;

        return _CommentaryCard(
          commentary: commentary,
          isExpanded: isExpanded,
          index: index,
          onExpansionChanged: onExpansionChanged,
        );
      },
    );
  }
}

/// Individual commentary card
class _CommentaryCard extends StatelessWidget {
  final SegmentCommentary commentary;
  final bool isExpanded;
  final int index;
  final ValueChanged<int?> onExpansionChanged;

  const _CommentaryCard({
    required this.commentary,
    required this.isExpanded,
    required this.index,
    required this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fontFamily = getFontFamily(commentary.language);
    final lineHeight = getLineHeight(commentary.language);
    final fontSize = commentary.language == 'bo' ? 20.0 : 16.0;
    final titleFontSize = commentary.language == 'bo' ? 16.0 : 14.0;

    return Container(
      margin: const EdgeInsets.only(top: _CommentaryPanelConstants.cardSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            '${commentary.title} (${commentary.segments.length})',
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: titleFontSize,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: _CommentaryPanelConstants.contentSpacing),
          // Content
          ...commentary.segments.map((segment) {
            final content = segment.content;
            final isTruncated =
                !isExpanded &&
                content.length >
                    _CommentaryPanelConstants.previewMaxLength;
            final displayContent =
                isExpanded
                    ? content
                    : content.length <=
                        _CommentaryPanelConstants.previewMaxLength
                    ? content
                    : content.substring(
                        0,
                        _CommentaryPanelConstants.previewMaxLength,
                      );
            return Text(
              isTruncated ? '$displayContent...' : displayContent,
              style: TextStyle(
                fontFamily: fontFamily,
                height: lineHeight,
                fontSize: fontSize,
              ),
            );
          }),
          // Expand/collapse button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                onExpansionChanged(isExpanded ? null : index);
              },
              child: Text(
                isExpanded
                    ? context.l10n.show_less
                    : context.l10n.show_more,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          // divider
          Container(
            height: _CommentaryPanelConstants.dividerHeight,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.greyDark
                : AppColors.greyLight,
          ),
        ],
      ),
    );
  }
}

/// Empty state when no commentaries found
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final localizations = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          _CommentaryPanelConstants.horizontalPadding * 2,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.comment_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
            ),
            const SizedBox(height: 12),
            Text(
              localizations.no_commentary,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Error state with retry
class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final localizations = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          _CommentaryPanelConstants.horizontalPadding * 2,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(localizations.retry),
            ),
          ],
        ),
      ),
    );
  }
}
