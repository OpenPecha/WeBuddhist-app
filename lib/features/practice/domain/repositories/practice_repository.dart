import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/practice/domain/entities/practice_progress.dart';
import 'package:flutter_pecha/features/practice/domain/entities/practice_session.dart';
import 'package:flutter_pecha/features/practice/domain/entities/routine.dart';
import 'package:flutter_pecha/shared/domain/base_classes/repository.dart';

/// Practice repository interface.
abstract class PracticeRepository extends Repository {
  /// Get all routines for the current user.
  Future<Either<Failure, List<Routine>>> getRoutines();

  /// Get a specific routine by ID.
  Future<Either<Failure, Routine?>> getRoutine(String id);

  /// Create a new routine.
  Future<Either<Failure, Routine>> createRoutine(Routine routine);

  /// Update an existing routine.
  Future<Either<Failure, Routine>> updateRoutine(Routine routine);

  /// Delete a routine.
  Future<Either<Failure, void>> deleteRoutine(String id);

  /// Get practice progress for the current user.
  Future<Either<Failure, PracticeProgress>> getPracticeProgress();

  /// Start a practice session.
  Future<Either<Failure, PracticeSession>> startSession(String routineId);

  /// Complete a practice session.
  Future<Either<Failure, void>> completeSession(String sessionId);

  /// Skip a scheduled practice session.
  Future<Either<Failure, void>> skipSession(String routineId);

  /// Get practice history for a date range.
  Future<Either<Failure, List<PracticeSession>>> getSessionsHistory(DateTime start, DateTime end);
}
