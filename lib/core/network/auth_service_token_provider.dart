import 'package:flutter_pecha/core/network/token_provider.dart';
import 'package:flutter_pecha/features/auth/auth_service.dart';

/// TokenProvider that retrieves tokens from AuthService (Auth0 credentials).
class AuthServiceTokenProvider implements TokenProvider {
  AuthServiceTokenProvider(this._authService);

  final AuthService _authService;

  @override
  Future<String?> getToken() async {
    try {
      return await _authService.getValidIdToken();
    } catch (_) {
      return null;
    }
  }
}
