import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_commentary/commentary_skeleton.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_translation/translation_panel_header.dart';
import 'package:flutter_pecha/features/texts/data/models/translation/segment_translation.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/segment_provider.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const double _horizontalPadding = 16.0;
const double _cardSpacing = 16.0;
const double _dividerHeight = 1.0;
const double _contentSpacing = 8.0;
const int _previewMaxLength = 150;

final _expandedTranslationIndexProvider = StateProvider.family<int?, String>(
  (ref, segmentId) => null,
);

class ReaderTranslationPanel extends ConsumerWidget {
  final String segmentId;
  final String textLanguage;
  final ReaderParams params;
  final double availableHeight;

  const ReaderTranslationPanel({
    super.key,
    required this.segmentId,
    required this.textLanguage,
    required this.params,
    required this.availableHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expandedIndex = ref.watch(
      _expandedTranslationIndexProvider(segmentId),
    );
    final segmentTranslations = ref.watch(
      segmentTranslationsFutureProvider(segmentId),
    );
    final notifier = ref.read(readerNotifierProvider(params).notifier);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(
        children: [
          TranslationPanelHeader(
            params: params,
            availableHeight: availableHeight,
            onClose: () {
              notifier.closeTranslation();
              ref
                  .read(_expandedTranslationIndexProvider(segmentId).notifier)
                  .state = null;
            },
          ),
          Expanded(
            child: segmentTranslations.when(
              data:
                  (data) => _TranslationPanelContent(
                    translations: data.translations,
                    expandedIndex: expandedIndex,
                    segmentId: segmentId,
                    textLanguage: textLanguage,
                    onExpansionChanged: (index) {
                      ref
                          .read(
                            _expandedTranslationIndexProvider(
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
                        segmentTranslationsFutureProvider(segmentId),
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

class _TranslationPanelContent extends StatelessWidget {
  final List<SegmentTranslation> translations;
  final int? expandedIndex;
  final String segmentId;
  final String textLanguage;
  final ValueChanged<int?> onExpansionChanged;

  const _TranslationPanelContent({
    required this.translations,
    required this.expandedIndex,
    required this.segmentId,
    required this.textLanguage,
    required this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (translations.isEmpty) {
      return const _EmptyState();
    }

    final sorted = List<SegmentTranslation>.from(translations)..sort((a, b) {
      final aFirst = a.language == textLanguage ? 0 : 1;
      final bFirst = b.language == textLanguage ? 0 : 1;
      return aFirst.compareTo(bFirst);
    });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final translation = sorted[index];
        final isExpanded = expandedIndex == index;

        return _TranslationCard(
          translation: translation,
          isExpanded: isExpanded,
          index: index,
          onExpansionChanged: onExpansionChanged,
        );
      },
    );
  }
}

class _TranslationCard extends StatelessWidget {
  final SegmentTranslation translation;
  final bool isExpanded;
  final int index;
  final ValueChanged<int?> onExpansionChanged;

  const _TranslationCard({
    required this.translation,
    required this.isExpanded,
    required this.index,
    required this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fontFamily = getFontFamily(translation.language);
    final lineHeight = getLineHeight(translation.language);
    final fontSize = translation.language == 'bo' ? 20.0 : 16.0;
    final titleFontSize = translation.language == 'bo' ? 16.0 : 14.0;

    final content = translation.content;
    final isTruncated = !isExpanded && content.length > _previewMaxLength;
    final displayContent =
        isExpanded
            ? content
            : content.length <= _previewMaxLength
            ? content
            : content.substring(0, _previewMaxLength);

    return Container(
      margin: const EdgeInsets.only(top: _cardSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            translation.title,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: titleFontSize,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: _contentSpacing),
          InkWell(
            onTap: () {
              onExpansionChanged(isExpanded ? null : index);
            },
            child: Text(
              isTruncated ? '$displayContent...' : displayContent,
              style: TextStyle(
                fontFamily: fontFamily,
                height: lineHeight,
                fontSize: fontSize,
              ),
            ),
          ),
          Container(
            height: _dividerHeight,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? AppColors.greyDark
                    : AppColors.greyLight,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final localizations = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_horizontalPadding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.translate_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
            ),
            const SizedBox(height: 12),
            Text(
              localizations.no_translation,
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

class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final localizations = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_horizontalPadding * 2),
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
