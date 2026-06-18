import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/calendar/domain/models/moon_phase.dart';
import 'package:flutter_pecha/features/calendar/presentation/calendar_l10n_utils.dart';
import 'package:flutter_pecha/features/calendar/presentation/providers/tibetan_calendar_providers.dart';
import 'package:flutter_pecha/features/calendar/presentation/widgets/moon_phase_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The "current lunar date" card: large "Day {n}", the lunar-month subtitle,
/// and the moon-phase icon for the selected day.
class CalendarHeaderCard extends ConsumerWidget {
  const CalendarHeaderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final selectedDay = ref.watch(selectedCalendarDayProvider);
    final day = ref.watch(resolvedDayProvider(selectedDay));
    final phase = moonPhaseForLunarDay(day.lunarDay);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.calendar_day_label} ${day.lunarDay}',
                  strutStyle: context.tibetanStrutStyle(
                    theme.textTheme.headlineSmall?.fontSize ?? 20,
                  ),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lunarMonthLabel(context, l10n, day.lunarMonth),
                  strutStyle: context.tibetanStrutStyle(
                    theme.textTheme.bodyMedium?.fontSize ?? 16,
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          MoonPhaseIcon(phase: phase, size: 52),
        ],
      ),
    );
  }
}
