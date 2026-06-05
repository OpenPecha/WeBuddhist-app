import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/services/service_providers.dart';
import 'package:flutter_pecha/core/services/upgrade/update_banner.dart';
import 'package:flutter_pecha/core/services/upgrade/upgrade_provider.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/core/widgets/skeletons/skeletons.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_enrollment_provider.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_provider.dart';
import 'package:flutter_pecha/features/home/presentation/home_screen_constants.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/continue_today_card.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/featured_series_card.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/series_card.dart';
import 'package:flutter_pecha/features/notifications/application/plan_enrollment_hook.dart';
import 'package:flutter_pecha/features/notifications/application/special_plan_enrollment_hook.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_utils.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/my_plans_paginated_provider.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('HomeScreen');

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _hasRequestedPermissions = false;
  bool _showUpdateBanner = false;

  final FocusScopeNode _searchFocusScopeNode = FocusScopeNode();
  bool _didJustDismissSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestNotificationPermissionsIfNeeded();
    });
  }

  @override
  void dispose() {
    _searchFocusScopeNode.dispose();
    super.dispose();
  }

  Future<void> _requestNotificationPermissionsIfNeeded() async {
    _log.info(
      '[HOME-SCREEN] _requestNotificationPermissionsIfNeeded ENTER '
      'hasRequested=$_hasRequestedPermissions',
    );
    if (_hasRequestedPermissions) return;
    _hasRequestedPermissions = true;

    final notificationService = ref.read(notificationServiceProvider);
    if (notificationService == null) {
      _log.warning(
        '[HOME-SCREEN] NotificationService not initialized, skipping permission request',
      );
      _navigateToPendingPlanIfNeeded();
      return;
    }

    try {
      final alreadyEnabled =
          await notificationService.areNotificationsEnabled();
      _log.info('[HOME-SCREEN] alreadyEnabled=$alreadyEnabled');
      if (!alreadyEnabled) {
        _log.info('[HOME-SCREEN] requesting notification permissions...');
        final granted = await notificationService.requestPermission();
        _log.info('[HOME-SCREEN] permission request result granted=$granted');
      }
    } catch (e) {
      _log.warning(
        '[HOME-SCREEN] error requesting notification permissions: $e',
      );
    }

    await _firePendingSpecialPlanDay1IfNeeded();
    _navigateToPendingPlanIfNeeded();
  }

  Future<void> _firePendingSpecialPlanDay1IfNeeded() async {
    _log.info('invalidating userPlansFutureProvider for fresh fetch');
    ref.invalidate(userPlansFutureProvider);

    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      _log.info('fetch attempt $attempt/$maxAttempts');
      try {
        final userPlansAsync = await ref.read(userPlansFutureProvider.future);
        final isFailure = userPlansAsync.isLeft();
        _log.info('attempt $attempt resolved isFailure=$isFailure');
        if (isFailure && attempt < maxAttempts) {
          _log.warning(
            'attempt $attempt failed — invalidating and retrying: '
            '${userPlansAsync.fold((f) => f, (_) => "")}',
          );
          ref.invalidate(userPlansFutureProvider);
          await Future.delayed(const Duration(milliseconds: 400));
          continue;
        }
        await userPlansAsync.fold(
          (failure) async {
            _log.warning(
              'giving up after $attempt attempts — fetch failed: $failure',
            );
          },
          (response) async {
            _log.info(
              'user plans loaded count=${response.userPlans.length} '
              'on attempt=$attempt — firing pending day notifications',
            );
            await tryFirePendingSpecialPlanNotifications(response.userPlans);
            await tryFirePendingPlanDayNotifications(
              response.userPlans,
              ref.read(routineProvider).blocks,
            );
          },
        );
        break;
      } catch (e, st) {
        _log.warning('attempt $attempt threw: $e\n$st');
        if (attempt < maxAttempts) {
          ref.invalidate(userPlansFutureProvider);
          await Future.delayed(const Duration(milliseconds: 400));
        }
      }
    }
    _log.info('_firePendingSpecialPlanDay1IfNeeded EXIT');
  }

  void _navigateToPendingPlanIfNeeded() {
    if (!mounted) return;
    final plan = ref.read(pendingOnboardingPlanProvider);
    if (plan == null) return;

    ref.read(pendingOnboardingPlanProvider.notifier).state = null;

    final anchor = plan.effectiveStartDate;
    final selectedDay = PlanUtils.dayNumberFor(
      anchor,
      DateTime.now(),
      plan.totalDays,
    ).clamp(1, plan.totalDays);
    _log.info(
      '[ENROLL-NAV] onboarding open ${plan.id} '
      'anchor=${anchor.toIso8601String()} '
      'startDate=${plan.startDate?.toIso8601String()} '
      'startedAt=${plan.startedAt.toIso8601String()} '
      'selectedDay=$selectedDay/${plan.totalDays}',
    );
    context.push(
      '/practice/details',
      extra: {'plan': plan, 'selectedDay': selectedDay, 'startDate': anchor},
    );

    ref.read(mainNavigationIndexProvider.notifier).state =
        MainTab.practice.index;
  }

  Future<void> _onRefresh() async {
    ref.invalidate(seriesListFutureProvider);
    await ref.read(seriesListFutureProvider.future);
  }

  void _navigateToSeries(Series series) {
    context.pushNamed(
      'home-series-detail',
      pathParameters: {'id': series.id},
      extra: {'series': series},
    );
  }

  String _buildGreeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.home_good_morning;
    if (hour < 17) return l10n.home_good_afternoon;
    return l10n.home_good_evening;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final updateAvailable = ref.watch(updateAvailableProvider);
    final bannerAlreadyShown = ref.watch(updateBannerShownProvider);

    updateAvailable.whenData((isAvailable) {
      if (isAvailable && !bannerAlreadyShown && !_showUpdateBanner) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _showUpdateBanner = true);
            ref.read(updateBannerShownProvider.notifier).state = true;
          }
        });
      }
    });

    final seriesAsync = ref.watch(seriesListFutureProvider);
    final userState = ref.watch(userProvider);
    final firstName = userState.user?.firstName?.trim() ?? '';
    final greeting =
        firstName.isNotEmpty
            ? '${_buildGreeting(l10n)}, $firstName'
            : _buildGreeting(l10n);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            _buildScrollBody(context, l10n, greeting, seriesAsync),
            if (_showUpdateBanner)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: UpdateBanner(
                  onUpdateTap: () => ref.read(openAppStoreProvider)(),
                  onDismissed: () {
                    if (mounted) setState(() => _showUpdateBanner = false);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollBody(
    BuildContext context,
    AppLocalizations l10n,
    String greeting,
    AsyncValue<Either<Failure, List<Series>>> seriesAsync,
  ) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Greeting app bar ──────────────────────────────────────────
          SliverAppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            scrolledUnderElevation: 0,
            pinned: false,
            floating: true,
            snap: true,
            title: Text(
              greeting,
              strutStyle: context.tibetanStrutStyle(
                Theme.of(context).textTheme.headlineSmall?.fontSize ?? 24,
              ),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              _buildSearchAction(l10n, seriesAsync),
              const SizedBox(width: 4),
            ],
          ),

          // ── Content body ─────────────────────────────────────────────
          seriesAsync.when(
            data: (seriesEither) => seriesEither.fold(
              (failure) => SliverFillRemaining(
                child: ErrorStateWidget(
                  error: failure,
                  onRetry: _onRefresh,
                ),
              ),
              (seriesList) => _buildSeriesSections(context, l10n, seriesList),
            ),
            loading: () => const SliverFillRemaining(
              child: TagGridSkeleton(),
            ),
            error: (error, _) => SliverFillRemaining(
              child: ErrorStateWidget(
                error: error,
                onRetry: _onRefresh,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeriesSections(
    BuildContext context,
    AppLocalizations l10n,
    List<Series> seriesList,
  ) {
    if (seriesList.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(HomeScreenConstants.emptyStatePadding),
            child: Text(
              l10n.no_feature_content,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final enrolledIds =
        ref.watch(userSeriesEnrollmentsProvider).valueOrNull ?? const <String>{};
    final myPlansState = ref.watch(myPlansPaginatedProvider);

    // Split series into featured, enrolled (continue today), and explore more.
    final featured = seriesList.where((s) => s.featured).toList();
    final featuredSeries = featured.isNotEmpty ? featured.first : seriesList.first;

    final enrolledSeries =
        seriesList.where((s) => enrolledIds.contains(s.id)).toList();

    final exploreSeries =
        seriesList
            .where((s) => !enrolledIds.contains(s.id) && s.id != featuredSeries.id)
            .toList();
    // If the featured series is enrolled, include it in explore only if not enrolled.
    final exploreSeriesWithFeatured =
        enrolledIds.contains(featuredSeries.id)
            ? exploreSeries
            : [
                if (!exploreSeries.any((s) => s.id == featuredSeries.id))
                  // featured already shown above; don't duplicate in grid
                  ...exploreSeries
                else
                  ...exploreSeries,
              ];

    return SliverList(
      delegate: SliverChildListDelegate([
        // ── Search bar ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _buildSearchBar(l10n, seriesList),
        ),

        // ── Featured ───────────────────────────────────────────────────
        if (!enrolledIds.contains(featuredSeries.id)) ...[
          _buildSectionHeader(context, l10n.home_featured),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FeaturedSeriesCard(
              series: featuredSeries,
              onTap: () => _navigateToSeries(featuredSeries),
              creatorName: _creatorNameFor(featuredSeries),
            ),
          ),
        ],

        // ── Continue today ─────────────────────────────────────────────
        if (enrolledSeries.isNotEmpty) ...[
          _buildSectionHeader(context, l10n.home_continue_today),
          ...enrolledSeries.map((series) {
            final progress = _computeProgress(series, myPlansState);
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ContinueTodayCard(
                series: series,
                onTap: () => _navigateToSeries(series),
                creatorName: _creatorNameFor(series),
                progressPercent: progress?.percent,
                currentPlanLabel: progress?.label,
              ),
            );
          }),
        ],

        // ── Explore more ───────────────────────────────────────────────
        if (exploreSeriesWithFeatured.isNotEmpty) ...[
          _buildSectionHeader(context, l10n.home_explore_more),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: HomeScreenConstants.bodyHorizontalPadding,
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.3,
              ),
              itemCount: exploreSeriesWithFeatured.length,
              itemBuilder: (context, index) {
                final series = exploreSeriesWithFeatured[index];
                return SeriesCard(
                  series: series,
                  onTap: () => _navigateToSeries(series),
                );
              },
            ),
          ),
        ],

        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final locale = ref.watch(localeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title.toUpperCase(),
        strutStyle: context.tibetanStrutStyle(
          Theme.of(context).textTheme.labelMedium?.fontSize ?? 12,
        ),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: labelColor,
          fontWeight: FontWeight.w600,
          letterSpacing: locale.languageCode == 'bo' ? 0 : 1.2,
        ),
      ),
    );
  }

  // ── Search ──────────────────────────────────────────────────────────────

  Widget _buildSearchAction(
    AppLocalizations l10n,
    AsyncValue<Either<Failure, List<Series>>> seriesAsync,
  ) {
    final seriesList =
        seriesAsync.whenOrNull(data: (e) => e.fold((_) => null, (l) => l)) ??
        <Series>[];
    return IconButton(
      icon: const Icon(Icons.search),
      tooltip: l10n.text_search,
      onPressed: () => _showSearchSheet(context, l10n, seriesList),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n, List<Series> seriesList) {
    final locale = ref.watch(localeProvider);
    final fontSize = locale.languageCode == 'bo' ? 18.0 : 16.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return FocusScope(
      node: _searchFocusScopeNode,
      onFocusChange: (isFocused) {
        if (_didJustDismissSearch && isFocused) {
          _didJustDismissSearch = false;
          _searchFocusScopeNode.unfocus();
        }
      },
      child: SearchAnchor(
        builder: (context, controller) => SearchBar(
          controller: controller,
          constraints: HomeScreenConstants.searchBarConstraints,
          padding: const WidgetStatePropertyAll<EdgeInsets>(
            EdgeInsets.symmetric(
              horizontal: HomeScreenConstants.searchBarHorizontalPadding,
            ),
          ),
          elevation: const WidgetStatePropertyAll(0.0),
          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
          onTap: controller.openView,
          onChanged: (_) => controller.openView(),
          leading: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          hintText: l10n.text_search,
          hintStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: fontSize, color: hintColor),
          ),
        ),
        viewLeading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            _didJustDismissSearch = true;
            Navigator.of(context).pop();
          },
        ),
        suggestionsBuilder: (context, controller) {
          final query = controller.text.toLowerCase();
          final filtered =
              query.isEmpty
                  ? seriesList
                  : seriesList
                      .where((s) => s.title.toLowerCase().contains(query))
                      .toList();

          if (filtered.isEmpty) {
            return [
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    l10n.home_no_series_found,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ];
          }

          return filtered.map((series) => ListTile(
            leading: Icon(
              Icons.tag,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              series.title,
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onTap: () {
              _didJustDismissSearch = true;
              controller.closeView(series.title);
              _navigateToSeries(series);
            },
          )).toList();
        },
      ),
    );
  }

  void _showSearchSheet(
    BuildContext context,
    AppLocalizations l10n,
    List<Series> seriesList,
  ) {
    // Handled inline by SearchAnchor in the bar — no separate sheet needed.
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Returns the author name from the first plan in the series, if available.
  String? _creatorNameFor(Series series) {
    if (series.plans.isEmpty) return null;
    return series.plans.first.authorName;
  }

  /// Computes rough series progress from enrolled plan data.
  _SeriesProgress? _computeProgress(
    Series series,
    MyPlansState myPlansState,
  ) {
    if (series.plans.isEmpty || series.totalDays <= 0) return null;

    // Match series plans against user's enrolled plans.
    final seriesPlanIds = series.plans.map((p) => p.id).toSet();
    final enrolledUserPlans =
        myPlansState.plans
            .where((up) => seriesPlanIds.contains(up.id))
            .toList();

    if (enrolledUserPlans.isEmpty) return null;

    // Compute total completed days across all enrolled plans.
    int completedDays = 0;
    for (final userPlan in enrolledUserPlans) {
      final anchor = userPlan.effectiveStartDate;
      final dayNum = PlanUtils.dayNumberFor(anchor, DateTime.now(), userPlan.totalDays);
      // Days completed = current day - 1 (don't count today as "done" yet).
      completedDays += (dayNum - 1).clamp(0, userPlan.totalDays);
    }

    final percent = ((completedDays / series.totalDays) * 100).round().clamp(0, 100);

    // Find the current active plan (last enrolled plan that isn't fully done).
    String? planLabel;
    final sortedByStart =
        [...enrolledUserPlans]..sort(
          (a, b) => a.effectiveStartDate.compareTo(b.effectiveStartDate),
        );
    for (var i = 0; i < sortedByStart.length; i++) {
      final up = sortedByStart[i];
      final anchor = up.effectiveStartDate;
      final dayNum = PlanUtils.dayNumberFor(anchor, DateTime.now(), up.totalDays);
      if (dayNum <= up.totalDays) {
        planLabel = 'Plan ${i + 1} · Day $dayNum';
        break;
      }
    }

    return _SeriesProgress(percent: percent, label: planLabel);
  }
}

class _SeriesProgress {
  final int percent;
  final String? label;
  const _SeriesProgress({required this.percent, this.label});
}
