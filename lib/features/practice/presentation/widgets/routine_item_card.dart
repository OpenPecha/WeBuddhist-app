import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class RoutineItemCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final VoidCallback? onDelete;
  final int? reorderIndex;

  const RoutineItemCard({
    super.key,
    required this.title,
    this.imageUrl,
    this.onDelete,
    this.reorderIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          if (onDelete != null) ...[
            GestureDetector(
              onTap: onDelete,
              child: Icon(PhosphorIconsRegular.minusCircle, size: 22),
            ),
            const SizedBox(width: 10),
          ],
          CachedNetworkImageWidget(
            imageUrl: imageUrl ?? '',
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (reorderIndex != null) ...[
            const SizedBox(width: 8),
            ReorderableDragStartListener(
              index: reorderIndex!,
              child: GestureDetector(
                onTapDown: (_) => HapticFeedback.heavyImpact(),
                child: Icon(
                  PhosphorIconsRegular.list,
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
    );
  }
}
