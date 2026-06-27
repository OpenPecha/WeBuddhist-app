import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mala_count.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/domain/repositories/mala_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

/// Loads the preset catalogue. The parameter is the language code used to
/// localize the embedded mantra content (null = server default).
class GetCatalogueUseCase extends UseCase<List<Mantra>, String?> {
  GetCatalogueUseCase(this._repository);
  final MalaRepository _repository;

  @override
  Future<Either<Failure, List<Mantra>>> call(String? language) =>
      _repository.getCatalogue(language: language);
}

/// Seeds the user's count for one preset (`GET /accumulators/{parent_id}`).
class GetAccumulatorDetailUseCase extends UseCase<MalaCount, String> {
  GetAccumulatorDetailUseCase(this._repository);
  final MalaRepository _repository;

  @override
  Future<Either<Failure, MalaCount>> call(String parentId) =>
      _repository.getAccumulatorDetail(parentId);
}

/// Lazily creates the user's accumulator for a preset on first sync
/// (`POST /accumulators/user`).
class CreateUserAccumulatorUseCase extends UseCase<MalaCount, String> {
  CreateUserAccumulatorUseCase(this._repository);
  final MalaRepository _repository;

  @override
  Future<Either<Failure, MalaCount>> call(String parentId) =>
      _repository.createUserAccumulator(parentId);
}

class UpdateUserAccumulatorParams {
  const UpdateUserAccumulatorParams({
    required this.accumulatorId,
    required this.currentCount,
  });
  final String accumulatorId;
  final int currentCount;
}

/// Pushes the absolute lifetime total to an existing user accumulator.
class UpdateUserAccumulatorUseCase
    extends UseCase<MalaCount, UpdateUserAccumulatorParams> {
  UpdateUserAccumulatorUseCase(this._repository);
  final MalaRepository _repository;

  @override
  Future<Either<Failure, MalaCount>> call(UpdateUserAccumulatorParams params) =>
      _repository.updateUserAccumulator(
        accumulatorId: params.accumulatorId,
        currentCount: params.currentCount,
      );
}

/// Soft-deletes a user accumulator (`DELETE /accumulators/user/{id}`).
class DeleteUserAccumulatorUseCase extends UseCase<Unit, String> {
  DeleteUserAccumulatorUseCase(this._repository);
  final MalaRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String accumulatorId) =>
      _repository.deleteUserAccumulator(accumulatorId);
}
