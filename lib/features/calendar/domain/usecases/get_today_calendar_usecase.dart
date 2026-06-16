import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/calendar/domain/entities/tibetan_calendar_day.dart';
import 'package:flutter_pecha/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:fpdart/fpdart.dart';

/// Fetches today's Tibetan calendar day from the backend.
class GetTodayCalendarUseCase extends UseCase<TibetanCalendarDay, NoParams> {
  final CalendarRepository _repository;

  GetTodayCalendarUseCase(this._repository);

  @override
  Future<Either<Failure, TibetanCalendarDay>> call(NoParams params) {
    return _repository.getToday();
  }
}
