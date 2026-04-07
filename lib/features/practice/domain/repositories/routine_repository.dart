import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_api_models.dart';

abstract class RoutineRepository {
  /// Fetches the authenticated user's routine.
  ///
  /// Returns null if the user has no routine yet.
  Future<Either<Failure, RoutineResponse?>> getUserRoutine({
    int skip,
    int limit,
  });

  /// Creates a new routine with the first time block.
  Future<Either<Failure, RoutineWithTimeBlocksResponse>> createRoutineWithTimeBlock(
    CreateTimeBlockRequest request,
  );

  /// Creates a new time block in an existing routine.
  Future<Either<Failure, TimeBlockDTO>> createTimeBlock(
    String routineId,
    CreateTimeBlockRequest request,
  );

  /// Updates a time block (full replacement of sessions).
  Future<Either<Failure, TimeBlockDTO>> updateTimeBlock(
    String routineId,
    String timeBlockId,
    UpdateTimeBlockRequest request,
  );

  /// Deletes a time block (soft delete).
  Future<Either<Failure, void>> deleteTimeBlock(
    String routineId,
    String timeBlockId,
  );
}
