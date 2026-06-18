import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/prayer_of_the_day/domain/entities/prayer.dart';
import 'package:flutter_pecha/shared/domain/base_classes/repository.dart';

/// Prayer repository interface.
abstract class PrayerRepository extends Repository {
  /// Get today's prayer.
  Future<Either<Failure, Prayer>> getTodayPrayer();

  /// Get prayer by date.
  Future<Either<Failure, Prayer?>> getPrayerByDate(DateTime date);

  /// Mark prayer as completed.
  Future<Either<Failure, void>> markAsCompleted(String prayerId);

  /// Get prayer history for a date range.
  Future<Either<Failure, List<Prayer>>> getPrayerHistory(
    DateTime start,
    DateTime end,
  );
}
