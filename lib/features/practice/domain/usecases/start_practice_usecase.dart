import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/practice/domain/entities/practice_session.dart';
import 'package:flutter_pecha/features/practice/domain/repositories/practice_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

/// Start practice session use case.
class StartPracticeUseCase extends UseCase<PracticeSession, StartPracticeParams> {
  final PracticeRepository _repository;

  StartPracticeUseCase(this._repository);

  @override
  Future<Either<Failure, PracticeSession>> call(StartPracticeParams params) async {
    if (params.routineId.isEmpty) {
      return const Left(ValidationFailure('Routine ID cannot be empty'));
    }
    return await _repository.startSession(params.routineId);
  }
}

class StartPracticeParams {
  final String routineId;

  const StartPracticeParams({required this.routineId});
}
