import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

class GetSeriesListUseCase extends UseCase<List<Series>, GetSeriesListParams> {
  final Future<Either<Failure, List<Series>>> Function({required String language}) _getSeriesList;

  GetSeriesListUseCase(this._getSeriesList);

  @override
  Future<Either<Failure, List<Series>>> call(GetSeriesListParams params) async {
    return _getSeriesList(language: params.language);
  }
}

class GetSeriesListParams {
  final String language;

  const GetSeriesListParams({required this.language});
}
