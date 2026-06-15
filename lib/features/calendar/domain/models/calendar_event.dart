import 'package:flutter_pecha/features/calendar/domain/models/moon_phase.dart';

/// Where a [CalendarEvent] came from.
enum CalendarEventKind {
  /// Computed offline from the lunar day (new/quarter/full moons).
  lunarPhase,

  /// Supplied by the backend (festivals, observances, custom dates).
  custom,
}

/// A single dated entry shown in the calendar's events list and as a grid
/// marker. [title] is already localized/display-ready.
class CalendarEvent {
  /// Gregorian date (date-only, midnight local) the event falls on.
  final DateTime date;

  /// Tibetan lunar day (1–30) of [date].
  final int lunarDay;

  /// Display title, e.g. "Full moon" or "Saga Dawa".
  final String title;

  final CalendarEventKind kind;

  /// Set for [CalendarEventKind.lunarPhase] events; null for custom ones.
  final MoonPhase? phase;

  const CalendarEvent({
    required this.date,
    required this.lunarDay,
    required this.title,
    required this.kind,
    this.phase,
  });

  @override
  String toString() => 'CalendarEvent($date, day $lunarDay, $title, $kind)';
}
