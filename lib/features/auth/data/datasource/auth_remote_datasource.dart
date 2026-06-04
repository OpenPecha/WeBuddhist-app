import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/features/auth/data/models/user_model.dart';
import 'package:flutter_pecha/features/auth/domain/entities/username_update_result.dart';

/// Auth remote datasource.
///
/// Error handling is centralized in ErrorInterceptor, which converts
/// DioExceptions to typed AppExceptions. Exceptions propagate naturally
/// to the repository layer for mapping to Failures.
abstract class AuthRemoteDataSource {
  Future<UserModel> getCurrentUser(String idToken);
  Future<UserModel> updateUserInfo(String idToken, Map<String, dynamic> body);

  /// PATCH /users/username — saves [username] and returns availability result.
  /// Returns [UsernameUpdateResult.conflict] on HTTP 409 (suggestions included).
  Future<UsernameUpdateResult> updateUsername(String idToken, String username);

  /// POST /users/upload — uploads [file] as multipart/form-data and returns the
  /// presigned S3 URL of the uploaded avatar.
  Future<String> uploadAvatar(String idToken, File file);
}

class AuthRemoteDatasourceImpl extends AuthRemoteDataSource {
  final Dio _dio;
  final String baseUrl = dotenv.env['BASE_API_URL']!;

  AuthRemoteDatasourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<UserModel> getCurrentUser(String idToken) async {
    final response = await _dio.get(
      '/users/info',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      ),
    );

    return UserModel.fromJson(response.data);
  }

  @override
  Future<UserModel> updateUserInfo(
    String idToken,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post(
      '/users/info',
      data: body,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      ),
    );

    return UserModel.fromJson(response.data);
  }

  @override
  Future<UsernameUpdateResult> updateUsername(
    String idToken,
    String username,
  ) async {
    try {
      final response = await _dio.patch(
        '/users/username',
        data: {'username': username},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
        ),
      );
      final confirmed =
          response.data['username'] as String? ?? username;
      return UsernameUpdateResult.success(confirmed);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final detail =
            e.response?.data['detail'] as Map<String, dynamic>?;
        final raw = detail?['suggestions'] as List?;
        final suggestions =
            raw?.map((s) => s.toString()).toList() ?? const <String>[];
        return UsernameUpdateResult.conflict(suggestions);
      }
      rethrow;
    }
  }

  @override
  Future<String> uploadAvatar(String idToken, File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
    });

    final response = await _dio.post(
      '/users/upload',
      data: formData,
      options: Options(
        headers: {'Authorization': 'Bearer $idToken'},
      ),
    );

    // The API returns a plain JSON string (the presigned URL).
    final raw = response.data;
    if (raw is String) return raw;
    return raw.toString();
  }
}
