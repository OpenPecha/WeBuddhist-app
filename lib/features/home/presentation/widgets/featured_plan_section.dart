import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/presentation/providers/featured_series_provider.dart';
import 'package:flutter_pecha/features/home/presentation/providers/routine_info_provider.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/featured_plan_section_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FeaturedPlanSection extends ConsumerWidget {
  const FeaturedPlanSection({super.key, required this.onSeriesTap});

  final ValueChanged<Series> onSeriesTap;

  static const _horizontalPadding = 16.0;
  static const _imageBorderRadius = 16.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuredAsync = ref.watch(featuredSeriesFutureProvider);

    return featuredAsync.when(
      data: (layoutEither) {
        return layoutEither.fold((_) => const SizedBox.shrink(), (layout) {
          if (layout == null) return const SizedBox.shrink();
          return _FeaturedPlanContent(layout: layout, onSeriesTap: onSeriesTap);
        });
      },
      loading: () => const FeaturedPlanSectionSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _FeaturedPlanContent extends ConsumerWidget {
  const _FeaturedPlanContent({required this.layout, required this.onSeriesTap});

  final FeaturedSeriesLayout layout;
  final ValueChanged<Series> onSeriesTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = ref.watch(localeProvider);
    final titleFontSize = locale.languageCode == 'bo' ? 16.0 : 16.0;
    final subtitleFontSize = locale.languageCode == 'bo' ? 12.0 : 13.0;
    final sectionTitleSize = locale.languageCode == 'bo' ? 20.0 : 18.0;
    final colorScheme = Theme.of(context).colorScheme;
    final hasStatsCard = ref
        .watch(routineInfoFutureProvider)
        .maybeWhen(
          data:
              (infoEither) => infoEither.fold(
                (_) => false,
                (info) => info.seriesCount > 0 || info.recitationCount > 0,
              ),
          orElse: () => false,
        );
    final allSeries = [layout.featured, ...layout.others];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FeaturedPlanSection._horizontalPadding,
        0,
        FeaturedPlanSection._horizontalPadding,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.creator_featured_plan,
            strutStyle: context.tibetanStrutStyle(sectionTitleSize),
            style: TextStyle(
              fontSize: sectionTitleSize,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          if (hasStatsCard)
            ...allSeries.map(
              (series) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _FeaturedPlanListItem(
                  series: series,
                  titleFontSize: titleFontSize,
                  subtitleFontSize: subtitleFontSize,
                  onTap: () => onSeriesTap(series),
                ),
              ),
            )
          else ...[
            _FeaturedPlanHeroCard(
              series: layout.featured,
              titleFontSize: titleFontSize,
              subtitleFontSize: subtitleFontSize,
              onTap: () => onSeriesTap(layout.featured),
            ),
            if (layout.others.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...layout.others.map(
                (series) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FeaturedPlanListItem(
                    series: series,
                    titleFontSize: titleFontSize,
                    subtitleFontSize: subtitleFontSize,
                    onTap: () => onSeriesTap(series),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _FeaturedPlanHeroCard extends StatelessWidget {
  const _FeaturedPlanHeroCard({
    required this.series,
    required this.titleFontSize,
    required this.subtitleFontSize,
    required this.onTap,
  });

  final Series series;
  final double titleFontSize;
  final double subtitleFontSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      borderRadius: BorderRadius.circular(
        FeaturedPlanSection._imageBorderRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ResponsiveCoverImage(
                image: series.coverImage,
                fallbackAsset: 'assets/images/tag_cover/cover_image.jpg',
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    series.title,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (series.subTitle != null &&
                      series.subTitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      series.subTitle!,
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _FeaturedPlanStatsRow(
                    planCount: series.planCount,
                    enrolledCount: series.enrolledCount,
                    fontSize: subtitleFontSize,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedPlanStatsRow extends StatelessWidget {
  const _FeaturedPlanStatsRow({
    required this.planCount,
    required this.enrolledCount,
    required this.fontSize,
  });

  final int planCount;
  final int enrolledCount;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: colorScheme.onSurfaceVariant,
      height: 1.2,
    );

    return Row(
      children: [
        _FeaturedPlanStatItem(
          icon: AppAssets.featuredSeriesPlanCount,
          value: planCount,
          style: statStyle,
        ),
        const SizedBox(width: 16),
        _FeaturedPlanStatItem(
          icon: AppAssets.featuredSeriesEnrolledCount,
          value: enrolledCount,
          style: statStyle,
        ),
      ],
    );
  }
}

class _FeaturedPlanStatItem extends StatelessWidget {
  const _FeaturedPlanStatItem({
    required this.icon,
    required this.value,
    required this.style,
  });

  final IconData icon;
  final int value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: style.color),
        const SizedBox(width: 6),
        Text('$value', style: style),
      ],
    );
  }
}

class _FeaturedPlanListItem extends StatelessWidget {
  const _FeaturedPlanListItem({
    required this.series,
    required this.titleFontSize,
    required this.subtitleFontSize,
    required this.onTap,
  });

  final Series series;
  final double titleFontSize;
  final double subtitleFontSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      borderRadius: BorderRadius.circular(
        FeaturedPlanSection._imageBorderRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: ResponsiveCoverImage(
                    image: series.coverImage,
                    fallbackAsset: 'assets/images/tag_cover/cover_image.jpg',
                    fit: BoxFit.cover,
                    width: 72,
                    height: 72,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.title,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (series.subTitle != null &&
                        series.subTitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        series.subTitle!,
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    _FeaturedPlanStatsRow(
                      planCount: series.planCount,
                      enrolledCount: series.enrolledCount,
                      fontSize: subtitleFontSize,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
