import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/core/widgets/skeletons/skeletons.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_enrollment_provider.dart';
import 'package:flutter_pecha/features/practice/data/models/session_selection.dart';
import 'package:flutter_pecha/features/practice/domain/entities/practice_item.dart';
import 'package:flutter_pecha/features/practice/domain/entities/practice_items_tab.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_items_paginated_provider.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitations_providers.dart';
import 'package:flutter_pecha/features/recitation/presentation/widgets/recitation_list_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = AppLogger('SelectSessionScreen');

/// Combined screen for selecting either a Plan, Series, or Recitation to add
/// to the routine. Returns a [SessionSelection] subtype that the caller
/// (`EditRoutineScreen`) dispatches on.
///
/// Plans/series come from `GET /practice/items` (page-based). Recitations
/// remain on their own list endpoint. The plans tab filters out:
///   - plan IDs already in the routine (`excludedPlanIds`)
///   - series IDs the user is already enrolled in
///     (`userSeriesEnrollmentsProvider`)
class SelectSessionScreen extends ConsumerStatefulWidget {
  /// IDs of plans already in the routine (across all blocks).
  final Set<String> excludedPlanIds;

  const SelectSessionScreen({super.key, this.excludedPlanIds = const {}});

  @override
  ConsumerState<SelectSessionScreen> createState() =>
      _SelectSessionScreenState();
}

class _SelectSessionScreenState extends ConsumerState<SelectSessionScreen>
    with SingleTickerProviderStateMixin {
  /// Tab used by the practice picker. Both plans and series live on the same
  /// "Add Plan" tab; recitations get their own tab.
  static const PracticeItemsTab _practiceTab = PracticeItemsTab.all;

  late TabController _tabController;
  final ScrollController _plansScrollController = ScrollController();

  /// ID of the item currently being enrolled/saved (null if idle).
  /// Reserved for future inline-loading affordances; today's flow pops
  /// immediately, so this stays null in normal use.
  final String? _enrollingItemId = null;

  @override
  void initState() {
    super.initState();
    _logger.debug('🚀 initState() called');
    _tabController = TabController(length: 2, vsync: this);
    _plansScrollController.addListener(_onPlansScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _plansScrollController.removeListener(_onPlansScroll);
    _plansScrollController.dispose();
    super.dispose();
  }

  void _onPlansScroll() {
    if (_plansScrollController.position.pixels >=
        _plansScrollController.position.maxScrollExtent - 200) {
      ref
          .read(practiceItemsPaginatedProvider(_practiceTab).notifier)
          .loadMore();
    }
  }

  void _onPracticeItemSelected(PracticeItem item) {
    if (_enrollingItemId != null) return;
    final selection = switch (item) {
      PracticePlanItem(:final plan) => PlanSessionSelection(plan),
      PracticeSeriesItem(:final series) => SeriesSessionSelection(series),
    };
    Navigator.of(context).pop<SessionSelection>(selection);
  }

  Future<void> _onRecitationSelected(dynamic recitation) async {
    if (_enrollingItemId != null) return;
    Navigator.of(context).pop(RecitationSessionSelection(recitation));
  }

  @override
  Widget build(BuildContext context) {
    _logger.debug('🎨 ===== BUILD STARTED =====');
    final localizations = AppLocalizations.of(context)!;

    final allExcludedPlanIds = widget.excludedPlanIds;
    _logger.debug('📊 Excluded Plan IDs: ${allExcludedPlanIds.length}');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.routine_add_session,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        scrolledUnderElevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: localizations.routine_add_plan),
            Tab(text: localizations.routine_add_recitation),
          ],
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 16,
          ),
          labelColor:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
          unselectedLabelColor:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.5),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PracticeItemsTab(
            tab: _practiceTab,
            scrollController: _plansScrollController,
            excludedPlanIds: allExcludedPlanIds,
            enrollingItemId: _enrollingItemId,
            onItemSelected: _onPracticeItemSelected,
          ),
          _RecitationsTab(
            enrollingItemId: _enrollingItemId,
            onRecitationSelected: _onRecitationSelected,
          ),
        ],
      ),
    );
  }
}

/// Tab content for the practice picker (plans + series).
///
/// Filtering rules:
///   - plan rows whose id is in [excludedPlanIds] are dropped (already in
///     the routine);
///   - series rows whose id is in [userSeriesEnrollmentsProvider] are
///     dropped (user is already enrolled — re-enrolling would be a no-op).
class _PracticeItemsTab extends ConsumerWidget {
  final PracticeItemsTab tab;
  final ScrollController scrollController;
  final Set<String> excludedPlanIds;
  final String? enrollingItemId;
  final void Function(PracticeItem item) onItemSelected;

  const _PracticeItemsTab({
    required this.tab,
    required this.scrollController,
    required this.excludedPlanIds,
    required this.enrollingItemId,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final itemsState = ref.watch(practiceItemsPaginatedProvider(tab));

    // Defensive fallback: if the enrolled-series fetch is still loading or
    // failed, hide nothing — matching the home enrollment flow's
    // `valueOrNull ?? {}` semantics so the list stays usable.
    final enrolledSeriesIds =
        ref.watch(userSeriesEnrollmentsProvider).valueOrNull ??
        const <String>{};

    _logger.debug(
      '📋 _PracticeItemsTab BUILD: ${itemsState.items.length} items, '
      'isLoading: ${itemsState.isLoading}, error: ${itemsState.error}',
    );

    if (itemsState.isLoading && itemsState.items.isEmpty) {
      return const PlanListSkeleton();
    }

    if (itemsState.error != null && itemsState.items.isEmpty) {
      return ErrorStateWidget(
        error: itemsState.error!,
        onRetry:
            () =>
                ref.read(practiceItemsPaginatedProvider(tab).notifier).retry(),
        customMessage: 'Unable to load plans.\nPlease try again later.',
      );
    }

    final availableItems =
        itemsState.items.where((item) {
          switch (item) {
            case PracticePlanItem(:final plan):
              return !excludedPlanIds.contains(plan.id);
            case PracticeSeriesItem(:final series):
              return !enrolledSeriesIds.contains(series.id);
          }
        }).toList();

    _logger.debug(
      '✅ Available practice items after filtering: ${availableItems.length}',
    );

    if (availableItems.isEmpty && !itemsState.isLoading) {
      // Edge case: after filtering (already-in-routine plans + enrolled
      // series), the current loaded pages may all be hidden while the API
      // still has more pages that could contain visible items. Keep advancing
      // pagination instead of showing a false empty-state.
      if (itemsState.hasMore) {
        if (itemsState.error != null) {
          return ErrorStateWidget(
            error: itemsState.error!,
            onRetry:
                () =>
                    ref
                        .read(practiceItemsPaginatedProvider(tab).notifier)
                        .retry(),
            customMessage: 'Unable to load more plans.\nPlease try again.',
          );
        }

        if (!itemsState.isLoadingMore) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            ref.read(practiceItemsPaginatedProvider(tab).notifier).loadMore();
          });
        }

        return const Center(child: CircularProgressIndicator());
      }

      return Center(
        child: Text(
          localizations.no_plans_found,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      itemCount: availableItems.length + (itemsState.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == availableItems.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child:
                  itemsState.isLoadingMore
                      ? const CircularProgressIndicator()
                      : const SizedBox.shrink(),
            ),
          );
        }

        final item = availableItems[index];
        return _buildItemTile(item);
      },
    );
  }

  Widget _buildItemTile(PracticeItem item) {
    switch (item) {
      case PracticePlanItem(:final plan):
        final isEnrolling = enrollingItemId == plan.id;
        return _SessionListTile(
          title: plan.title,
          subtitle: null,
          imageUrl: plan.coverImageUrl,
          isLoading: isEnrolling,
          isDisabled: enrollingItemId != null,
          onTap: () => onItemSelected(item),
        );
      case PracticeSeriesItem(:final series):
        final isEnrolling = enrollingItemId == series.id;
        return _SessionListTile(
          title: series.title,
          subtitle: series.description.isNotEmpty ? series.description : null,
          imageUrl: series.imageUrl,
          isLoading: isEnrolling,
          isDisabled: enrollingItemId != null,
          onTap: () => onItemSelected(item),
        );
    }
  }
}

/// Tab content for displaying and selecting recitations.
/// Filters out recitations that are already saved or in the routine.
class _RecitationsTab extends ConsumerWidget {
  final String? enrollingItemId;
  final void Function(dynamic recitation) onRecitationSelected;

  const _RecitationsTab({
    required this.enrollingItemId,
    required this.onRecitationSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final recitationsAsync = ref.watch(recitationsFutureProvider);

    return recitationsAsync.when(
      loading: () => const RecitationListSkeleton(),
      error:
          (error, _) => Center(
            child: Text(
              localizations.recitations_no_content,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
      data: (recitationsEither) {
        return recitationsEither.fold(
          (failure) => Center(
            child: Text(
              localizations.recitations_no_content,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          (recitations) {
            if (recitations.isEmpty) {
              return Center(
                child: Text(
                  localizations.recitations_no_content,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              itemCount: recitations.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final recitation = recitations[index];
                final isEnrolling = enrollingItemId == recitation.textId;

                return _SessionListTile(
                  title: recitation.title,
                  subtitle: null,
                  imageUrl: AppAssets.recitationCoverDefault,
                  isLoading: isEnrolling,
                  isDisabled: enrollingItemId != null,
                  onTap: () => onRecitationSelected(recitation),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Reusable list tile for session selection (plans, series, recitations).
/// Supports loading and disabled states for enrollment/save feedback.
class _SessionListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final VoidCallback onTap;
  final bool isLoading;
  final bool isDisabled;

  const _SessionListTile({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.onTap,
    this.isLoading = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      child: AnimatedOpacity(
        opacity: isDisabled && !isLoading ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    imageUrl?.trim().isNotEmpty == true
                        ? CachedNetworkImageWidget(
                          imageUrl: imageUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(8),
                        )
                        : Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.grey100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.music_note,
                            color: AppColors.textSecondary,
                            size: 24,
                          ),
                        ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(left: 12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
