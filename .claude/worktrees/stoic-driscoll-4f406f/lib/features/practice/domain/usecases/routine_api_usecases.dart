import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_api_models.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/domain/repositories/routine_api_repository.dart';

/// Fetches the authenticated user's routine from the API.
/// Returns [Right(null)] when no routine exists yet.
class GetUserRoutineUseCase {
  final RoutineApiRepository _repository;
  const GetUserRoutineUseCase(this._repository);

  Future<Either<Failure, RoutineData?>> call({
    int skip = 0,
    int limit = 20,
  }) =>
      _repository.getUserRoutine(skip: skip, limit: limit);
}

/// Creates a new routine with its first time block.
/// Returns the server-assigned [routineId] and [timeBlockId].
class CreateRoutineWithTimeBlockUseCase {
  final RoutineApiRepository _repository;
  const CreateRoutineWithTimeBlockUseCase(this._repository);

  Future<Either<Failure, ({String routineId, String timeBlockId})>> call(
    TimeBlockRequest request,
  ) =>
      _repository.createRoutineWithTimeBlock(request);
}

/// Adds a new time block to an existing routine.
/// Returns the server-assigned [timeBlockId] of the created block.
class CreateTimeBlockUseCase {
  final RoutineApiRepository _repository;
  const CreateTimeBlockUseCase(this._repository);

  Future<Either<Failure, String>> call(
    String routineId,
    TimeBlockRequest request,
  ) =>
      _repository.createTimeBlock(routineId, request);
}

/// Fully replaces a time block (time + all sessions).
class UpdateTimeBlockUseCase {
  final RoutineApiRepository _repository;
  const UpdateTimeBlockUseCase(this._repository);

  Future<Either<Failure, void>> call(
    String routineId,
    String timeBlockId,
    TimeBlockRequest request,
  ) =>
      _repository.updateTimeBlock(routineId, timeBlockId, request);
}

/// Soft-deletes a time block from the routine.
class DeleteTimeBlockUseCase {
  final RoutineApiRepository _repository;
  const DeleteTimeBlockUseCase(this._repository);

  Future<Either<Failure, void>> call(
    String routineId,
    String timeBlockId,
  ) =>
      _repository.deleteTimeBlock(routineId, timeBlockId);
}
