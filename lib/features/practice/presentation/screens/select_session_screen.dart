import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/core/widgets/skeletons/skeletons.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_pecha/features/practice/data/models/session_selection.dart';
import 'package:flutter_pecha/features/practice/domain/entities/practice_item.dart';
import 'package:flutter_pecha/features/practice/domain/entities/practice_items_tab.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_items_paginated_provider.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitations_providers.dart';
import 'package:flutter_pecha/features/recitation/presentation/widgets/recitation_list_skeleton.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_pecha/features/timer/presentation/providers/timers_providers.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';

final _logger = AppLogger('SelectSessionScreen');

/// Session picker with four tabs: Plans · Chants · Malas · Timers.
/// Returns a [SessionSelection] subtype that [EditRoutineScreen] dispatches on.
class SelectSessionScreen extends ConsumerStatefulWidget {
  const SelectSessionScreen({super.key});

  @override
  ConsumerState<SelectSessionScreen> createState() =>
      _SelectSessionScreenState();
}

class _SelectSessionScreenState extends ConsumerState<SelectSessionScreen>
    with SingleTickerProviderStateMixin {
  static const PracticeItemsTab _practiceTab = PracticeItemsTab.all;

  late TabController _tabController;
  final ScrollController _plansScrollController = ScrollController();

  final String? _enrollingItemId = null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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

  void _onRecitationSelected(RecitationModel recitation) {
    if (_enrollingItemId != null) return;
    Navigator.of(context).pop<SessionSelection>(
      RecitationSessionSelection(recitation),
    );
  }

  void _onMantraSelected(Mantra mantra) {
    Navigator.of(context).pop<SessionSelection>(MantraSessionSelection(mantra));
  }

  void _onTimerSelected(PresetTimer timer) {
    Navigator.of(context).pop<SessionSelection>(TimerSessionSelection(timer));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AppAssets.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Text(
          localizations.routine_add_session,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        scrolledUnderElevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 22),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: localizations.home_plans),
            Tab(text: localizations.home_chants),
            Tab(text: localizations.home_mala),
            Tab(text: localizations.home_timer),
          ],
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          labelColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          unselectedLabelColor: isDark
              ? AppColors.textTertiaryDark
              : AppColors.textSecondary,
          indicatorColor: Colors.blue,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PlansTab(
            tab: _practiceTab,
            scrollController: _plansScrollController,
            enrollingItemId: _enrollingItemId,
            onItemSelected: _onPracticeItemSelected,
          ),
          _ChantsTab(
            enrollingItemId: _enrollingItemId,
            onRecitationSelected: _onRecitationSelected,
          ),
          _MalasTab(onMantraSelected: _onMantraSelected),
          _TimersTab(onTimerSelected: _onTimerSelected),
        ],
      ),
    );
  }
}

// ─── Plans tab ───────────────────────────────────────────────────────────────

class _PlansTab extends ConsumerWidget {
  final PracticeItemsTab tab;
  final ScrollController scrollController;
  final String? enrollingItemId;
  final void Function(PracticeItem item) onItemSelected;

  const _PlansTab({
    required this.tab,
    required this.scrollController,
    required this.enrollingItemId,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsState = ref.watch(practiceItemsPaginatedProvider(tab));

    _logger.debug(
      '📋 _PlansTab BUILD: ${itemsState.items.length} items, '
      'isLoading: ${itemsState.isLoading}, error: ${itemsState.error}',
    );

    if (itemsState.isLoading && itemsState.items.isEmpty) {
      return const PlanListSkeleton();
    }

    if (itemsState.error != null && itemsState.items.isEmpty) {
      return ErrorStateWidget(
        error: itemsState.error!,
        onRetry: () =>
            ref.read(practiceItemsPaginatedProvider(tab).notifier).retry(),
        customMessage: 'Unable to load plans.\nPlease try again later.',
      );
    }

    final items = itemsState.items;

    if (items.isEmpty && !itemsState.isLoading) {
      return Center(
        child: Text(
          'No plans found',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: items.length + (itemsState.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: itemsState.isLoadingMore
                  ? const CircularProgressIndicator()
                  : const SizedBox.shrink(),
            ),
          );
        }

        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildPlanCard(context, item),
        );
      },
    );
  }

  Widget _buildPlanCard(BuildContext context, PracticeItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (item) {
      case PracticePlanItem(:final plan):
        final dateRange = _formatDateRange(
          plan.startDate,
          plan.startDate?.add(Duration(days: plan.totalDays)),
        );
        return _SessionCard(
          isDark: isDark,
          onTap: enrollingItemId == null ? () => onItemSelected(item) : null,
          child: Row(
            children: [
              _CoverImage(image: plan.coverImage, size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (dateRange != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        dateRange,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );

      case PracticeSeriesItem(:final series):
        final dateRange = _formatDateRange(series.startDate, series.endDate);
        final subtitle = series.subTitle?.isNotEmpty == true
            ? series.subTitle
            : dateRange;
        return _SessionCard(
          isDark: isDark,
          onTap: enrollingItemId == null ? () => onItemSelected(item) : null,
          child: Row(
            children: [
              _CoverImage(image: series.coverImage, size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }

  static String? _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null) return null;
    final fmt = DateFormat('MMM d');
    final startStr = fmt.format(start.toLocal());
    if (end == null) return startStr;
    return '$startStr - ${fmt.format(end.toLocal())}';
  }
}

// ─── Chants tab ──────────────────────────────────────────────────────────────

class _ChantsTab extends ConsumerWidget {
  final String? enrollingItemId;
  final void Function(RecitationModel recitation) onRecitationSelected;

  const _ChantsTab({
    required this.enrollingItemId,
    required this.onRecitationSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recitationsAsync = ref.watch(recitationsFutureProvider);

    return recitationsAsync.when(
      loading: () => const RecitationListSkeleton(),
      error: (_, __) => Center(
        child: Text(
          'Unable to load chants',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
      data: (recitationsEither) => recitationsEither.fold(
        (_) => Center(
          child: Text(
            'Unable to load chants',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        (recitations) {
          if (recitations.isEmpty) {
            return Center(
              child: Text(
                'No chants found',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: recitations.length,
            itemBuilder: (context, index) {
              final recitation = recitations[index];
              final description = recitation.firstSegment?.content;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SessionCard(
                  isDark: isDark,
                  onTap: enrollingItemId == null
                      ? () => onRecitationSelected(recitation)
                      : null,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 4,
                        height: description != null ? null : 44,
                        constraints: const BoxConstraints(minHeight: 44),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.grey400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recitation.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (description != null &&
                                description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.textTertiaryDark
                                      : AppColors.textSecondary,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Malas tab ───────────────────────────────────────────────────────────────

class _MalasTab extends ConsumerWidget {
  final void Function(Mantra mantra) onMantraSelected;

  const _MalasTab({required this.onMantraSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final language = ref.watch(localeProvider).languageCode;
    final catalogueAsync = ref.watch(malaCatalogueProvider);

    return catalogueAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(
          'Unable to load malas',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
      data: (either) => either.fold(
        (_) => Center(
          child: Text(
            'Unable to load malas',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        (mantras) {
          if (mantras.isEmpty) {
            return Center(
              child: Text(
                'No malas found',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: mantras.length,
            itemBuilder: (context, index) {
              final mantra = mantras[index];
              final imageUrl =
                  mantra.beadImageUrl ?? mantra.mantra?.beadImageUrl;
              final title = mantra.displayTitle(language);
              _logger.debug(
                '🪬 Mala[$index] title=$title imageUrl=$imageUrl',
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SessionCard(
                  isDark: isDark,
                  onTap: () => onMantraSelected(mantra),
                  child: Row(
                    children: [
                      _CircularImage(imageUrl: imageUrl, size: 52),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Timers tab ──────────────────────────────────────────────────────────────

class _TimersTab extends ConsumerWidget {
  final void Function(PresetTimer timer) onTimerSelected;

  const _TimersTab({required this.onTimerSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;
    final timersAsync = ref.watch(presetTimersFutureProvider);

    return timersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(
          'Unable to load timers',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
      data: (either) => either.fold(
        (_) => Center(
          child: Text(
            'Unable to load timers',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        (timers) {
          if (timers.isEmpty) {
            return Center(
              child: Text(
                'No timers found',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: timers.length,
            itemBuilder: (context, index) {
              final timer = timers[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SessionCard(
                  isDark: isDark,
                  onTap: () => onTimerSelected(timer),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceVariantDark
                              : AppColors.grey100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? AppColors.cardBorderDark
                                : AppColors.grey300,
                          ),
                        ),
                        child: Icon(
                          PhosphorIconsRegular.timer,
                          size: 22,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${timer.displayMinutes} ${localizations.timer_min}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Shared card wrapper ──────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final VoidCallback? onTap;

  const _SessionCard({
    required this.child,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.cardBorderDark : AppColors.grey100,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── Shared image widgets ─────────────────────────────────────────────────────

/// Rounded-rectangle cover image or grey placeholder.
class _CoverImage extends StatelessWidget {
  final ResponsiveImage? image;
  final double size;

  const _CoverImage({this.image, required this.size});

  @override
  Widget build(BuildContext context) {
    if (image != null && !image!.isEmpty) {
      return ResponsiveCoverImage(
        image: image,
        width: size,
        height: size,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(8),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

/// Circular image for malas — uses CachedNetworkImage so bead art renders
/// correctly (same approach as MalaBeads).
class _CircularImage extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const _CircularImage({this.imageUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _placeholder(),
          errorWidget: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: AppColors.grey100,
      shape: BoxShape.circle,
    ),
  );
}
