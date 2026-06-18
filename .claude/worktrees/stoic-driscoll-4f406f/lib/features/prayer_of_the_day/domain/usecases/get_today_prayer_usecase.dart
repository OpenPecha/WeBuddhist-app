import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/prayer_of_the_day/domain/entities/prayer.dart';
import 'package:flutter_pecha/features/prayer_of_the_day/domain/repositories/prayer_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

/// Get today's prayer use case.
class GetTodayPrayerUseCase extends UseCase<Prayer, NoParams> {
  final PrayerRepository _repository;

  GetTodayPrayerUseCase(this._repository);

  @override
  Future<Either<Failure, Prayer>> call(NoParams params) async {
    return await _repository.getTodayPrayer();
  }
}

/// Mark prayer as completed use case.
class MarkPrayerCompletedUseCase extends UseCase<void, MarkCompletedParams> {
  final PrayerRepository _repository;

  MarkPrayerCompletedUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(MarkCompletedParams params) async {
    if (params.prayerId.isEmpty) {
      return const Left(ValidationFailure('Prayer ID cannot be empty'));
    }
    return await _repository.markAsCompleted(params.prayerId);
  }
}

class MarkCompletedParams {
  final String prayerId;

  const MarkCompletedParams({required this.prayerId});
}
