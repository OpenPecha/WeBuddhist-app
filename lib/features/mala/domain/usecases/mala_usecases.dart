import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mala_count.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/domain/repositories/mala_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

/// Loads the preset catalogue (mantras joined with content).
class GetCatalogueUseCase extends UseCase<List<Mantra>, NoParams> {
  GetCatalogueUseCase(this._repository);
  final MalaRepository _repository;

  @override
  Future<Either<Failure, List<Mantra>>> call(NoParams params) =>
      _repository.getCatalogue();
}

/// Loads all of the current user's accumulator totals (for seeding).
class GetUserTotalsUseCase extends UseCase<List<MalaCount>, NoParams> {
  GetUserTotalsUseCase(this._repository);
  final MalaRepository _repository;

  @override
  Future<Either<Failure, List<MalaCount>>> call(NoParams params) =>
      _repository.getUserTotals();
}

class CreateUserAccumulatorParams {
  const CreateUserAccumulatorParams({
    required this.name,
    this.mantraId,
    required this.currentCount,
  });
  final String name;
  final String? mantraId;
  final int currentCount;
}

/// Lazily creates the user's accumulator for a preset on first sync.
class CreateUserAccumulatorUseCase
    extends UseCase<MalaCount, CreateUserAccumulatorParams> {
  CreateUserAccumulatorUseCase(this._repository);
  final MalaRepository _repository;

  @override
  Future<Either<Failure, MalaCount>> call(
    CreateUserAccumulatorParams params,
  ) =>
      _repository.createUserAccumulator(
        name: params.name,
        mantraId: params.mantraId,
        currentCount: params.currentCount,
      );
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
  Future<Either<Failure, MalaCount>> call(
    UpdateUserAccumulatorParams params,
  ) =>
      _repository.updateUserAccumulator(
        accumulatorId: params.accumulatorId,
        currentCount: params.currentCount,
      );
}
