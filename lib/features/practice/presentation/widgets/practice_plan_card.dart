import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/series_plan_card_widgets.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_date_format.dart';

class PracticePlanCard extends StatelessWidget {
  const PracticePlanCard({
    super.key,
    required this.series,
    required this.onTap,
    this.width = 300,
  });

  final Series series;
  final VoidCallback onTap;
  final double width;

  static const _metaFontSize = 12.0;
  static const _titleFontSize = 14.0;

  @override
  Widget build(BuildContext context) {
    final dateRange = _formatSeriesDateRange(series);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
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
                height: 150,
                width: width,
                child: ResponsiveCoverImage(
                  image: series.coverImage,
                  fallbackAsset: 'assets/images/tag_cover/cover_image.jpg',
                  fit: BoxFit.cover,
                  width: 200,
                  height: 120,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 6.0,
              ),
              child: Text(
                series.title,
                style: const TextStyle(
                  fontSize: _titleFontSize,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (series.partner != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SeriesPlanPartnerRow(
                        partner: series.partner!,
                        fontSize: _metaFontSize,
                        avatarSize: 28,
                      ),
                    ),
                    if (series.enrolledCount > 0) ...[
                      const SizedBox(width: 8),
                      SeriesPlanEnrolledCount(
                        count: series.enrolledCount,
                        fontSize: _metaFontSize,
                      ),
                    ],
                  ],
                ),
              )
            else if (dateRange != null || series.enrolledCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: SeriesPlanMetaRow(
                  series: series,
                  fontSize: _metaFontSize,
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String? _formatSeriesDateRange(Series series) {
    return PlanDateFormat.formatRangeOrNull(series.startDate, series.endDate);
  }
}
