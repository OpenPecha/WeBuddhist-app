import 'package:flutter_pecha/features/calendar/domain/entities/tibetan_calendar_day.dart';

/// Parses a single day from the calendar API and maps it to the domain
/// [TibetanCalendarDay].
class CalendarDayModel {
  final String? gregorianDate;
  final int lunarDay;
  final int lunarMonth;
  final String? monthDesignation;
  final String? yearDesignation;

  const CalendarDayModel({
    required this.gregorianDate,
    required this.lunarDay,
    required this.lunarMonth,
    this.monthDesignation,
    this.yearDesignation,
  });

  factory CalendarDayModel.fromJson(Map<String, dynamic> json) {
    final lunarMonth = json['lunar_month'] as Map<String, dynamic>?;
    final newYear = json['new_year'] as Map<String, dynamic>?;
    return CalendarDayModel(
      gregorianDate: json['gregorian_date'] as String?,
      lunarDay: (json['lunar_day'] as num).toInt(),
      lunarMonth: ((lunarMonth?['month']) as num?)?.toInt() ?? 0,
      monthDesignation: lunarMonth?['designation'] as String?,
      yearDesignation: newYear?['designation'] as String?,
    );
  }

  TibetanCalendarDay toEntity() {
    final raw = gregorianDate;
    final date = (raw == null || raw.isEmpty) ? null : DateTime.tryParse(raw);
    return TibetanCalendarDay(
      gregorianDate:
          date == null ? null : DateTime(date.year, date.month, date.day),
      lunarDay: lunarDay,
      lunarMonth: lunarMonth,
      yearDesignation: formatDesignation(yearDesignation),
      monthDesignation: formatDesignation(monthDesignation),
      isOmitted: date == null,
    );
  }
}

/// Converts the API's hyphenated designation ("Fire-male-Horse") into a
/// space-separated, title-cased label ("Fire Male Horse"). Returns '' for null.
String formatDesignation(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '';
  return raw
      .split('-')
      .map((w) => w.trim())
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}
