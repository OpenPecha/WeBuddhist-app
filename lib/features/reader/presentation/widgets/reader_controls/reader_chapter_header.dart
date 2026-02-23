import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/texts/models/text_detail.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';

/// Header widget showing the text title
class ReaderChapterHeader extends StatelessWidget {
  final TextDetail textDetail;

  const ReaderChapterHeader({super.key, required this.textDetail});

  @override
  Widget build(BuildContext context) {
    const fontSize = 22.0;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: ReaderConstants.segmentHorizontalPadding + 4,
        vertical: 12,
      ),
      child: Text(
        textDetail.title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontSize: fontSize,
          fontFamily: getFontFamily(textDetail.language),
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
