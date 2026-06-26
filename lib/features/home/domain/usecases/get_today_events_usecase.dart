import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/domain/entities/today_event.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

class GetTodayEventsUseCase
    extends UseCase<List<TodayEvent>, GetTodayEventsParams> {
  final Future<Either<Failure, List<TodayEvent>>> Function({
    required String language,
  })
  _getTodayEvents;

  GetTodayEventsUseCase(this._getTodayEvents);

  @override
  Future<Either<Failure, List<TodayEvent>>> call(
    GetTodayEventsParams params,
  ) async {
    return _getTodayEvents(language: params.language);
  }
}

class GetTodayEventsParams {
  final String language;

  const GetTodayEventsParams({required this.language});
}
