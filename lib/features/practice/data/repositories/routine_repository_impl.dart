import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/practice/data/datasource/routine_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_api_models.dart';
import 'package:flutter_pecha/features/practice/domain/repositories/routine_repository.dart';

class RoutineRepositoryImpl implements RoutineRepository {
  final RoutineRemoteDatasource _remoteDatasource;
  final _logger = AppLogger('RoutineRepository');

  RoutineRepositoryImpl({required RoutineRemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  @override
  Future<Either<Failure, RoutineResponse?>> getUserRoutine({
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final result = await _remoteDatasource.getUserRoutine(
        skip: skip,
        limit: limit,
      );
      return Right(result);
    } catch (e) {
      _logger.error('Failed to fetch routine', e);
      return Left(ExceptionMapper.map(e, context: 'Failed to fetch routine'));
    }
  }

  @override
  Future<Either<Failure, RoutineWithTimeBlocksResponse>> createRoutineWithTimeBlock(
    CreateTimeBlockRequest request,
  ) async {
    try {
      final result = await _remoteDatasource.createRoutineWithTimeBlock(request);
      return Right(result);
    } catch (e) {
      _logger.error('Failed to create routine', e);
      return Left(ExceptionMapper.map(e, context: 'Failed to create routine'));
    }
  }

  @override
  Future<Either<Failure, TimeBlockDTO>> createTimeBlock(
    String routineId,
    CreateTimeBlockRequest request,
  ) async {
    try {
      final result = await _remoteDatasource.createTimeBlock(routineId, request);
      return Right(result);
    } catch (e) {
      _logger.error('Failed to create time block', e);
      return Left(ExceptionMapper.map(e, context: 'Failed to create time block'));
    }
  }

  @override
  Future<Either<Failure, TimeBlockDTO>> updateTimeBlock(
    String routineId,
    String timeBlockId,
    UpdateTimeBlockRequest request,
  ) async {
    try {
      final result = await _remoteDatasource.updateTimeBlock(
        routineId,
        timeBlockId,
        request,
      );
      return Right(result);
    } catch (e) {
      _logger.error('Failed to update time block', e);
      return Left(ExceptionMapper.map(e, context: 'Failed to update time block'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTimeBlock(
    String routineId,
    String timeBlockId,
  ) async {
    try {
      await _remoteDatasource.deleteTimeBlock(routineId, timeBlockId);
      return const Right(null);
    } catch (e) {
      _logger.error('Failed to delete time block', e);
      return Left(ExceptionMapper.map(e, context: 'Failed to delete time block'));
    }
  }
}
