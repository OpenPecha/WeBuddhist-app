import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/calendar/presentation/calendar_l10n_utils.dart';
import 'package:flutter_pecha/features/calendar/presentation/providers/tibetan_calendar_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Month navigation header: ‹ / › chevrons around the Gregorian month/year and
/// a Tibetan lunar-month subtitle. Drives [focusedCalendarMonthProvider].
class CalendarMonthNav extends ConsumerWidget {
  const CalendarMonthNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final focusedMonth = ref.watch(focusedCalendarMonthProvider);

    final monthTitle = DateFormat.yMMMM(
      dateFormatLocale(context),
    ).format(focusedMonth);
    final today = dateOnly(DateTime.now());
    final isCurrentMonth =
        today.year == focusedMonth.year && today.month == focusedMonth.month;
    final sampleDate =
        isCurrentMonth
            ? today
            : DateTime(focusedMonth.year, focusedMonth.month + 1, 0);
    final lunarMonth = ref.watch(resolvedDayProvider(sampleDate)).lunarMonth;
    final lunarSubtitle = lunarMonthLabel(context, l10n, lunarMonth);

    void shift(int months) {
      ref.read(focusedCalendarMonthProvider.notifier).state = DateTime(
        focusedMonth.year,
        focusedMonth.month + months,
        1,
      );
    }

    return Row(
      children: [
        _NavChevron(icon: Icons.chevron_left, onTap: () => shift(-1)),
        Expanded(
          child: Column(
            children: [
              Text(
                monthTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                lunarSubtitle,
                textAlign: TextAlign.center,
                strutStyle: context.tibetanStrutStyle(
                  theme.textTheme.bodySmall?.fontSize ?? 12,
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        _NavChevron(icon: Icons.chevron_right, onTap: () => shift(1)),
      ],
    );
  }
}

class _NavChevron extends StatelessWidget {
  const _NavChevron({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
            ),
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.onSurface),
        ),
      ),
    );
  }
}
