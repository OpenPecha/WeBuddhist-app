import 'package:flutter_pecha/shared/domain/entities/value_object.dart';

/// Date range value object.
///
/// Encapsulates a start and end date, ensuring validity at creation time.
class DateRange extends ValueObject {
  final DateTime start;
  final DateTime end;

  const DateRange._(this.start, this.end);

  /// Create a DateRange instance. Returns null if invalid.
  static DateRange? create(DateTime start, DateTime end) {
    if (start.isAfter(end)) return null;
    return DateRange._(start, end);
  }

  /// Create a DateRange or throw an exception.
  factory DateRange.fromDates(DateTime start, DateTime end) {
    final range = create(start, end);
    if (range == null) {
      throw ArgumentError('Start date must be before end date');
    }
    return range;
  }

  /// Create a DateRange from a start date and duration.
  factory DateRange.fromDuration(DateTime start, Duration duration) {
    final end = start.add(duration);
    return DateRange.fromDates(start, end);
  }

  /// Get the duration of this range.
  Duration get duration => end.difference(start);

  /// Check if a date falls within this range.
  bool contains(DateTime date) {
    return !date.isBefore(start) && !date.isAfter(end);
  }

  /// Check if this range overlaps with another.
  bool overlaps(DateRange other) {
    return start.isBefore(other.end) && end.isAfter(other.start);
  }

  @override
  List<Object?> get props => [start, end];

  @override
  String toString() => '$start to $end';
}
