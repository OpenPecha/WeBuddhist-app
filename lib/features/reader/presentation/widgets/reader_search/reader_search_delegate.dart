import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/texts/data/providers/apis/texts_provider.dart';
import 'package:flutter_pecha/features/texts/models/search/segment_match.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Search delegate for the reader feature
/// Returns a Map with 'textId' and 'segmentId' on selection
class ReaderSearchDelegate extends SearchDelegate<Map<String, String>?> {
  final WidgetRef ref;
  final String textId;
  String _submittedQuery = '';
  bool _hasSubmitted = false;

  ReaderSearchDelegate({required this.ref, required this.textId});

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

    final searchParams = SearchTextParams(
      query: _submittedQuery,
      textId: textId,
    );

    return Consumer(
      builder: (context, ref, child) {
        final searchResults = ref.watch(searchTextFutureProvider(searchParams));

        return searchResults.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, stackTrace) => ErrorStateWidget(
                error: error,
                customMessage: 'Unable to perform search.\nPlease try again.',
              ),
          data: (searchResponse) {
            if (searchResponse.sources == null ||
                searchResponse.sources!.isEmpty) {
              return _buildNoResults();
            }

            final allSegmentMatches = <SegmentMatch>[];
            for (final source in searchResponse.sources!) {
              allSegmentMatches.addAll(source.segmentMatches);
            }

            if (allSegmentMatches.isEmpty) {
              return _buildNoResults();
            }

            return _SearchResultsList(
              matches: allSegmentMatches,
              onSelect: (segmentId) {
                close(context, {'textId': textId, 'segmentId': segmentId});
              },
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

/// Widget displaying search results as a list
class _SearchResultsList extends StatelessWidget {
  final List<SegmentMatch> matches;
  final void Function(String segmentId) onSelect;

  const _SearchResultsList({required this.matches, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView.separated(
        itemCount: matches.length,
        separatorBuilder:
            (context, index) => const Divider(
              height: 1,
              color: Colors.grey,
              indent: 20,
              endIndent: 20,
            ),
        itemBuilder: (context, index) {
          final match = matches[index];
          return _SearchResultItem(
            match: match,
            onTap: () => onSelect(match.segmentId),
          );
        },
      ),
    );
  }
}

/// Individual search result item
class _SearchResultItem extends StatelessWidget {
  final SegmentMatch match;
  final VoidCallback onTap;

  const _SearchResultItem({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cleanContent = match.content.replaceAll(RegExp(r'<[^>]*>'), '');

    return ListTile(
      title: Text(cleanContent),
      subtitle: Text(
        'Segment ${match.content}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      onTap: onTap,
    );
  }
}
