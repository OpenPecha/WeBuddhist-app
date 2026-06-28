/// Domain abstraction over a Tibetan-calendar conversion engine.
///
/// The reader/calendar UI depends only on this interface and the plain models
/// below — never on the third-party `tibetan_calendar` package directly. That
/// keeps the (currently low-adoption) package quarantined behind one seam, so
/// we can swap the engine later without touching any widgets.
library;

/// A single date in the Tibetan lunisolar calendar, paired with the western
/// (Gregorian) date it maps to.
///
/// The boolean flags capture the features that make this calendar hard — and
/// that off-the-shelf Chinese/Vietnamese lunar packages get wrong: intercalary
/// (leap) months, and days that are either doubled or omitted.
class TibetanDay {
  /// Tibetan year, e.g. 2152 for the Wood-Snake year that begins in 2025.
  final int year;

  /// Lunar month, 1–12.
  final int month;

  /// Lunar day, 1–30.
  final int day;

  /// True when [month] is the intercalary (added) month of a leap year.
  final bool isLeapMonth;

  /// True when [month] is one of a doubled pair (two months share the number).
  final bool isDoubledMonth;

  /// True when this is the second occurrence of a doubled day number.
  final bool isLeapDay;

  /// True when this day number occurs twice within the month.
  final bool isDoubledDay;

  /// True when this day number is omitted (skipped) in the month.
  final bool isSkippedDay;

  /// True when the preceding day number was skipped.
  final bool isPreviousDaySkipped;

  /// The Gregorian date this Tibetan day corresponds to.
  final DateTime westernDate;

  const TibetanDay({
    required this.year,
    required this.month,
    required this.day,
    required this.isLeapMonth,
    required this.isDoubledMonth,
    required this.isLeapDay,
    required this.isDoubledDay,
    required this.isSkippedDay,
    required this.isPreviousDaySkipped,
    required this.westernDate,
  });

  @override
  String toString() =>
      'TibetanDay($year-$month-$day'
      '${isLeapMonth ? ' leapMonth' : ''}'
      '${isLeapDay ? ' leapDay' : ''}'
      '${isSkippedDay ? ' skipped' : ''} <- $westernDate)';
}

/// Calendrical attributes of a Tibetan year: its 12-animal / 5-element name
/// and its position in the 60-year Rabjung cycle.
class TibetanYearInfo {
  /// Tibetan year, e.g. 2152.
  final int year;

  /// One of the 12 animals, e.g. "Snake".
  final String animal;

  /// One of the 5 elements, e.g. "Wood" (note: the engine uses "Iron", the
  /// Tibetan convention, rather than "Metal").
  final String element;

  /// "Male" or "Female".
  final String gender;

  /// Which 60-year Rabjung cycle this year falls in (1-based).
  final int rabjungCycle;

  /// Position within the Rabjung cycle, 1–60.
  final int rabjungYear;

  const TibetanYearInfo({
    required this.year,
    required this.animal,
    required this.element,
    required this.gender,
    required this.rabjungCycle,
    required this.rabjungYear,
  });

  /// Human-readable year name, e.g. "Wood Snake".
  String get name => '$element $animal';

  @override
  String toString() => 'TibetanYearInfo($year, $name, $gender)';
}

/// Converts between the Gregorian and Tibetan calendars.
abstract class TibetanCalendarService {
  /// The Tibetan day corresponding to [date] (time component ignored).
  TibetanDay fromWestern(DateTime date);

  /// Attributes (animal, element, Rabjung position) of [tibetanYear].
  TibetanYearInfo yearInfo(int tibetanYear);

  /// The Gregorian date of Losar — the 1st day of the 1st month — for
  /// [tibetanYear]. Returned as a date-only [DateTime] (midnight local).
  DateTime losarForTibetanYear(int tibetanYear);
}
