import 'package:flutter_pecha/features/auth/domain/usecases/clear_guest_mode_and_onboarding_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/clear_guest_mode_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/continue_as_guest_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/get_credentials_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/get_valid_id_token_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/has_valid_credentials_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/initialize_auth_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/is_guest_mode_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/login_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/logout_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/refresh_id_token_usecase.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ========== Use Case Providers ==========

/// Provider for LoginUseCase.
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUseCase(repository);
});

/// Provider for InitializeAuthUseCase.
final initializeAuthUseCaseProvider = Provider<InitializeAuthUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return InitializeAuthUseCase(repository);
});

/// Provider for HasValidCredentialsUseCase.
final hasValidCredentialsUseCaseProvider = Provider<HasValidCredentialsUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return HasValidCredentialsUseCase(repository);
});

/// Provider for GetCredentialsUseCase.
final getCredentialsUseCaseProvider = Provider<GetCredentialsUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetCredentialsUseCase(repository);
});

/// Provider for GetValidIdTokenUseCase.
final getValidIdTokenUseCaseProvider = Provider<GetValidIdTokenUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetValidIdTokenUseCase(repository);
});

/// Provider for RefreshIdTokenUseCase.
final refreshIdTokenUseCaseProvider = Provider<RefreshIdTokenUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return RefreshIdTokenUseCase(repository);
});

/// Provider for ContinueAsGuestUseCase.
final continueAsGuestUseCaseProvider = Provider<ContinueAsGuestUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return ContinueAsGuestUseCase(repository);
});

/// Provider for IsGuestModeUseCase.
final isGuestModeUseCaseProvider = Provider<IsGuestModeUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return IsGuestModeUseCase(repository);
});

/// Provider for ClearGuestModeUseCase.
final clearGuestModeUseCaseProvider = Provider<ClearGuestModeUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return ClearGuestModeUseCase(repository);
});

/// Provider for LogoutUseCase (LocalLogout).
final localLogoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LogoutUseCase(repository);
});

/// Provider for GetCurrentUserUseCase.
final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetCurrentUserUseCase(repository);
});

/// Provider for ClearGuestModeAndOnboardingUseCase.
final clearGuestModeAndOnboardingUseCaseProvider = Provider<ClearGuestModeAndOnboardingUseCase>((ref) {
  final clearGuestModeUseCase = ref.watch(clearGuestModeUseCaseProvider);
  final isGuestModeUseCase = ref.watch(isGuestModeUseCaseProvider);
  return ClearGuestModeAndOnboardingUseCase(
    clearGuestModeUseCase,
    isGuestModeUseCase,
  );
});
