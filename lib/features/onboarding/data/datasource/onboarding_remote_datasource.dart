import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/onboarding/data/models/onboarding_preferences.dart';

final _logger = AppLogger('OnboardingRemoteDatasource');

/// Remote datasource for saving onboarding preferences to backend
class OnboardingRemoteDatasource {
  const OnboardingRemoteDatasource({required this.dio});

  final Dio dio;

  /// Save onboarding preferences to backend
  ///
  /// Endpoint: POST /api/v1/users/me/onboarding-preferences
  /// Body: JSON with  preferredLanguage, selectedPaths
  /// Returns: Success boolean
  Future<bool> saveOnboardingPreferences(OnboardingPreferences prefs) async {
    try {
      final response = await dio.post(
        '/users/me/onboarding-preferences',
        data: prefs.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger.info('Onboarding preferences saved to backend');
        return true;
      } else {
        _logger.warning('Failed to save onboarding preferences: ${response.statusCode}');
        if (response.statusCode == 401) {
          throw const AuthenticationException('Unauthorized');
        } else if (response.statusCode == 403) {
          throw const AuthorizationException('Forbidden');
        } else if (response.statusCode == 429) {
          throw const RateLimitException('Too many requests');
        } else {
          throw ServerException('Failed to save onboarding preferences: ${response.statusCode}');
        }
      }
    } on DioException catch (e) {
      _logger.error('Dio error saving onboarding preferences to backend', e);
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const NetworkException('Connection timeout');
      } else if (e.type == DioExceptionType.connectionError) {
        throw const NetworkException('No internet connection');
      } else if (e.response?.statusCode != null) {
        final statusCode = e.response!.statusCode!;
        if (statusCode == 401) {
          throw const AuthenticationException('Unauthorized');
        } else if (statusCode == 403) {
          throw const AuthorizationException('Forbidden');
        } else if (statusCode == 429) {
          throw const RateLimitException('Too many requests');
        } else {
          throw ServerException('Failed to save onboarding preferences: $statusCode');
        }
      } else {
        throw const NetworkException('Network error');
      }
    }
  }
}
