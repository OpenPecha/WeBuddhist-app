import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_profile_model.dart';

class GroupProfileRemoteDatasource {
  final Dio dio;
  final _logger = AppLogger('GroupProfileRemoteDatasource');

  GroupProfileRemoteDatasource({required this.dio});

  Future<GroupProfileModel> fetchGroupProfile(
    String groupId, {
    required String language,
  }) async {
    try {
      final response = await dio.get(
        '/author/groups/$groupId',
        queryParameters: {'language': language},
      );

      if (response.statusCode == 200) {
        return GroupProfileModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        _logger.error(
          'Failed to load group profile $groupId: ${response.statusCode}',
        );
        throw _statusToException(
          response.statusCode,
          'Failed to load group profile',
        );
      }
    } on DioException catch (e) {
      _logger.error('Dio error in fetchGroupProfile', e);
      throw _dioToException(e, 'Failed to load group profile');
    }
  }

  Future<void> followGroup(String groupId) async {
    try {
      final response = await dio.post('/author/groups/$groupId/join');
      if (response.statusCode != 200 &&
          response.statusCode != 201 &&
          response.statusCode != 204) {
        throw _statusToException(response.statusCode, 'Failed to join group');
      }
    } on DioException catch (e) {
      _logger.error('Dio error in followGroup', e);
      throw _dioToException(e, 'Failed to join group');
    }
  }

  Future<bool> checkFollowStatus(String groupId) async {
    try {
      final response = await dio.get(
        '/users/me/joined/author/groups',
        queryParameters: {'group_id': groupId, 'skip': 0, 'limit': 20},
        options: Options(extra: {'no_cache': true}),
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return false;
      }
      _logger.error('Dio error in checkFollowStatus', e);
      throw _dioToException(e, 'Failed to check join status');
    }
  }

  Future<void> unfollowGroup(String groupId) async {
    try {
      final response = await dio.delete('/author/groups/$groupId/join');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _statusToException(
          response.statusCode,
          'Failed to leave group',
        );
      }
    } on DioException catch (e) {
      _logger.error('Dio error in unfollowGroup', e);
      throw _dioToException(e, 'Failed to leave group');
    }
  }

  Exception _statusToException(int? statusCode, String label) {
    if (statusCode == 401) {
      return const AuthenticationException('Unauthorized');
    } else if (statusCode == 404) {
      return const NotFoundException('Group not found');
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
