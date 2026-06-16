import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

class StopUserTimerParams extends Equatable {
  const StopUserTimerParams({
    required this.timerId,
    required this.durationMs,
  });

  final String timerId;
  final int durationMs;

  @override
  List<Object?> get props => [timerId, durationMs];
}

class StopUserTimerUseCase extends UseCase<void, StopUserTimerParams> {
  StopUserTimerUseCase(this._stopUserTimer);

  final Future<Either<Failure, void>> Function({
    required String timerId,
    required int durationMs,
  }) _stopUserTimer;

  @override
  Future<Either<Failure, void>> call(StopUserTimerParams params) async {
    if (params.timerId.isEmpty) {
      return const Left(ValidationFailure('Timer ID cannot be empty'));
    }
    if (params.durationMs < 0) {
      return const Left(ValidationFailure('Duration cannot be negative'));
    }
    return _stopUserTimer(
      timerId: params.timerId,
      durationMs: params.durationMs,
    );
  }
}
