import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';

abstract class TimersRepositoryInterface {
  Future<Either<Failure, List<PresetTimer>>> getPresetTimers({
    int skip,
    int limit,
  });

  Stream<Either<Failure, List<PresetTimer>>> watchPresetTimers({
    int skip,
    int limit,
  });

  Future<Either<Failure, List<PresetTimer>>> refreshPresetTimers({
    int skip,
    int limit,
  });

  Future<Either<Failure, void>> stopUserTimer({
    required String timerId,
    required int durationMs,
  });

  Future<void> flushPendingTimerStops();
}
