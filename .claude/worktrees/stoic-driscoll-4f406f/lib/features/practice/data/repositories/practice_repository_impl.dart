import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/practice/data/datasource/routine_local_storage.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/data/services/routine_notification_service.dart';
import 'package:flutter_pecha/features/practice/domain/entities/practice_progress.dart';
import 'package:flutter_pecha/features/practice/domain/entities/practice_session.dart';
import 'package:flutter_pecha/features/practice/domain/entities/routine.dart';
import 'package:flutter_pecha/features/practice/domain/repositories/practice_repository.dart';

const _uuid = Uuid();

/// Practice repository implementation.
///
/// Bridges the domain layer with the data layer, handling conversion
/// between RoutineData (data model) and Routine (domain entity).
class PracticeRepositoryImpl implements PracticeRepository {
  final RoutineLocalStorage _localStorage;
  final RoutineNotificationService _notificationService;

  PracticeRepositoryImpl({
    required RoutineLocalStorage localStorage,
    required RoutineNotificationService notificationService,
  })  : _localStorage = localStorage,
        _notificationService = notificationService;

  // ========== Routine Operations ==========

  @override
  Future<Either<Failure, List<Routine>>> getRoutines() async {
    try {
      final data = await _localStorage.loadRoutine();
      final routines = data.blocks.map((block) => _blockToRoutine(block)).toList();
      return Right(routines);
    } catch (e) {
      return Left(CacheFailure('Failed to load routines: $e'));
    }
  }

  @override
  Future<Either<Failure, Routine?>> getRoutine(String id) async {
    try {
      final data = await _localStorage.loadRoutine();
      final index = data.blocks.indexWhere((b) => b.id == id);
      if (index == -1) {
        return Right(null);
      }
      return Right(_blockToRoutine(data.blocks[index]));
    } catch (e) {
      return Left(CacheFailure('Failed to load routine: $e'));
    }
  }

  @override
  Future<Either<Failure, Routine>> createRoutine(Routine routine) async {
    try {
      final data = await _localStorage.loadRoutine();
      final block = _routineToBlock(routine);

      if (data.blocks.length >= RoutineData.maxBlocks) {
        return Left(
          ValidationFailure('Maximum number of routines (${RoutineData.maxBlocks}) reached'),
        );
      }

      final newBlocks = [...data.blocks, block];
      final newData = RoutineData(blocks: newBlocks).sortedByTime;

      await _localStorage.saveRoutine(newData);
      await _notificationService.syncNotifications(newData.blocks);

      return Right(_blockToRoutine(block));
    } catch (e) {
      return Left(CacheFailure('Failed to create routine: $e'));
    }
  }

  @override
  Future<Either<Failure, Routine>> updateRoutine(Routine routine) async {
    try {
      final data = await _localStorage.loadRoutine();
      final block = _routineToBlock(routine);

      final index = data.blocks.indexWhere((b) => b.id == routine.id);
      if (index == -1) {
        return Left(NotFoundFailure('Routine not found: ${routine.id}'));
      }

      final newBlocks = List<RoutineBlock>.from(data.blocks)..[index] = block;
      final newData = RoutineData(blocks: newBlocks).sortedByTime;

      await _localStorage.saveRoutine(newData);
      await _notificationService.syncNotifications(newData.blocks);

      return Right(_blockToRoutine(block));
    } catch (e) {
      return Left(CacheFailure('Failed to update routine: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRoutine(String id) async {
    try {
      final data = await _localStorage.loadRoutine();
      final index = data.blocks.indexWhere((b) => b.id == id);

      if (index == -1) {
        return Left(NotFoundFailure('Routine not found: $id'));
      }

      final block = data.blocks[index];
      await _notificationService.cancelBlockNotification(block);

      final newBlocks = data.blocks.where((b) => b.id != id).toList();
      final newData = RoutineData(blocks: newBlocks);

      await _localStorage.saveRoutine(newData);

      return Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to delete routine: $e'));
    }
  }

  // ========== Session Operations ==========

  @override
  Future<Either<Failure, PracticeProgress>> getPracticeProgress() async {
    try {
      final data = await _localStorage.loadRoutine();
      final routines = data.blocks.map((block) => _blockToRoutine(block)).toList();

      // Calculate progress based on active routines
      final activeRoutines = routines.where((r) => r.isActive).toList();

      // Default progress - in a real implementation, this would be stored
      final progress = PracticeProgress(
        userId: 'current_user', // TODO: Get actual user ID
        weeklyGoalMinutes: {},
        currentWeekMinutes: {},
        activeRoutines: activeRoutines,
        totalSessionsThisWeek: 0,
        totalSessionsThisMonth: 0,
        lastPracticeDate: DateTime.now(),
      );

      return Right(progress);
    } catch (e) {
      return Left(CacheFailure('Failed to load progress: $e'));
    }
  }

  @override
  Future<Either<Failure, PracticeSession>> startSession(String routineId) async {
    try {
      final session = PracticeSession(
        id: _uuid.v4(),
        routineId: routineId,
        startTime: DateTime.now(),
        endTime: DateTime.now(), // Will be updated on complete
        durationMinutes: 0,
        status: SessionStatus.inProgress,
      );

      // TODO: Store session in local storage
      return Right(session);
    } catch (e) {
      return Left(CacheFailure('Failed to start session: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> completeSession(String sessionId) async {
    try {
      // TODO: Update session in local storage, calculate duration
      // TODO: Update streak count for the routine
      return Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to complete session: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> skipSession(String routineId) async {
    try {
      // TODO: Record skipped session
      return Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to skip session: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PracticeSession>>> getSessionsHistory(
    DateTime start,
    DateTime end,
  ) async {
    try {
      // TODO: Implement session history retrieval from local storage
      return Right([]);
    } catch (e) {
      return Left(CacheFailure('Failed to load session history: $e'));
    }
  }

  // ========== Conversion Helpers ==========

  /// Convert a RoutineBlock to a Routine domain entity.
  Routine _blockToRoutine(RoutineBlock block) {
    // Determine routine type based on time
    final hour = block.time.hour;
    final type = hour < 12
        ? RoutineType.morning
        : hour < 17
            ? RoutineType.afternoon
            : RoutineType.evening;

    // Create time slot from block time
    final timeSlot = TimeSlot(
      hour: block.time.hour,
      minute: block.time.minute,
      days: [], // Default to all days - could be enhanced
    );

    // Calculate duration based on number of items
    final durationMinutes = block.items.length * 15; // Default 15 min per item

    return Routine(
      id: block.id,
      name: _getRoutineName(block),
      description: '${block.items.length} ${block.items.length == 1 ? 'practice' : 'practices'}',
      durationMinutes: durationMinutes,
      type: type,
      timeSlots: [timeSlot],
      isActive: block.notificationEnabled,
      streakCount: 0, // TODO: Track streak count
    );
  }

  /// Convert a Routine domain entity to a RoutineBlock.
  RoutineBlock _routineToBlock(Routine routine) {
    // For existing blocks, we'd need to load them first to preserve items
    // This is a simplified conversion - in practice, you'd want to cache
    // the block data or include items in the entity

    return RoutineBlock(
      id: routine.id,
      time: TimeOfDay(
        hour: routine.timeSlots.isNotEmpty ? routine.timeSlots.first.hour : 8,
        minute: routine.timeSlots.isNotEmpty ? routine.timeSlots.first.minute : 0,
      ),
      notificationEnabled: routine.isActive,
      items: [], // Items would need to be preserved separately
    );
  }

  String _getRoutineName(RoutineBlock block) {
    if (block.items.isEmpty) return 'Practice';
    return block.items.first.title;
  }
}
