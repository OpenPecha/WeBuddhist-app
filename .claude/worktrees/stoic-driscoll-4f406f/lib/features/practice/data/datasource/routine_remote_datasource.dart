import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_api_models.dart';

class RoutineRemoteDatasource {
  final Dio _dio;
  final _logger = AppLogger('RoutineRemoteDatasource');

  RoutineRemoteDatasource({required Dio dio}) : _dio = dio;

  /// POST /routines
  /// Creates a new routine for the user with the first time block.
  Future<RoutineWithTimeBlocksResponse> createRoutineWithTimeBlock(
    TimeBlockRequest request,
  ) async {
    try {
      final response = await _dio.post('/routines', data: request.toJson());
      return RoutineWithTimeBlocksResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapCreateRoutineError(e);
    }
  }

  /// POST /routines/{routineId}/time-blocks
  /// Creates a new time block in an existing routine.
  Future<TimeBlockDTO> createTimeBlock(
    String routineId,
    TimeBlockRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/routines/$routineId/time-blocks',
        data: request.toJson(),
      );
      return TimeBlockDTO.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapTimeBlockMutationError(e, 'create');
    }
  }

  /// PUT /routines/{routineId}/time-blocks/{timeBlockId}
  /// Replaces a time block and all its sessions.
  Future<TimeBlockDTO> updateTimeBlock(
    String routineId,
    String timeBlockId,
    TimeBlockRequest request,
  ) async {
    try {
      final response = await _dio.put(
        '/routines/$routineId/time-blocks/$timeBlockId',
        data: request.toJson(),
      );
      return TimeBlockDTO.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapTimeBlockMutationError(e, 'update');
    }
  }

  /// DELETE /routines/{routineId}/time-blocks/{timeBlockId}
  /// Soft-deletes a time block.
  Future<void> deleteTimeBlock(
    String routineId,
    String timeBlockId,
  ) async {
    try {
      await _dio.delete('/routines/$routineId/time-blocks/$timeBlockId');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404) {
        throw RoutineNotFoundException(
          _extractMessage(e) ?? 'Routine or time block not found',
        );
      }
      if (e.error is Exception) throw e.error! as Exception;
      rethrow;
    }
  }

  /// GET /users/me/routine
  /// Fetches the authenticated user's routine, or null if none exists.
  Future<RoutineResponse?> getUserRoutine({
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/users/me/routine',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      return RoutineResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final status = e.response?.statusCode;

      if (status == 404) return null;

      // Backend returns 400 when no routine has been created yet.
      if (status == 400) {
        final msg = _extractMessage(e)?.toLowerCase() ?? '';
        if (msg.contains('no routine')) {
          _logger.info('No routine for user – treating as empty');
          return null;
        }
      }

      if (e.error is Exception) throw e.error! as Exception;
      rethrow;
    }
  }

  // ─── Error mapping helpers ───

  /// Maps errors specific to routine creation (409 = already exists).
  Exception _mapCreateRoutineError(DioException e) {
    final status = e.response?.statusCode;
    final message = _extractMessage(e);
    return switch (status) {
      409 => RoutineAlreadyExistsException(
          message ?? 'Routine already exists for this user'),
      422 => RoutineValidationException(message ?? 'Validation error'),
      _ => e.error is Exception ? e.error! as Exception : e,
    };
  }

  /// Maps errors for time-block mutations (409 = time conflict).
  Exception _mapTimeBlockMutationError(DioException e, String action) {
    final status = e.response?.statusCode;
    final message = _extractMessage(e);
    return switch (status) {
      404 => RoutineNotFoundException(
          message ?? 'Routine or time block not found'),
      409 => RoutineTimeConflictException(
          message ?? 'Time block with this time already exists'),
      422 => RoutineValidationException(message ?? 'Validation error'),
      _ => e.error is Exception ? e.error! as Exception : e,
    };
  }

  /// Extracts a human-readable message from the Dio error response.
  /// Handles both flat `{ "message": "..." }` and nested `{ "detail": { "message": "..." } }`.
  String? _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is Map<String, dynamic>) {
        return detail['message'] as String?;
      }
      return (data['message'] ?? data['error']) as String?;
    }
    return null;
  }
}

// ─── Exception classes ───

class RoutineApiException implements Exception {
  final String message;
  final int statusCode;

  const RoutineApiException(this.message, this.statusCode);

  @override
  String toString() => 'RoutineApiException($statusCode): $message';
}

class RoutineAlreadyExistsException implements Exception {
  final String message;
  const RoutineAlreadyExistsException(this.message);

  @override
  String toString() => 'RoutineAlreadyExistsException: $message';
}

class RoutineNotFoundException implements Exception {
  final String message;
  const RoutineNotFoundException(this.message);

  @override
  String toString() => 'RoutineNotFoundException: $message';
}

class RoutineTimeConflictException implements Exception {
  final String message;
  const RoutineTimeConflictException(this.message);

  @override
  String toString() => 'RoutineTimeConflictException: $message';
}

class RoutineValidationException implements Exception {
  final String message;
  const RoutineValidationException(this.message);

  @override
  String toString() => 'RoutineValidationException: $message';
}
