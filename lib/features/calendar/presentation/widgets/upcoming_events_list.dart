import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/calendar/domain/models/calendar_event.dart';
import 'package:flutter_pecha/features/calendar/presentation/calendar_l10n_utils.dart';
import 'package:flutter_pecha/features/calendar/presentation/providers/tibetan_calendar_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// "Upcoming events" section: the events that fall within the displayed month.
class UpcomingEventsList extends ConsumerWidget {
  const UpcomingEventsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final focusedMonth = ref.watch(focusedCalendarMonthProvider);
    final events = ref.watch(monthEventsProvider(focusedMonth));
    if (events.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.calendar_upcoming_events,
          strutStyle: context.tibetanStrutStyle(
            theme.textTheme.titleMedium?.fontSize ?? 16,
          ),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        for (final event in events) ...[
          _EventCard(event: event),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final weekday = DateFormat.E(locale).format(event.date).toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Gregorian date block.
          _StackedLabel(
            value: '${event.date.day}',
            label: weekday,
            theme: theme,
          ),
          Container(
            width: 1,
            height: 34,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: theme.colorScheme.outline,
          ),
          // Title.
          Expanded(
            child: Text(
              eventTitle(l10n, event),
              strutStyle: context.tibetanStrutStyle(
                theme.textTheme.bodyLarge?.fontSize ?? 16,
              ),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Lunar day block.
          _StackedLabel(
            value: '${event.lunarDay}',
            label: l10n.calendar_day_short,
            theme: theme,
            alignEnd: true,
          ),
        ],
      ),
    );
  }
}

/// A big value with a small muted caption beneath — used for both the Gregorian
/// (date / weekday) and lunar (day / "DAY") blocks of an event card.
class _StackedLabel extends StatelessWidget {
  const _StackedLabel({
    required this.value,
    required this.label,
    required this.theme,
    this.alignEnd = false,
  });

  final String value;
  final String label;
  final ThemeData theme;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
