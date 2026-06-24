import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:intl/intl.dart';

/// Horizontal list-row card for a practice plan: a small rounded thumbnail on
/// the left with the title and date range on the right.
class PracticePlanListTile extends StatelessWidget {
  const PracticePlanListTile({
    super.key,
    required this.series,
    required this.onTap,
  });

  final Series series;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateRange = _formatSeriesDateRange(series);

    return Material(
      color: isDark ? AppColors.cardBackgroundDark : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 56,
                  width: 56,
                  child: ResponsiveCoverImage(
                    image: series.coverImage,
                    fallbackAsset: 'assets/images/tag_cover/cover_image.jpg',
                    fit: BoxFit.cover,
                    width: 56,
                    height: 56,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      series.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (dateRange != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        dateRange,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String? _formatSeriesDateRange(Series series) {
    final startDate = series.startDate;
    final endDate = series.endDate;
    if (startDate == null || endDate == null) return null;
    final formatter = DateFormat('MMM d');
    return '${formatter.format(startDate.toLocal())} - ${formatter.format(endDate.toLocal())}';
  }
}
