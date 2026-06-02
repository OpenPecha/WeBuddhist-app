import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';

/// Leading segment-number label shown beside segment content.
///
/// Shared by [SegmentItem] and [InterlinearSegmentItem] so both render the
/// number with identical width, padding, scale, and font conventions.
class SegmentNumber extends StatelessWidget {
  const SegmentNumber({
    super.key,
    required this.segmentNumber,
    required this.fontSize,
    required this.language,
  });

  /// Raw segment number; formatted (padded) for display internally.
  final int segmentNumber;

  /// Base content font size; the number is rendered at
  /// [ReaderConstants.segmentNumberFontScale] of this.
  final double fontSize;
  final String language;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: SizedBox(
        width: ReaderConstants.segmentNumberWidth,
        child: Text(
          segmentNumber.toString().padLeft(2),
          textAlign: TextAlign.left,
          style: TextStyle(
            fontSize: fontSize * ReaderConstants.segmentNumberFontScale,
            fontWeight: FontWeight.w500,
            fontFamily: getFontFamily(language),
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ),
    );
  }
}
