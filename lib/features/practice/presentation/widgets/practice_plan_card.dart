import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:intl/intl.dart';

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
                height: 140,
                width: width,
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
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
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
