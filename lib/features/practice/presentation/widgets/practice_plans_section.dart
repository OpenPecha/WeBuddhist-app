import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_explore_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_section_container.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_section_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class PracticePlansSection extends ConsumerWidget {
  const PracticePlansSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final seriesAsync = ref.watch(practiceExploreFeaturedSeriesProvider);

    return seriesAsync.when(
      data:
          (either) => either.fold((_) => const SizedBox.shrink(), (seriesList) {
            if (seriesList.isEmpty) return const SizedBox.shrink();
            return PracticeSectionContainer(
              title: l10n.home_shortcut_plans,
              child: SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: seriesList.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final series = seriesList[index];
                    return _PlanCard(
                      series: series,
                      onTap: () => _navigateToSeries(context, series),
                    );
                  },
                ),
              ),
            );
          }),
      loading: () => const PracticeSectionSkeleton(height: 200),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _navigateToSeries(BuildContext context, Series series) {
    context.pushNamed(
      'home-series-detail',
      pathParameters: {'id': series.id},
      extra: {'series': series},
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.series, required this.onTap});

  final Series series;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateRange = _formatSeriesDateRange(series);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? AppColors.cardBackgroundDark
                  : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: SizedBox(
                height: 140,
                width: 300,
                child: ResponsiveCoverImage(
                  image: series.coverImage,
                  fallbackAsset: 'assets/images/tag_cover/cover_image.jpg',
                  fit: BoxFit.cover,
                  width: 220,
                  height: 140,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                series.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (dateRange != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  dateRange,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String? _formatSeriesDateRange(Series series) {
    final startDate = series.startDate;
    final endDate = series.endDate;
    if (startDate == null || endDate == null) return null;
    final formatter = DateFormat('d MMM');
    return '${formatter.format(startDate.toLocal())} – ${formatter.format(endDate.toLocal())}';
  }
}
