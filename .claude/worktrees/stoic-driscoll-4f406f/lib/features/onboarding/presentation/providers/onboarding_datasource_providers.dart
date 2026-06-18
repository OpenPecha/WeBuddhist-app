import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/onboarding/data/datasource/onboarding_local_datasource.dart';
import 'package:flutter_pecha/features/onboarding/data/datasource/onboarding_remote_datasource.dart';
import 'package:flutter_pecha/features/onboarding/data/repositories/onboarding_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provider for local datasource
final onboardingLocalDatasourceProvider = Provider<OnboardingLocalDatasource>((ref) {
  final localStorageService = ref.watch(localStorageServiceProvider);
  return OnboardingLocalDatasource(localStorageService: localStorageService);
});

/// Provider for remote datasource
final onboardingRemoteDatasourceProvider = Provider<OnboardingRemoteDatasource>((ref) {
  final dio = ref.watch(dioProvider);
  return OnboardingRemoteDatasource(dio: dio);
});

/// Provider for repository implementation
final onboardingRepositoryProvider = Provider<OnboardingRepositoryImpl>((ref) {
  final localDatasource = ref.watch(onboardingLocalDatasourceProvider);
  final remoteDatasource = ref.watch(onboardingRemoteDatasourceProvider);
  return OnboardingRepositoryImpl(
    localDatasource: localDatasource,
    remoteDatasource: remoteDatasource,
  );
});
