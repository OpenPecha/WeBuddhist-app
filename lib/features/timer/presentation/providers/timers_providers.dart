import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/timer/data/datasource/timers_remote_datasource.dart';
import 'package:flutter_pecha/features/timer/data/repositories/timers_repository.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_pecha/features/timer/domain/repositories/timers_repository.dart';
import 'package:flutter_pecha/features/timer/domain/usecases/get_preset_timers_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

final timersRemoteDatasourceProvider = Provider<TimersRemoteDatasource>((ref) {
  return TimersRemoteDatasource(dio: ref.watch(dioProvider));
});

final timersDomainRepositoryProvider =
    Provider<TimersRepositoryInterface>((ref) {
  return TimersRepository(remote: ref.watch(timersRemoteDatasourceProvider));
});

final getPresetTimersUseCaseProvider = Provider<GetPresetTimersUseCase>((ref) {
  final repository = ref.watch(timersDomainRepositoryProvider);
  return GetPresetTimersUseCase(repository.getPresetTimers);
});

final presetTimersFutureProvider =
    FutureProvider<Either<Failure, List<PresetTimer>>>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth.isLoading || !auth.isLoggedIn || auth.isGuest) {
    return const Left(AuthenticationFailure('Not authenticated'));
  }

  final useCase = ref.watch(getPresetTimersUseCaseProvider);
  return useCase(const GetPresetTimersParams());
});
