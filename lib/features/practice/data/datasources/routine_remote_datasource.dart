import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_api_models.dart';
import 'package:http/http.dart' as http;

class RoutineRemoteDatasource {
  final http.Client client;
  final String baseUrl = dotenv.env['BASE_API_URL']!;
  final _logger = AppLogger('RoutineRemoteDatasource');

  RoutineRemoteDatasource({required this.client});

  /// POST /routines
  /// Creates a new routine for the user with the first time block.
  Future<RoutineWithTimeBlocksResponse> createRoutineWithTimeBlock(
    CreateTimeBlockRequest request,
  ) async {
    final uri = Uri.parse('$baseUrl/routines');
    _logger.info('POST $uri');

    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 201) {
      final decoded = utf8.decode(response.bodyBytes);
      return RoutineWithTimeBlocksResponse.fromJson(
        jsonDecode(decoded) as Map<String, dynamic>,
      );
    }

    final errorBody = _tryParseError(response);
    switch (response.statusCode) {
      case 401:
        throw RoutineApiException('Unauthorized', response.statusCode);
      case 409:
        throw RoutineAlreadyExistsException(
          errorBody?.message ?? 'Routine already exists for this user',
        );
      case 422:
        throw RoutineValidationException(
          errorBody?.message ?? 'Validation error',
        );
      default:
        throw RoutineApiException(
          errorBody?.message ?? 'Failed to create routine: ${response.statusCode}',
          response.statusCode,
        );
    }
  }

  /// POST /routines/{routineId}/time-blocks
  /// Creates a new time block in an existing routine.
  Future<TimeBlockDTO> createTimeBlock(
    String routineId,
    CreateTimeBlockRequest request,
  ) async {
    final uri = Uri.parse('$baseUrl/routines/$routineId/time-blocks');
    _logger.info('POST $uri');

    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 201) {
      final decoded = utf8.decode(response.bodyBytes);
      return TimeBlockDTO.fromJson(
        jsonDecode(decoded) as Map<String, dynamic>,
      );
    }

    final errorBody = _tryParseError(response);
    switch (response.statusCode) {
      case 401:
        throw RoutineApiException('Unauthorized', response.statusCode);
      case 403:
        throw RoutineApiException('Forbidden', response.statusCode);
      case 404:
        throw RoutineNotFoundException(
          errorBody?.message ?? 'Routine not found',
        );
      case 409:
        throw RoutineTimeConflictException(
          errorBody?.message ?? 'Time block with this time already exists',
        );
      case 422:
        throw RoutineValidationException(
          errorBody?.message ?? 'Validation error',
        );
      default:
        throw RoutineApiException(
          errorBody?.message ?? 'Failed to create time block: ${response.statusCode}',
          response.statusCode,
        );
    }
  }

  /// PUT /routines/{routineId}/time-blocks/{timeBlockId}
  /// Replaces a time block and all its sessions.
  Future<TimeBlockDTO> updateTimeBlock(
    String routineId,
    String timeBlockId,
    UpdateTimeBlockRequest request,
  ) async {
    final uri = Uri.parse(
      '$baseUrl/routines/$routineId/time-blocks/$timeBlockId',
    );
    _logger.info('PUT $uri');

    final response = await client.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 201) {
      final decoded = utf8.decode(response.bodyBytes);
      return TimeBlockDTO.fromJson(
        jsonDecode(decoded) as Map<String, dynamic>,
      );
    }

    final errorBody = _tryParseError(response);
    switch (response.statusCode) {
      case 401:
        throw RoutineApiException('Unauthorized', response.statusCode);
      case 403:
        throw RoutineApiException('Forbidden', response.statusCode);
      case 404:
        throw RoutineNotFoundException(
          errorBody?.message ?? 'Routine or time block not found',
        );
      case 409:
        throw RoutineTimeConflictException(
          errorBody?.message ?? 'Time block with this time already exists',
        );
      case 422:
        throw RoutineValidationException(
          errorBody?.message ?? 'Validation error',
        );
      default:
        throw RoutineApiException(
          errorBody?.message ?? 'Failed to update time block: ${response.statusCode}',
          response.statusCode,
        );
    }
  }

  /// DELETE /routines/{routineId}/time-blocks/{timeBlockId}
  /// Soft-deletes a time block.
  Future<void> deleteTimeBlock(
    String routineId,
    String timeBlockId,
  ) async {
    final uri = Uri.parse(
      '$baseUrl/routines/$routineId/time-blocks/$timeBlockId',
    );
    _logger.info('DELETE $uri');

    final response = await client.delete(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 204) return;

    final errorBody = _tryParseError(response);
    switch (response.statusCode) {
      case 401:
        throw RoutineApiException('Unauthorized', response.statusCode);
      case 403:
        throw RoutineApiException('Forbidden', response.statusCode);
      case 404:
        throw RoutineNotFoundException(
          errorBody?.message ?? 'Routine or time block not found',
        );
      default:
        throw RoutineApiException(
          errorBody?.message ?? 'Failed to delete time block: ${response.statusCode}',
          response.statusCode,
        );
    }
  }

  /// GET /users/me/routine
  /// Fetches the authenticated user's routine, or null if none exists (404).
  Future<RoutineResponse?> getUserRoutine({
    int skip = 0,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/users/me/routine').replace(
      queryParameters: {
        'skip': skip.toString(),
        'limit': limit.toString(),
      },
    );
    _logger.info('GET $uri');

    final response = await client.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      return RoutineResponse.fromJson(
        jsonDecode(decoded) as Map<String, dynamic>,
      );
    }

    if (response.statusCode == 404) {
      return null;
    }

    final errorBody = _tryParseError(response);
    switch (response.statusCode) {
      case 401:
        throw RoutineApiException('Unauthorized', response.statusCode);
      default:
        throw RoutineApiException(
          errorBody?.message ?? 'Failed to fetch routine: ${response.statusCode}',
          response.statusCode,
        );
    }
  }

  ErrorResponse? _tryParseError(http.Response response) {
    try {
      final decoded = utf8.decode(response.bodyBytes);
      return ErrorResponse.fromJson(
        jsonDecode(decoded) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
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
