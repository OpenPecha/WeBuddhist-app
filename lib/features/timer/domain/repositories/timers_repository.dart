import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';

abstract class TimersRepositoryInterface {
  Future<Either<Failure, List<PresetTimer>>> getPresetTimers({
    int skip,
    int limit,
  });
}
