import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/calendar/data/datasource/calendar_remote_datasource.dart';
import 'package:flutter_pecha/features/calendar/domain/entities/tibetan_calendar_day.dart';
import 'package:flutter_pecha/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:fpdart/fpdart.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  final CalendarRemoteDatasource _datasource;

  CalendarRepositoryImpl({required CalendarRemoteDatasource datasource})
    : _datasource = datasource;

  @override
  Future<Either<Failure, List<TibetanCalendarDay>>> getMonth(
    int year,
    int month,
  ) async {
    try {
      final model = await _datasource.fetchMonth(year, month);
      return Right(model.toEntities());
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Calendar'));
    }
  }

  @override
  Future<Either<Failure, TibetanCalendarDay>> getToday() async {
    try {
      final model = await _datasource.fetchToday();
      return Right(model.toEntity());
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'Calendar'));
    }
  }
}
