import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_pecha/features/texts/data/providers/font_size_provider.dart';
import 'package:flutter_pecha/features/texts/data/providers/texts_provider.dart';
import 'package:flutter_pecha/features/texts/models/section.dart';
import 'package:flutter_pecha/features/texts/models/segment.dart';
import 'package:flutter_pecha/features/texts/models/text/reader_response.dart';
import 'package:flutter_pecha/features/texts/models/text/toc.dart';
import 'package:flutter_pecha/features/texts/models/text_detail.dart';
import 'package:flutter_pecha/features/texts/presentation/segment_html_widget.dart';
import 'package:flutter_pecha/shared/utils/helper_fucntions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fquery/fquery.dart';

class Chapter extends ConsumerWidget {
  final Toc content;
  final int? selectedIndex;
  final TextDetail textDetail;
  final UseInfiniteQueryResult<ReaderResponse, dynamic, TextDetailsParams>
  infiniteQuery;

  const Chapter({
    super.key,
    required this.content,
    this.selectedIndex,
    required this.textDetail,
    required this.infiniteQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (content.sections.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Loading previous content indicator
          if (infiniteQuery.isFetchingPreviousPage)
            _buildLoadingIndicator("Loading previous content..."),

          // Map through sections - equivalent to content.sections.map()
          ...content.sections.map(
            (section) => _buildRecursiveSection(section, ref),
          ),

          // Loading next content indicator
          if (infiniteQuery.isFetchingNextPage)
            _buildLoadingIndicator("Loading more content..."),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
      ),
    );
  }

  Widget _buildRecursiveSection(Section section, WidgetRef ref) {
    final sectionKey = GlobalKey();
    return Container(
      key: sectionKey,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          if (section.title != null && section.title!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                section.title!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // Outer container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              children: [
                // Segments mapping
                ...section.segments.map(
                  (segment) => _buildSegmentWidget(segment, ref),
                ),

                // Nested sections
                if (section.sections != null && section.sections!.isNotEmpty)
                  ...section.sections!.map(
                    (nestedSection) => Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: _buildRecursiveSection(nestedSection, ref),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentWidget(Segment segment, WidgetRef ref) {
    // final isSelected = selectedSegmentId == segment.segmentId;

    return Container(
      key: Key(segment.segmentId),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // onTap: () => onSegmentClick?.call(segment.segmentId),
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              // color:
              //     isSelected
              //         ? Theme.of(context).primaryColor.withOpacity(0.1)
              //         : Colors.transparent,
              // border: Border.all(
              //   color:
              //       isSelected
              //           ? Theme.of(context).primaryColor
              //           : Colors.grey.withOpacity(0.3),
              // ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Segment number
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: SizedBox(
                    width: 30,
                    child: Text(
                      segment.segmentNumber.toString(),
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Segment content
                Expanded(
                  child: SegmentHtmlWidget(
                    htmlContent: segment.content ?? '',
                    segmentIndex: segment.segmentNumber,
                    fontSize: ref.watch(fontSizeProvider),
                    language: textDetail.language,
                  ),
                  // child: Html(
                  //   data: segment.content ?? '',
                  //   style: {
                  //     "body": Style(
                  //       fontFamily: getFontFamily(textDetail.language ?? 'en'),
                  //       fontSize: FontSize(
                  //         getFontSize(textDetail.language ?? 'en') ?? 14,
                  //       ),
                  //       margin: Margins.zero,
                  //       padding: HtmlPaddings.zero,
                  //     ),
                  //   },
                  // ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
