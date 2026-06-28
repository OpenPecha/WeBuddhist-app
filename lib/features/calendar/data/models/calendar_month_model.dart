import 'package:flutter_pecha/features/calendar/data/models/calendar_day_model.dart';
import 'package:flutter_pecha/features/calendar/domain/entities/tibetan_calendar_day.dart';

/// Parses a month from `GET /calendar/{year}/{month}`, where [year]/[month] are
/// the *Gregorian* year and month; each day carries its Tibetan lunar data.
class CalendarMonthModel {
  final int year;
  final int month;
  final String? designation;
  final List<CalendarDayModel> days;

  const CalendarMonthModel({
    required this.year,
    required this.month,
    required this.designation,
    required this.days,
  });

  factory CalendarMonthModel.fromJson(Map<String, dynamic> json) {
    final rawDays = (json['days'] as List<dynamic>?) ?? const [];
    return CalendarMonthModel(
      year: (json['year'] as num?)?.toInt() ?? 0,
      month: (json['month'] as num?)?.toInt() ?? 0,
      designation: json['designation'] as String?,
      days: rawDays
          .map((d) => CalendarDayModel.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }

  List<TibetanCalendarDay> toEntities() =>
      days.map((d) => d.toEntity()).toList();
}
