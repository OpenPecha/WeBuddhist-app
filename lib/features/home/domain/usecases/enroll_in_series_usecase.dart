import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

class EnrollInSeriesUseCase extends UseCase<Unit, EnrollInSeriesParams> {
  final Future<Either<Failure, Unit>> Function(String seriesId) _enrollInSeries;

  EnrollInSeriesUseCase(this._enrollInSeries);

  @override
  Future<Either<Failure, Unit>> call(EnrollInSeriesParams params) async {
    if (params.seriesId.isEmpty) {
      return const Left(ValidationFailure('Series ID cannot be empty'));
    }
    return _enrollInSeries(params.seriesId);
  }
}

class EnrollInSeriesParams {
  final String seriesId;

  const EnrollInSeriesParams({required this.seriesId});
}
