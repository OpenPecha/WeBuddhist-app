import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

class EnrollInSeriesUseCase extends UseCase<Unit, EnrollInSeriesParams> {
  final Future<Either<Failure, Unit>> Function(
    String seriesId, {
    String? groupId,
    bool autoEnrollNext,
    bool startImmediately,
  })
  _enrollInSeries;

  EnrollInSeriesUseCase(this._enrollInSeries);

  @override
  Future<Either<Failure, Unit>> call(EnrollInSeriesParams params) async {
    if (params.seriesId.isEmpty) {
      return const Left(ValidationFailure('Series ID cannot be empty'));
    }
    return _enrollInSeries(
      params.seriesId,
      groupId: params.groupId,
      autoEnrollNext: params.autoEnrollNext,
      startImmediately: params.startImmediately,
    );
  }
}

class EnrollInSeriesParams {
  final String seriesId;
  final String? groupId;
  final bool autoEnrollNext;
  final bool startImmediately;

  const EnrollInSeriesParams({
    required this.seriesId,
    this.groupId,
    this.autoEnrollNext = false,
    this.startImmediately = false,
  });
}
