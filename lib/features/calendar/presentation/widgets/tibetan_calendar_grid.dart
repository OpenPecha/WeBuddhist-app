import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/calendar/presentation/providers/tibetan_calendar_providers.dart';
import 'package:flutter_pecha/features/calendar/presentation/widgets/calendar_day_cell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

/// The month grid. Renders each day with its Gregorian + Tibetan lunar day via
/// [CalendarDayCell], drives selection and month navigation through the
/// calendar providers, and reads resolved days from [resolvedMonthDaysProvider]
/// (backend-primary, engine fallback) so cells don't re-convert on every
/// rebuild.
class TibetanCalendarGrid extends ConsumerWidget {
  const TibetanCalendarGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final focusedMonth = ref.watch(focusedCalendarMonthProvider);
    final selectedDay = ref.watch(selectedCalendarDayProvider);
    final lunarDays = ref.watch(resolvedMonthDaysProvider(focusedMonth));

    // Dates within the focused month that carry an event (for the dot marker).
    final eventDays =
        ref
            .watch(monthEventsProvider(focusedMonth))
            .map((e) => dateOnly(e.date))
            .toSet();

    int? lunarFor(DateTime day) => lunarDays[dateOnly(day)]?.lunarDay;
    bool hasEvent(DateTime day) => eventDays.contains(dateOnly(day));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: TableCalendar<void>(
        firstDay: DateTime.utc(1900, 1, 1),
        lastDay: DateTime.utc(2100, 12, 31),
        focusedDay: focusedMonth,
        currentDay: dateOnly(DateTime.now()),
        headerVisible: false,
        startingDayOfWeek: StartingDayOfWeek.monday,
        availableGestures: AvailableGestures.horizontalSwipe,
        rowHeight: 58,
        daysOfWeekHeight: 28,
        locale: Localizations.localeOf(context).toString(),
        selectedDayPredicate: (day) => isSameDay(day, selectedDay),
        // TODO: Uncomment this when we have a way to select a day.
        // onDaySelected: (selected, focused) {
        //   ref.read(selectedCalendarDayProvider.notifier).state = dateOnly(
        //     selected,
        //   );
        //   final month = DateTime(focused.year, focused.month, 1);
        //   if (month != focusedMonth) {
        //     ref.read(focusedCalendarMonthProvider.notifier).state = month;
        //   }
        // },
        onPageChanged: (focused) {
          ref.read(focusedCalendarMonthProvider.notifier).state = DateTime(
            focused.year,
            focused.month,
            1,
          );
        },
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: theme.textTheme.labelSmall!.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            letterSpacing: 0.5,
          ),
          weekendStyle: theme.textTheme.labelSmall!.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            letterSpacing: 0.5,
          ),
        ),
        calendarBuilders: CalendarBuilders<void>(
          dowBuilder: (context, day) {
            // Uppercase short weekday name (MON, TUE, …), localized via intl.
            final locale = Localizations.localeOf(context).toString();
            final label = DateFormat.E(locale).format(day).toUpperCase();
            return Center(
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  letterSpacing: 0.5,
                ),
              ),
            );
          },
          defaultBuilder:
              (context, day, focused) => CalendarDayCell(
                gregorianDay: day.day,
                lunarDay: lunarFor(day),
                hasEvent: hasEvent(day),
              ),
          todayBuilder:
              (context, day, focused) => CalendarDayCell(
                gregorianDay: day.day,
                lunarDay: lunarFor(day),
                isToday: true,
                hasEvent: hasEvent(day),
              ),
          selectedBuilder:
              (context, day, focused) => CalendarDayCell(
                gregorianDay: day.day,
                lunarDay: lunarFor(day),
                isSelected: true,
                isToday: isSameDay(day, dateOnly(DateTime.now())),
                hasEvent: hasEvent(day),
              ),
          outsideBuilder:
              (context, day, focused) => CalendarDayCell(
                gregorianDay: day.day,
                lunarDay: lunarFor(day),
                isOutside: true,
              ),
        ),
      ),
    );
  }
}
