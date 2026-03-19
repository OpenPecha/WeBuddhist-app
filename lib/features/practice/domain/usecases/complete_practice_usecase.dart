import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/practice/domain/entities/practice_progress.dart';
import 'package:flutter_pecha/features/practice/domain/repositories/practice_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

/// Complete practice session use case.
class CompletePracticeUseCase extends UseCase<void, CompleteSessionParams> {
  final PracticeRepository _repository;

  CompletePracticeUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(CompleteSessionParams params) async {
    if (params.sessionId.isEmpty) {
      return const Left(ValidationFailure('Session ID cannot be empty'));
    }
    return await _repository.completeSession(params.sessionId);
  }
}

class CompleteSessionParams {
  final String sessionId;

  const CompleteSessionParams({required this.sessionId});
}

/// Get practice progress use case.
class GetPracticeProgressUseCase extends UseCase<PracticeProgress, NoParams> {
  final PracticeRepository _repository;

  GetPracticeProgressUseCase(this._repository);

  @override
  Future<Either<Failure, PracticeProgress>> call(NoParams params) async {
    return await _repository.getPracticeProgress();
  }
}
