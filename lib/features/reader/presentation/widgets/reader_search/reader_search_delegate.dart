import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/text_search_skeleton.dart';
import 'package:flutter_pecha/features/texts/constants/text_screen_constants.dart';
import 'package:flutter_pecha/features/texts/data/providers/apis/texts_provider.dart';
import 'package:flutter_pecha/features/texts/models/search/multilingual_source_result.dart';
import 'package:flutter_pecha/features/texts/utils/text_highlight_helper.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Search delegate for the reader feature
/// Returns a Map with 'textId' and 'segmentId' on selection
class ReaderSearchDelegate extends SearchDelegate<Map<String, String>?> {
  final WidgetRef ref;
  final String textId;
  final String? language;
  String _submittedQuery = '';
  bool _hasSubmitted = false;

  ReaderSearchDelegate({
    required this.ref,
    required this.textId,
    this.language,
  });

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          _submittedQuery = '';
          _hasSubmitted = false;
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isNotEmpty && !_hasSubmitted) {
      _submittedQuery = query;
      _hasSubmitted = true;
    }
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (_hasSubmitted && query != _submittedQuery) {
      _hasSubmitted = false;
      _submittedQuery = '';
    }
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: const Center(
          child: Text(
            'Type to search',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    if (!_hasSubmitted || _submittedQuery.isEmpty) {
      return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: const Center(
          child: Text(
            'Press search button to search',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    final searchParams = LibrarySearchParams(
      query: _submittedQuery,
      textId: textId,
      language: language,
    );

    return Consumer(
      builder: (context, ref, child) {
        final searchResults = ref.watch(
          multilingualSearchProvider(searchParams),
        );

        return searchResults.when(
          loading: () => const TextSearchSkeleton(),
          error:
              (error, stackTrace) => ErrorStateWidget(
                error: error,
                customMessage: 'Unable to perform search.\nPlease try again.',
              ),
          data: (searchResponse) {
            if (searchResponse.sources.isEmpty) {
              return _buildNoResults();
            }

            final allSegmentMatches = <MultilingualSegmentMatch>[];
            for (final source in searchResponse.sources) {
              if (source.text.textId == textId) {
                allSegmentMatches.addAll(source.segmentMatches);
              }
            }

            if (allSegmentMatches.isEmpty) {
              return _buildNoResults();
            }

            final segments =
                allSegmentMatches
                    .map(
                      (match) => {
                        'segmentId': match.segmentId,
                        'content': match.content,
                      },
                    )
                    .toList();

            return Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: ListView(
                children: [
                  _SearchResultsCard(
                    textId: textId,
                    segments: segments,
                    searchQuery: _submittedQuery,
                    onSegmentTap: (segmentId) {
                      close(context, {
                        'textId': textId,
                        'segmentId': segmentId,
                      });
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Text(
        'No results found for "$_submittedQuery"',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}

/// Custom search result card for reader that handles segment selection
class _SearchResultsCard extends ConsumerWidget {
  final String textId;
  final List<Map<String, String>> segments;
  final String searchQuery;
  final void Function(String segmentId) onSegmentTap;

  const _SearchResultsCard({
    required this.textId,
    required this.segments,
    required this.searchQuery,
    required this.onSegmentTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(localeProvider).languageCode;
    final fontFamily = getFontFamily(language);
    final lineHeight = getLineHeight(language);
    final fontSize = language == 'bo' ? 20.0 : 16.0;

    return Card(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      margin: TextScreenConstants.cardMargin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...segments.asMap().entries.map((entry) {
            final segmentIndex = entry.key;
            final segment = entry.value;
            final segmentId = segment['segmentId']!;
            final content = segment['content']!;
            final cleanContent = content.replaceAll(RegExp(r'<[^>]*>'), '');

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSegmentItem(
                  context,
                  segmentId,
                  cleanContent,
                  language,
                  fontFamily,
                  lineHeight,
                  fontSize,
                ),
                if (segmentIndex < segments.length - 1)
                  SizedBox(height: TextScreenConstants.contentVerticalSpacing),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSegmentItem(
    BuildContext context,
    String segmentId,
    String content,
    String language,
    String? fontFamily,
    double? lineHeight,
    double fontSize,
  ) {
    return InkWell(
      onTap: () => onSegmentTap(segmentId),
      borderRadius: BorderRadius.circular(TextScreenConstants.cardBorderRadius),
      child: Container(
        width: double.infinity,
        padding: TextScreenConstants.cardInnerPaddingValue,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(
            TextScreenConstants.cardBorderRadius,
          ),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: TextScreenConstants.thinDividerThickness,
          ),
        ),
        child: Text.rich(
          TextSpan(
            children: buildHighlightedText(
              context,
              content,
              searchQuery,
              TextStyle(
                fontSize: fontSize,
                fontFamily: fontFamily,
                height: lineHeight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
