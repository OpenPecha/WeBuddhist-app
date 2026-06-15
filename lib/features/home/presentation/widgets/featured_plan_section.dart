import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/presentation/providers/featured_series_provider.dart';
import 'package:flutter_pecha/features/home/presentation/providers/routine_info_provider.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/featured_plan_section_skeleton.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
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
    final isTibetan = context.isTibetanLocale;
    final sectionTitleSize = isTibetan ? 16.0 : 18.0;
    final titleFontSize = isTibetan ? 14.0 : 16.0;
    final subtitleFontSize = isTibetan ? 12.0 : 13.0;
    final sectionContentGap = isTibetan ? 16.0 : 12.0;
    final itemBottomGap = isTibetan ? 16.0 : 12.0;
    final heroOthersGap = isTibetan ? 20.0 : 16.0;
    final contentPadding = isTibetan ? 16.0 : 12.0;
    final titleSubtitleGap = isTibetan ? 8.0 : 4.0;
    final statsTopGap = isTibetan ? 12.0 : 8.0;
    final imageTextGap = isTibetan ? 16.0 : 12.0;
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
          SizedBox(height: sectionContentGap),
          if (hasStatsCard)
            ...allSeries.map(
              (series) => Padding(
                padding: EdgeInsets.only(bottom: itemBottomGap),
                child: _FeaturedPlanListItem(
                  series: series,
                  titleFontSize: titleFontSize,
                  subtitleFontSize: subtitleFontSize,
                  contentPadding: contentPadding,
                  titleSubtitleGap: titleSubtitleGap,
                  statsTopGap: statsTopGap,
                  imageTextGap: imageTextGap,
                  onTap: () => onSeriesTap(series),
                ),
              ),
            )
          else ...[
            _FeaturedPlanHeroCard(
              series: layout.featured,
              titleFontSize: titleFontSize,
              subtitleFontSize: subtitleFontSize,
              contentPadding: contentPadding,
              titleSubtitleGap: titleSubtitleGap,
              statsTopGap: statsTopGap,
              onTap: () => onSeriesTap(layout.featured),
            ),
            if (layout.others.isNotEmpty) ...[
              SizedBox(height: heroOthersGap),
              ...layout.others.map(
                (series) => Padding(
                  padding: EdgeInsets.only(bottom: itemBottomGap),
                  child: _FeaturedPlanListItem(
                    series: series,
                    titleFontSize: titleFontSize,
                    subtitleFontSize: subtitleFontSize,
                    contentPadding: contentPadding,
                    titleSubtitleGap: titleSubtitleGap,
                    statsTopGap: statsTopGap,
                    imageTextGap: imageTextGap,
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
    required this.contentPadding,
    required this.titleSubtitleGap,
    required this.statsTopGap,
    required this.onTap,
  });

  final Series series;
  final double titleFontSize;
  final double subtitleFontSize;
  final double contentPadding;
  final double titleSubtitleGap;
  final double statsTopGap;
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
              padding: EdgeInsets.fromLTRB(
                contentPadding,
                contentPadding,
                contentPadding,
                contentPadding + 4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    series.title,
                    strutStyle: context.tibetanStrutStyle(titleFontSize),
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
                    SizedBox(height: titleSubtitleGap),
                    Text(
                      series.subTitle!,
                      strutStyle: context.tibetanStrutStyle(subtitleFontSize),
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
                  SizedBox(height: statsTopGap),
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
        Text(
          '$value',
          style: style.copyWith(
            fontFamily: getSystemFontFamily(AppConfig.englishLanguageCode),
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _FeaturedPlanListItem extends StatelessWidget {
  const _FeaturedPlanListItem({
    required this.series,
    required this.titleFontSize,
    required this.subtitleFontSize,
    required this.contentPadding,
    required this.titleSubtitleGap,
    required this.statsTopGap,
    required this.imageTextGap,
    required this.onTap,
  });

  final Series series;
  final double titleFontSize;
  final double subtitleFontSize;
  final double contentPadding;
  final double titleSubtitleGap;
  final double statsTopGap;
  final double imageTextGap;
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
          padding: EdgeInsets.all(contentPadding),
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
              SizedBox(width: imageTextGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.title,
                      strutStyle: context.tibetanStrutStyle(titleFontSize),
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
                      SizedBox(height: titleSubtitleGap),
                      Text(
                        series.subTitle!,
                        strutStyle: context.tibetanStrutStyle(subtitleFontSize),
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
                    SizedBox(height: statsTopGap),
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
