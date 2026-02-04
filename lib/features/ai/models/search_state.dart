import 'package:flutter_pecha/features/texts/models/search/multilingual_search_response.dart';
import 'package:flutter_pecha/features/texts/models/search/title_search_response.dart';

/// Enum representing different search tabs
enum SearchTab { aiMode, all, titles, contents, author }

/// State model for search functionality
class SearchState {
  final String currentQuery;
  final SearchTab selectedTab;
  final MultilingualSearchResponse? contentResults;
  final TitleSearchResponse? titleResults;
  final TitleSearchResponse? authorResults;
  final bool isLoading;
  final String? error;
  final List<String> searchHistory;
  final bool shouldSwitchToAiMode;

  const SearchState({
    required this.currentQuery,
    this.selectedTab = SearchTab.all,
    this.contentResults,
    this.titleResults,
    this.authorResults,
    this.isLoading = false,
    this.error,
    this.searchHistory = const [],
    this.shouldSwitchToAiMode = false,
  });

  SearchState copyWith({
    String? currentQuery,
    SearchTab? selectedTab,
    MultilingualSearchResponse? contentResults,
    TitleSearchResponse? titleResults,
    TitleSearchResponse? authorResults,
    bool? isLoading,
    String? error,
    List<String>? searchHistory,
    bool? shouldSwitchToAiMode,
  }) {
    return SearchState(
      currentQuery: currentQuery ?? this.currentQuery,
      selectedTab: selectedTab ?? this.selectedTab,
      contentResults: contentResults ?? this.contentResults,
      titleResults: titleResults ?? this.titleResults,
      authorResults: authorResults ?? this.authorResults,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchHistory: searchHistory ?? this.searchHistory,
      shouldSwitchToAiMode: shouldSwitchToAiMode ?? this.shouldSwitchToAiMode,
    );
  }
}
