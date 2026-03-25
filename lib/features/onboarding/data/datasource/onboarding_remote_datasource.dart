import 'package:dio/dio.dart';
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
        return false;
      }
    } catch (e) {
      _logger.error('Error saving onboarding preferences to backend', e);
      return false;
    }
  }
}
