import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/more/domain/entities/series_day_completed.dart';
import 'package:flutter_pecha/features/more/presentation/providers/series_day_completed_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PracticeDaysSheet extends ConsumerWidget {
  const PracticeDaysSheet({super.key, required this.fallbackTotalDays});

  final int fallbackTotalDays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asyncData = ref.watch(seriesDayCompletedProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : AppColors.goldLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            asyncData.when(
              data: (either) {
                final page = either.fold(
                  (_) => SeriesDayCompletedPage.empty,
                  (page) => page,
                );

                return Flexible(
                  child: _PracticeDaysSheetContent(
                    totalDays: fallbackTotalDays,
                    series: page.series,
                    hasError: either.isLeft(),
                  ),
                );
              },
              loading:
                  () => Flexible(
                    child: _PracticeDaysSheetContent(
                      totalDays: fallbackTotalDays,
                      series: const [],
                      isLoading: true,
                    ),
                  ),
              error:
                  (_, __) => Flexible(
                    child: _PracticeDaysSheetContent(
                      totalDays: fallbackTotalDays,
                      series: const [],
                      hasError: true,
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PracticeDaysSheetContent extends StatelessWidget {
  const _PracticeDaysSheetContent({
    required this.totalDays,
    required this.series,
    this.isLoading = false,
    this.hasError = false,
  });

  final int totalDays;
  final List<SeriesDayCompleted> series;
  final bool isLoading;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  AppAssets.homeList,
                  size: 22,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.me_days_plan_practiced_suffix,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  l10n.me_streak_days_count(totalDays),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, thickness: 1, color: dividerColor),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(),
            )
          else if (series.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Text(
                hasError ? l10n.something_went_wrong : l10n.no_plans_found,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.grey300 : AppColors.grey600,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: series.length,
                separatorBuilder:
                    (_, __) => Divider(
                      height: 1,
                      thickness: 1,
                      indent: 20,
                      endIndent: 20,
                      color: dividerColor,
                    ),
                itemBuilder: (context, index) {
                  final item = series[index];
                  return _SeriesDayCompletedRow(item: item);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SeriesDayCompletedRow extends StatelessWidget {
  const _SeriesDayCompletedRow({required this.item});

  final SeriesDayCompleted item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImageWidget(
              imageUrl: item.imageUrl,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              fallbackAsset: 'assets/images/tag_cover/cover_image.jpg',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.seriesTitle,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            l10n.me_streak_days_count(item.daysCompleted),
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

void showPracticeDaysSheet(BuildContext context, {required int totalDays}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (_) => PracticeDaysSheet(fallbackTotalDays: totalDays),
  );
}
