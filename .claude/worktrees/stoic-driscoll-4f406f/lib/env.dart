import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration for the app.
///
/// This class provides type-safe access to environment variables
/// loaded from .env files. Ensure dotenv.load() is called in main()
/// before accessing these values.
class Env {
  Env._();

  /// API base URL for the backend
  static String get apiBaseUrl => dotenv.env['BASE_API_URL'] ??
      (throw Exception('BASE_API_URL not found in environment'));

  /// AI service URL
  static String get aiUrl =>
      dotenv.env['AI_URL'] ?? 'https://aichat.webuddhist.com';

  /// Auth0 domain (fetched from backend /props endpoint)
  static String? get auth0Domain => dotenv.env['AUTH0_DOMAIN'];

  /// Auth0 client ID (fetched from backend /props endpoint)
  static String? get auth0ClientId => dotenv.env['AUTH0_CLIENT_ID'];

  /// Auth0 audience (fetched from backend /props endpoint)
  static String? get auth0Audience => dotenv.env['AUTH0_AUDIENCE'];

  /// Whether the app is running in debug mode
  static bool get isDebug =>
      dotenv.env['ENVIRONMENT'] != 'production';

  /// Current environment (dev, staging, prod)
  static String get environment =>
      dotenv.env['ENVIRONMENT'] ?? 'development';

  /// API timeout duration
  static Duration get apiTimeout => const Duration(seconds: 30);

  /// Cache TTL for static content
  static Duration get cacheTTL => const Duration(hours: 24);

  /// Cache TTL for user-specific content
  static Duration get userCacheTTL => const Duration(hours: 1);

  /// Maximum number of items to cache per type
  static int get maxCacheItems => 50;

  /// Enable verbose logging
  static bool get enableVerboseLogging => isDebug;
}
