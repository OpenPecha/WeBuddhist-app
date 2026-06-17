import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/connect/domain/entities/discover_groups_page.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_profile_model.dart';

class ConnectRemoteDatasource {
  ConnectRemoteDatasource({required this.dio});

  final Dio dio;
  final _logger = AppLogger('ConnectRemoteDatasource');

  Future<DiscoverGroupsPage> fetchDiscoverGroups({
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

      if (response.statusCode != 200) {
        _logger.error(
          'Failed to load discover groups: ${response.statusCode}',
        );
        throw _statusToException(
          response.statusCode,
          'Failed to load discover groups',
        );
      }

      final data = response.data as Map<String, dynamic>;
      final groupsJson = data['groups'] as List<dynamic>? ?? const [];
      final groups =
          groupsJson
              .whereType<Map<String, dynamic>>()
              .map(GroupProfileModel.fromJson)
              .map((model) => model.toEntity())
              .toList();

      return DiscoverGroupsPage(
        groups: groups,
        skip: (data['skip'] as num?)?.toInt() ?? skip,
        limit: (data['limit'] as num?)?.toInt() ?? limit,
        total: (data['total'] as num?)?.toInt() ?? groups.length,
      );
    } on DioException catch (e) {
      _logger.error('Dio error in fetchDiscoverGroups', e);
      throw _dioToException(e, 'Failed to load discover groups');
    }
  }

  Exception _statusToException(int? statusCode, String label) {
    if (statusCode == 401) {
      return const AuthenticationException('Unauthorized');
    } else if (statusCode == 404) {
      return const NotFoundException('Groups not found');
    } else if (statusCode == 429) {
      return const RateLimitException('Too many requests');
    } else {
      return ServerException('$label: $statusCode');
    }
  }

  Exception _dioToException(DioException e, String label) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkException('Connection timeout');
    } else if (e.type == DioExceptionType.connectionError) {
      return const NetworkException('No internet connection');
    } else if (e.response?.statusCode != null) {
      return _statusToException(e.response!.statusCode, label);
    } else {
      return const NetworkException('Network error');
    }
  }
}
