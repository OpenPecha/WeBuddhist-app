/// Abstraction for providing authentication tokens.
///
/// Implementations retrieve tokens from different sources
/// (AuthService, SecureStorage, etc.) without the consumer
/// needing to know the source.
abstract class TokenProvider {
  Future<String?> getToken();
}
