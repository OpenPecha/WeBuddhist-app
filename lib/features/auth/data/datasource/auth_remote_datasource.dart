import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/features/auth/data/models/user_model.dart';

/// Auth remote datasource.
///
/// Error handling is centralized in ErrorInterceptor, which converts
/// DioExceptions to typed AppExceptions. Exceptions propagate naturally
/// to the repository layer for mapping to Failures.
abstract class AuthRemoteDataSource {
  Future<UserModel> getCurrentUser(String idToken);
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
    // ErrorInterceptor already converted DioException → AppException
    // AppException propagates naturally to repository
  }
}
