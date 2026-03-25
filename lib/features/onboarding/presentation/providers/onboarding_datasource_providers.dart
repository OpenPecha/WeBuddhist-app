import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/onboarding/data/datasource/onboarding_local_datasource.dart';
import 'package:flutter_pecha/features/onboarding/data/datasource/onboarding_remote_datasource.dart';
import 'package:flutter_pecha/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:flutter_pecha/features/onboarding/data/repositories/onboarding_repository.dart' show OnboardingRepositoryImpl;
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provider for local datasource
final onboardingLocalDatasourceProvider = Provider<OnboardingLocalDatasource>((
  ref,
) {
  final localStorageService = ref.watch(localStorageServiceProvider);
  return OnboardingLocalDatasource(localStorageService: localStorageService);
});

/// Provider for remote datasource
final onboardingRemoteDatasourceProvider = Provider<OnboardingRemoteDatasource>(
  (ref) {
    final dio = ref.watch(dioProvider);
    return OnboardingRemoteDatasource(dio: dio);
  },
);

/// Provider for repository implementation (implements domain interface)
final onboardingRepositoryProvider = Provider<OnboardingRepositoryImpl>((ref) {
  final localDatasource = ref.watch(onboardingLocalDatasourceProvider);
  final remoteDatasource = ref.watch(onboardingRemoteDatasourceProvider);
  final userNotifier = ref.watch(userProvider.notifier);
  final localeNotifier = ref.watch(localeProvider.notifier);
  return OnboardingRepositoryImpl(
    localDatasource: localDatasource,
    remoteDatasource: remoteDatasource,
    userNotifier: userNotifier,
    localeNotifier: localeNotifier,
  );
});
