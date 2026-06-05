import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';

/// Card shown in the "Continue today" section of the Home screen for an
/// enrolled series. Shows the series image, title, creator/duration metadata,
/// and overall progress.
class ContinueTodayCard extends StatelessWidget {
  const ContinueTodayCard({
    super.key,
    required this.series,
    required this.onTap,
    this.creatorName,
    this.progressPercent,
    this.currentPlanLabel,
  });

  final Series series;
  final VoidCallback onTap;
  final String? creatorName;

  /// 0–100 overall series progress (null = unknown / loading).
  final int? progressPercent;

  /// Short label like "Plan 2 · Day 3" shown near the progress chip.
  final String? currentPlanLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;
    final cardColor =
        isDark ? AppColors.surfaceDark : AppColors.cardBackgroundLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: cardColor,
          border: isDark
              ? Border.all(color: AppColors.cardBorderDark, width: 1)
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: CachedNetworkImageWidget(
                imageUrl: series.imageUrl,
                fallbackAsset: 'assets/images/tag_cover/cover_image.jpg',
                fit: BoxFit.cover,
                placeholder: _buildPlaceholder(context),
                errorWidget: _buildPlaceholder(context),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentPlanLabel != null) ...[
                      Text(
                        currentPlanLabel!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      series.title,
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _buildSubtitle(context),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildProgressRow(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow(BuildContext context) {
    final l10n = context.l10n;
    final pct = progressPercent;

    if (pct == null) {
      return Text(
        l10n.home_series_in_progress,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l10n.home_series_progress(pct),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct / 100.0,
            minHeight: 4,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  String _buildSubtitle(BuildContext context) {
    final l10n = context.l10n;
    final parts = <String>[];
    if (creatorName != null && creatorName!.isNotEmpty) {
      parts.add(creatorName!);
    }
    if (series.totalDays > 0) {
      parts.add(l10n.home_series_n_days(series.totalDays));
    }
    return parts.join(' · ');
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 28,
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
