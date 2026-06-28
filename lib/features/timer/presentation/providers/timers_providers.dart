import 'dart:async';

import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/timer/data/datasource/timers_local_datasource.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/timer/data/datasource/timers_remote_datasource.dart';
import 'package:flutter_pecha/features/timer/data/repositories/timers_repository.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_pecha/features/timer/domain/repositories/timers_repository.dart';
import 'package:flutter_pecha/features/timer/domain/usecases/get_preset_timers_usecase.dart';
import 'package:flutter_pecha/features/timer/domain/usecases/stop_user_timer_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

final timersRemoteDatasourceProvider = Provider<TimersRemoteDatasource>((ref) {
  return TimersRemoteDatasource(dio: ref.watch(dioProvider));
});

final timersLocalDatasourceProvider = Provider<TimersLocalDatasource>((ref) {
  return TimersLocalDatasource();
});

final timersDomainRepositoryProvider = Provider<TimersRepositoryInterface>((
  ref,
) {
  return TimersRepository(
    remote: ref.watch(timersRemoteDatasourceProvider),
    local: ref.watch(timersLocalDatasourceProvider),
  );
});

final getPresetTimersUseCaseProvider = Provider<GetPresetTimersUseCase>((ref) {
  final repository = ref.watch(timersDomainRepositoryProvider);
  return GetPresetTimersUseCase(repository.getPresetTimers);
});

final stopUserTimerUseCaseProvider = Provider<StopUserTimerUseCase>((ref) {
  final repository = ref.watch(timersDomainRepositoryProvider);
  return StopUserTimerUseCase(repository.stopUserTimer);
});

final presetTimersFutureProvider =
    StreamProvider<Either<Failure, List<PresetTimer>>>((ref) {
      final auth = ref.watch(authProvider);
      if (auth.isLoading || !auth.isLoggedIn || auth.isGuest) {
        return Stream.value(
          const Left(AuthenticationFailure('Not authenticated')),
        );
      }

      final repository = ref.watch(timersDomainRepositoryProvider);
      return repository.watchPresetTimers();
    });

/// Keeps pending local timer-stop writes moving after connectivity returns.
final timerSyncBootstrapProvider = Provider<void>((ref) {
  final subscription = ref
      .watch(connectivityServiceProvider)
      .onConnectivityChanged
      .listen((isOnline) {
        if (isOnline) {
          unawaited(
            ref.read(timersDomainRepositoryProvider).flushPendingTimerStops(),
          );
        }
      });
  ref.onDispose(() {
    subscription.cancel();
  });
});
