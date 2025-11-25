import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/network/api_client_provider.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/auth/application/user_notifier.dart';
import 'package:flutter_pecha/features/onboarding/data/onboarding_local_datasource.dart';
import 'package:flutter_pecha/features/onboarding/data/onboarding_remote_datasource.dart';
import 'package:flutter_pecha/features/onboarding/data/onboarding_repository.dart';
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
    final client = ref.watch(apiClientProvider);
    return OnboardingRemoteDatasource(client: client);
  },
);

/// Provider for repository
final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final localDatasource = ref.watch(onboardingLocalDatasourceProvider);
  final remoteDatasource = ref.watch(onboardingRemoteDatasourceProvider);
  final userNotifier = ref.watch(userProvider.notifier);
  final localeNotifier = ref.watch(localeProvider.notifier);
  return OnboardingRepository(
    localDatasource: localDatasource,
    remoteDatasource: remoteDatasource,
    userNotifier: userNotifier,
    localeNotifier: localeNotifier,
  );
});
