import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/more/domain/entities/series_day_completed.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

class GetSeriesDayCompletedParams extends Equatable {
  final String language;
  final int skip;
  final int limit;

  const GetSeriesDayCompletedParams({
    required this.language,
    this.skip = 0,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [language, skip, limit];
}

class GetSeriesDayCompletedUseCase
    extends UseCase<SeriesDayCompletedPage, GetSeriesDayCompletedParams> {
  final Future<Either<Failure, SeriesDayCompletedPage>> Function(
    GetSeriesDayCompletedParams params,
  )
  _getSeriesDayCompleted;

  GetSeriesDayCompletedUseCase(this._getSeriesDayCompleted);

  @override
  Future<Either<Failure, SeriesDayCompletedPage>> call(
    GetSeriesDayCompletedParams params,
  ) {
    return _getSeriesDayCompleted(params);
  }
}
