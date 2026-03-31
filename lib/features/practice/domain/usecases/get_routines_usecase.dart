import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/practice/domain/entities/routine.dart';
import 'package:flutter_pecha/features/practice/domain/repositories/practice_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

/// Get routines use case.
class GetRoutinesUseCase extends UseCase<List<Routine>, NoParams> {
  final PracticeRepository _repository;

  GetRoutinesUseCase(this._repository);

  @override
  Future<Either<Failure, List<Routine>>> call(NoParams params) async {
    return await _repository.getRoutines();
  }
}
