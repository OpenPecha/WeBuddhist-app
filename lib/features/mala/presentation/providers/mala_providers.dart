import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_local_datasource.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_remote_datasource.dart';
import 'package:flutter_pecha/features/mala/data/repositories/mala_repository_impl.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/domain/repositories/mala_repository.dart';
import 'package:flutter_pecha/features/mala/domain/usecases/mala_usecases.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_counter_notifier.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_sync_manager.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

// ============ Data sources ============

final malaRemoteDataSourceProvider = Provider<MalaRemoteDataSource>((ref) {
  return MalaRemoteDataSource(dio: ref.watch(dioProvider));
});

/// Local store is a singleton; the Hive box is opened in app bootstrap.
final malaLocalDataSourceProvider = Provider<MalaLocalDataSource>((ref) {
  return MalaLocalDataSource();
});

// ============ Repository ============

final malaRepositoryProvider = Provider<MalaRepository>((ref) {
  return MalaRepositoryImpl(remote: ref.watch(malaRemoteDataSourceProvider));
});

// ============ Use cases ============

final getCatalogueUseCaseProvider = Provider<GetCatalogueUseCase>((ref) {
  return GetCatalogueUseCase(ref.watch(malaRepositoryProvider));
});

final getUserTotalsUseCaseProvider = Provider<GetUserTotalsUseCase>((ref) {
  return GetUserTotalsUseCase(ref.watch(malaRepositoryProvider));
});

final createUserAccumulatorUseCaseProvider =
    Provider<CreateUserAccumulatorUseCase>((ref) {
  return CreateUserAccumulatorUseCase(ref.watch(malaRepositoryProvider));
});

final updateUserAccumulatorUseCaseProvider =
    Provider<UpdateUserAccumulatorUseCase>((ref) {
  return UpdateUserAccumulatorUseCase(ref.watch(malaRepositoryProvider));
});

// ============ Auth helpers ============

bool _isAuthenticated(Ref ref) {
  final auth = ref.read(authProvider);
  return auth.isLoggedIn && !auth.isGuest;
}

String? _currentUserId(Ref ref) => ref.read(userProvider).user?.id;

// ============ Sync manager (app-scoped, kept alive) ============

/// Read this early (app shell) so [MalaSyncManager.start] runs and the manager
/// observes lifecycle + connectivity for the whole app lifetime.
final malaSyncManagerProvider = Provider<MalaSyncManager>((ref) {
  final manager = MalaSyncManager(
    local: ref.watch(malaLocalDataSourceProvider),
    createAccumulator: ref.watch(createUserAccumulatorUseCaseProvider),
    updateAccumulator: ref.watch(updateUserAccumulatorUseCaseProvider),
    isLoggedIn: () => _isAuthenticated(ref),
    currentUserId: () => _currentUserId(ref),
    connectivityStream:
        ref.watch(connectivityServiceProvider).onConnectivityChanged,
    analytics: ref.watch(analyticsServiceProvider),
  )..start();
  ref.onDispose(manager.dispose);
  return manager;
});

// ============ Catalogue ============

final malaCatalogueProvider =
    FutureProvider<Either<Failure, List<Mantra>>>((ref) async {
  if (!_isAuthenticated(ref)) {
    return const Left(AuthenticationFailure('Not authenticated'));
  }
  return ref.watch(getCatalogueUseCaseProvider)(const NoParams());
});

// ============ Per-mantra counter ============

final malaCounterProvider = StateNotifierProvider.autoDispose
    .family<MalaCounterNotifier, MalaCounterState, Mantra>((ref, mantra) {
  return MalaCounterNotifier(
    mantra: mantra,
    local: ref.watch(malaLocalDataSourceProvider),
    getUserTotals: ref.watch(getUserTotalsUseCaseProvider),
    sync: ref.watch(malaSyncManagerProvider),
    currentUserId: () => _currentUserId(ref),
    analytics: ref.watch(analyticsServiceProvider),
  );
});
