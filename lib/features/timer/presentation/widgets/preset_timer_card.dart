import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';

class PresetTimerCard extends StatelessWidget {
  const PresetTimerCard({
    super.key,
    required this.timer,
    required this.minLabel,
    this.onTap,
  });

  final PresetTimer timer;
  final String minLabel;
  final VoidCallback? onTap;

  static const _borderRadius = 16.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.surfaceDark : AppColors.surfaceWhite;
    final borderColor =
        isDark ? AppColors.cardBorderDark : const Color(0xFFE4E4E4);
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Material(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${timer.displayMinutes}',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  minLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
