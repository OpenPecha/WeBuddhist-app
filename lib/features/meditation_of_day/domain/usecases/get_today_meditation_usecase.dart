import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/meditation_of_day/domain/entities/meditation.dart';
import 'package:flutter_pecha/features/meditation_of_day/domain/repositories/meditation_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

/// Get today's meditation use case.
class GetTodayMeditationUseCase extends UseCase<Meditation, NoParams> {
  final MeditationRepository _repository;

  GetTodayMeditationUseCase(this._repository);

  @override
  Future<Either<Failure, Meditation>> call(NoParams params) async {
    return await _repository.getTodayMeditation();
  }
}

/// Mark meditation as completed use case.
class MarkMeditationCompletedUseCase extends UseCase<void, MarkCompletedParams> {
  final MeditationRepository _repository;

  MarkMeditationCompletedUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(MarkCompletedParams params) async {
    if (params.meditationId.isEmpty) {
      return const Left(ValidationFailure('Meditation ID cannot be empty'));
    }
    return await _repository.markAsCompleted(params.meditationId);
  }
}

class MarkCompletedParams {
  final String meditationId;

  const MarkCompletedParams({required this.meditationId});
}
