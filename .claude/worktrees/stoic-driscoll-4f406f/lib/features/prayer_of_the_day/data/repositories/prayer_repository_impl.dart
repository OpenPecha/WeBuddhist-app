import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/prayer_of_the_day/data/datasource/prayer_local_datasource.dart';
import 'package:flutter_pecha/features/prayer_of_the_day/data/models/prayer_model.dart';
import 'package:flutter_pecha/features/prayer_of_the_day/domain/entities/prayer.dart';
import 'package:flutter_pecha/features/prayer_of_the_day/domain/repositories/prayer_repository.dart';

/// Prayer repository implementation.
class PrayerRepositoryImpl implements PrayerRepository {
  final PrayerLocalDataSource _localDataSource;

  PrayerRepositoryImpl({
    required PrayerLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  @override
  Future<Either<Failure, Prayer>> getTodayPrayer() async {
    try {
      final model = await _localDataSource.getTodayPrayer();

      if (model == null) {
        // Return a default prayer for today
        final today = DateTime.now();
        final defaultPrayer = PrayerModel(
          id: 'prayer_${today.year}_${today.month}_${today.day}',
          title: 'Prayer of the Day',
          audioUrl: 'https://s3.ap-south-1.amazonaws.com/monlam.ai.stt/Garchen+Rinpoche+STT/guru-yoga-2009/01-Lama.wav',
          segments: _getDefaultSegments(),
          totalDuration: 'PT5M',
          date: today,
        );

        await _localDataSource.saveTodayPrayer(defaultPrayer);
        return Right(defaultPrayer.toEntity());
      }

      return Right(model.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to load prayer: $e'));
    }
  }

  @override
  Future<Either<Failure, Prayer?>> getPrayerByDate(DateTime date) async {
    try {
      final model = await _localDataSource.getTodayPrayer();

      if (model == null) {
        return Right(null);
      }

      // Check if the stored prayer matches the requested date
      if (_isSameDay(model.date, date)) {
        return Right(model.toEntity());
      }

      return Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to load prayer: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markAsCompleted(String prayerId) async {
    try {
      await _localDataSource.markAsCompleted(prayerId);
      return Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to mark prayer as completed: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Prayer>>> getPrayerHistory(
    DateTime start,
    DateTime end,
  ) async {
    try {
      // For now, return empty list as history tracking is not implemented
      // TODO: Implement proper history tracking in data source
      return Right([]);
    } catch (e) {
      return Left(CacheFailure('Failed to load prayer history: $e'));
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  List<PrayerSegmentModel> _getDefaultSegments() {
    // Default prayer segments - in production, this would come from an API
    return const [
      PrayerSegmentModel(
        id: '1',
        text: 'Avert enemies, harm, and epidemics,',
        startTime: '00:00',
        endTime: '00:10',
      ),
      PrayerSegmentModel(
        id: '2',
        text: 'Pacify all conflicts, expand bodily and mental bliss,',
        startTime: '00:10',
        endTime: '00:20',
      ),
      PrayerSegmentModel(
        id: '3',
        text: 'Increase wealth, dominion, grain, and lifespan,',
        startTime: '00:20',
        endTime: '00:30',
      ),
    ];
  }
}
