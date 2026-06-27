import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

class GetFeaturedSeriesUseCase
    extends UseCase<List<Series>, GetFeaturedSeriesParams> {
  final Future<Either<Failure, List<Series>>> Function({
    required String language,
    int limit,
  })
  _getFeaturedSeries;

  GetFeaturedSeriesUseCase(this._getFeaturedSeries);

  @override
  Future<Either<Failure, List<Series>>> call(
    GetFeaturedSeriesParams params,
  ) async {
    return _getFeaturedSeries(language: params.language, limit: params.limit);
  }
}

class GetFeaturedSeriesParams {
  final String language;
  final int limit;

  const GetFeaturedSeriesParams({required this.language, this.limit = 10});
}
