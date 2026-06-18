import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/core.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/calendar/domain/models/calendar_event.dart';
import 'package:flutter_pecha/features/calendar/presentation/calendar_l10n_utils.dart';
import 'package:flutter_pecha/features/calendar/presentation/providers/tibetan_calendar_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Number of events shown before the user taps "Show more".
const int _kCollapsedEventCount = 2;

/// "Upcoming events" section: the events that fall within the displayed month.
///
/// Shows [_kCollapsedEventCount] events by default with a "Show more" toggle
/// that expands to the full list (and "Show less" to collapse again). The
/// toggle only appears when there are more events than the collapsed count.
class UpcomingEventsList extends ConsumerStatefulWidget {
  const UpcomingEventsList({super.key});

  @override
  ConsumerState<UpcomingEventsList> createState() => _UpcomingEventsListState();
}

class _UpcomingEventsListState extends ConsumerState<UpcomingEventsList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final focusedMonth = ref.watch(focusedCalendarMonthProvider);
    final events = ref.watch(monthEventsProvider(focusedMonth));
    if (events.isEmpty) return const SizedBox.shrink();

    final canToggle = events.length > _kCollapsedEventCount;
    final visible =
        (_expanded || !canToggle)
            ? events
            : events.take(_kCollapsedEventCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.calendar_upcoming_events,
          strutStyle: context.tibetanStrutStyle(
            theme.textTheme.titleMedium?.fontSize ?? 16,
          ),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        // Animate the height as events are revealed/hidden.
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final event in visible) ...[
                _EventCard(event: event),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        if (canToggle)
          _ShowMoreButton(
            expanded: _expanded,
            onTap: () => setState(() => _expanded = !_expanded),
          ),
      ],
    );
  }
}

/// Full-width outlined pill that toggles between "Show more ⌄" and
/// "Show less ⌃".
class _ShowMoreButton extends StatelessWidget {
  const _ShowMoreButton({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  expanded ? l10n.show_less : l10n.show_more,
                  strutStyle: context.tibetanStrutStyle(
                    theme.textTheme.bodyMedium?.fontSize ?? 14,
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  expanded ? AppAssets.caretUp : AppAssets.caretDown,
                  size: 20,
                  color: theme.colorScheme.onSurface,
                ),
              ],
            ),
          ),
        ),
      ),
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
    final weekday =
        DateFormat.E(
          dateFormatLocale(context),
        ).format(event.date).toUpperCase();

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
            height: 38,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: const Color(0xFF9E9E9E).withValues(alpha: 0.3),
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
          Container(
            width: 1,
            height: 38,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: const Color(0xFF9E9E9E).withValues(alpha: 0.3),
          ),
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
