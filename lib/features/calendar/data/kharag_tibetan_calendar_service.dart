import 'package:flutter_pecha/features/calendar/domain/tibetan_calendar_service.dart';
import 'package:tibetan_calendar/tibetan_calendar.dart' as tc;

/// [TibetanCalendarService] backed by the `tibetan_calendar` package
/// (publisher: kharagedition.com), which implements the Phugpa astronomical
/// system.
///
/// Deliberately uses the package's *modern* generator API
/// (`getDayFromWestern`, `getYearFromTibetan`, `getLosarForYear`) rather than
/// the deprecated `TibetanCalendar.getTibetanDate` / `getYearAttributes`
/// statics — only the modern `Day`/`Month` types expose the leap-month and
/// doubled/skipped-day flags this app needs.
class KharagTibetanCalendarService implements TibetanCalendarService {
  const KharagTibetanCalendarService();

  @override
  TibetanDay fromWestern(DateTime date) {
    // Normalise to a date-only value so a time component can't nudge the
    // conversion across a day boundary.
    final day = tc.getDayFromWestern(DateTime(date.year, date.month, date.day));
    return TibetanDay(
      year: day.year,
      month: day.month.month,
      day: day.day,
      isLeapMonth: day.month.isLeapMonth,
      isDoubledMonth: day.month.isDoubledMonth,
      isLeapDay: day.isLeapDay,
      isDoubledDay: day.isDoubledDay,
      isSkippedDay: day.skippedDay,
      isPreviousDaySkipped: day.isPreviousSkipped,
      westernDate: DateTime(
        day.westernDate.year,
        day.westernDate.month,
        day.westernDate.day,
      ),
    );
  }

  @override
  TibetanYearInfo yearInfo(int tibetanYear) {
    final year = tc.getYearFromTibetan(tibetanYear);
    // animal/element/gender are nullable on the package's Year, but
    // getYearFromTibetan always routes through yearAttributes() which fills
    // them; guard anyway so a future package change surfaces loudly here
    // rather than as a confusing null somewhere in the UI.
    return TibetanYearInfo(
      year: year.tibYear,
      animal: year.animal ?? '',
      element: year.element ?? '',
      gender: year.gender ?? '',
      rabjungCycle: year.rabjungCycle,
      rabjungYear: year.rabjungYear,
    );
  }

  @override
  DateTime losarForTibetanYear(int tibetanYear) {
    // The package returns Losar as a "YYYY-MM-DD" Gregorian string.
    final iso = tc.getLosarForYear(tibetanYear, isTibetan: true);
    final parsed = DateTime.parse(iso);
    return DateTime(parsed.year, parsed.month, parsed.day);
  }
}
