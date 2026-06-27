import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

class GetSeriesByIdUseCase extends UseCase<Series, GetSeriesByIdParams> {
  final Future<Either<Failure, Series>> Function(
    String id, {
    required String language,
  })
  _getSeriesById;

  GetSeriesByIdUseCase(this._getSeriesById);

  @override
  Future<Either<Failure, Series>> call(GetSeriesByIdParams params) async {
    return _getSeriesById(params.id, language: params.language);
  }
}

class GetSeriesByIdParams {
  final String id;
  final String language;

  const GetSeriesByIdParams({required this.id, required this.language});
}
