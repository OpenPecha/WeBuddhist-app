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
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_provider.dart';
import 'package:flutter_pecha/features/home/presentation/home_screen_constants.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/series_card.dart';
import 'package:flutter_pecha/features/notifications/application/notification_sync_engine.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_utils.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
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

  // For proper keyboard dismissal with SearchAnchor
  final FocusScopeNode _searchFocusScopeNode = FocusScopeNode();
  bool _didJustDismissSearch = false;

  @override
  void initState() {
    super.initState();
    // Request notification permissions when home screen loads
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

    // Capture the root ProviderContainer BEFORE any await. The OS permission
    // dialog backgrounds the app and may dispose this State by the time we
    // resume — `ref` becomes unusable but the container lives for the whole
    // app, so post-permission scheduling still fires either way.
    final container = ProviderScope.containerOf(context, listen: false);

    final notificationService = container.read(notificationServiceProvider);
    if (notificationService == null) {
      _log.warning(
        '[HOME-SCREEN] NotificationService not initialized, skipping permission request',
      );
      if (mounted) _navigateToPendingPlanIfNeeded();
      return;
    }

    try {
      // Check if permissions are already granted
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

    // Permission flow has run — fire any pending special-plan Day 1
    // notifications now (e.g. user just enrolled in ITCC during onboarding
    // after 09:00). Without permission, `_plugin.show()` silently no-ops, so
    // this MUST run after the permission request above.
    await _firePendingSpecialPlanDay1IfNeeded(container);

    if (!mounted) return;

    // After the permission flow (dialog shown or already granted), check
    // whether onboarding left a plan waiting to be opened in Practice.
    _navigateToPendingPlanIfNeeded();
  }

  Future<void> _firePendingSpecialPlanDay1IfNeeded(
    ProviderContainer container,
  ) async {
    // Use [container], NOT `this.ref` — see the comment in the caller.
    // Invalidate first — the provider may have been evaluated pre-login
    // (no auth header) and cached a Forbidden failure. We need a fresh read.
    _log.info('invalidating userPlansFutureProvider for fresh fetch');
    container.invalidate(userPlansFutureProvider);

    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      _log.info('fetch attempt $attempt/$maxAttempts');
      try {
        final userPlansAsync =
            await container.read(userPlansFutureProvider.future);
        final isFailure = userPlansAsync.isLeft();
        _log.info('attempt $attempt resolved isFailure=$isFailure');
        if (isFailure && attempt < maxAttempts) {
          _log.warning(
            'attempt $attempt failed — invalidating and retrying: '
            '${userPlansAsync.fold((f) => f, (_) => "")}',
          );
          container.invalidate(userPlansFutureProvider);
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
              'on attempt=$attempt — triggering engine sync (appLaunch)',
            );
            // Permission may have just been granted; trigger a sync so
            // catch-up immediates fire now that `plugin.show()` works.
            await container
                .read(notificationSyncEngineProvider)
                .sync(trigger: SyncTrigger.appLaunch);
          },
        );
        break;
      } catch (e, st) {
        _log.warning('attempt $attempt threw: $e\n$st');
        if (attempt < maxAttempts) {
          container.invalidate(userPlansFutureProvider);
          await Future.delayed(const Duration(milliseconds: 400));
        }
      }
    }
    _log.info('_firePendingSpecialPlanDay1IfNeeded EXIT');
  }

  /// Consumes [pendingOnboardingPlanProvider] and navigates to the Practice
  /// tab + plan detail screen. Called once, right after notification setup.
  void _navigateToPendingPlanIfNeeded() {
    if (!mounted) return;
    final plan = ref.read(pendingOnboardingPlanProvider);
    if (plan == null) return;

    // Clear immediately so back-navigation never re-triggers this.
    ref.read(pendingOnboardingPlanProvider.notifier).state = null;

    // Push plan details FIRST while HomeScreen is still mounted.
    // Switching the tab index BEFORE the push would unmount HomeScreen,
    // making the subsequent context.push a no-op.
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

    // Switch bottom-nav to Practice so popping back from plan details
    // lands on the Practice tab rather than Home.
    ref.read(mainNavigationIndexProvider.notifier).state =
        MainTab.practice.index;
  }

  /// Pull-to-refresh handler. Invalidates the series list and awaits the
  /// refreshed result so the RefreshIndicator spinner stays until data lands.
  Future<void> _onRefresh() async {
    ref.invalidate(seriesListFutureProvider);
    await ref.read(seriesListFutureProvider.future);
  }

  /// Manual refetch/retry method that can be called from UI.
  /// Reuses the same logic as pull-to-refresh for consistent behavior.
  void _refetchSeries() {
    _onRefresh();
  }

  void _navigateToSeries(Series series) {
    context.pushNamed(
      'home-series-detail',
      pathParameters: {'id': series.id},
      extra: {'series': series},
    );
  }

  @override
  Widget build(BuildContext context) {
    final seriesAsync = ref.watch(seriesListFutureProvider);
    final l10n = context.l10n;

    // Check for app updates (only show once per app session)
    final updateAvailable = ref.watch(updateAvailableProvider);
    final bannerAlreadyShown = ref.watch(updateBannerShownProvider);

    updateAvailable.whenData((isAvailable) {
      if (isAvailable && !bannerAlreadyShown && !_showUpdateBanner) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _showUpdateBanner = true);
            // Mark as shown so it won't appear again this session
            ref.read(updateBannerShownProvider.notifier).state = true;
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          l10n.nav_home,
          strutStyle: context.tibetanStrutStyle(
            Theme.of(context).textTheme.headlineMedium?.fontSize ?? 28,
          ),
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildSearchSection(l10n, seriesAsync),
                SizedBox(height: HomeScreenConstants.bodyVerticalPadding),
                _buildBody(context, l10n),
              ],
            ),
            if (_showUpdateBanner)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: UpdateBanner(
                  onUpdateTap: () {
                    ref.read(openAppStoreProvider)();
                  },
                  onDismissed: () {
                    if (mounted) {
                      setState(() => _showUpdateBanner = false);
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  TextStyle _searchHintTextStyle(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: 16,
      color: isDarkMode ? AppColors.textTertiaryDark : AppColors.textSecondary,
    );
  }

  Widget _buildSearchSection(
    AppLocalizations localizations,
    AsyncValue<Either<Failure, List<Series>>> seriesAsync,
  ) {
    final locale = ref.watch(localeProvider);
    final lineHeight = getLineHeight(locale.languageCode);
    final fontSize = locale.languageCode == 'bo' ? 18.0 : 16.0;
    final TextStyle searchHintStyle = _searchHintTextStyle(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: seriesAsync.when(
        data: (seriesEither) {
          return seriesEither.fold(
            (failure) => const SizedBox.shrink(),
            (seriesList) => FocusScope(
              node: _searchFocusScopeNode,
              onFocusChange: (isFocused) {
                if (_didJustDismissSearch && isFocused) {
                  _didJustDismissSearch = false;
                  _searchFocusScopeNode.unfocus();
                }
              },
              child: SearchAnchor(
                builder: (BuildContext context, SearchController controller) {
                  return SearchBar(
                    controller: controller,
                    constraints: HomeScreenConstants.searchBarConstraints,
                    padding: const WidgetStatePropertyAll<EdgeInsets>(
                      EdgeInsets.symmetric(
                        horizontal:
                            HomeScreenConstants.searchBarHorizontalPadding,
                      ),
                    ),
                    elevation: const WidgetStatePropertyAll(0.0),
                    shadowColor: const WidgetStatePropertyAll(
                      Colors.transparent,
                    ),
                    onTap: () {
                      controller.openView();
                    },
                    onChanged: (_) {
                      controller.openView();
                    },
                    leading: Icon(
                      Icons.search,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    hintText: localizations.text_search,
                    hintStyle: WidgetStatePropertyAll(searchHintStyle),
                  );
                },
                viewLeading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    _didJustDismissSearch = true;
                    Navigator.of(context).pop();
                  },
                ),
                suggestionsBuilder: (
                  BuildContext context,
                  SearchController controller,
                ) {
                  final query = controller.text.toLowerCase();
                  final filtered =
                      query.isEmpty
                          ? seriesList
                          : seriesList
                              .where(
                                (s) => s.title.toLowerCase().contains(query),
                              )
                              .toList();

                  if (filtered.isEmpty) {
                    return [
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            localizations.home_no_series_found,
                            style: TextStyle(
                              fontSize: fontSize,
                              height: lineHeight,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ];
                  }

                  return filtered.map((series) {
                    return ListTile(
                      leading: Icon(
                        Icons.tag,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        series.title,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w500,
                          height: lineHeight,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      onTap: () {
                        _didJustDismissSearch = true;
                        controller.closeView(series.title);
                        _log.info('Series selected from search: ${series.id}');
                        _navigateToSeries(series);
                      },
                    );
                  }).toList();
                },
              ),
            ),
          );
        },
        loading:
            () => SearchBar(
              constraints: HomeScreenConstants.searchBarConstraints,
              padding: const WidgetStatePropertyAll<EdgeInsets>(
                EdgeInsets.symmetric(
                  horizontal: HomeScreenConstants.searchBarHorizontalPadding,
                ),
              ),
              enabled: false,
              elevation: const WidgetStatePropertyAll(0.0),
              leading: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              hintText: localizations.text_search,
              hintStyle: WidgetStatePropertyAll(searchHintStyle),
            ),
        error:
            (_, __) => SearchBar(
              constraints: HomeScreenConstants.searchBarConstraints,
              padding: const WidgetStatePropertyAll<EdgeInsets>(
                EdgeInsets.symmetric(
                  horizontal: HomeScreenConstants.searchBarHorizontalPadding,
                ),
              ),
              enabled: false,
              leading: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              hintText: localizations.text_search,
              hintStyle: WidgetStatePropertyAll(searchHintStyle),
            ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations localizations) {
    final seriesAsync = ref.watch(seriesListFutureProvider);
    final language = ref.watch(localeProvider).languageCode;
    final fontSize = language == 'bo' ? 22.0 : 18.0;

    return Expanded(
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: seriesAsync.when(
          data: (seriesEither) {
            return seriesEither.fold(
              (failure) => _buildScrollableMessage(
                ErrorStateWidget(error: failure, onRetry: _refetchSeries),
              ),
              (seriesList) {
                if (seriesList.isEmpty) {
                  return _buildScrollableMessage(
                    Padding(
                      padding: const EdgeInsets.all(
                        HomeScreenConstants.emptyStatePadding,
                      ),
                      child: Text(
                        localizations.no_feature_content,
                        style: TextStyle(fontSize: fontSize),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: HomeScreenConstants.bodyHorizontalPadding,
                    vertical: HomeScreenConstants.bodyVerticalPadding,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: seriesList.length,
                  itemBuilder: (context, index) {
                    final series = seriesList[index];
                    return SeriesCard(
                      series: series,
                      onTap: () {
                        _log.info('Series tapped: ${series.id}');
                        _navigateToSeries(series);
                      },
                    );
                  },
                );
              },
            );
          },
          loading: () => const TagGridSkeleton(),
          error:
              (error, stackTrace) => _buildScrollableMessage(
                ErrorStateWidget(error: error, onRetry: _refetchSeries),
              ),
        ),
      ),
    );
  }

  Widget _buildScrollableMessage(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}
