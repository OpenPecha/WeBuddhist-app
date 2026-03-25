import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> getCurrentUser(String idToken);
}

class AuthRemoteDatasourceImpl extends AuthRemoteDataSource {
  final Dio _dio;
  final String baseUrl = dotenv.env['BASE_API_URL']!;

  AuthRemoteDatasourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<UserModel> getCurrentUser(String idToken) async {
    try {
      final response = await _dio.get(
        '/users/info',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw ServerException('User data not found in response');
      }
    } catch (e) {
      throw ServerException('Failed to get current user: ${e.toString()}');
    }
  }
}
