import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/user_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/use_case_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/auth/presentation/state/user_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for Auth State Management
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    loginUseCase: ref.watch(loginUseCaseProvider),
    initializeAuthUseCase: ref.watch(initializeAuthUseCaseProvider),
    hasValidCredentialsUseCase: ref.watch(hasValidCredentialsUseCaseProvider),
    getCredentialsUseCase: ref.watch(getCredentialsUseCaseProvider),
    continueAsGuestUseCase: ref.watch(continueAsGuestUseCaseProvider),
    isGuestModeUseCase: ref.watch(isGuestModeUseCaseProvider),
    clearGuestModeUseCase: ref.watch(clearGuestModeUseCaseProvider),
    localLogoutUseCase: ref.watch(localLogoutUseCaseProvider),
    clearGuestModeAndOnboardingUseCase: ref.watch(clearGuestModeAndOnboardingUseCaseProvider),
    ref: ref,
  );
});

/// Provider for User State Management
final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  final localStorageService = ref.watch(localStorageServiceProvider);
  return UserNotifier(
    getCurrentUserUseCase: ref.watch(getCurrentUserUseCaseProvider),
    localStorageService: localStorageService,
  );
});
