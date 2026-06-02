import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/segment_number.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/font_size_notifier.dart';
import 'package:flutter_pecha/features/texts/presentation/segment_html_widget.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InterlinearSegmentItem extends ConsumerWidget {
  const InterlinearSegmentItem({
    super.key,
    required this.segment,
    required this.depth,
    required this.primaryLanguage,
    required this.secondarySlot,
    this.secondaryContentBySegmentNumber,
    this.secondaryIsLoading = false,
    this.isSelected = false,
    this.isHighlighted = false,
    this.highlightSource = NavigationSource.normal,
    this.isGreyedOut = false,
    this.onTap,
  });

  final Segment segment;
  final int depth;
  final String primaryLanguage;
  final ReaderSlotConfig secondarySlot;

  /// Lookup map of secondary version content keyed by segment_number.
  /// Falls back to a placeholder when the key is missing or while loading.
  final Map<int, String>? secondaryContentBySegmentNumber;
  final bool secondaryIsLoading;
  final bool isSelected;
  // Received from caller but visual highlight not yet applied in interlinear mode.
  final bool isHighlighted;
  final NavigationSource highlightSource;
  final bool isGreyedOut;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(fontSizeProvider);
    final primaryHtml = normalizeSegmentHtml(segment.content);
    final secondary = _resolveSecondaryContent();

    return AnimatedOpacity(
      opacity: isGreyedOut ? 0.3 : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            ReaderConstants.segmentBorderRadius,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: ReaderConstants.segmentHorizontalPadding + (depth * 8),
              right: ReaderConstants.segmentHorizontalPadding,
              top: ReaderConstants.segmentVerticalPadding,
              bottom: ReaderConstants.segmentVerticalPadding,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentNumber(
                  segmentNumber: segment.segmentNumber,
                  fontSize: fontSize,
                  language: primaryLanguage,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SegmentHtmlWidget(
                        htmlContent: primaryHtml,
                        segmentIndex: segment.segmentNumber,
                        fontSize: fontSize,
                        language: primaryLanguage,
                        isSelected: isSelected,
                      ),
                      const SizedBox(height: 4),
                      _SecondaryLine(
                        text: secondary.text,
                        isPlaceholder: secondary.isPlaceholder,
                        language: secondarySlot.languageCode,
                        fontSize: fontSize * 0.78,
                      ),
                      const SizedBox(height: 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _SecondaryResolved _resolveSecondaryContent() {
    final fromMap = secondaryContentBySegmentNumber?[segment.segmentNumber];
    if (fromMap != null && fromMap.trim().isNotEmpty) {
      return _SecondaryResolved(
        text: normalizeSegmentText(fromMap),
        isPlaceholder: false,
      );
    }
    if (secondaryIsLoading) {
      return const _SecondaryResolved(text: 'Loading…', isPlaceholder: true);
    }
    return _SecondaryResolved(
      text: 'Translation in ${secondarySlot.languageLabel} unavailable',
      isPlaceholder: true,
    );
  }
}

class _SecondaryResolved {
  final String text;
  final bool isPlaceholder;
  const _SecondaryResolved({required this.text, required this.isPlaceholder});
}

class _SecondaryLine extends StatelessWidget {
  const _SecondaryLine({
    required this.text,
    required this.isPlaceholder,
    required this.language,
    required this.fontSize,
  });

  final String text;
  final bool isPlaceholder;
  final String language;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontFamily: getFontFamily(language),
        fontWeight: FontWeight.w400,
        fontStyle: isPlaceholder ? FontStyle.italic : FontStyle.normal,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
        height: 1.4,
      ),
    );
  }
}
