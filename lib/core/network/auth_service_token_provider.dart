import 'package:flutter_pecha/core/network/token_provider.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/auth/auth_service.dart';

/// TokenProvider that retrieves tokens from AuthService (Auth0 credentials).
class AuthServiceTokenProvider implements TokenProvider {
  AuthServiceTokenProvider(this._authService, [AppLogger? logger])
      : _logger = logger ?? AppLogger('AuthServiceTokenProvider');

  final AuthService _authService;
  final AppLogger _logger;

  @override
  Future<String?> getToken() async {
    try {
      return await _authService.getValidIdToken();
    } catch (e) {
      _logger.warning('Failed to get valid ID token: $e');
      return null;
    }
  }
}
