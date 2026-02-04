import 'package:flutter_pecha/features/ai/models/search_state.dart';
import 'package:flutter_pecha/features/texts/data/providers/apis/texts_provider.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controller for managing search state and operations
class SearchStateNotifier extends StateNotifier<SearchState> {
  final Ref ref;
  final _logger = AppLogger('SearchStateNotifier');
  static const int maxHistorySize = 10;

  SearchStateNotifier(this.ref) : super(const SearchState(currentQuery: ''));

  /// Perform search with the given query
  /// Fetches content, title, and author results simultaneously
  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;

    _logger.info('Performing search for: $query');

    state = state.copyWith(
      currentQuery: query,
      isLoading: true,
      error: null,
    );

    try {
      // Fetch all three search types in parallel for better performance
      final contentParams = LibrarySearchParams(query: query);
      final titleParams = TitleSearchParams(title: query);
      final authorParams = AuthorSearchParams(author: query);

      final contentResults =
          await ref.read(multilingualSearchProvider(contentParams).future);
      final titleResults =
          await ref.read(titleSearchProvider(titleParams).future);
      final authorResults =
          await ref.read(authorSearchProvider(authorParams).future);

      // Add to history (limit to 10, avoid duplicates)
      final newHistory = {query, ...state.searchHistory}
          .take(maxHistorySize)
          .toList();

      _logger.info(
        'Search completed with ${contentResults.sources.length} content results, '
        '${titleResults.results.length} title results, and '
        '${authorResults.results.length} author results',
      );

      state = state.copyWith(
        contentResults: contentResults,
        titleResults: titleResults,
        authorResults: authorResults,
        isLoading: false,
        searchHistory: newHistory,
      );
    } catch (e) {
      _logger.error('Search failed', e);
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Switch to a different tab
  void switchTab(SearchTab tab) {
    _logger.debug('Switching to tab: $tab');
    state = state.copyWith(selectedTab: tab);
  }

  /// Clear the current error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Update the current query without performing search
  void updateQuery(String query) {
    state = state.copyWith(currentQuery: query);
  }

  /// Set flag to switch to AI mode (used when navigating from search results)
  void setSwitchToAiMode(bool value) {
    state = state.copyWith(shouldSwitchToAiMode: value);
  }
}

/// Provider for search state management
final searchStateProvider =
    StateNotifierProvider<SearchStateNotifier, SearchState>((ref) {
  return SearchStateNotifier(ref);
});
