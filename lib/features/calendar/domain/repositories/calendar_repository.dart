import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/calendar/domain/entities/tibetan_calendar_day.dart';
import 'package:fpdart/fpdart.dart';

/// Backend source of authoritative Tibetan calendar data.
abstract class CalendarRepository {
  /// All days of the Gregorian [month] (1–12) of [year], each carrying its
  /// Tibetan lunar data. Omitted lunar days are included with a null
  /// `gregorianDate`.
  Future<Either<Failure, List<TibetanCalendarDay>>> getMonth(
    int year,
    int month,
  );

  /// Today's Tibetan calendar day (`GET /calendar/today`).
  Future<Either<Failure, TibetanCalendarDay>> getToday();
}
