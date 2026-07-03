import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';

class PracticeChantListTile extends StatelessWidget {
  const PracticeChantListTile({
    super.key,
    required this.recitation,
    this.onTap,
    this.showTrailingCaret = true,
    this.includeOuterPadding = true,
  });

  final RecitationModel recitation;
  final VoidCallback? onTap;
  final bool showTrailingCaret;
  final bool includeOuterPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = theme.colorScheme.onSurfaceVariant;
    final firstSegmentContent =
        normalizeSegmentText(recitation.firstSegment?.content).trim();
    final hasFirstSegment = firstSegmentContent.isNotEmpty;
    final hasTibetanSegment = _containsTibetan(firstSegmentContent);
    final firstSegmentLanguage =
        hasTibetanSegment ? AppConfig.tibetanLanguageCode : recitation.language;
    final firstSegmentStyle = getContentTextStyle(
      firstSegmentLanguage,
      theme.textTheme.bodySmall?.copyWith(
        color: isDark ? AppColors.textSubtleDark : AppColors.grey900,
        fontSize: hasTibetanSegment ? 15 : 13,
        height: hasTibetanSegment ? 1.55 : 1.35,
      ),
    );

    final tile = Material(
      color: isDark ? AppColors.cardBackgroundDark : Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : AppColors.grey800,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        recitation.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasFirstSegment) ...[
                        const SizedBox(height: 4),
                        Text(
                          firstSegmentContent,
                          style: firstSegmentStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (showTrailingCaret) ...[
                  const SizedBox(width: 8),
                  Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withAlpha(100),
                          width: 1,
                        ),
                      ),
                      child: Icon(AppAssets.caretRight, size: 16, color: color),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (!includeOuterPadding) {
      return tile;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: tile,
    );
  }

  bool _containsTibetan(String value) {
    return RegExp(r'[\u0F00-\u0FFF]').hasMatch(value);
  }
}
