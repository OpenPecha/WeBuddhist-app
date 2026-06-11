import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/core/widgets/skeletons/skeletons.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_provider.dart';
import 'package:flutter_pecha/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/plan_list_view.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SeriesDetailScreen extends ConsumerWidget {
  final String seriesId;
  final Series? series;

  const SeriesDetailScreen({super.key, required this.seriesId, this.series});

  Future<void> _onRefresh(WidgetRef ref) async {
    ref.invalidate(seriesByIdProvider(seriesId));
    await ref.read(seriesByIdProvider(seriesId).future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
      myPlansPaginatedProvider,
    ); // pre-warm so enrolled state is ready when list items render
    final seriesAsync = ref.watch(seriesByIdProvider(seriesId));
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(
              context,
              seriesAsync.whenOrNull(
                    data: (either) => either.fold((_) => null, (s) => s.title),
                  ) ??
                  series?.title ??
                  '',
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _onRefresh(ref),
                child: seriesAsync.when(
                  data: (either) {
                    return either.fold(
                      (failure) => _buildScrollableMessage(
                        ErrorStateWidget(
                          error: failure,
                          onRetry: () => _onRefresh(ref),
                        ),
                      ),
                      (series) {
                        if (series.plans.isEmpty) {
                          return _buildScrollableMessage(
                            _buildEmptyState(context, localizations, ref),
                          );
                        }
                        return PlanListView(
                          plans: series.plans,
                          seriesId: seriesId,
                          series: series,
                        );
                      },
                    );
                  },
                  loading: () => const PlanListSkeleton(),
                  error:
                      (error, stackTrace) => _buildScrollableMessage(
                        ErrorStateWidget(
                          error: error,
                          onRetry: () => _onRefresh(ref),
                        ),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: MainNavigationBottomBar(
        onTabChanged: (_) => context.go('/home'),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(AppAssets.arrowLeft),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48, height: 48),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations localizations,
    WidgetRef ref,
  ) {
    final locale = ref.watch(localeProvider);
    final fontSize = locale.languageCode == 'bo' ? 22.0 : 18.0;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Text(
        localizations.no_feature_content,
        style: TextStyle(fontSize: fontSize),
        textAlign: TextAlign.center,
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
