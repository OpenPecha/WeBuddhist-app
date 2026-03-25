import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/meditation_of_day/data/datasource/meditation_local_datasource.dart';
import 'package:flutter_pecha/features/meditation_of_day/data/models/meditation_model.dart';
import 'package:flutter_pecha/features/meditation_of_day/domain/entities/meditation.dart';
import 'package:flutter_pecha/features/meditation_of_day/domain/repositories/meditation_repository.dart';

/// Meditation repository implementation.
class MeditationRepositoryImpl implements MeditationRepository {
  final MeditationLocalDataSource _localDataSource;

  MeditationRepositoryImpl({
    required MeditationLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  @override
  Future<Either<Failure, Meditation>> getTodayMeditation() async {
    try {
      final model = await _localDataSource.getTodayMeditation();

      if (model == null) {
        // Return a default meditation for today
        final today = DateTime.now();
        final defaultMeditation = MeditationModel(
          id: 'meditation_${today.year}_${today.month}_${today.day}',
          title: 'Daily Meditation',
          description: 'Take a moment to breathe and find peace.',
          audioUrl: 'assets/audios/monday_meditation.mp3',
          imageUrl: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800',
          durationMinutes: 10,
          date: today,
        );

        await _localDataSource.saveTodayMeditation(defaultMeditation);
        return Right(defaultMeditation.toEntity());
      }

      return Right(model.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to load meditation: $e'));
    }
  }

  @override
  Future<Either<Failure, Meditation?>> getMeditationByDate(DateTime date) async {
    try {
      final model = await _localDataSource.getTodayMeditation();

      if (model == null) {
        return Right(null);
      }

      // Check if the stored meditation matches the requested date
      if (_isSameDay(model.date, date)) {
        return Right(model.toEntity());
      }

      return Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to load meditation: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markAsCompleted(String meditationId) async {
    try {
      await _localDataSource.markAsCompleted(meditationId);
      return Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to mark meditation as completed: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Meditation>>> getMeditationHistory(
    DateTime start,
    DateTime end,
  ) async {
    try {
      // For now, return empty list as history tracking is not implemented
      // TODO: Implement proper history tracking in data source
      return Right([]);
    } catch (e) {
      return Left(CacheFailure('Failed to load meditation history: $e'));
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
