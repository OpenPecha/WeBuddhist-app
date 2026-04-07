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
    CreateTimeBlockRequest request,
  ) async {
    final response = await _dio.post('/routines', data: request.toJson());
    return RoutineWithTimeBlocksResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// POST /routines/{routineId}/time-blocks
  /// Creates a new time block in an existing routine.
  Future<TimeBlockDTO> createTimeBlock(
    String routineId,
    CreateTimeBlockRequest request,
  ) async {
    final response = await _dio.post(
      '/routines/$routineId/time-blocks',
      data: request.toJson(),
    );
    return TimeBlockDTO.fromJson(response.data as Map<String, dynamic>);
  }

  /// PUT /routines/{routineId}/time-blocks/{timeBlockId}
  /// Replaces a time block and all its sessions.
  Future<TimeBlockDTO> updateTimeBlock(
    String routineId,
    String timeBlockId,
    UpdateTimeBlockRequest request,
  ) async {
    final response = await _dio.put(
      '/routines/$routineId/time-blocks/$timeBlockId',
      data: request.toJson(),
    );
    return TimeBlockDTO.fromJson(response.data as Map<String, dynamic>);
  }

  /// DELETE /routines/{routineId}/time-blocks/{timeBlockId}
  /// Soft-deletes a time block.
  Future<void> deleteTimeBlock(
    String routineId,
    String timeBlockId,
  ) async {
    await _dio.delete('/routines/$routineId/time-blocks/$timeBlockId');
  }

  /// GET /users/me/routine
  /// Fetches the authenticated user's routine, or null if none exists.
  ///
  /// Returns null when:
  /// - Server returns 404 (routine not found)
  /// - Server returns 400 with "no routine" message (backend-specific)
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

      // 404: Routine not found
      if (status == 404) {
        _logger.info('No routine for user (404)');
        return null;
      }

      // Backend returns 400 when no routine has been created yet
      if (status == 400) {
        final data = e.response?.data;
        String? msg;
        if (data is Map<String, dynamic>) {
          final detail = data['detail'];
          if (detail is Map<String, dynamic>) {
            msg = detail['message'] as String?;
          } else {
            msg = data['message'] as String?;
          }
        } else if (data is String) {
          msg = data;
        }
        if (msg?.toLowerCase().contains('no routine') == true) {
          _logger.info('No routine for user – treating as empty (400)');
          return null;
        }
      }

      // Re-throw for ErrorInterceptor to handle
      rethrow;
    }
  }
}
