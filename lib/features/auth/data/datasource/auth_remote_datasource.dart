import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/features/auth/data/models/user_model.dart';
import 'package:flutter_pecha/features/auth/domain/entities/username_update_result.dart';

/// Auth remote datasource.
///
/// Authentication is centralized: [AuthInterceptor] attaches the bearer
/// (access) token to every protected route (see [ProtectedRoutes]), so these
/// methods never set an `Authorization` header themselves.
///
/// Error handling is centralized in ErrorInterceptor, which converts
/// DioExceptions to typed AppExceptions. Exceptions propagate naturally
/// to the repository layer for mapping to Failures.
abstract class AuthRemoteDataSource {
  Future<UserModel> getCurrentUser();
  Future<UserModel> updateUserInfo(Map<String, dynamic> body);

  /// PATCH /users/username — saves [username] and returns availability result.
  /// Returns [UsernameUpdateResult.conflict] on HTTP 409 (suggestions included).
  Future<UsernameUpdateResult> updateUsername(String username);

  /// POST /users/upload — uploads [file] as multipart/form-data and returns the
  /// presigned S3 URL of the uploaded avatar.
  Future<String> uploadAvatar(File file);

  /// DELETE /users/info — permanently deletes the authenticated user's account.
  Future<void> deleteUser();
}

class AuthRemoteDatasourceImpl extends AuthRemoteDataSource {
  final Dio _dio;
  final String baseUrl = dotenv.env['BASE_API_URL']!;

  AuthRemoteDatasourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<UserModel> getCurrentUser() async {
    final response = await _dio.get('/users/info');

    return UserModel.fromJson(response.data);
  }

  @override
  Future<UserModel> updateUserInfo(Map<String, dynamic> body) async {
    final response = await _dio.post('/users/info', data: body);

    return UserModel.fromJson(response.data);
  }

  @override
  Future<UsernameUpdateResult> updateUsername(String username) async {
    try {
      final response = await _dio.patch(
        '/users/username',
        data: {'username': username},
      );
      final confirmed = response.data['username'] as String? ?? username;
      return UsernameUpdateResult.success(confirmed);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final detail = e.response?.data['detail'] as Map<String, dynamic>?;
        final raw = detail?['suggestions'] as List?;
        final suggestions =
            raw?.map((s) => s.toString()).toList() ?? const <String>[];
        return UsernameUpdateResult.conflict(suggestions);
      }
      rethrow;
    }
  }

  @override
  Future<String> uploadAvatar(File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
    });

    final response = await _dio.post('/users/upload', data: formData);

    // The API returns a plain JSON string (the presigned URL).
    final raw = response.data;
    if (raw is String) return raw;
    return raw.toString();
  }

  @override
  Future<void> deleteUser() async {
    await _dio.delete('/users/info');
  }
}
