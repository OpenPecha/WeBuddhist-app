import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/features/auth/data/models/user_model.dart';
import 'package:http/http.dart' as http;

abstract class AuthRemoteDataSource {
  Future<UserModel> getCurrentUser(String idToken);
}

class AuthRemoteDatasourceImpl extends AuthRemoteDataSource {
  final http.Client _client;
  final String baseUrl = dotenv.env['BASE_API_URL']!;

  AuthRemoteDatasourceImpl({required http.Client client}) : _client = client;

  @override
  Future<UserModel> getCurrentUser(String idToken) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/users/info'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final jsonData = json.decode(decoded);
        return UserModel.fromJson(jsonData);
      } else {
        throw ServerException('User data not found in response');
      }
    } catch (e) {
      throw ServerException('Failed to get current user: ${e.toString()}');
    }
  }
}
