import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/meditation_of_day/domain/entities/meditation.dart';
import 'package:flutter_pecha/shared/domain/base_classes/repository.dart';

/// Meditation repository interface.
abstract class MeditationRepository extends Repository {
  /// Get today's meditation.
  Future<Either<Failure, Meditation>> getTodayMeditation();

  /// Get meditation by date.
  Future<Either<Failure, Meditation?>> getMeditationByDate(DateTime date);

  /// Mark meditation as completed.
  Future<Either<Failure, void>> markAsCompleted(String meditationId);

  /// Get meditation history for a date range.
  Future<Either<Failure, List<Meditation>>> getMeditationHistory(
    DateTime start,
    DateTime end,
  );
}
