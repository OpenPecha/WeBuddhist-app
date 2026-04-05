import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/practice/data/datasource/routine_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_api_models.dart';

class RoutineRepository {
  final RoutineRemoteDatasource _remoteDatasource;
  final _logger = AppLogger('RoutineRepository');

  RoutineRepository({required RoutineRemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  Future<RoutineResponse?> getUserRoutine({
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      return await _remoteDatasource.getUserRoutine(
        skip: skip,
        limit: limit,
      );
    } catch (e) {
      _logger.error('Failed to fetch routine', e);
      rethrow;
    }
  }

  Future<RoutineWithTimeBlocksResponse> createRoutineWithTimeBlock(
    CreateTimeBlockRequest request,
  ) async {
    try {
      return await _remoteDatasource.createRoutineWithTimeBlock(request);
    } catch (e) {
      _logger.error('Failed to create routine', e);
      rethrow;
    }
  }

  Future<TimeBlockDTO> createTimeBlock(
    String routineId,
    CreateTimeBlockRequest request,
  ) async {
    try {
      return await _remoteDatasource.createTimeBlock(routineId, request);
    } catch (e) {
      _logger.error('Failed to create time block', e);
      rethrow;
    }
  }

  Future<TimeBlockDTO> updateTimeBlock(
    String routineId,
    String timeBlockId,
    UpdateTimeBlockRequest request,
  ) async {
    try {
      return await _remoteDatasource.updateTimeBlock(
        routineId,
        timeBlockId,
        request,
      );
    } catch (e) {
      _logger.error('Failed to update time block', e);
      rethrow;
    }
  }

  Future<void> deleteTimeBlock(
    String routineId,
    String timeBlockId,
  ) async {
    try {
      await _remoteDatasource.deleteTimeBlock(routineId, timeBlockId);
    } catch (e) {
      _logger.error('Failed to delete time block', e);
      rethrow;
    }
  }
}
