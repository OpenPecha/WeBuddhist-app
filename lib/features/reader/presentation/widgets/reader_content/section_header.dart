import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/texts/models/section.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';

/// Widget for displaying a section header in the reader
class SectionHeader extends StatelessWidget {
  final Section section;
  final int depth;
  final String language;

  const SectionHeader({
    super.key,
    required this.section,
    required this.depth,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final title = section.title;
    if (title == null || title.isEmpty) {
      return const SizedBox.shrink();
    }

    final fontSize =
        language == 'bo'
            ? ReaderConstants.sectionTitleFontSizeTibetan
            : ReaderConstants.sectionTitleFontSizeDefault;

    // Adjust font size based on depth (nested sections are smaller)
    final adjustedFontSize = fontSize - (depth * 2);

    return Padding(
      padding: EdgeInsets.only(
        top: depth == 0 ? 16.0 : 12.0,
        bottom: 8.0,
        left: ReaderConstants.segmentHorizontalPadding + (depth * 8),
        right: ReaderConstants.segmentHorizontalPadding,
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: adjustedFontSize,
          fontWeight: FontWeight.bold,
          fontFamily: getFontFamily(language),
        ),
      ),
    );
  }
}
