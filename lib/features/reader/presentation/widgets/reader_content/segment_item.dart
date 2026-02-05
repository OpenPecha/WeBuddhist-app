import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/reader/data/models/highlight_config.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/texts/data/providers/font_size_notifier.dart';
import 'package:flutter_pecha/features/texts/models/segment.dart';
import 'package:flutter_pecha/features/texts/presentation/segment_html_widget.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Widget for displaying a single segment in the reader
class SegmentItem extends ConsumerWidget {
  final Segment segment;
  final int depth;
  final String language;
  final bool isSelected;
  final bool isHighlighted;
  final NavigationSource highlightSource;
  final VoidCallback? onTap;

  const SegmentItem({
    super.key,
    required this.segment,
    required this.depth,
    required this.language,
    this.isSelected = false,
    this.isHighlighted = false,
    this.highlightSource = NavigationSource.normal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(fontSizeProvider);
    final content = segment.content;
    final segmentNumber = segment.segmentNumber.toString().padLeft(2);

    return AnimatedContainer(
      key: Key(segment.segmentId),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        borderRadius: BorderRadius.circular(ReaderConstants.segmentBorderRadius),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ReaderConstants.segmentBorderRadius),
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
                // Segment number
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
                        fontFamily: getFontFamily(language),
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                ),
                // Segment content
                Expanded(
                  child: SegmentHtmlWidget(
                    htmlContent: content ?? '',
                    segmentIndex: segment.segmentNumber,
                    fontSize: fontSize,
                    language: language,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color? _getBackgroundColor(BuildContext context) {
    if (isHighlighted) {
      final config = HighlightConfig.forSource(highlightSource);
      return config.getColor(context);
    }

    if (isSelected) {
      return Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.primary.withAlpha(60)
          : Theme.of(context).colorScheme.primary.withAlpha(30);
    }

    return null;
  }
}
