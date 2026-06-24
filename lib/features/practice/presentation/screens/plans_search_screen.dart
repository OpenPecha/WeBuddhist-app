import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/series_search_provider.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_plan_list_tile.dart';
import 'package:flutter_pecha/features/recitation/presentation/widgets/recitation_list_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlansSearchScreen extends ConsumerStatefulWidget {
  const PlansSearchScreen({super.key, required this.onTap});

  final ValueChanged<Series> onTap;

  @override
  ConsumerState<PlansSearchScreen> createState() => _PlansSearchScreenState();
}

class _PlansSearchScreenState extends ConsumerState<PlansSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final SeriesSearchNotifier _searchNotifier;

  @override
  void initState() {
    super.initState();
    _searchNotifier = ref.read(seriesSearchProvider.notifier);
    _searchController.addListener(_onSearchTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onSearchTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _focusNode.dispose();
    _searchNotifier.clear();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    ref.read(seriesSearchProvider.notifier).search(query);
  }

  void _onClear() {
    _searchController.clear();
    ref.read(seriesSearchProvider.notifier).clear();
    _focusNode.requestFocus();
  }

  void _onBack() {
    ref.read(seriesSearchProvider.notifier).clear();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final searchState = ref.watch(seriesSearchProvider);
    final borderColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final subtitleColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _onBack,
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      onChanged: _onQueryChanged,
                      textInputAction: TextInputAction.search,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: context.l10n.search_plans,
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: subtitleColor,
                          fontSize: 15,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 20,
                          color: subtitleColor,
                        ),
                        suffixIcon:
                            _searchController.text.isNotEmpty
                                ? IconButton(
                                  onPressed: _onClear,
                                  icon: Icon(
                                    Icons.clear,
                                    size: 20,
                                    color: subtitleColor,
                                  ),
                                )
                                : null,
                        filled: true,
                        fillColor:
                            isDark
                                ? AppColors.surfaceDark
                                : AppColors.surfaceWhite,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide(color: borderColor),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildBody(context, searchState, subtitleColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SeriesSearchState searchState,
    Color subtitleColor,
  ) {
    final l10n = context.l10n;

    if (searchState.query.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    if (searchState.isLoading && searchState.results.isEmpty) {
      return const RecitationListSkeleton();
    }

    if (searchState.error != null && searchState.results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                searchState.error!,
                style: TextStyle(color: subtitleColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(seriesSearchProvider.notifier).retry(),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (searchState.results.isEmpty && !searchState.isLoading) {
      return Center(
        child: Text(
          l10n.home_no_series_found,
          style: TextStyle(color: subtitleColor),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: searchState.results.length,
      itemBuilder: (context, index) {
        final series = searchState.results[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PracticePlanListTile(
            series: series,
            onTap: () => widget.onTap(series),
          ),
        );
      },
    );
  }
}
