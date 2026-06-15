import 'package:flutter_pecha/features/calendar/domain/tibetan_calendar_service.dart';

/// A resolved calendar day for display — produced either from the backend
/// (`/calendar/...`) or, when offline/unavailable, from the local
/// [TibetanCalendarService]. The UI depends only on this entity, so the two
/// sources are interchangeable.
class TibetanCalendarDay {
  /// Gregorian date this lunar day maps to. Null only for an *omitted* lunar
  /// day (the backend returns `gregorian_date: null` for skipped days); such
  /// days never appear in the Gregorian grid.
  final DateTime? gregorianDate;

  /// Lunar day, 1–30.
  final int lunarDay;

  /// Lunar month, 1–12.
  final int lunarMonth;

  /// Localized/elemental year name, e.g. "Fire Male Horse". May be empty if
  /// unavailable.
  final String yearDesignation;

  /// Elemental month name, e.g. "Iron Male Dragon". May be empty (the offline
  /// engine does not currently provide a month designation).
  final String monthDesignation;

  /// True when this is an omitted (skipped) lunar day — has no Gregorian date.
  final bool isOmitted;

  const TibetanCalendarDay({
    required this.gregorianDate,
    required this.lunarDay,
    required this.lunarMonth,
    this.yearDesignation = '',
    this.monthDesignation = '',
    this.isOmitted = false,
  });

  /// Builds a day from the local engine for [date]. Used as the offline
  /// fallback and as the instant value before backend data arrives.
  factory TibetanCalendarDay.fromEngine(
    DateTime date,
    TibetanCalendarService service,
  ) {
    final tib = service.fromWestern(date);
    final year = service.yearInfo(tib.year);
    return TibetanCalendarDay(
      gregorianDate: DateTime(date.year, date.month, date.day),
      lunarDay: tib.day,
      lunarMonth: tib.month,
      // Engine exposes the year's element/gender/animal; format to match the
      // backend's "Element Gender Animal" designation style.
      yearDesignation: '${year.element} ${year.gender} ${year.animal}'.trim(),
      isOmitted: tib.isSkippedDay,
    );
  }

  @override
  String toString() =>
      'TibetanCalendarDay($gregorianDate, lunar $lunarMonth/$lunarDay, '
      '$yearDesignation${isOmitted ? ', omitted' : ''})';
}
