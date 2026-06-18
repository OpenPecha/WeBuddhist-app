import 'package:equatable/equatable.dart';

/// Authentication credentials entity.
///
/// This domain entity represents authentication credentials
/// independently of any specific auth provider (Auth0, Firebase, etc.).
/// This allows the domain layer to remain framework-agnostic.
class AuthCredentials extends Equatable {
  /// The access token used for API requests
  final String accessToken;

  /// The ID token containing user identity information
  final String idToken;

  /// The token type (typically "Bearer")
  final String tokenType;

  /// Time in seconds until the token expires
  final int expiresIn;

  /// When the credentials were obtained
  final DateTime obtainedAt;

  /// Refresh token (if available)
  final String? refreshToken;

  /// Token scope (if applicable)
  final String? scope;

  const AuthCredentials({
    required this.accessToken,
    required this.idToken,
    required this.tokenType,
    required this.expiresIn,
    required this.obtainedAt,
    this.refreshToken,
    this.scope,
  });

  /// Calculate when the token expires
  DateTime get expiresAt => obtainedAt.add(Duration(seconds: expiresIn));

  /// Check if the credentials are expired
  bool isExpired() => DateTime.now().isAfter(expiresAt);

  /// Check if the credentials are expired or will expire within the buffer time
  bool isExpiredOrExpiring({int bufferSeconds = 60}) {
    final expiryTime = expiresAt.subtract(Duration(seconds: bufferSeconds));
    return DateTime.now().isAfter(expiryTime);
  }

  @override
  List<Object?> get props => [
    accessToken,
    idToken,
    tokenType,
    expiresIn,
    obtainedAt,
    refreshToken,
    scope,
  ];

  /// Create a copy with some fields replaced
  AuthCredentials copyWith({
    String? accessToken,
    String? idToken,
    String? tokenType,
    int? expiresIn,
    DateTime? obtainedAt,
    String? refreshToken,
    String? scope,
  }) {
    return AuthCredentials(
      accessToken: accessToken ?? this.accessToken,
      idToken: idToken ?? this.idToken,
      tokenType: tokenType ?? this.tokenType,
      expiresIn: expiresIn ?? this.expiresIn,
      obtainedAt: obtainedAt ?? this.obtainedAt,
      refreshToken: refreshToken ?? this.refreshToken,
      scope: scope ?? this.scope,
    );
  }
}
