import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
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
  static const _contentPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );
  static const _labelSpacing = 8.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.surfaceDark : AppColors.surfaceWhite;
    final borderColor =
        isDark ? AppColors.cardBorderDark : const Color(0xFFE4E4E4);
    final textColor = Theme.of(context).colorScheme.onSurface;
    final isTibetan = AppFontConfig.isTibetanLanguage(
      Localizations.localeOf(context).languageCode,
    );

    final minuteText = Text(
      '${timer.displayMinutes}',
      style: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w600,
        height: isTibetan ? AppFontConfig.tibetanCompactLineHeight : null,
        leadingDistribution:
            isTibetan ? AppFontConfig.tibetanLeadingDistribution : null,
        color: textColor,
      ),
    );

    final minLabelText = Text(
      minLabel,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: isTibetan ? AppFontConfig.tibetanCompactLineHeight : 1.2,
        leadingDistribution:
            isTibetan ? AppFontConfig.tibetanLeadingDistribution : null,
        color: textColor,
      ),
    );

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
            child: Padding(
              padding: _contentPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                    isTibetan
                        ? [
                          minLabelText,
                          const SizedBox(height: _labelSpacing),
                          minuteText,
                        ]
                        : [
                          minuteText,
                          const SizedBox(height: _labelSpacing),
                          minLabelText,
                        ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
