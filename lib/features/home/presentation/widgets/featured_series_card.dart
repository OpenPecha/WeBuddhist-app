import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';

class FeaturedSeriesCard extends StatelessWidget {
  const FeaturedSeriesCard({
    super.key,
    required this.series,
    required this.onTap,
    this.creatorName,
  });

  final Series series;
  final VoidCallback onTap;
  final String? creatorName;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surfaceContainer,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImageWidget(
                imageUrl: series.imageUrl,
                fallbackAsset: 'assets/images/tag_cover/cover_image.jpg',
                fit: BoxFit.cover,
                placeholder: _buildPlaceholder(context),
                errorWidget: _buildPlaceholder(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    series.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle(BuildContext context) {
    final l10n = context.l10n;
    final parts = <String>[];
    if (creatorName != null && creatorName!.isNotEmpty) {
      parts.add(creatorName!);
    }
    if (series.plans.isNotEmpty) {
      parts.add(l10n.home_series_n_plans(series.plans.length));
    }
    if (series.totalDays > 0) {
      parts.add(l10n.home_series_n_days(series.totalDays));
    }
    return parts.join(' · ');
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
