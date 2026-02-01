import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/ai/models/search_state.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/search_result_card.dart';
import 'package:flutter_pecha/features/texts/models/search/multilingual_source_result.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Tab view showing both titles and contents (limited to 3 each)
class AllTabView extends StatelessWidget {
  final SearchState searchState;
  final Function(SearchTab) onShowMore;
  final VoidCallback onRetry;

  const AllTabView({
    super.key,
    required this.searchState,
    required this.onShowMore,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (searchState.isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (searchState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: isDarkMode ? AppColors.grey500 : AppColors.grey400,
              ),
              const SizedBox(height: 16),
              Text(
                'Error: ${searchState.error}',
                style: TextStyle(
                  color: isDarkMode ? AppColors.grey400 : AppColors.grey600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: searchState.isLoading ? null : onRetry,
                icon: Icon(
                  searchState.isLoading ? Icons.hourglass_empty : Icons.refresh,
                ),
                label: Text(searchState.isLoading ? 'Retrying...' : 'Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final results = searchState.contentResults;
    if (results == null || results.sources.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'No results found for "${searchState.currentQuery}"',
            style: TextStyle(
              color: isDarkMode ? AppColors.grey400 : AppColors.grey600,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Get first 3 content results
    final contentResults = results.sources.take(3).toList();
    final hasMoreContent = results.sources.length > 1;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Titles Section
        _buildSectionHeader(context, isDarkMode, 'Titles'),
        _buildComingSoonMessage(context, isDarkMode),
        const SizedBox(height: 24),

        // Contents Section
        if (contentResults.isNotEmpty) ...[
          _buildSectionHeader(context, isDarkMode, 'Contents'),
          ...contentResults.map(
            (source) => _buildContentResultCard(
              context,
              source,
              searchState.currentQuery,
            ),
          ),
          if (hasMoreContent) ...[
            const SizedBox(height: 25),
            _buildShowMoreButton(context, isDarkMode, SearchTab.contents),
          ],
          const SizedBox(height: 16),
        ],
        // Author Section
        _buildSectionHeader(context, isDarkMode, 'Author'),
        _buildComingSoonMessage(context, isDarkMode),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    bool isDarkMode,
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 16, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? AppColors.surfaceWhite : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildContentResultCard(
    BuildContext context,
    MultilingualSourceResult source,
    String query,
  ) {
    // Reuse existing SearchResultCard - only show first segment
    final segments =
        source.segmentMatches.isNotEmpty
            ? <Map<String, String>>[
              {
                'segmentId': source.segmentMatches[0].segmentId,
                'content': source.segmentMatches[0].content,
              },
            ]
            : <Map<String, String>>[];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SearchResultCard(
        textId: source.text.textId,
        textTitle: source.text.title,
        segments: segments,
        searchQuery: query,
      ),
    );
  }

  Widget _buildComingSoonMessage(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? AppColors.grey800.withOpacity(0.3)
                : AppColors.grey300.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? AppColors.grey800 : AppColors.grey300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: isDarkMode ? AppColors.grey400 : AppColors.grey600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? AppColors.grey400 : AppColors.grey600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowMoreButton(
    BuildContext context,
    bool isDarkMode,
    SearchTab tab,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () => onShowMore(tab),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.5),
              width: 1,
            ),
            color: AppColors.primary.withValues(alpha: 0.05),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Show More',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
