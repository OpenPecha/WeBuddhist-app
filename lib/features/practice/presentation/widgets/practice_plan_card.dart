import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (dateRange != null || series.enrolledCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: _PracticePlanMetaRow(
                  dateRange: dateRange,
                  enrolledCount: series.enrolledCount,
                  fontSize: 12,
                  secondaryColor:
                      Theme.of(context).colorScheme.onSurfaceVariant,
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

class _PracticePlanMetaRow extends StatelessWidget {
  const _PracticePlanMetaRow({
    required this.dateRange,
    required this.enrolledCount,
    required this.fontSize,
    required this.secondaryColor,
  });

  final String? dateRange;
  final int enrolledCount;
  final double fontSize;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(fontSize: fontSize, color: secondaryColor);

    return Row(
      children: [
        if (dateRange != null)
          Expanded(
            child: Text(
              dateRange!,
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (enrolledCount > 0) ...[
          Icon(AppAssets.usercard, size: fontSize + 2, color: secondaryColor),
          const SizedBox(width: 4),
          Text('$enrolledCount', style: textStyle),
        ],
      ],
    );
  }
}
