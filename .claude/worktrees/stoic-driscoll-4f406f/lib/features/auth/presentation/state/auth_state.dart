/// Authentication state
///
/// Handles ONLY authentication concerns:
/// - Login/logout status
/// - Guest mode
/// - Auth loading states
/// - Auth errors
///
/// User profile data is now managed by UserNotifier (userProvider)
class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final bool isGuest;
  final String? errorMessage;

  const AuthState({
    required this.isLoggedIn,
    this.isGuest = false,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    bool? isGuest,
    String? errorMessage,
  }) => AuthState(
    isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    isLoading: isLoading ?? this.isLoading,
    isGuest: isGuest ?? this.isGuest,
    errorMessage: errorMessage,
  );

  AuthState clearError() => copyWith(errorMessage: '');
}
