import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
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

  final bool isSelected;
  final bool isHighlighted;
  final NavigationSource highlightSource;
  final bool isGreyedOut;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(fontSizeProvider);
    final theme = Theme.of(context);
    final content = segment.content ?? '';
    final segmentNumber = segment.segmentNumber.toString().padLeft(2);

    final secondaryContent = _resolveSecondaryContent();
    final secondaryFontSize = fontSize * 0.78;

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
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: SizedBox(
                    width: ReaderConstants.segmentNumberWidth,
                    child: Text(
                      segmentNumber,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: fontSize * 0.6,
                        fontWeight: FontWeight.w500,
                        fontFamily: getFontFamily(primaryLanguage),
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SegmentHtmlWidget(
                        htmlContent: content,
                        segmentIndex: segment.segmentNumber,
                        fontSize: fontSize,
                        language: primaryLanguage,
                        isSelected: isSelected,
                      ),
                      const SizedBox(height: 4),
                      _SecondaryLine(
                        text: secondaryContent.text,
                        isPlaceholder: secondaryContent.isPlaceholder,
                        language: secondarySlot.languageCode,
                        fontSize: secondaryFontSize,
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
    final translation = segment.translation;
    if (translation != null && translation.content.trim().isNotEmpty) {
      return _SecondaryResolved(
        text: translation.content,
        isPlaceholder: false,
      );
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
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontFamily: getFontFamily(language),
        fontWeight: FontWeight.w400,
        fontStyle: isPlaceholder ? FontStyle.italic : FontStyle.normal,
        color: baseColor,
        height: 1.4,
      ),
    );
  }
}
