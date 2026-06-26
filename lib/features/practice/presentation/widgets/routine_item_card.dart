import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class RoutineItemCard extends StatelessWidget {
  final String title;
  final ResponsiveImage? coverImage;
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final int? reorderIndex;
  final RoutineItemType? type;

  /// Optional widget rendered below the title (e.g. a date-range label).
  final Widget? subtitle;

  /// Optional plan title shown below [title] when no custom [subtitle] is set.
  final String? planTitle;

  /// Optional widget rendered on the right of the subtitle row (e.g. a
  /// status indicator). Only visible when [subtitle] is also provided.
  final Widget? trailing;

  /// Optional callback for the circular plan navigation button on the right.
  final VoidCallback? onPlanTap;

  const RoutineItemCard({
    super.key,
    required this.title,
    this.coverImage,
    this.imageUrl,
    this.onTap,
    this.onDelete,
    this.reorderIndex,
    this.type,
    this.subtitle,
    this.planTitle,
    this.trailing,
    this.onPlanTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedPlanTitle =
        planTitle != null && planTitle!.isNotEmpty ? planTitle : null;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            if (onDelete != null) ...[
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? AppColors.surfaceVariantDark
                            : AppColors.grey100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    AppAssets.minus,
                    size: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 20),
            ],
            if (type == RoutineItemType.recitation)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  AppAssets.recitationCoverDefault,
                  width: 74,
                  height: 74,
                  fit: BoxFit.cover,
                ),
              )
            else if (type == RoutineItemType.timer)
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceVariantDark
                      : AppColors.grey100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  PhosphorIconsRegular.timer,
                  size: 32,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textSecondary,
                ),
              )
            else if (type == RoutineItemType.accumulator)
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceVariantDark
                      : AppColors.grey100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIconsRegular.circlesThree,
                  size: 32,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textSecondary,
                ),
              )
            else
              ResponsiveCoverImage(
                image:
                    coverImage ??
                    (imageUrl != null && imageUrl!.isNotEmpty
                        ? ResponsiveImage.uniform(imageUrl!)
                        : null),
                width: 74,
                height: 74,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(10),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (resolvedPlanTitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      resolvedPlanTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color:
                            isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: subtitle!),
                        if (trailing != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: trailing!,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (onPlanTap != null) ...[
              const SizedBox(width: 12),
              _PlanNavigationButton(onTap: onPlanTap!, isDark: isDark),
            ],
            if (reorderIndex != null) ...[
              const SizedBox(width: 8),
              ReorderableDragStartListener(
                index: reorderIndex!,
                child: GestureDetector(
                  onTapDown: (_) => HapticFeedback.heavyImpact(),
                  child: Icon(
                    AppAssets.list,
                    size: 22,
                    color:
                        isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanNavigationButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;

  const _PlanNavigationButton({required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            width: 1,
          ),
        ),
        child: Icon(
          AppAssets.caretRight,
          size: 16,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
      ),
    );
  }
}
