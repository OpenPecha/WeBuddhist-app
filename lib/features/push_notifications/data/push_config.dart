class PushConfig {
  PushConfig._();

  /// Backend endpoint that registers a device's FCM token for the user.
  ///
  /// NOTE: Placeholder path — confirm with the backend team before enabling.
  /// Listed in [ProtectedRoutes] so the bearer token is injected automatically.
  static const String deviceTokenPath = '/users/device-token';

  /// While `false`, captured tokens are logged locally but NOT sent to the
  /// backend (the endpoint above is not live yet). Flip to `true` once the
  /// backend starts accepting device tokens.
  static const bool backendSyncEnabled = false;
}
