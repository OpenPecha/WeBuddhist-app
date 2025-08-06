import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_pecha/features/texts/data/providers/selected_segment_provider.dart';
import 'package:flutter_pecha/features/texts/data/providers/texts_provider.dart';
import 'package:flutter_pecha/features/texts/models/section.dart';
import 'package:flutter_pecha/features/texts/models/text/reader_response.dart';
import 'package:flutter_pecha/features/texts/models/text/toc.dart';
import 'package:flutter_pecha/features/texts/models/text_detail.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/chapter.dart';
import 'package:flutter_pecha/features/texts/utils/hepler_functions.dart';
import 'package:flutter_pecha/shared/utils/helper_fucntions.dart';
import 'package:fquery/fquery.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// text chapter layout for long text
class TextChapter extends HookConsumerWidget {
  final String textId;
  final String contentId;
  final String? segmentId;
  const TextChapter({
    super.key,
    required this.textId,
    required this.contentId,
    this.segmentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedSegmentProvider);

    // Initialize the infinite query
    final infiniteQuery = useInfiniteQuery<
      ReaderResponse,
      dynamic,
      TextDetailsParams
    >(
      ['content', textId, contentId, segmentId!, 20],
      // Initial page parameters
      initialPageParam: TextDetailsParams(
        textId: textId,
        contentId: contentId,
        segmentId: segmentId,
        direction: 'next',
      ),
      // Function to fetch data for each page
      (TextDetailsParams params) async =>
          await ref.read(textDetailsFutureProvider(params).future),

      // Get the next page parameter
      getNextPageParam: (lastPage, allPages, lastPageParam, allParams) {
        if (lastPage.currentSegmentPosition == lastPage.totalSegments) {
          return null;
        }
        final lastSegmentId = getLastSegmentId(lastPage.content.sections);
        return TextDetailsParams(
          textId: textId,
          contentId: contentId,
          segmentId: lastSegmentId,
          direction: 'next',
        );
      },

      // Get the previous page parameter
      getPreviousPageParam: (firstPage, allPages, firstPageParam, allParams) {
        if (firstPage.currentSegmentPosition == 1) {
          return null;
        }
        final firstSegmentId = getFirstSegmentId(firstPage.content.sections);
        return TextDetailsParams(
          textId: textId,
          contentId: contentId,
          segmentId: firstSegmentId,
          direction: 'previous',
        );
      },
      enabled: textId.isNotEmpty,
    );

    // Debug prints to understand the state
    print("Query state: ${infiniteQuery.status}");
    print("Has data: ${infiniteQuery.data != null}");
    print("Pages count: ${infiniteQuery.data?.pages.length ?? 0}");
    if (infiniteQuery.data?.pages.isNotEmpty == true) {
      print(
        "First page title: ${infiniteQuery.data!.pages[0].textDetail.title}",
      );
    }

    // Merge all loaded sections for rendering
    final allContent = useMemoized(() {
      if (infiniteQuery.data?.pages == null ||
          infiniteQuery.data!.pages.isEmpty) {
        print("No pages available in infiniteQuery.data");
        return null;
      }
      try {
        List<Section> mergedSections = [];
        final textDetail = infiniteQuery.data!.pages[0].textDetail;

        for (int index = 0; index < infiniteQuery.data!.pages.length; index++) {
          final page = infiniteQuery.data!.pages[index];
          if (index == 0) {
            mergedSections = page.content.sections;
          } else {
            mergedSections = mergeSections(
              mergedSections,
              page.content.sections,
              'next',
            );
          }
        }

        // Create proper Toc object instead of Map
        final mergedToc = Toc(
          id: infiniteQuery.data!.pages[0].content.id,
          textId: infiniteQuery.data!.pages[0].content.textId,
          sections: mergedSections,
        );

        print("Successfully created merged content");
        return {'content': mergedToc, 'text_detail': textDetail};
      } catch (e) {
        print("Error creating merged content: $e");
        return null;
      }
    }, [infiniteQuery.data?.pages]);

    print("allContent: ${allContent != null ? 'not null' : 'null'}");

    Widget chapter;
    if (infiniteQuery.isLoading) {
      chapter = const Center(child: Text("Loading..."));
    } else if (infiniteQuery.isError) {
      chapter = const Center(child: Text('No data found'));
    } else {
      final content = allContent?['content'] as Toc;
      final textDetail = allContent?['text_detail'] as TextDetail;
      chapter = Column(
        children: [
          _buildChapterHeader(context, ref, textDetail),
          _buildChapter(
            context,
            ref,
            content,
            textDetail,
            infiniteQuery,
            selectedIndex,
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            ref.read(selectedSegmentProvider.notifier).state = null;
            context.pop();
          },
        ),
        toolbarHeight: 50,
      ),
      body: chapter,
    );
  }

  Widget _buildChapterHeader(
    BuildContext context,
    WidgetRef ref,
    TextDetail textDetail,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        textDetail.title,
        style: TextStyle(
          fontSize: getFontSize(textDetail.language),
          fontFamily: getFontFamily(textDetail.language),
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildChapter(
    BuildContext context,
    WidgetRef ref,
    Toc content,
    TextDetail textDetail,
    UseInfiniteQueryResult<ReaderResponse, dynamic, TextDetailsParams>
    infiniteQuery,
    int? selectedIndex,
  ) {
    return Expanded(
      child: Stack(
        children: [
          // Main content
          Chapter(
            textDetail: textDetail,
            content: content,
            selectedIndex: selectedIndex,
            infiniteQuery: infiniteQuery,
          ),
          // Segment action bar
          // if (selectedIndex != null) _buildSegmentActionBar(selectedIndex),
        ],
      ),
    );
  }
}
