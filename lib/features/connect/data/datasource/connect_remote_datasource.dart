import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_profile_model.dart';

class ConnectRemoteDatasource {
  ConnectRemoteDatasource({required this.dio});

  final Dio dio;
  final _logger = AppLogger('ConnectRemoteDatasource');

  Future<List<GroupProfileModel>> fetchDiscoverGroups({
    required String language,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        '/author/groups',
        queryParameters: {
          'language': language,
          'group_type': 'COMMUNITY',
          'skip': skip,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final groupsJson =
            (response.data['groups'] as List<dynamic>?) ?? const [];
        return groupsJson
            .whereType<Map<String, dynamic>>()
            .map(GroupProfileModel.fromJson)
            .toList();
      }

      _logger.error(
        'Failed to load discover groups: ${response.statusCode}',
      );
      throw _statusToException(
        response.statusCode,
        'Failed to load discover groups',
      );
    } on DioException catch (e) {
      _logger.error('Dio error in fetchDiscoverGroups', e);
      throw _dioToException(e, 'Failed to load discover groups');
    }
  }

  Future<List<GroupProfileModel>> fetchJoinedGroups({
    required String language,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        '/users/me/joined/author/groups',
        queryParameters: {
          'language': language,
          'skip': skip,
          'limit': limit,
        },
        options: Options(extra: {'no_cache': true}),
      );

      if (response.statusCode == 200) {
        final groupsJson = _parseGroupsResponse(response.data);
        final models =
            groupsJson.map(GroupProfileModel.fromJson).toList();

        return Future.wait(
          models.map(
            (model) => _enrichJoinedGroupIfNeeded(
              model: model,
              language: language,
            ),
          ),
        );
      }

      _logger.error(
        'Failed to load joined groups: ${response.statusCode}',
      );
      throw _statusToException(
        response.statusCode,
        'Failed to load joined groups',
      );
    } on DioException catch (e) {
      _logger.error('Dio error in fetchJoinedGroups', e);
      throw _dioToException(e, 'Failed to load joined groups');
    }
  }

  Future<GroupProfileModel> _enrichJoinedGroupIfNeeded({
    required GroupProfileModel model,
    required String language,
  }) async {
    final title = model.metadata?['title'] as String?;
    if (title != null && title.trim().isNotEmpty) {
      return model;
    }

    try {
      return await _fetchJoinedGroupDetail(
        groupId: model.id,
        language: language,
      );
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to enrich joined group ${model.id}, using list payload',
        e,
        stackTrace,
      );
      return model;
    }
  }

  Future<GroupProfileModel> _fetchJoinedGroupDetail({
    required String groupId,
    required String language,
  }) async {
    final response = await dio.get(
      '/users/me/joined/author/groups',
      queryParameters: {
        'group_id': groupId,
        'language': language,
        'skip': 0,
        'limit': 20,
      },
      options: Options(extra: {'no_cache': true}),
    );

    if (response.statusCode != 200) {
      throw _statusToException(
        response.statusCode,
        'Failed to load joined group detail',
      );
    }

    final groupsJson = _parseGroupsResponse(response.data);
    if (groupsJson.isEmpty) {
      throw ServerException('Joined group detail response was empty');
    }

    return GroupProfileModel.fromJson(groupsJson.first);
  }

  /// Handles list payloads (`{groups: [...]}`) and single-group payloads
  /// returned when `group_id` is provided.
  List<Map<String, dynamic>> _parseGroupsResponse(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return const [];
    }

    final groups = data['groups'];
    if (groups is List) {
      return groups.whereType<Map<String, dynamic>>().toList();
    }

    if (data.containsKey('id')) {
      return [data];
    }

    return const [];
  }

  Exception _statusToException(int? statusCode, String label) {
    if (statusCode == 401) {
      return const AuthenticationException('Unauthorized');
    } else if (statusCode == 404) {
      return NotFoundException(label);
    } else if (statusCode == 429) {
      return const RateLimitException('Too many requests');
    } else {
      return ServerException('$label (${statusCode ?? 'unknown'})');
    }
  }

  Exception _dioToException(DioException e, String label) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkException('No internet connection');
    }

    final statusCode = e.response?.statusCode;
    if (statusCode != null) {
      return _statusToException(statusCode, label);
    }

    return ServerException('$label: ${e.message}');
  }
}
