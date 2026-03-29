import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/core/network/dio_error_handler.dart';
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

      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      DioErrorHandler.handleDioException(e, 'Failed to get user');
    }
  }
}
