import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

class GetUserSeriesEnrollmentsUseCase
    extends UseCase<Set<String>, NoParams> {
  final Future<Either<Failure, Set<String>>> Function() _getEnrollments;

  GetUserSeriesEnrollmentsUseCase(this._getEnrollments);

  @override
  Future<Either<Failure, Set<String>>> call(NoParams params) =>
      _getEnrollments();
}
