import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/practice/domain/entities/practice_progress.dart';
import 'package:flutter_pecha/features/practice/domain/repositories/practice_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

/// Get practice progress use case.
class GetPracticeProgressUseCase extends UseCase<PracticeProgress, NoParams> {
  final PracticeRepository _repository;

  GetPracticeProgressUseCase(this._repository);

  @override
  Future<Either<Failure, PracticeProgress>> call(NoParams params) async {
    return await _repository.getPracticeProgress();
  }
}
