import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/onboarding/data/models/onboarding_preferences.dart';

final _logger = AppLogger('OnboardingRemoteDatasource');

/// Remote datasource for onboarding preferences.
///
/// Error handling is centralized in ErrorInterceptor, which converts
/// DioExceptions to typed AppExceptions. Exceptions propagate naturally
/// to the repository layer for mapping to Failures.
class OnboardingRemoteDatasource {
  OnboardingRemoteDatasource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Save onboarding preferences to backend.
  ///
  /// Endpoint: POST /api/v1/users/me/onboarding-preferences
  Future<bool> saveOnboardingPreferences(OnboardingPreferences prefs) async {
    final response = await _dio.post(
      '/users/me/onboarding-preferences',
      data: prefs.toJson(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      _logger.info('Onboarding preferences saved to backend');
      return true;
    }

    _logger.warning('Unexpected status: ${response.statusCode}');
    return false;
  }

  /// Fetch onboarding preferences from backend.
  ///
  /// Endpoint: GET /api/v1/users/me/onboarding-preferences
  /// Returns: OnboardingPreferences or null if not found
  Future<OnboardingPreferences?> fetchOnboardingPreferences() async {
    final response = await _dio.get('/users/me/onboarding-preferences');

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return OnboardingPreferences.fromJson(data);
      }
    }

    return null;
  }
}
