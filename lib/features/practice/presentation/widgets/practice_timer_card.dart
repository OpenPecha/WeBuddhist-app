import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';

class PracticeTimerCard extends StatelessWidget {
  const PracticeTimerCard({
    super.key,
    required this.timer,
    required this.minLabel,
    required this.onTap,
  });

  final PresetTimer timer;
  final String minLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? const Color(0xFF353535) : const Color(0xFFE4E4E4);
    final isTibetan = Localizations.localeOf(context).languageCode == 'bo';
    final textColor = Theme.of(context).colorScheme.onSurface;

    final minuteText = Text(
      '${timer.displayMinutes}',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 2,
        color: textColor,
      ),
    );

    final minLabelText = Text(
      minLabel,
      style: TextStyle(fontSize: 14, color: textColor),
    );

    return Material(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                isTibetan
                    ? [minLabelText, const SizedBox(height: 2), minuteText]
                    : [minuteText, const SizedBox(height: 2), minLabelText],
          ),
        ),
      ),
    );
  }
}
