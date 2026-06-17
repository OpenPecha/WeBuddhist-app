import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/calendar/domain/entities/tibetan_calendar_day.dart';
import 'package:flutter_pecha/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:fpdart/fpdart.dart';

/// Fetches one lunar month of authoritative calendar data from the backend.
class GetCalendarMonthUseCase
    extends UseCase<List<TibetanCalendarDay>, GetCalendarMonthParams> {
  final CalendarRepository _repository;

  GetCalendarMonthUseCase(this._repository);

  @override
  Future<Either<Failure, List<TibetanCalendarDay>>> call(
    GetCalendarMonthParams params,
  ) {
    return _repository.getMonth(params.year, params.month);
  }
}

class GetCalendarMonthParams {
  /// Gregorian year.
  final int year;

  /// Gregorian month, 1–12.
  final int month;

  const GetCalendarMonthParams({required this.year, required this.month});
}
